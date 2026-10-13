# Mutation proof — the test of the test

A test is only worth what it **fails**. The mutation proof is the cheap step that separates a test
from theater: break the behavior on purpose and require the test to turn red.

## Procedure (2 minutes, always)

1. **Run the new/changed test and see green.**
2. **Mutate the production code** the scenario exercises — a small, surgical change, in the behavior
   the `then` describes:
   - invert the guard's condition (`if (pastDue)` → `if (!pastDue)`);
   - change the rule's return (block → allow);
   - remove the effect (do not emit the event, do not persist the field);
   - move the boundary (`>=` → `>`), when the scenario is about a limit.
3. **Run it again.** The test **has** to fail — and the failure message should say what broke.
4. **Revert the mutation** (`git checkout -- <file>` or undo the line) and confirm green again.
5. Record it on the PR, in one line: *"mutation proof: inverted the outstanding-balance guard →
   checkout-014 failed as expected."*

An automated mutation tool (Stryker, mutmut, PIT) is welcome where it already exists, but it is **not
a prerequisite** — a manual mutation aimed at the `then` catches the case that matters and costs two
minutes.

## When the mutation survives (the test passed with the code broken)

The problem is the **test**, not the code. Causes in order of frequency:

| Symptom | Cause | Fix |
|---|---|---|
| Passes with anything | generic assertion (`toBeTruthy`, status 200 only) | assert the effect of the `then` (value, message, persisted state, event) |
| Passes because nothing ran | the flow aborted early (setup failed silently) | assert the pre-state; make the setup fail loudly |
| Passes because the mock answered | the mock replaced exactly the rule under test | go up a level (L2/L3) or fake only the edge, never the core |
| Passes by timing luck | a fixed wait masking a race | wait on a condition; remove `sleep`/`waitForTimeout` |

Fix the assertion and repeat the proof. **Never** "solve" it by adjusting the mutation to one the test
catches: that is choosing the target after the shot.

## At the gate

- **`qa-spec` does not close** without the proof passing; **`preflight` does not stamp** local review
  with a new/changed spec in the diff and no proof declared (`preflight/scripts/qa-lint.sh` lists the
  specs that need one).
- **A zero failure rate is a symptom.** If in a month no mutation brought a test down, the proof is
  loose — it is mutating what the test does not look at. Track that in `health`
  (`health/references/qa-metrics.md`), not the number of tests.
