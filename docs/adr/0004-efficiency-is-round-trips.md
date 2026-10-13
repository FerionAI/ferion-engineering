# ADR-0004: The plugin's efficiency is measured in round trips, not words

- **Status:** accepted
- **Date:** 2026-10-13   ·   **Author(s):** `<FILL>`   ·   **Issue/Epic:** —

## Context
The perception was that the plugin "talks too much" and that this made it slow and expensive. The
way to settle that is to measure, not to argue: the local transcripts already record, per API
request, the token usage split by type (input, output, cache read, cache write), the tool calls and
the timestamps. Read a few weeks of real sessions and a sample of issues with their cost recorded,
and four things stand out:

- **Almost all tokens are context re-reads** (cache read). Every call re-sends the whole context, so
  the bill tracks the context size times the number of calls. The output is a small fraction of the
  total, roughly half of it is thinking, and **prose addressed to the person is around one percent**.
- **The mechanical steps were chatty.** A single `preflight` run took on the order of a hundred
  calls; recording the cost spent dozens, most of them rediscovering constants (where the script
  lives, which field or marker to write).
- **Rituals re-read what was already there.** The session hook injects the flow status, and the
  agent still ran `flow-gate.sh status` by hand, over and over; it searched the plugin's own folder
  for its scripts; it read whole files when it needed one section.
- **Prose is concentrated, not spread.** The median message is short; a small share of messages —
  the end-of-step reports — carries most of the text.

So: `spend ≈ round trips × context size`. Cutting prose improves **reading**; only cutting calls
improves the **bill** and the **clock**.

Run the same measurement on your own sessions before trusting the conclusion:
`python3 skills/cost/scripts/skill-profile.py` prints, per skill, the calls, minutes and tokens, and
for the whole set the share of context re-reads and of prose.

## Decision
1. **The plugin's efficiency is measured in round trips.** `session-cost.py` reports `requests`,
   and it goes into the issue's cost marker next to tokens, USD and hours.
2. **Mechanical checks run batched.** `preflight` step 1 is **one call**
   (`skills/preflight/scripts/preflight.sh`: build, types, lint, tests and the PR-bot check, with a
   short report and only the tail of a failing step's log). Split into separate calls only to debug
   one specific failure.
3. **Do not re-query state a hook already injected.** The `SessionStart` banner already carries
   `flow-gate.sh status`; the command is kept for when the banner is missing (`/clear`, a
   summarized context).
4. **Constants live in the skill, not in a search.** Script paths are fixed in the skill, and
   `session-cost.py` prints the ready comment body (marker included): recording cost is **two
   calls** — run the script, post the comment.
5. **Closing a step is up to 3 lines + the link.** A long report only when asked (P8).
6. **Costs measured with different methods are never added or compared.** A QA-automation slice
   that counts only its own work is not on the same base as a dev session that counts every context
   re-read; it carries its own `kind` in the marker and is aggregated one kind at a time.

## Alternatives considered
- **Only tighten the terseness rule** (the initial hypothesis) — it addresses about one percent of
  the cost. Rejected as the *only* measure; it stays, for the reading gain.
- **Switch to a cheaper model for mechanical work** — already P8 and still valid, but it does not
  touch the cause: the volume is context re-reading, which exists with any model.
- **Compress the context aggressively (summaries, frequent `/clear`)** — risks losing flow state and
  causes rework, which costs more. Rejected for now; revisit if the median context keeps growing.
- **Run the preflight steps in parallel** — build and tests compete for the same output directory,
  and the gain is smaller than collapsing the round trips. Deferred (noted as `ponytail:` in the
  script).

## Consequences
- **Positive:** less wall time per issue, fewer tokens re-read, a per-issue cost that is comparable
  across teams (`requests` is the actionable number), shorter reports to read.
- **Negative / costs:** `preflight.sh` has to **detect** the repo's commands — a repo off the usual
  shape needs an override (`PREFLIGHT_BUILD`/`PREFLIGHT_TYPES`/`PREFLIGHT_LINT`/`PREFLIGHT_TEST`),
  and a step with no command reports "not configured" (degrades with a warning; never green). One
  call gives fewer chances to interrupt midway — that is why "found it, show it now" still holds for
  steps 2–4.
- **Impact:** `preflight`, `cost`, `start`, `ship`, `agentic-flow`, `health`, the session banner and
  the constitution (P8).

## Constitution principles involved
- **P8** (agentic efficiency): gains its operational criterion — `round trips × context` — and the
  rules to batch, not re-query, keep constants in the skill and read the excerpt instead of the file.
- **P3** (review/honesty): the gate is still a loop until zero findings; batching the execution does
  not authorize stamping without running.

---
> ADRs record relevant architecture decisions (required by P5/P6 and by the Definition of Done).
> Where ADRs live: `docs/adr/NNNN-title.md` in the affected repository (incremental numbering).
