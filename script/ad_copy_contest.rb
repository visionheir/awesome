#!/usr/bin/env ruby
# frozen_string_literal: true
#
# ad_copy_contest.rb — a blind advertising-copywriting contest across Claude models.
#
# WHAT IT DOES
#   1. Sends ONE identical creative brief to each contestant model.
#   2. Anonymizes the entries (A, B, C…) and has a judge model score them BLIND on
#      five criteria, then rank them.
#   3. Prints a leaderboard and writes timestamped .md + .html reports.
#
# WHY IT EXISTS
#   The genuinely old models (Opus 3, Sonnet 3 / 3.5 / 3.7, Opus 4.1) are RETIRED and
#   can't be called at all. The still-active older builds below ARE callable, but only
#   with direct API access. Run this where you hold an ANTHROPIC_API_KEY to get the
#   real bake-off that a sandboxed session can't.
#
# SETUP
#   gem install anthropic
#   export ANTHROPIC_API_KEY=sk-ant-...
#
# RUN
#   ruby script/ad_copy_contest.rb
#
# OPTIONS (environment variables)
#   JUDGE_MODEL   model id used to score entries   (default: claude-opus-4-8)
#   OUT_DIR       directory for the reports         (default: ./contest_out)
#
# Everything you'd want to change — the contestants and the brief — are the two
# constants right below.

require "anthropic"
require "json"
require "time"
require "fileutils"

# ---------------------------------------------------------------------------
# Contestants — the still-active older Opus & Sonnet builds.
# Aliases are stable; edit freely. Drop in a current model (e.g. "claude-opus-5")
# if you want a modern benchmark competing in the same field.
# ---------------------------------------------------------------------------
CONTESTANTS = [
  { id: "claude-opus-4-7",   name: "Opus 4.7"   },
  { id: "claude-opus-4-6",   name: "Opus 4.6"   },
  { id: "claude-opus-4-5",   name: "Opus 4.5"   },
  { id: "claude-opus-4-0",   name: "Opus 4.0"   },
  { id: "claude-sonnet-4-6", name: "Sonnet 4.6" },
  { id: "claude-sonnet-4-5", name: "Sonnet 4.5" },
  { id: "claude-sonnet-4-0", name: "Sonnet 4.0" },
].freeze

JUDGE_MODEL = ENV.fetch("JUDGE_MODEL", "claude-opus-4-8")
OUT_DIR     = ENV.fetch("OUT_DIR", File.join(Dir.pwd, "contest_out"))

# ---------------------------------------------------------------------------
# The creative brief. Swap this for your own campaign — it is the only thing
# every contestant sees, and they all see it verbatim.
# ---------------------------------------------------------------------------
BRIEF_NAME = "Torch Hot Sauce — launch ad"

BRIEF = <<~BRIEF
  You are a world-class advertising copywriter entering a copywriting contest.
  Write a single print/social advertisement for the product below.

  PRODUCT
  - Brand: Torch
  - What it is: a small-batch hot sauce that is genuinely, stupidly hot — but that
    actually tastes good. Smoked chili, charred citrus, real depth. Heat with flavor,
    not heat instead of it.
  - Audience: people who put hot sauce on everything and are bored of sauces that are
    all burn and no taste.
  - Personality: bold, witty, a little reckless. Confident, never mean.

  DELIVERABLE (use exactly these four labels, in this order)
  Headline: <= 8 words — the star of the ad
  Body: exactly 2 short sentences, <= 40 words total
  Tagline: <= 5 words — the line that sticks
  Alt headline: one different headline direction, <= 8 words

  RULES
  - American English. No emojis.
  - Do not use the words "unleash", "flavor journey", "bring the heat", or
    "faint of heart" — they are banned clichés.
  - Make the reader want to buy it. Return ONLY the ad, as the four labeled lines.
BRIEF

# Judging rubric — five criteria, each scored 0–10 (so 50 is a perfect card).
CRITERIA = %w[hook voice persuasion craft originality].freeze

# ---------------------------------------------------------------------------
# Anthropic plumbing
# ---------------------------------------------------------------------------
def client
  @client ||= Anthropic::Client.new
end

# Pull the plain text out of a response, ignoring any non-text blocks.
def extract_text(message)
  blocks = message.respond_to?(:content) ? message.content : []
  blocks
    .select { |b| b.respond_to?(:text) && b.respond_to?(:type) && b.type.to_s == "text" }
    .map(&:text)
    .join("\n")
    .strip
end

