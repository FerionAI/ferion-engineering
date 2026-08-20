---
name: workspace
description: 'Coordinates work that spans several repositories of the same workspace — the common polyrepo case, where front and back live in separate repos and one front end consumes several back ends. Use when a change touches more than one repo at once, when coordinating front + back in different repositories, when changing an API contract that must propagate to the front end(s), or when someone asks "which front ends consume this back end", "how do these repos talk", "how do I ship back and front together without breaking anything". It understands the repo map and orchestrates the vertical slice, the PRs and the deploy between them — delegating each repo''s mechanics to the existing skills.'
---

# workspace — multi-repo work

In a **polyrepo** setup, front and back live in separate repositories and one front end consumes
**several** back ends (N:1). Valuable work almost always crosses repos. This skill does two things:
**understand the workspace** (which repos, how they talk) and **coordinate** the change/deploy
between them — without duplicating what `ship`/`preflight`/`release`/`issues` already do per repo.

## 1. First: understand the workspace

Before acting, build the map of the open repos:

1. **Which repos** — every folder with a `.git` is a repo. Classify each one with `context`
   (`context/references/applications.md`): front end? back end? library/design system? tooling?
   Where its issues live is trivial here: **in the repo itself** — one of the reasons GitHub Issues
   beats an external tracker for this standard.
2. **How they talk (the seam)** — typically the front end consumes the back end through an **OpenAPI
   contract**: the back end exposes a schema; the front end declares the upstreams, generates types
   (`openapi-typescript` → a committed `.d.ts`) and builds a typed client per API. Mechanics and
   pitfalls in `references/cross-repo-coordination.md`.
3. **Who depends on whom** — a back end usually serves **N front ends**. Changing a back end means a
   blast radius across every front end that generates types from it. List them before touching
   anything (the blast radius section in the reference).

> `onboard` documents **one** repo; `workspace` is the level above — the map **between** repos.

## 2. Coordinate a change that spans repos

An issue whose value crosses repos (a new API field + the screen that uses it) follows a **vertical
slice across repos** — one spec per repo, contract first, one PR per repo, all linked to the same
issue:

1. **One spec per repo (rule).** Each repo touched has **its own** `specs/<feature>/` (spec/plan/tasks
   through `spec-flow`), **all linked to the same issue** — that repo's slice is specified **in it**,
   not concentrated in one place. (A repo already using Spec Kit: follow its structure — `onboard`.)
2. **Contract first** — agree the schema in the back end (it is the source of truth for the type).
   Without that, the front end generates types for something that does not exist yet.
3. **Back before front** — implement and ship the back end (to staging); then **regenerate the types**
   in the front end and consume them. Golden rule **expand/contract**: the back end adds before the
   front end uses; it only removes the old shape when no front end uses it
   (`fullstack/references/api-versioning.md`).
4. **One PR per repo, one issue** — each repo has its own branch/PR (Conventional Commits, P3), **all
   referencing the same issue**. Use `Closes #N` in the repo that owns the issue and a plain
   `org/repo#N` reference in the others, so only one PR closes it.
5. **Preflight per repo** — `preflight` runs in **every** repo touched. "Done" only when **all** are
   green — and the types regenerated with no drift (the front end's typecheck must pass against the
   new schema).
6. **Coordinated deploy** — back before front (the new front end depends on the new API). The **order
   between repos** is coordinated here; `release` handles the deploy/rollback **per service**. Detail
   in `references/cross-repo-coordination.md`.

> Watch out: type generation is usually manual and **there is no contract test in CI** — the front
> end's typecheck against the regenerated schema is the only net. Treat regeneration + the front-end
> build as a mandatory step of the slice (`preflight/references/contract-testing.md`).

## How it delegates (it does not duplicate)

`workspace` orchestrates; each repo's mechanics belong to the skills that already exist:

- **The contract between the ends:** `fullstack` + `fullstack/references/contract-and-vertical-slice.md`.
- **Evolving the API without breaking consumers:** `fullstack/references/api-versioning.md`.
- **Propagating a shared library** to its N consumers: `references/shared-libraries.md`.
- **Asynchronous seam** (an event crossing repos): `integrations/references/event-bus.md`.
- **The pipeline for each slice:** `ship` (idea→PR, per repo).
- **The pre-PR gate:** `preflight` (run in every repo touched).
- **Deploy/rollback per service:** `release`; the **order** between repos is coordinated here.
- **Issue ↔ N PRs:** `issues` (the issue ties them together); decomposing an epic that crosses repos:
  `epic`.
- **Each repo's map / the inventory:** `onboard` (one repo) and `context` (the ecosystem).
