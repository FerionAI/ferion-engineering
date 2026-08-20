# Decomposing an epic that spans teams and repos

An epic whose value crosses repositories is the normal case in a polyrepo organization, and the place
where decomposition most often goes wrong: one giant issue in one repo, and three teams waiting on
each other with no visible dependency.

## The rule: one issue per repo, one epic tying them

- **The issue lives in the repo that owns the change.** Not in a central "project" repo — the issue
  has to sit next to the code so the flow gate, the PR and `Closes #N` all work.
- **The epic lives where the initiative is coordinated** (the product repo, or a dedicated planning
  repo), and links the children with a task list. Cross-repo references render fine:

  ```markdown
  ## Backend (api repo)
  - [ ] acme/api#412 — add `subscription_status` to the user contract
  ## Frontend (web repo)
  - [ ] acme/web#288 — show the expired badge in the listing
  ```

- **Dependencies are explicit, in the issue body**: "blocked by acme/api#412". A dependency that only
  exists in someone's head is the dependency that slips.

## Order the slices by contract, not by team

The sequence that works, every time:

1. **The contract issue first** — the schema/field/event both sides agree on. This is the issue that
   unblocks parallel work.
2. **The producer** (the back end) implements and ships to staging — additive, expand phase.
3. **The consumer(s)** (the front ends) regenerate types and consume.
4. **The cleanup issue** (contract phase) — remove the old shape, only after every consumer migrated.
   This one is almost always forgotten; create it up front with the others.

Step 4 existing as a real issue from day one is what stops "temporary" compatibility shims from
becoming permanent.

## Blast radius before you decompose

A back-end change usually serves **N** front ends. Before writing the issues, list who consumes what
you are about to change (`workspace/references/cross-repo-coordination.md`). An epic that assumes one
consumer and finds three mid-flight loses a sprint.

## Shared repositories

A repository owned by no single team (a shared library, a common API) is where cross-team epics
stall. Two things help:

- **Name the reviewer up front** in the issue — not "the team", a person.
- **Prefer additive changes** in shared code, so consumers migrate on their own schedule instead of
  in a coordinated big bang.

## Checklist

- [ ] One issue per repository touched, each with its own acceptance criteria.
- [ ] The epic links them all with a task list; dependencies stated explicitly.
- [ ] The contract issue is first and unblocks the others.
- [ ] A cleanup issue exists for the contract phase.
- [ ] Every consumer of a changed contract is listed (blast radius).
- [ ] Deploy order is written down (`workspace` coordinates it; `release` executes per service).
