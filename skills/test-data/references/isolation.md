# The six isolation rules

The canonical list. Playbooks and skills **reference** this file instead of repeating the rules — a
duplicated rule becomes a divergence by its third version. They apply to every automated test
(L0–L3).

1. **Every test creates what it needs.** No record that "is already there": state comes from a
   factory/API fixture, with domain traits (`SKILL.md`). A test that depends on the environment fails
   looking like a product bug.
2. **`runId` in every identifier created.** Format `qa-<person|ci>-<YYYYMMDD>-<n>`, in the email, in
   the name, in its own field. Without it there is no parallel run, no safe cleanup, and no way to
   know who dirtied the environment.
3. **Order does not matter.** Each test passes alone, in parallel and shuffled. A test that only
   passes after its neighbor is reading the neighbor's state.
4. **Cleanup by disposal, not surgical deletion.** Preference, in this order: **ephemeral
   database/environment** (Testcontainers, a schema per run) → **sweep by `runId` prefix** (a job
   that collects whatever is older than 24h) → `DELETE /__test-data/run/{runId}` at the end, only
   where the environment is shared and persistent. Never truncate a table in a shared environment,
   never a `beforeEach` that wipes the world: both take down someone else's run.
5. **No fixed waits.** No `sleep`, `waitForTimeout`, `cy.wait(2000)` — wait on a **condition**
   (element, status, event, query). A fixed wait is contracted flakiness, and `preflight` blocks it
   (`preflight/scripts/qa-lint.sh`).
6. **No production data.** No copy, no "just one real national id to test with" (`privacy`).
   Synthetic data always; email on an example/test domain.

**Why six and not one:** each one alone looks like bureaucracy; together they are what lets the suite
run in parallel, in any order, as many times as needed — which is the condition for it to run on
every PR. A suite that cannot always run protects nothing.
