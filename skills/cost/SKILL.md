---
name: cost
description: Measures what each task costs in tokens and time and records it on the issue itself (GitHub or GitLab) (the source of truth), to gauge efficiency and price features (time is money too). Use when someone asks "how much did this task/feature cost", "how many tokens did we spend", "how efficient is this", "how long did it take", "what should we charge for this feature", "cost by task type", or when setting up cost capture. Writes to the issue as a structured comment; feeds the health dashboard.
---

# cost — cost and efficiency per task

Measure what each task costs — **tokens + time** — and **write it on the issue** (GitHub, or GitLab via `glab issue note` — `issues/references/forge-commands.md`). Since the
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

Where the numbers come from — **one command, fixed path** (see `references/capture.md`):

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/cost/scripts/session-cost.py
# {"session":"…","scope":"issue","issue":"123","tokens":138034,"usd":0.1066,"requests":85,…,
#  "comment":"<!-- ferion:cost tokens=138034 usd=0.1066 active_h=0.17 wall_h=0.49 requests=85 -->\n**Dev cost** …"}
```

It resolves the repository's current session, counts tokens, round trips and hours in the transcript,
takes the USD from `ccusage` (the same source as `/usage`) **and returns the comment body ready to post**.

> **Do not go looking** for the script or the marker format — they are here and inside the script.
> Recording cost is **two calls**: run the script → `gh issue comment <n> --body '<comment>'`. Every
> extra call spent rediscovering a constant re-reads the whole context (ADR-0004).

**`requests` (round trips) is the number that predicts time and dollars.** Spend is ~`calls × context`
and almost all tokens are context re-reads; a raw token count does not say where to improve, the call
count does. It goes into the marker. To see **where** the calls go across skills (not one issue), run
`python3 ${CLAUDE_PLUGIN_ROOT}/skills/cost/scripts/skill-profile.py` — calls, minutes and tokens per
skill, from the local transcripts.

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

**How** — post the script's `comment` as is: the machine-readable marker plus the table. A number
that is unavailable is already **left out** of the marker (never `null`).

```bash
gh issue comment 123 --body '<!-- ferion:cost tokens=1403090 usd=2.05 active_h=0.17 wall_h=0.49 requests=85 -->
**Dev cost** (estimated, session `abc123`)

| tokens | USD | active | wall | round trips | model |
|---|---|---|---|---|---|
| 1,403,090 | 2.05 | 0.17h | 0.49h | 85 | claude-opus-5 |

in 1,220,000 · out 21,000 · cache read 160,990 · cache write 1,100'
```

Rules:
- **Use `--body`, not `--body-file`.** The flow hook stamps the cost milestone from the marker it can
  see in the command — a file path tells it nothing. This is a deliberate constraint: the milestone
  is stamped from reality, never from a claim.
- **Several sessions on the same issue:** read the previous comment and **add to it**, or post a new
  comment and let `health` sum them. Be consistent; say which you did.
- **Several issues in one PR (a group):** the script measures the group once and splits it (`split: N`):
  the marker carries 1/N of every number. Post the **same** comment on each issue of the group, so
  summing the markers gives the group back. The split is equal; if one issue clearly weighed more,
  say so in the comment.
- **Never edit a cost comment another process posted** — post your own. Each record being its own
  comment is what keeps one process from overwriting another's number.
- **Several issues in the same session:** do not add anything up — the script already cuts at the
  issue's baseline (above). If it says `scope:"session"` where it should say `issue`, the number covers
  the whole session: say that in the comment.
- **No number** (app flow, `ccusage` unavailable): **do not post a number** — comment what you have
  and flag it in the summary. Never invent a cost.
- **Never put PII in a cost record** (privacy): issue number and team, not a person's data.

### A cost measured another way (`kind=qa`)

A QA-automation slice — only the work of automating one scenario, measured from when it started
(`session-cost.py --since=<ISO> --kind=qa`) — goes in **its own comment**, with `kind=qa` in the
marker. **Never add it to the dev cost or compare the two:** the dev slice counts every context
re-read of a whole working session, the QA slice only its own work, so they differ by orders of
magnitude by **method**, not by effort. A "total cost of the issue" adding both is a false number;
aggregate one kind at a time and say which (a marker with no `kind` is dev).

## 3. Aggregate and decide (from the issues)

With the cost on the issues, aggregate with `gh`:

```bash
gh issue list --state closed --limit 200 --json number,title,labels
gh api "repos/{owner}/{repo}/issues/123/comments" --jq '.[].body' | grep -o 'ferion:cost[^>]*'
```

- One `kind` at a time (no `kind` = dev; `kind=qa` is a separate series — above).
- Cost by task type (feature/bug/refactor) and the trend.
- Tokens and **round trips** per PR; the effect of writing less code (less code → fewer tokens).
- Feature pricing from the median of similar issues (see `references/efficiency-and-pricing.md`).
- The `health` dashboard pulls these numbers **from the issues** for its Cost & Efficiency block.

### The plugin's own usage (where the plugin costs, not what one issue cost)

A cost comment only exists for an issue that **reached the end of the flow** — it measures the issue,
not adoption. For "where does the flow leak, which skill eats the round trips" across people, the
source is the aggregated telemetry posted to an issue of the plugin's own repo — **only from people
who opted in** (`touch ~/.claude/ferion-telemetry`; ADR-0005):

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/hooks/telemetry.py --preview   # what would leave this machine (no opt-in needed)
python3 ${CLAUDE_PLUGIN_ROOT}/hooks/telemetry.py --report    # this month: the flow funnel + cost per skill
```

Aggregated, with no ranking per person — **measure to decide, not to punish**.

## Principles

- **The issue carries the cost** — as it carries scope and QA.
- **Measure to decide, not to punish** (P8): cost is an efficiency signal.
- **Cheap with quality** is the goal; cheap that generates rework is expensive.
- **No PII** in cost records: issue number and team, never personal data.
