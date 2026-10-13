# ADR-0008: The spec and the session become gates; review runs before preflight again

- **Status:** accepted
- **Date:** 2026-10-13   ·   **Author(s):** `<FILL>`   ·   **Issue/Epic:** —

## Context
Reading what the flow actually produced, three signals point to the same lesson as "flow order is
mechanical, not prose": what is only written leaks, and what has a gate does not.

1. **The spec leaks.** The steps with a gate (local review, cost, the review label) happen in close to
   every session that opens a PR. The spec was the only step with no gate, and `specs/` was touched in
   a small fraction of those sessions. `spec-flow` and `ship` were rarely loaded at all: implementation
   happened straight under the router.
2. **Context makes everything expensive.** Cost tracks `calls × context` (ADR-0004), and the median
   context per call ran several times higher in sessions that crossed several unlinked issues than in
   sessions that stayed on one.
3. **The review gets skipped.** The `review` skill said `preflight` runs before it, while `start`,
   `mandatory-flow` and `ship` said the opposite. The agent followed the skill, went to preflight and
   did not come back: `review` was loaded and dropped within seconds, and nobody walked the Definition
   of Done (P5, P7, P8).

To measure your own baseline: count the sessions or PRs of a period that changed a file under
`specs/`, against those that opened a PR; and compare the context per call of sessions that touched
one issue with those that touched several.

## Decision
- **Spec gate (at the PR):** `gh pr create` is blocked when no file under `specs/` (at any depth)
  changed on the branch since the merge-base with `origin/HEAD`/`main`/`master`. The proof is git, not
  the conversation. A bug fix already updated the feature's existing spec under the old rule, so there
  is no new friction there. A change with no behaviour leaves through `bypass`, recorded. With no
  remote there is no base, and the gate does not block.
- **One session, one group (at the edit):** the state keeps `session` and `session_issues`. Editing the
  code of an issue with no overlap with the group the session already edited is blocked, and the
  message hands over the sentence for the new session. Linked issues stay together (ADR-0007). The
  link survives `stamp task` and `reset`, so `reset` is not a shortcut. With no `session_id` in the
  payload (another tool), the gate does not compare.
- **Review order:** at step 4, `review` runs first and walks the Definition of Done with ✅/⚠️/❌, and
  `preflight` comes after. The sentence that sent the agent away was replaced.

## Alternatives considered
- **A spec gate that only warns:** rejected. That is the model that already existed — the rule was
  written in every skill — and it is exactly what leaked.
- **A context warning instead of a session gate:** rejected. A recommendation does not change an
  agent's behaviour, and the saving is in the cases where nobody would remember to `/clear`.
- **Gate the move of another issue instead of the edit:** rejected. Moving another issue's label is
  legitimate (closing, returning), and the hook cannot tell that apart from starting work on it.
  Editing code is unambiguous.
- **Gate on context size (reading the transcript):** deferred. Fairer to short sessions, but fragile.
  Revisit if short sessions get blocked often.
- **Merge `review` into `preflight`:** deferred. First see whether removing the contradiction is enough.

## Consequences
- **Positive:** a spec exists for every change with behaviour. Unlinked issues stop paying for the
  previous ones' context. The Definition of Done is walked again.
- **Negative / costs:** one `/clear` per loose issue in a batch. A short session is blocked too (the
  context threshold is deferred). A spec `bypass` releases the rest of the flow until the next issue,
  like any bypass.
- **Impact:** no migration. An old state has no `session`, so the first edit only records the link.
  The checks are in `hooks/flow-gate.test.sh` (sections 9 and 10).

## Constitution principles involved
P1 (spec-driven), now with proof in git. P8 (efficiency), because context is what costs. P3 and the
Definition of Done, because `review` walks the DoD again before the PR.

---
> ADRs record relevant architecture decisions (required by P5/P6 and by the Definition of Done).
> Where ADRs live: `docs/adr/NNNN-title.md` in the affected repository (incremental numbering).
