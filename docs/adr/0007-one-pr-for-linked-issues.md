# ADR-0007: One PR can resolve several linked issues; the strength of the signal decides the grouping

- **Status:** accepted
- **Date:** 2026-10-13   ·   **Author(s):** `<FILL>`   ·   **Issue/Epic:** —

## Context
Asked to work through a batch of issues, the agent did them one at a time, even when they were so
linked that one PR would resolve all of them. The cause was in the hook, not only in the prose. The
flow state (`.git/ferion-flow`) held one issue, and assuming a second issue was read as a new flow:
it cleared the first one's milestones and its cost baseline. The agent learned to work in series so
as not to lose what it had already closed. `start` ("one issue at a time") and `issues` ("take each
issue through the pipeline") reinforced it.

Linked issues done in series are expensive: the same spec and the same code read several times, PRs
that conflict with each other, and several reviews of the same lines. Cost tracks
`round trips × context` (ADR-0004), so every repeated read is paid in full.

## Decision
**One PR can resolve a group of linked issues.** `flow-gate.sh stamp task 42 43 44` records the group:

- The local review and the PR belong to the group. The PR must name **every** issue (`Closes #N` in
  the body, or the number in the branch).
- `in progress`, cost and `in review` are **per issue**. Assuming another issue of the group clears
  nothing, and each issue needs its own cost recorded before it is labelled for review.
- Naming the current issue in a `stamp task` extends the group without losing a milestone. An issue
  outside the group still opens a new flow.
- The group's cost is measured once and **split equally** across its N issues; the comment on each
  issue says it is 1/N and shows the whole group's numbers.

**The strength of the signal decides whether to group:**
- **Strong:** a dependency between the issues (one is blocked by the other, or a task list ties them);
  one does not compile or test without the other; both touch the same code; the person asked for one
  PR. The agent groups and moves on, saying so in one line.
- **Weak:** same epic, same module or a similar theme. The agent explains the grouping and asks.
- **Never groups:** different repositories (that is `workspace`); an estimated total well above
  ~400 lines (P3); a hotfix.

Unlinked issues of the same batch go one at a time, without asking permission between them. To run
them in parallel, use one session per worktree (each worktree has its own flow state).

## Alternatives considered
- **Keep one issue per PR:** rejected. It is the behaviour that caused the complaint, and conflicts
  between PRs over the same lines are rework, not discipline.
- **The agent always groups on its own:** rejected. A weak signal turns into a large PR that is hard
  to review. Same rule as anywhere else in the standard: a weak signal proposes, it never assumes.
- **Always ask before grouping:** rejected. One question per batch is one more round trip exactly in
  the obvious cases (a declared dependency).
- **Split the cost by each issue's diff:** deferred. In a single PR there is no reliable way to tell
  which lines belong to which issue. An equal split is the honest approximation, and the comment says so.

## Consequences
- **Positive:** a batch of linked issues ships as one PR, with one read of the context and one review.
  Cost stays per issue and still adds up to the real total.
- **Negative / costs:** the per-issue cost of a group is an average, not a measurement. Issues of very
  different size come out distorted; the comment flags it.
- **Impact:** a flow state written before this change (`dev=1`, `cost=1`) keeps working: `1` means the
  whole group. Nothing to migrate. The checks are in `hooks/flow-gate.test.sh` (section 8).

## Constitution principles involved
P3 (small, focused PR): the ~400-line limit is what stops a grouping. The commit → PR → issue trail
holds, now with N issue references on the PR. P8 (efficiency): fewer round trips per delivery.

---
> ADRs record relevant architecture decisions (required by P5/P6 and by the Definition of Done).
> Where ADRs live: `docs/adr/NNNN-title.md` in the affected repository (incremental numbering).
