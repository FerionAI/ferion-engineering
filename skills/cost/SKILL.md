---
name: cost
description: Measures what each task costs in tokens and time and records it on the GitHub issue itself (the source of truth), to gauge efficiency and price features (time is money too). Use when someone asks "how much did this task/feature cost", "how many tokens did we spend", "how efficient is this", "how long did it take", "what should we charge for this feature", "cost by task type", or when setting up cost capture. Writes to the issue as a structured comment; feeds the health dashboard.
---

# cost — cost and efficiency per task

Measure what each task costs — **tokens + time** — and **write it on the GitHub issue**. Since the
issue is the source of truth, it should carry its own cost alongside scope and QA. Time is as much
currency as tokens.

> The dollar figure is a **client-side estimate** (computed locally), great for comparison and trend;
> for authoritative billing, use the provider's console.
>
> **Where capture works:** `/usage`, `ccusage` and the telemetry come from **Claude Code (local
> CLI)**. In a browser-app flow (typical for a PM), those numbers may not exist — in that case record
> what you can (lead time from the issue timeline) and flag that the token cost came from the CLI or
> is pending. Never invent a cost number.

## 1. Measure (tokens + time)

- **Tokens:** input, output, cache read/write (cheap cache counts in your favor).
- **Estimated cost (USD):** tokens × model price.
- **Time:** active agent time (API), wall time, and the human lead time (DORA).
- **Output:** lines, PRs, commits — to relate cost to delivery.

Where the numbers come from — **one command** (see `references/capture.md`):

```bash
python3 <path to this skill>/scripts/session-cost.py
# {"session":"…","scope":"issue","issue":"123","since":"2026-08-26T15:49:18Z","tokens":138034,"usd":0.1066,…}
```

It resolves the repository's current session, counts tokens and hours in the transcript, and takes the
USD from `ccusage` (the same source as `/usage`).

**One session can hold several issues — the cost must not become one bucket.** So `flow-gate.sh` writes
a **baseline** (UTC) into the repo flow state on every new issue, and the script measures **from there
onwards** (`scope:"issue"`). Nothing to do by hand: switch issue, the cost resets with it. Edge cases:

- `--whole-session` — ignore the baseline (`scope:"session"`); that is what applies when the flow is in
  `bypass` or the repo has no flow state.
- `--since=<ISO>` — an explicit baseline (resuming an old issue, fixing a bad cut).
- The slice's USD is the model's `ccusage` cost **prorated by the relative price of its tokens**
  (output 5x input, cache write 1.25x/2x, cache read 0.1x) — exact per model, still an estimate.

## 2. Record it ON the issue (primary)

**When:** at the `in review` milestone — **before** labelling the issue `status:in-review`
(`preflight` step 5). The cost is part of the milestone, not an optional step afterwards: it is where
dev cost closes, the agent is already writing to the issue, and the session still exists to be
measured. This holds even when the label was not applied through `preflight` (a direct request,
`ship`) — whoever labels, records. (An extra session later — review fixes — adds on top.)

**How** — a comment with a machine-readable marker:

```bash
gh issue comment 123 --body '<!-- ferion:cost tokens=1403090 usd=2.05 active_h=0.17 wall_h=0.49 -->
**Dev cost** (estimated, session `abc123`)

| tokens | USD | active | wall | model |
|---|---|---|---|---|
| 1,403,090 | 2.05 | 0.17h | 0.49h | claude-opus-5 |

in 1.2M · out 21k · cache 180k'
```

Rules:
- **Use `--body`, not `--body-file`.** The flow hook stamps the cost milestone from the marker it can
  see in the command — a file path tells it nothing. This is a deliberate constraint: the milestone
  is stamped from reality, never from a claim.
- **Several sessions on the same issue:** read the previous comment and **add to it**, or post a new
  comment and let `health` sum them. Be consistent; say which you did.
- **Several issues in the same session:** do not add anything up — the script already cuts at the
  issue's baseline (above). If it says `scope:"session"` where it should say `issue`, the number covers
  the whole session: say that in the comment.
- **No number** (app flow, `ccusage` unavailable): **do not post a number** — comment what you have
  and flag it in the summary. Never invent a cost.
- **Never put PII in a cost record** (privacy): issue number and team, not a person's data.

## 3. Aggregate and decide (from the issues)

With the cost on the issues, aggregate with `gh`:

```bash
gh issue list --state closed --limit 200 --json number,title,labels
gh api "repos/{owner}/{repo}/issues/123/comments" --jq '.[].body' | grep -o 'ferion:cost[^>]*'
```

- Cost by task type (feature/bug/refactor) and the trend.
- Tokens per PR; the effect of writing less code (less code → fewer tokens).
- Feature pricing from the median of similar issues (see `references/efficiency-and-pricing.md`).
- The `health` dashboard pulls these numbers **from the issues** for its Cost & Efficiency block.

## Principles

- **The issue carries the cost** — as it carries scope and QA.
- **Measure to decide, not to punish** (P8): cost is an efficiency signal.
- **Cheap with quality** is the goal; cheap that generates rework is expensive.
- **No PII** in cost records: issue number and team, never personal data.