# One generation call. Never raises — a failed model is reported and skipped so
# one deprecation doesn't kill the whole contest.
def generate(model_id, prompt, max_tokens: 1024)
  message = client.messages.create(
    model: model_id,
    max_tokens: max_tokens,
    messages: [{ role: "user", content: prompt }]
  )
  { ok: true, text: extract_text(message) }
rescue StandardError => e
  { ok: false, error: "#{e.class}: #{e.message}" }
end

def parse_json(text)
  JSON.parse(text)
rescue JSON::ParserError
  match = text.match(/\{.*\}/m) # tolerate stray prose around the JSON
  match ? (JSON.parse(match[0]) rescue nil) : nil
end

def build_judge_prompt(brief, labeled_entries)
  entries = labeled_entries
            .map { |e| "=== ENTRY #{e[:label]} ===\n#{e[:text]}" }
            .join("\n\n")

  <<~PROMPT
    You are the head judge of an advertising copywriting contest — a seasoned
    creative director with no patience for filler. Below is the brief the writers
    were given, then #{labeled_entries.size} anonymous entries. Judge the writing
    alone; you do not know who wrote what.

    THE BRIEF
    #{brief}

    THE ENTRIES
    #{entries}

    Score EVERY entry on these five criteria, each an integer 0–10:
      hook        — does the headline stop you cold
      voice       — nails the bold/witty/reckless brand personality
      persuasion  — actually makes you want to buy the sauce
      craft       — tight, precise, well-made lines; follows the format
      originality — fresh; not a cliché or a paraphrase of the brief

    Be decisive and spread the scores — do not bunch everything at 7–8. Penalize any
    banned cliché or broken format. Reward a real idea.

    Return ONLY valid JSON — no prose, no code fence — in exactly this shape:
    {
      "results": [
        {"label": "A", "scores": {"hook": 0, "voice": 0, "persuasion": 0, "craft": 0, "originality": 0}, "note": "<= 20 words on why"}
      ],
      "winner": "A",
      "summary": "<= 40 words on what separated the top of the field from the rest"
    }
  PROMPT
end

# Prefer summing the criteria ourselves so a judge arithmetic slip can't skew ranks.
def total_for(scores, fallback)
  if CRITERIA.all? { |k| scores[k].is_a?(Numeric) }
    CRITERIA.sum { |k| scores[k] }
  else
    fallback.to_f
  end
end

def h(str)
  str.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
end

# ---------------------------------------------------------------------------
# Reports
# ---------------------------------------------------------------------------
def markdown_report(rows, summary, stamp)
  out = []
  out << "# Advertising copy contest — #{BRIEF_NAME}"
  out << ""
  out << "- Run: #{stamp}"
  out << "- Judge: `#{JUDGE_MODEL}` (blind — entries anonymized A/B/C… before scoring)"
  out << "- Contestants: #{rows.map { |r| r[:model] }.join(', ')}"
  out << ""
  out << "> One brief, one sample per model, one judge on a fixed rubric. Illustrative, not a benchmark."
  out << ""
  out << "## Leaderboard"
  out << ""
  out << "| # | Model | Total /50 | Hook | Voice | Persuasion | Craft | Originality |"
  out << "|--:|-------|:---------:|:----:|:-----:|:----------:|:-----:|:-----------:|"
  rows.each_with_index do |r, i|
    s = r[:scores]
    out << "| #{i + 1} | **#{r[:model]}** | **#{r[:total]}** | " \
           "#{s['hook']} | #{s['voice']} | #{s['persuasion']} | #{s['craft']} | #{s['originality']} |"
  end
  out << ""
  out << "**Judge summary:** #{summary}" if summary && !summary.empty?
  out << ""
  out << "## The entries"
  out << ""
  rows.each_with_index do |r, i|
    out << "### #{i + 1}. #{r[:model]} — #{r[:total]}/50"
    out << ""
    out << "> _#{r[:note]}_" if r[:note] && !r[:note].to_s.empty?
    out << ""
    out << "```"
    out << r[:text]
    out << "```"
    out << ""
  end
  out.join("\n")
end

