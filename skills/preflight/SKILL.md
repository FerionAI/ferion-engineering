---
name: preflight
description: 'The mandatory gate before opening any PR — reviews EVERYTHING against every rule of the standard so that nothing reaches the PR below standard and no automated reviewer (static analysis, linters, PR bots) has anything to flag. It is the defense against agent hallucination: it verifies that what was generated actually exists, compiles, tests and meets the standard. Use when finishing any implementation, before opening/updating a PR, or when someone says "is it ready for a PR?", "review everything before I push", "make sure it is spotless", "check it did not hallucinate". It is the final step of the flow (spec-flow/ship).'
---

# preflight — spotless before the PR

Because the flow runs through AI end to end, **nothing opens a PR without passing here**. Target:
zero findings from any automated reviewer; human review is left with code taste and "does anything
look off?". This gate exists to catch what the agent that generated the code cannot see — including
hallucinations (invented APIs/components/files, tests that prove nothing, leftovers).

**Hard rule:** only declare "ready for PR" when everything below is green. If something fails,
**fix it and run again** — this is a loop until zero findings, not a report of pending items.

**Do not fake green (important).** If a check could not be executed — commands not configured (empty
team config / `context`), tool or MCP unavailable, the design system package not installed to verify
components — **do not approve as if it had passed**. Say clearly what could not be verified, offer to
run `setup`/`onboard`, and **do not count it as green**. If the repo legitimately does not have that
gate (a prototype, say), record the limitation and leave the decision to proceed **explicit (human)**
— never fake "ok". Approving without executing is the worst outcome in an agentic flow.

**Found it, show it now.** Report each finding **the moment it appears**, with the proposed fix
attached — never accumulate everything into a report at the end. Three lines per finding: **what**
(`file:line` + the rule violated), **why it breaks**, **the fix** (the minimum diff). Then:

- **Obvious, local fix** (lint, type, a nonexistent import, a test that proves nothing, leftover
  debug): apply it now, say in one line what you did, and move on.
- **Fix with a decision inside it** (changing a contract, altering behavior, two plausible outcomes,
  anything `spec-flow` would have clarified): show the proposal and **wait for the person** —
  running ahead here is how the agent introduces the second bug.

The summary at the end is only the closing ("steps 1–5 green, N findings handled"), not where the
person discovers the problems. Discovering everything at the end takes away their chance to correct
course while it was cheap — the opposite of the loop.

## Step 1 — Run the real tools (do not trust "it should pass")

Execute and require green (real commands in `context`):

- **Build/compilation** — no errors.
- **Types** — typecheck clean (TS strict / mypy / etc.).
- **Lint + format** — no violations (ESLint/Prettier/Biome, ruff, golangci-lint…).
- **Tests** — unit + integration + relevant e2e passing; coverage of new code at target.
- **Static analysis** — the local analyzer if available: quality gate green, hotspots reviewed.
- **Dependency security** — no new blocker/high CVE (SCA — OWASP A06).

If any of them fails, fix it before moving on. The numbers come from execution, not assumption.

## Step 1.2 — Who actually reviews this repo (and who is mute)

