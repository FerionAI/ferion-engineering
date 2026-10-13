---
name: bug
description: 'Drives the fix of a defect in the order that makes the regression suite grow by itself: bug → scenario in the catalog → a test that fails (red) → root-cause fix → green. Use when someone says "I found a bug", "it is broken", "reproduce this defect", "fix #123", "this broke in production", or brings a bug report or an error screenshot. Refuses to move to the fix while the test is born green — a test that does not fail does not prove the bug exists.'
---

# bug — the red test comes before the fix

Fixing without a failing test is betting that you understood the defect. The order below costs a few
extra minutes **once** and gives back regression coverage forever — it is what makes the suite grow in
the right place, guided by what actually broke.

**Mandatory order, no skipping:** bug → scenario → red test → fix → green.

> **Running it now?** Follow the playbook, with a gate and an observable output at each stage:
> `references/bug-to-regression.md`. This skill holds the judgment (what the cause is, which level);
> the playbook holds the sequence.

## 1. Understand the defect (not the complaint)

The report describes a **symptom**. Before any edit:

- reproduce it: steps, environment, user/state, what was expected vs. what happened;
- look for the signal (`integrations` → observability: the error's log/trace, when it started, how
  many are affected);
- no issue? **Every change is born from an issue** (`issues`) — ask and create it, do not scan the
  backlog;
- a badly formed report becomes a good one with `qa/references/bug-report.md`.

If you cannot reproduce it, **stop here and say so**. An unreproduced bug does not become a blind fix:
it becomes a question, extra logging or a request for data. "I fixed what I thought it was" is how the
second bug is born.

## 2. Scenario in the catalog (`origin: bug`)

Record it in `scenarios/<journey>.yaml` with `origin: bug` and the bug's issue number in `issue:`
(`qa/references/scenario-catalog.md`). `given:` describes **the state that produces the defect** in
domain traits — if a trait does not exist, that is a request to `test-data`, not a reason to use the
staging record where the bug showed up.

Pick `target_level` by **where the cause is**, not where the symptom appeared: a calculation bug
discovered on the screen is **L0**, not L3 (`test-strategy/references/test-levels.md`).

## 3. Red test — this skill's lock

Write the scenario's test (`qa-spec`) **against the broken code** and run it.

> **If it passes, STOP.** The test does not reproduce the bug: either the scenario is wrong, or the
> cause is different, or the starting state is not what you think. Fix the test until it fails **for
> the right reason** (read the failure message: it has to describe the reported defect). **Do not move
> to the fix** — fixing with a green test is writing code with no proof there was a problem.

## 4. Fix the cause, not the symptom

- **Where every caller passes through.** Before editing, see who else calls the function: a guard in
  the shared function is a smaller diff than a guard in each caller — and it stops breaking the
  siblings the report did not mention.
- **The existing spec is updated, not replaced.** A bug fix **updates** `specs/<feature>/` of the
  affected feature; it does not open a new spec (`spec-flow`).
- A fix that changes agreed behavior (a contract, a business rule) goes back to `spec-flow`; it does
  not ship on impulse.

## 5. Green + what else this breaks

1. The test from step 3 passes. A **mutation proof** confirms it fails again if you undo the fix
   (`qa-spec/references/mutation-proof.md`).
2. Regression around it: what else touches this cause (`qa/references/risk-and-regression.md`).
3. Catalog: `status: automated` + `spec:`.
4. Issue: root cause, fix and the scenario that now covers it — in plain language, on the issue
   (`issues`).
5. The normal flow continues: `preflight` → PR (`start` takes care of the order of the steps).

**A production bug with impact right now** enters through `incident` (mitigate first, fix later) — and
comes back here calmly for the test and the root cause. A postmortem without a regression test is a
promise.
