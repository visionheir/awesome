# Advertising copy contest (`script/ad_copy_contest.rb`)

A blind advertising-copywriting contest across the **still-active older Claude
models**. It sends one identical creative brief to every contestant, then has a
judge model score the anonymized entries on a five-part rubric and rank them.

This is the honest version of the model bake-off that a sandboxed session can't
run — the older builds are only reachable over the direct API, so you run this
where you hold a key.

## Why this exists

The genuinely *old* models can't be tested at all — **Opus 3, Sonnet 3 / 3.5 /
3.7, and Opus 4.1 are retired**; no endpoint answers for them. The builds this
script competes are the ones that are still callable:

- **Opus** 4.7, 4.6, 4.5, 4.0
- **Sonnet** 4.6, 4.5, 4.0

## Setup

```bash
gem install anthropic
export ANTHROPIC_API_KEY=sk-ant-...
```

## Run

```bash
ruby script/ad_copy_contest.rb
```

You get a console leaderboard plus two timestamped reports in `./contest_out/`:
a Markdown file and a self-contained, theme-aware HTML page (open it in a
browser).

## How the judging works

1. **Generate** — each contestant answers the same brief, one shot each. A model
   that errors or has been retired is reported and skipped, not fatal.
2. **Judge blind** — entries are shuffled and relabeled `A`, `B`, `C`… so the
   judge never sees which model wrote what. It scores every entry 0–10 on
   **hook, voice, persuasion, craft, originality** (50 = perfect card). Totals
   are summed locally, so a judge arithmetic slip can't skew the ranking.
3. **Reveal** — labels are mapped back to model names and the field is ranked.

## Customizing

Everything you'd want to change lives at the top of the script:

| What | How |
|------|-----|
| The brief | Edit the `BRIEF` / `BRIEF_NAME` constants (ships with a hot-sauce ad brief). |
| The contestants | Edit the `CONTESTANTS` array — drop in `claude-opus-5` to benchmark a current model against the old field. |
| The judge | `JUDGE_MODEL=claude-opus-5 ruby script/ad_copy_contest.rb` (default `claude-opus-4-8`). |
| Output folder | `OUT_DIR=./results ruby script/ad_copy_contest.rb` |

## Caveats

One brief, one sample per model, one judge on a fixed rubric — **illustrative,
not a benchmark**. A different brief, or even a re-run, will reshuffle the close
calls. For a sturdier read, run it several times or across a few briefs and
average. Reaching a current model in as a contestant is the fairest way to see
how far the older builds actually sit behind today's models.
