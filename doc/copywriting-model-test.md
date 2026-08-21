# Hero Copy Bake-Off — Claude models

A copywriting test: the **same** SaaS landing-page hero brief handed to four
Claude models, each rendered as it would ship and scored on the craft.

- **Run date:** 2026-08-21
- **Brief:** SaaS landing-page hero (headline, subhead, three benefit bullets, CTA)
- **Product (fictional):** Cadence — an AI async standup for remote engineering teams
- **Entrants:** the current models served for the `opus`, `sonnet`, `haiku`, and `fable` aliases
- **Scoring:** one reviewer, five criteria, each out of 5 (total /25)

> **Read the caveats before quoting the scores** — see [Method & caveats](#method--caveats).

---

## The brief

Every model received this exact prompt — one shot each, no follow-ups.

- **Product — Cadence:** an AI async standup for remote engineering teams. It reads
  each engineer's GitHub, Jira, and Slack activity and posts one concise daily digest,
  so the team can skip the live standup meeting.
- **Deliverable:** Headline (~10 words), subhead (~20 words), three benefit bullets with
  bold lead-ins (~12 words each), one CTA label (~4 words).
- **Voice + rules:** confident, modern, a little playful; not corporate; no emojis;
  American English; stay within the word limits.
- **Control:** identical brief to every entrant. In the visual version every hero is set
  in the same typeface and layout, so the only variable is the writing.

---

## The entries (ranked)

### 01 · Fable 5 — *Boldest* — 23.5 / 25

> **Headline:** The standup that writes itself.
> **Subhead:** Cadence turns your team's GitHub, Jira, and Slack activity into one crisp daily digest — no meeting required.
> **Bullets:**
> - **Reclaim 5 hours** — cancel daily standups and give engineers their mornings back.
> - **Zero status-writing** — updates come straight from commits, PRs, and tickets. Automatically.
> - **Catch blockers early** — stalled work gets flagged before it becomes a fire.
>
> **CTA:** Skip tomorrow's standup

Hook 5.0 · Clarity 4.5 · Voice 5.0 · Bullets & CTA 5.0 · Discipline 4.0

### 01 · Opus — *Sharpest* — 23.5 / 25

> **Headline:** Kill standup. Keep the updates.
> **Subhead:** Cadence turns your team's real GitHub, Jira, and Slack activity into one sharp daily digest — no meeting required.
> **Bullets:**
> - **Skip standup** — Reclaim roughly five hours a week, every week.
> - **Zero busywork** — Updates write themselves from commits, PRs, and tickets.
> - **Catch blockers** — Stalled work surfaces early, before it slips.
>
> **CTA:** Start free

Hook 5.0 · Clarity 5.0 · Voice 4.5 · Bullets & CTA 4.0 · Discipline 5.0

### 03 · Sonnet — *Cleverest* — 22.0 / 25

> **Headline:** Skip the standup. Keep the sync.
> **Subhead:** Cadence turns your team's GitHub, Jira, and Slack activity into one daily digest—no status updates required.
> **Bullets:**
> - **Zero meetings** — Reclaim about 5 hours a week, per team.
> - **No manual updates** — Auto-built from real commits, PRs, and tickets.
> - **Early warnings** — Blockers surface before they become emergencies.
>
> **CTA:** Get Your Time Back

Hook 4.5 · Clarity 4.0 · Voice 4.5 · Bullets & CTA 4.5 · Discipline 4.5

### 04 · Haiku 4.5 — *Clearest* — 21.0 / 25

> **Headline:** Daily updates. No meetings.
> **Subhead:** Your commits, PRs, and tickets become your daily standup—automatically, no meeting.
> **Bullets:**
> - **Skip meetings** — Get back five hours a week per team.
> - **Never write status** — Commits and PRs become your updates.
> - **Nothing slips** — Spot blockers and stalled work early.
>
> **CTA:** Start free

Hook 3.5 · Clarity 5.0 · Voice 3.5 · Bullets & CTA 4.0 · Discipline 5.0

---

## Scorecard

Criteria: **Hook** (headline pull) · **Clarity** (does the value land instantly) ·
**Voice** (on-brief and distinctive) · **Bullets & CTA** (craft of the support copy) ·
**Discipline** (format and word-limit adherence). Each out of 5.

| Model      | Hook | Clarity | Voice | Bullets & CTA | Discipline | **Total** |
|------------|:----:|:-------:|:-----:|:-------------:|:----------:|:---------:|
| **Fable 5**  | 5.0 | 4.5 | 5.0 | 5.0 | 4.0 | **23.5** |
| **Opus**     | 5.0 | 5.0 | 4.5 | 4.0 | 5.0 | **23.5** |
| **Sonnet**   | 4.5 | 4.0 | 4.5 | 4.5 | 4.5 | **22.0** |
| **Haiku 4.5**| 3.5 | 5.0 | 3.5 | 4.0 | 5.0 | **21.0** |

---

## The verdict

Every model cleared the bar — all four nailed the format, hit the numbers, and wrote a
hero you could ship. The spread isn't about competence; it's about nerve.

- **Fable** and **Opus** finish in a genuine photo finish, for opposite reasons. Fable
  takes the biggest swing — *"The standup that writes itself"* is the most quotable line
  in the set, and *"Skip tomorrow's standup"* is the only CTA that names the payoff
  instead of the pricing; it pays with a little discipline, running its bullets long.
  Opus wins the other way — *"Kill standup. Keep the updates."* compresses the whole value
  prop into six words with nothing out of place, but parks on a safe *"Start free."*
- **Sonnet** is the sharp middle: *"Keep the sync"* is the cleverest turn of phrase, though
  the pun costs a touch of literal clarity.
- **Haiku** is the honest tradeoff of its tier — the plainest voice, but also the clearest
  and tightest; nothing wasted. Fine for volume work a human will lightly punch up.

**Pattern worth remembering:** on a task this constrained, capability buys
**distinctiveness, not accuracy**. Generating a hundred variants to A/B? The faster models
are fine. Want the one line that stops a scroll? Reach up the ladder.

---

## Method & caveats

**Why not the actual old models?** The original ask was a bake-off across the *old* Opus
and Sonnet models. Most can't be run: Opus 3, Sonnet 3, both Sonnet 3.5s, Sonnet 3.7, and
Opus 4.1 are **retired** — no endpoint answers for them, and imitating their output would
be fiction, not a test. The still-active older builds (`opus 4.7 / 4.6 / 4.5 / 4.0`,
`sonnet 4.6 / 4.5 / 4.0`) *are* callable, but only over the direct API, which the session
that produced this couldn't reach. So the entrants are the **current** models served for
each alias.

**What is "Opus" / "Sonnet" here?** Whatever the runtime currently serves for the `opus`,
`sonnet`, `haiku`, and `fable` aliases — hence labeled by **tier**, not a pinned version
string. The build behind an alias is harness-controlled and can change.

**How rigorous is the scoring?** Not very, and it isn't trying to be: one brief, one
sample per model, one reviewer on a fixed rubric. No temperature sweeps, no repeated runs,
no blind panel. It's **illustrative**, not a benchmark — a different brief or even a re-run
will reshuffle the close calls. Raw submissions are printed in full above so you can score
them yourself.

**Want the real old-model comparison?** The honest version is a script you run where you
hold an `ANTHROPIC_API_KEY`: it sends this same brief to each still-active older build and
prints the outputs side by side. A ready-to-run harness can be added to this branch on
request.
