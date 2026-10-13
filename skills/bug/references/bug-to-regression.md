# Playbook — From bug to regression test

**Location:** `skills/bug/references/bug-to-regression.md` · referenced by `bug`
**When:** a defect was reported and will become a permanent regression test — before any fix
**Goal:** that the bug leaves here linked on all three sides: issue ↔ catalog scenario ↔ spec

> **Failure contract (applies to every step):** if a step cannot be completed, **stop, say exactly what is missing and do not improvise**. Never work around a gate. A bug returned because it does not reproduce is worth more than a fix on a hunch.

---

## Gate 0 — Preconditions

- [ ] **The bug reproduces deterministically:** same state, same action, same result, **3 out of 3**.
- [ ] **The issue exists** (`issues`). Every change is born from an issue; without one, ask and create it.
- [ ] **The state that produces the bug can be described in domain traits** (`customer[past_due]`), not as "record 4821".

**Hard gate:** it does not reproduce deterministically → **stop here**. The bug is not understood yet, and a test that "sometimes catches it" is worse than none: it enters the suite, fails at random and trains the team to ignore red. Record what you tried, what varied between attempts and what is missing (a log, a step, data) — that is a deliverable, not giving up.

**Output of this step:** the three attempts recorded (state, action, result) and the list of traits involved.

---

## Step 1 — Reproduce through the factory, not the record where it showed up

1. Build the state through a fixture/factory with the traits from Gate 0 and its own `runId` (`test-data/references/isolation.md`).
2. Run the action and observe the defect **in that** freshly created state.

**Gate:** it only reproduces on the original record (staging/production) and not on the created one → **stop**. That is not a rule bug: it is a data difference, and the cause is in what that record has that is different. Find the difference before writing a test — otherwise you will automate the wrong symptom.

**Output:** the defect reproduced from state created from scratch, with the ids and the `runId`.

---

## Step 2 — Name the cause

1. Use the signal to find where the rule goes wrong: the error's log/trace, when it started, how many are affected (`integrations` — observability).
2. Write one sentence: **"rule X decides Y when it should decide Z"**, with `file:line`.

**Gate:** do not move on with "it errors on checkout". Without the rule named, step 4 has no way to pick the level, and the test ends up as E2E for lack of a target.

**Output:** the cause sentence + the `file:line`.

---

## Step 3 — Record the scenario in the catalog

An entry in `scenarios/<journey>.yaml` with `origin: bug`, the bug's issue number in `issue:`, `status: draft`, and `given:` in traits. Format: `qa/references/scenario-catalog.md`.

**Gate:** a needed trait that does not exist → it is **a request to `test-data`**, not permission to use the staging record where the bug showed up.

**Output:** the YAML entry created, with a new id (never recycled).

---

## Step 4 — Pick the lowest level that reproduces it

The level comes from **where the cause is** (step 2), not where the symptom appeared: a calculation bug discovered on the screen is **L0**, not L3. Rungs in `test-strategy/references/test-levels.md`.

Write the sentence saying why: *"the error is in the rounding of the monthly fee — L0 reproduces it and points at the line; the screen only displayed the wrong number"*.

**Output:** `target_level` filled in the catalog + the sentence.

---

## Step 5 — The test is born red

1. Write the scenario's test **against the still-broken code** (`qa-spec`, and the playbook `qa-spec/references/automate-scenario.md` for the mechanics).
2. Run it. Read the failure message.

**Hard gate:** **born green → the test does not reproduce the bug.** Do not fix anything, do not "adjust later": go back to step 1. Either the state is not what you think, or the cause is different, or the assertion looks at the wrong place. A green test before the fix means you are about to fix something with no proof there was a problem — and the regression comes back in three months with nobody noticing.

**Gate:** red **for the right reason**. The failure message has to describe the reported defect, not a setup error.

**Output:** the red run's output, pasted, with the message that describes the defect.

---

## Step 6 — Only then, fix

1. Fix **at the cause**, where every caller passes through — before editing, see who else calls the function (a guard in the shared function is a smaller diff than a guard in each caller).
2. **Update the feature's existing spec** in `specs/<feature>/`; a bug fix does not open a new spec (`spec-flow`).

**Gate:** a fix that changes agreed behavior (a contract, a business rule) goes back to `spec-flow` — it does not ship on impulse.

**Output:** the fix's diff + the feature's spec updated.

---

## Step 7 — Close

- [ ] The test from step 5 is **green**, and undoing the fix makes it **red again** (`qa-spec/references/mutation-proof.md`)
- [ ] Catalog: `status: automated` + `spec: <path>`
- [ ] Regression around it checked: what else touches this cause (`qa/references/risk-and-regression.md`)
- [ ] The **three sides linked**: issue ↔ scenario id ↔ spec path, each one citing the other two
- [ ] A comment on the issue with the root cause, the fix and what is now covered (`issues`)

A production bug with impact right now enters through `incident` (mitigate first) and comes back here calmly — a postmortem without a regression test is a promise.

---

## Anti-patterns

- **Fixing before the test.** You lose the only cheap chance to prove you understood the defect; after the fix, nobody can see the test fail anymore.
- **Moving on with a test that was born green.** A test that never protected anything enters the suite labelled "regression covered".
- **Testing at the level where the symptom appeared.** A rule bug becomes E2E: slow, unstable and pointing at the screen instead of the wrong line.
- **Reproducing on the record where it showed up.** Ties the test to the environment and hides that the cause could be the data, not the rule.
- **Closing the bug without a scenario in the catalog.** The regression comes back, and nobody links the return to the old defect.
- **"I couldn't reproduce it, but I think it's this."** A hunch that looks like a fix — and the real bug is still there, now with a green test on top of it.
