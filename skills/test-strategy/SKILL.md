---
name: test-strategy
description: 'Decides at refinement — with PM, QA and dev at the same table — which scenarios an epic needs and at which level each one is tested (L0–L4), turning it into the test Definition of Ready before any line of code. Use when someone asks "what tests does this feature need", "at what level do I test this", "is this epic ready for dev?", "test DoR", "test strategy/plan for the epic", "test pyramid", or when refining an epic that `epic` just broke down.'
---

# test-strategy — the test is decided first, by all three heads

A scenario decided after the code exists is born crooked: it becomes e2e because that is what is
left, and the team pays for it in slowness and flakiness. Deciding **before** — when changing your
mind costs a sentence — is the biggest long-term lever of the QA kit.

**Honest prerequisite:** this only works once the level vocabulary is already in use by the team
(`references/test-levels.md`). Before that, it becomes a refinement ceremony with nothing behind it —
start with `qa-spec` on real scenarios and come back here afterwards.

## Input

An epic (`epic`) or an issue with acceptance criteria (`issues`). Read the criteria as they are: what
is not written is not agreed — and that is exactly what this conversation uncovers.

## Step 1 — What risk this change carries

Three questions, in this order, and the answer belongs to the trio (not to QA alone):

1. **What hurts if it breaks?** (money, sign-up, customer data, reputation) → gives the `criticality`.
2. **Where is it most likely to break?** (new rule, integration, migration, heavily changed code).
3. **What has broken here before?** (scenarios with `origin: bug` in the catalog, past incidents).

Test more where it hurts and where it breaks. Uniform coverage is waste spread evenly.

## Step 2 — Write the scenarios (given/when/then)

One scenario per observable behavior, in the language of the domain, in the catalog
(`qa/references/scenario-catalog.md`), with `origin: refinement`.

- **`given:` already in traits** (`customer: [past_due]`) — that is what reveals, still in
  refinement, that a factory is missing (`test-data`). An epic blocked by a missing trait becomes a
  visible item, not a surprise in the middle of the sprint.
- Include the **sad path** and the **empty** one, not only the happy one: that is where the defects
  that escape live.
- Do not write a scenario for what nobody observes. If nobody can say the "then", the acceptance
  criterion is loose — fix the criterion, do not invent the test.

## Step 3 — The level of each scenario

Assign `target_level` (L0–L4) scenario by scenario, using the question of each rung in
`references/test-levels.md`. Rule of thumb: **the lowest level that still proves the behavior**; go
up a rung only when the risk lives in the seam (integration, session, payment, screen).

Mark explicitly what will be **`manual-permanent`** (visual perception, content, a third party out of
your control). Deciding that here avoids the silent debt of a scenario that stays in draft forever.

## Step 4 — Test DoR (the gate)

The epic/issue is **ready for dev** when:

- [ ] every acceptance criterion has at least one scenario in the catalog;
- [ ] every scenario has `target_level` and `criticality`;
- [ ] the traits in `given:` exist — or became an explicit item for `test-data`;
- [ ] what is `manual-permanent` is marked, with the reason;
- [ ] you can say, in one sentence, **what this delivery will not cover** (and the team accepts it).

Missing an item? The epic goes back to refinement — it does not enter dev "so we do not lose the
sprint". Without this, QA finds the hole at the end, when fixing it costs ten times more.

## Output

Scenarios in the catalog (versioned with the code), the test DoR recorded on the issue (`issues`),
and the automation queue: scenarios in `draft`, lowest level first, then by criticality. From there
on: `qa-spec` automates, `preflight` enforces, `health` shows whether the strategy is working.