"Zero automated findings" only means something against the reviewers that **exist in this repo** —
which are rarely the ones you assume. Find out instead of guessing:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/preflight/scripts/pr-bots.sh    # current repo, last 20 PRs
```

- **ALIVE bots** = the list the checklist has to anticipate. If one of them keeps flagging something
  step 1 does not catch, **fold that rule into the checklist** — same law as any preflight defect.
- **MUTE bots** (quota exhausted, subscription paused, unlicensed seat) post a notice and go quiet: the
  PR ships **with no review at all** while looking reviewed. When there is one, **say it in the
  summary** ("this PR gets no automated review: `<bot>` is out of quota") and treat step 4 as the only
  net left.
- No `gh`, no network, or a repo with no bots: degrade with a warning — never invent a reviewer.

`onboard` records this list in the repo conventions; here you confirm it still holds.

## Step 1.5 — Devserver validation (bigger change / touches UI)

A headless test can pass while the screen is broken. For a **bigger change, or one touching UI or a
flow** (the high/medium risk tiers in `qa`), **validate the live app** before the PR: start the app
on a devserver, use **synthetic seed data** with no PII (`context/references/seed-and-environments.md`),
and **drive the key flow(s) in the browser through the Playwright MCP** — happy path + one
error/empty case — capturing **screenshots** and checking that **console and network are clean**.
Attach the evidence to the issue/PR. Detail in `references/devserver-validation.md`.

**A small change with no UI skips** this step. If you cannot start the devserver or seed it,
**degrade with a warning** — do not fake green and do not stall for missing infrastructure; the
decision to proceed stays explicit (human).

## Step 2 — Anti-hallucination (what the agent may have invented)

See `references/anti-hallucination.md`. In short, **verify that it actually exists**:

- Imports, functions, types, endpoints and components referenced **exist** (grep/types), they were
  not invented. Design system components: they exist in the package (check the types/Storybook).
- Tests **prove something** — real assertions, not `expect(true).toBe(true)` and not mocks that hide
  the bug.
- No placeholder/TODO/`<FILL: …>`, no hardcoded secret, no debug `console.log`/print, no dead code.
- What was done matches what was asked — no silent extra scope (YAGNI).

> **Contract between repos:** if the change touches a contract (REST API **or** an event schema),
> verify compatibility **before** the PR — `references/contract-testing.md`. Ordinary CI does not
> catch a cross-repo contract break (build/lint/test run inside the repo; the contract lives between
> them).

## Step 3 — Full checklist against the standard

Run `references/preflight-checklist.md`, which covers every rule of the standard: Definition of Done,
OWASP (`quality`), privacy (`privacy`), design system (`design-system`), accessibility/Core Web
Vitals, observability (P5), the issue's acceptance criteria (`issues`) and the conventions
(`context`).

## Step 4 — Independent (adversarial) verification

The agent that wrote the code is biased. Run an **independent** verification (subagent, strong model
— `agentic-flow/references/agent-orchestration.md`) whose mission is to **try to reject** the change:
look for hallucination, standard violations and whatever a review bot would flag. If it finds
something real, go back to step 1. For risky changes, use more than one verifier with different
lenses (correctness, security, standard).

## Step 5 — Only then, the PR

When steps 1–4 are clean — and **only then** — close the local review step of the flow:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/flow-gate.sh stamp review
```

That is the stamp that unlocks opening the PR — the flow gate blocks a PR without it
(`start/references/mandatory-flow.md`). **Stamping without having run is exactly the hallucination
this gate exists to catch**: if any step came out red or could not be executed, do not stamp — fix
it, or leave the decision to proceed explicit (human) and record it.

With the stamp: open/update the PR, linked to the issue with `Closes #N` in the body, with the
standard description and the evidence from the checks. **The gate blocks a PR that references no
issue** (not in the body, not in the branch): that reference is the only thread tying PR to issue —
without it, cost, lead time and adoption stop being measurable. CI and the quality gate should come out green
first try — because we already guaranteed it here.

**Record the dev cost on the issue** as soon as the PR opens (`cost`): run `session-cost.py` and post
tokens, USD and hours as a comment with the machine-readable marker
(`cost/references/capture.md` — step B). This is where cost is captured, not after the deploy: the
dev work just ended and the next session is a different one. No number available? Comment what you
have and say so — do not invent.

**Only then label the issue for review** (`status:in-review`) — an issue cannot sit in the backlog
with an open PR, and the cost is part of the milestone: cost first, label second. The agent **acts
and reports it in the summary** (cost included); it does not ask first.

**After it opens, CI is the final judge.** The gate looks again at the `in review` milestone and
**blocks the label while a check is failing** — fix it in the same PR. If CI caught what step 1 did
not, the command that was missing goes into that repo's conventions.

> If an automated reviewer flags something afterwards, that is a **preflight defect**: fold the rule
> that slipped through into the checklist so it does not happen twice. If the reviewer flagged
> nothing **because it is mute**, do not count that as a win — record it in the summary.
