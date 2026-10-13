# Playbook — Triage of an unstable (flaky) test

**Location:** `skills/preflight/references/flaky-triage.md` · referenced by `preflight`
**When:** a test failed with no apparent behavior change — in CI or on your machine
**Goal:** that the failure ends with a **named cause** or with the test removed; never with "run it again"

> **Failure contract (applies to every step):** if a step cannot be completed, **stop, say exactly what is missing and do not improvise**. Never work around a gate. A quarantined test with an unknown cause is still open work, not a resolved item.

---

## Gate 0 — Classify before labelling

**Presume a real defect until proven otherwise.** Calling a true concurrency bug "flaky" is the most expensive mistake in this flow: it silences the hardest finding to get and sends it back to production.

- [ ] **The failure was actually observed**, with the log/output kept (a link to the CI run or the local output). "I heard it sometimes fails" does not open a triage.
- [ ] **The exact command** that produced the failure is recorded (`context/references/conventions.md`).
- [ ] **Nothing changed in the behavior** that explains the failure (it is not a test legitimately failing on a new bug — check the recent diff of the code under test).

**Output of this step:** the evidence of the failure + the command, and the sentence "I presume a real defect until proven otherwise".

---

## Step 1 — Reproduce with repetition

Run the test **20 times alone** and **20 times with the suite**, with retries off (`--retries=0` or the runner's equivalent; confirm the flag with `--help`).

**Output:** the failure rate in both modes (e.g. `0/20 alone · 6/20 in the suite`). That table is what decides step 2:

| Alone | In the suite | Reading |
|---|---|---|
| always passes | sometimes fails | order coupling or shared data |
| sometimes fails | sometimes fails | a fixed wait, real concurrency, or the environment |
| always passes | always passes | the failure came from the CI environment — investigate there, not in the test |

**Gate:** do not move on without both numbers. Without them, the "cause" will be a guess — and a guess becomes a label.

---

## Step 2 — Name the cause

Pick **one** category and prove it with evidence:

| Category | Evidence that confirms it |
|---|---|
| **Order coupling** | passes alone; fails after one specific test (bisect the suite) |
| **Shared data** | fails when two runs coexist; ids without a `runId` in the trail |
| **Fixed wait** | there is a `sleep`/`waitForTimeout`/`cy.wait(n)` on the path (`preflight/scripts/qa-lint.sh` points at it) |
| **Real concurrency** | the product loses/duplicates something under parallelism — **it is a product bug** |
| **Environment instability** | the failure correlates with network/container/resources, not with the test |

**Hard gate — real concurrency:** **do not quarantine it.** Open a bug (`bug`, and the playbook `bug/references/bug-to-regression.md`) and treat it as a defect: the test is right, the product is wrong. Sending it to quarantine erases the most valuable finding of the triage.

**Gate:** "instability" alone **is not a cause**. If you cannot name it with evidence, the test goes to quarantine (step 3) and the item stays **open as an investigation** — not as resolved.

**Output:** the category + the evidence that confirms it.

---

## Step 3 — Quarantine with an owner and a deadline

Only after naming the cause (or explicitly failing to). Mark the test with the comment:

```
quarantine until 2026-03-13 · owner: <who authored it> · cause: order coupling · ref: #123
```

- **The owner is whoever authored the test**, not whoever saw it fail. Whoever wrote it knows what it meant to prove.
- **Deadline: 5 business days.** An absolute date in the comment, never "soon".
- Out of the blocking gate, but **inside the nightly** — quarantine is not switching it off, it is taking it out of the merge path.

**Output:** the test marked, an issue with the owner and the date, and the PR gate green without it.

---

## Step 4 — Fix at the cause

| Cause | Fix |
|---|---|
| Order coupling | isolate the state (rule 3 in `test-data/references/isolation.md`) |
| Shared data | a `runId` in every identifier + its own factory (rules 1, 2 and 4) |
| Fixed wait | wait on a condition (rule 5) |
| Real concurrency | fix the **product** through the `bug` flow |
| Environment | stabilize the CI infrastructure (container, resources, network) — do not touch the test |

**Gate:** `--retries` **is not a fix**. Retries hide the cause, slow the suite down and turn red into tolerated noise.

**Output:** the fix's diff + the cause it addresses, named.

---

## Step 5 — Reinstate or delete

- **Reinstate** only after **10 consecutive green runs** in the mode it used to fail in (alone or in the suite). Remove the quarantine comment.
- **Deadline expired → delete the test**, recording the cause and what stopped being covered. **Do not renew the deadline.** A test nobody trusts poisons the reading of the whole suite: every red starts needing judgment, and the team learns to ignore it. If the scenario matters, it comes back through the catalog as `draft` and is re-automated from scratch.

**Output:** the 10 green runs, or the commit removing the test + the catalog entry saying what was left uncovered.

---

## Step 6 — Close

- [ ] Cause named with evidence (or the test deleted, with a record)
- [ ] Quarantine removed from the code, or never applied (the real-concurrency case)
- [ ] If it became a product bug: an issue opened and linked to the scenario
- [ ] No quarantined test past its deadline in the repo: `grep -rn "quarantine until" <test dirs>` and compare each date with today

---

## Anti-patterns

- **Labelling it flaky without reproducing it.** That is how a real concurrency bug becomes folklore ("that test is annoying") and reaches production.
- **Retries as the fix.** Buys silence, not stability: the cause remains and the suite gets slower.
- **Renewing the quarantine deadline.** A renewed quarantine is a dead test taking up room and diluting the trust in every other one.
- **Quarantine without an owner.** It becomes nobody's and expires on its own.
- **Deleting without recording the cause.** The finding and the scenario are lost; three months later someone rewrites the same test with the same defect.
- **Fixing the symptom in the test** (raising a timeout, sorting the list in the assertion). The product still has the problem, now invisible.
