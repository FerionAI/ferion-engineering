---
name: context
description: The project's application context — the inventory of services and apps, each one's stack, infrastructure patterns and per-language conventions (TypeScript/Node, Python, Go/Java/.NET). Use when entering a new repository, onboarding a person or an agent, planning changes that cross services, or when someone asks "what is this application", "how do the services talk", "what's the stack here", "where does this run". It provides the context that stops people and agents from starting from zero.
---

# Application context

Use this skill to understand the technical ecosystem before planning or implementing. It attacks the
onboarding/context bottleneck: instead of a person (or an agent) reconstructing the domain from
scratch, the essential context is already here.

> **This skill ships empty on purpose.** The inventory belongs to your project, not to the standard.
> `onboard` fills `references/applications.md` and `references/conventions.md` from the actual code —
> stack, entry points, build/test commands, conventions. What ships is the **shape** and the method
> for filling it, never someone else's values.

## How to use it

1. When starting work in a repository, identify **which application** it is (by repo/folder name) and
   read the matching entry in `references/applications.md`.
2. Before changes that cross services, confirm **how the services communicate** and where the
   responsibility boundaries are, in `references/applications.md`.
3. When writing code, follow the **per-language and infrastructure conventions** in
   `references/conventions.md`.
4. If a service's context here is incomplete or out of date, say so and propose updating this file —
   context is a living asset. An empty entry is a gap to fill, not permission to guess.
5. Cross-cutting topics: internationalization (`references/i18n.md`) and data seeding / test
   environments (`references/seed-and-environments.md`).

## The essentials (detail in the references)

- **Repository organization:** `<FILL: monorepo, polyrepo, or mixed — which is which>`.
  For work spanning several of those repos at once, use `workspace` (multi-repo coordination).
- **Infrastructure:** `<FILL: cloud and deploy patterns>`. Networking, queues/events and
  observability patterns in `references/conventions.md`.
- **Stack:** `<FILL: the languages actually in use>`. Per-language conventions in
  `references/conventions.md`.

Read `references/applications.md` for the inventory and `references/conventions.md` for the patterns.

## Filling it in

Do not fill this by hand if the code can answer it. Run `onboard` in each repository: it detects the
stack from the manifests, the maturity against the Definition of Done, and the real build/lint/test
commands — which is exactly what `preflight` needs in order to run the real tools instead of guessing.