def html_report(rows, summary, stamp)
  css = <<~CSS
    :root{--bg:#eceef3;--card:#fff;--ink:#14161b;--soft:#535966;--line:#dce0e8;--accent:#2e56c8;--gold:#b77714}
    @media (prefers-color-scheme:dark){:root{--bg:#0c0e12;--card:#15181e;--ink:#eaecf1;--soft:#9ba2ae;--line:#262b33;--accent:#7ca1ff;--gold:#e4ac4a}}
    *{box-sizing:border-box}
    body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
    main{max-width:820px;margin:0 auto;padding:44px 20px 70px}
    .eyebrow{font:600 .72rem/1 ui-monospace,monospace;letter-spacing:.18em;text-transform:uppercase;color:var(--accent);margin:0 0 12px}
    h1{font-size:clamp(1.7rem,4vw,2.4rem);margin:0 0 6px;letter-spacing:-.02em;text-wrap:balance}
    .meta{color:var(--soft);margin:0 0 26px;font-size:.9rem}
    .meta code{font-family:ui-monospace,monospace;font-size:.85em}
    .tw{overflow-x:auto;border:1px solid var(--line);border-radius:12px;background:var(--card)}
    table{width:100%;border-collapse:collapse;font-size:.9rem;min-width:520px}
    th,td{padding:11px 8px;text-align:center;border-bottom:1px solid var(--line)}
    th{font:600 .64rem/1 ui-monospace,monospace;letter-spacing:.08em;text-transform:uppercase;color:var(--soft)}
    td{font-variant-numeric:tabular-nums;color:var(--soft)}
    td.m,th.m{text-align:left}
    td.m{color:var(--ink);font-weight:600}
    td.t{color:var(--ink);font-weight:700}
    tr.win td{background:color-mix(in srgb,var(--gold) 13%,transparent)}
    tr:last-child td{border-bottom:0}
    .summary{color:var(--soft);font-style:italic;margin:18px 2px 34px;max-width:64ch}
    .cards{display:flex;flex-direction:column;gap:16px}
    .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:18px 20px}
    .card.win{border-color:color-mix(in srgb,var(--gold) 45%,var(--line))}
    .card header{display:flex;align-items:center;gap:12px;margin-bottom:10px}
    .rk{font:700 1rem/1 ui-monospace,monospace;color:var(--soft)}
    .card.win .rk{color:var(--gold)}
    .card h3{margin:0;font-size:1.2rem;flex:1}
    .tot{font:700 1.3rem/1 ui-monospace,monospace}
    .tot i{font-style:normal;font-size:.7rem;color:var(--soft)}
    .scores{display:flex;flex-wrap:wrap;gap:6px 14px;margin-bottom:10px;font-size:.78rem;color:var(--soft)}
    .scores i{font-style:normal;color:var(--accent);margin-right:5px;text-transform:uppercase;letter-spacing:.04em;font-size:.9em}
    .note{margin:0 0 12px;color:var(--soft);font-size:.9rem}
    pre{margin:0;background:var(--bg);border:1px solid var(--line);border-radius:8px;padding:14px 16px;font:.82rem/1.6 ui-monospace,SFMono-Regular,Menlo,monospace;white-space:pre-wrap;word-break:break-word;color:var(--ink)}
    footer{margin-top:34px;color:var(--soft);font-size:.78rem;border-top:1px solid var(--line);padding-top:18px}
  CSS

  rows_html = rows.each_with_index.map do |r, i|
    s = r[:scores]
    cls = i.zero? ? ' class="win"' : ""
    "<tr#{cls}><td>#{i + 1}</td><td class=\"m\">#{h(r[:model])}</td><td class=\"t\">#{r[:total]}</td>" \
      "<td>#{s['hook']}</td><td>#{s['voice']}</td><td>#{s['persuasion']}</td>" \
      "<td>#{s['craft']}</td><td>#{s['originality']}</td></tr>"
  end.join("\n")

  cards_html = rows.each_with_index.map do |r, i|
    s = r[:scores]
    score_bits = CRITERIA.map { |k| "<span><i>#{k}</i>#{s[k].nil? ? '&ndash;' : s[k]}</span>" }.join
    <<~CARD
      <article class="card#{i.zero? ? ' win' : ''}">
        <header><span class="rk">#{i + 1}</span><h3>#{h(r[:model])}</h3><span class="tot">#{r[:total]}<i>/50</i></span></header>
        <div class="scores">#{score_bits}</div>
        #{r[:note].to_s.empty? ? '' : "<p class=\"note\">#{h(r[:note])}</p>"}
        <pre>#{h(r[:text])}</pre>
      </article>
    CARD
  end.join("\n")

  <<~HTML
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Ad Copy Contest — #{h(BRIEF_NAME)}</title>
    <style>#{css}</style>
    </head>
    <body>
    <main>
      <p class="eyebrow">Advertising copywriting contest &middot; blind judging</p>
      <h1>#{h(BRIEF_NAME)}</h1>
      <p class="meta">#{stamp} &middot; judge <code>#{h(JUDGE_MODEL)}</code> &middot; #{rows.size} contestants</p>
      <div class="tw"><table>
        <thead><tr><th>#</th><th class="m">Model</th><th>Total</th><th>Hook</th><th>Voice</th><th>Persu.</th><th>Craft</th><th>Orig.</th></tr></thead>
        <tbody>#{rows_html}</tbody>
      </table></div>
      #{summary.to_s.empty? ? '' : "<p class=\"summary\">#{h(summary)}</p>"}
      <section class="cards">#{cards_html}</section>
      <footer>One brief &middot; one sample per model &middot; one judge on a fixed rubric. Illustrative, not a benchmark — a different brief or a re-run will reshuffle close calls. Entries were anonymized before scoring.</footer>
    </main>
    </body>
    </html>
  HTML
end

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
def run
  if ENV["ANTHROPIC_API_KEY"].to_s.empty?
    abort "Set ANTHROPIC_API_KEY first (export ANTHROPIC_API_KEY=sk-ant-...)."
  end

  puts "Advertising copy contest"
  puts "  Brief:       #{BRIEF_NAME}"
  puts "  Contestants: #{CONTESTANTS.size}"
  puts "  Judge:       #{JUDGE_MODEL}"
  puts "-" * 60

  # Phase 1 — every contestant answers the same brief.
  entries = []
  CONTESTANTS.each do |c|
    print "  #{c[:name].ljust(11)} … "
    res = generate(c[:id], BRIEF)
    if res[:ok] && !res[:text].empty?
      puts "ok"
      entries << { model: c[:name], id: c[:id], text: res[:text] }
    else
      puts "SKIPPED (#{res[:error] || 'empty response'})"
    end
  end
  abort "\nNo contestant produced copy — check your key and model access." if entries.empty?

  # Phase 2 — anonymize, then judge blind.
  labels  = ("A".."Z").to_a
  labeled = entries.shuffle.each_with_index.map { |e, i| e.merge(label: labels[i]) }

  puts "\nJudging #{labeled.size} entries blind with #{JUDGE_MODEL} …"
  judged = generate(JUDGE_MODEL, build_judge_prompt(BRIEF, labeled), max_tokens: 2000)
  abort "Judge call failed: #{judged[:error]}" unless judged[:ok]

  verdict = parse_json(judged[:text])
  abort "Could not parse the judge's JSON. Raw output:\n\n#{judged[:text]}" unless verdict

  # Phase 3 — map anonymous labels back to real models and rank.
  by_label = labeled.to_h { |e| [e[:label], e] }
  rows = Array(verdict["results"]).filter_map do |r|
    e = by_label[r["label"]]
    next unless e

    scores = r["scores"] || {}
    { model: e[:model], id: e[:id], label: e[:label], text: e[:text],
      scores: scores, total: total_for(scores, r["total"]), note: r["note"].to_s }
  end

  # Include any entry the judge forgot, so nothing silently vanishes.
  scored = rows.map { |r| r[:label] }
  labeled.reject { |e| scored.include?(e[:label]) }.each do |e|
    rows << { model: e[:model], id: e[:id], label: e[:label], text: e[:text],
              scores: {}, total: 0, note: "(not scored by judge)" }
  end
  rows.sort_by! { |r| -r[:total].to_f }

  summary   = verdict["summary"].to_s
  stamp     = Time.now.strftime("%Y-%m-%d %H:%M")
  file_ts   = Time.now.strftime("%Y%m%d-%H%M%S")

  # Console leaderboard
  puts "\n" + "=" * 60
  puts "RESULTS — #{BRIEF_NAME}"
  puts "=" * 60
  rows.each_with_index do |r, i|
    puts "#{(i + 1).to_s.rjust(2)}. #{r[:model].ljust(11)} #{r[:total].to_s.rjust(4)}/50   #{r[:note]}"
  end
  puts "\nWinner: #{rows.first[:model]} (blind entry #{rows.first[:label]})" unless rows.empty?
  puts "Judge:  #{summary}" unless summary.empty?

  # Reports
  FileUtils.mkdir_p(OUT_DIR)
  md_path   = File.join(OUT_DIR, "contest-#{file_ts}.md")
  html_path = File.join(OUT_DIR, "contest-#{file_ts}.html")
  File.write(md_path, markdown_report(rows, summary, stamp))
  File.write(html_path, html_report(rows, summary, stamp))

  puts "\nReports written:"
  puts "  #{md_path}"
  puts "  #{html_path}   (open in a browser)"
end

run if $PROGRAM_NAME == __FILE__
