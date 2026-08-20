# The cost block in the dashboard — where each number comes from

The `cost` skill posts a machine-readable marker on each issue; this is how the dashboard turns those
into a block someone can act on.

## Collecting

```bash
# issues closed in the window
gh issue list --state closed --search "closed:2026-08-13..2026-08-20" \
  --json number,title,labels --limit 200

# the cost marker on one issue
gh api "repos/{owner}/{repo}/issues/<n>/comments" --jq '.[].body' \
  | grep -o 'ferion:cost[^>]*'
# -> ferion:cost tokens=1403090 usd=2.05 active_h=0.17 wall_h=0.49
```

Parse the `key=value` pairs. An issue with no marker counts toward the **coverage** denominator — it
does not silently disappear from the sample.

## Capture coverage comes first

```
coverage = issues with a cost marker / issues delivered in the window
```

Show this **before** any average. An average with no coverage next to it is an anecdote presented as
a metric.

| Coverage | What to do |
|---|---|
| ≥ 80% | the block is representative |
| 50–80% | show it, flag the sample size |
| < 50% | show it with a warning, and make closing the capture gap the action item — list the issues missing a marker |

## Median, not average

Cost has a long tail: one runaway session distorts every average. Report:

- **Median per issue**, and the spread (p25–p75) so the reader sees the variability.
- **Median per type** (feature / bug / chore) — the interesting comparison.
- **Sum per epic** — this is the number that prices an initiative.
- **Trend vs the previous window** (rule #1: no number without its previous value).

## Reading sentences, not just tiles

Every tile gets one sentence saying what it means and what to do:

> *Median cost per feature: $2.10 · was $3.40 · improved 38%. The drop follows the state matrix
> becoming mandatory in refinement — fewer QA round trips per issue.*

A number with no interpretation gets ignored; a number with a wrong interpretation gets acted on
wrongly. If you cannot explain the movement, say "no clear explanation" — that is honest and it
prompts someone who knows to fill it in.

## Rules

- **USD is an estimate** derived from tokens, useful for comparison and trend. Never present it as an
  invoice; the provider console is authoritative.
- **Per issue, per type, per team — never per person** (P8). The moment cost is attributed to
  individuals, the numbers stop being recorded honestly.
- **Read cost next to the QA failure rate.** Cheap work that generates rework is expensive work with
  a delayed invoice.
- **No PII** anywhere in the cost data.

## What the block is for

Not accounting. It answers three questions: which classes of work are expensive, is the trend
improving, and what should a similar feature cost next time
(`cost/references/efficiency-and-pricing.md`).
