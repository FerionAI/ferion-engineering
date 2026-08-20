# Efficiency and feature pricing

Once the cost lives on the issues, two questions become answerable with data instead of opinion:
*are we getting more efficient?* and *what should this feature cost?*

## Reading the numbers

Pull the markers and group them:

```bash
gh issue list --state all --limit 200 --json number,title,labels --jq '.[] | [.number, .title] | @tsv' |
while IFS=$'\t' read -r n t; do
  c=$(gh api "repos/{owner}/{repo}/issues/$n/comments" --jq '.[].body' 2>/dev/null |
      grep -o 'ferion:cost[^-]*' | head -1)
  [ -n "$c" ] && printf '%s\t%s\t%s\n' "$n" "$t" "$c"
done
```

What to look at, in order of usefulness:

| Metric | How to read it |
|---|---|
| **Median cost per issue type** | feature vs bug vs chore. The spread matters more than the average — one 10× outlier is a process problem, not a cost problem. |
| **Tokens per merged PR** | the efficiency signal. Falling over time = the standard is working (less rework, better specs). |
| **Cost of rework** | issues that failed QA and came back. This is where the money actually goes; a spec that prevents one round pays for itself. |
| **Active vs wall time** | a big gap means waiting (on people, on CI, on environments), not on the AI. That is a delivery problem you can fix. |

## The efficiency thesis, and how to check it

Writing less code should cost less: fewer tokens generated, fewer tokens re-read on every subsequent
turn, less to review, less to maintain. That is testable. Compare the median tokens-per-PR of a
period before and after adopting a practice (the write-less-code ladder, better specs, the preflight
gate). If it does not move, the practice is not paying for itself — say so instead of defending it.

Two honest caveats:

- **Cost per issue is not comparable across issue sizes.** Normalize by something (PR count, changed
  lines, story points if you use them) or compare medians within a type.
- **A cheap task that generates rework is expensive.** Always read cost next to the QA-failure rate.
  Optimizing tokens while doubling rework is a loss dressed as a win.

## Pricing a feature

For teams that bill work or need an internal estimate:

1. **Find comparable issues** — same type, similar scope, same stack.
2. **Take the median**, not the average (one runaway session distorts everything).
3. **Add the human time**: the AI cost is rarely the dominant term. Lead time × the loaded cost of
   the people involved is usually 10–100× the token bill.
4. **Add a rework factor** from your actual QA-failure rate, not from optimism.
5. **State the confidence.** "Median of 6 comparable issues, spread 0.8×–2.1×" is an estimate;
   a single number with no spread is a guess wearing a suit.

```
estimate = median(comparable token cost)
         + (estimated lead time × loaded hourly cost)
         × (1 + historical rework rate)
```

## What this is not for

**It is a signal for improvement, never a stick** (P8). The moment cost per task is used to rank
people, two things happen: the numbers stop being recorded honestly, and the team optimizes for the
metric instead of the delivery. Measure the system, not the person.

Concretely, do not: put individual names next to cost numbers, set per-person token budgets, or
compare two developers' medians. Do: track the team trend, find the expensive *classes* of work, and
fix the process that makes them expensive.
