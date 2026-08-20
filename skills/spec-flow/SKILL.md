---
name: spec-flow
description: Spec-driven development flow (Spec Kit style) — takes a feature from the constitution to implementation through clear steps (specify, clarify, plan, tasks, implement, analyze), always anchored in the standard and the project context. Use when building a new feature, doing a meaningful refactor, "write a spec", "plan this task", "break this into tasks", or when a request is too vague to start implementing. Reduces rework and stops the AI from building the wrong thing.
---

# Spec-driven flow

You drive feature development with the spec-driven method (based on the GitHub Spec Kit), adapted to
this standard. The goal is to **specify before coding** (constitution P1) and attack the four
bottlenecks every team has: inconsistency, onboarding, quality and badly defined requirements.

## Before starting (mandatory)

1. **Make sure the GitHub issue exists first (rule)** — every change becomes an issue. If the request
   does not cite one, ask; if it does not exist, create it (skill `issues`). The issue is the source
   of truth (intent + acceptance criteria = the "what/why"); the spec starts from it and **is
   recorded** (do not skip this).
2. Load the standards: read the `constitution` skill (P1–P8 + Definition of Done).
3. Load the context: read the `context` skill for the target application.
4. Every artifact you generate must respect the constitution and the conventions.

## The steps

Run them in order. Do not skip steps on non-trivial features. For small changes it is acceptable to
condense (specify + plan together), but never skip the tests (P2) or the Definition of Done.

### 1. Constitution (once per repo/context)
Make sure the repository has the constitution and context available (`memory/constitution.md` and/or
`AGENTS.md`). If not, offer to sync it from the central standard before continuing.
**If the repo already uses Spec Kit** (`.specify/`, `specs/`), use the **existing constitution and
structure** (e.g. `.specify/memory/constitution.md`) — do not create parallel ones; run `onboard` to
align.

### 2. Specify — the what and the why
**Before creating anything, look for the feature's existing spec** (`Glob specs/*/spec.md` + read
whatever matches the area you are touching). If the change alters something **already specified** —
the typical case being a **bug fix** — **update that spec**, do not open a new folder: correct the
acceptance criterion that was wrong, add the edge case that was missing, and record what changed and
why. A new folder is only for a **new capability**. A legacy feature **with no** spec: do not
reconstruct the whole feature — create `specs/<feature>/` covering only the behavior you touch
(spec+plan condensed, sized to the change).

> A fix spec in a separate folder breaks the coherence that step 7 verifies: the original spec ends
> up describing a behavior the code no longer has.

Start from the `discovery` brief (empathize+ideate) when there is one. Produce the **specification**
using `references/templates/spec.md`. Focus on:
- Problem and goal (the "why").
- User stories and acceptance criteria (the "what").
- Do **not** decide technology/architecture here.

Save as `specs/<feature>/spec.md` (or **update the existing one** — see above), **following the
structure/numbering the repo already uses** (e.g. Spec Kit's `specs/NNN-feature/`); do not invent a
new layout when one exists.

### 3. Clarify — remove ambiguity
Before planning, identify vague or missing points in the spec and **ask objective questions**.
Record the answers back into the spec. Do not move forward with an ambiguous requirement (P1).

### 4. Plan — the how
Produce the **technical plan** using `references/templates/plan.md`:
- Architecture decisions and trade-offs, **citing** the constitution principles that drove them.
  Record relevant decisions as an **ADR** (`references/templates/adr-template.md`) — P5/P6.
- **Risky change** (release, data migration, breaking API contract): include the rollback plan from
  the start — see the `release` skill.
- Stack/services affected (use `context`), API contracts, data changes.
- **Is there UI?** Validate the layout with `design-review` before implementing (design system,
  WCAG, all four states).
- Test strategy (P2) and observability strategy (P5).

Save as `specs/<feature>/plan.md`.

### 5. Tasks — break it into execution
Generate an actionable **task list** from the plan, using `references/templates/tasks.md`. Each task:
small, verifiable, with the tests that go with it. Mark dependencies and what can be parallelized.
Save as `specs/<feature>/tasks.md`.

> Optional: offer to turn the tasks into GitHub sub-issues linked to the parent
> (`- [ ] #123` in the parent's body) when the team tracks work that way.

### 6. Implement — execute
**Before the first line of code, assume the issue** (the `in progress` milestone — `issues`): the
agent **assigns it to the current user** and applies `status:in-progress`; whoever looks at the board
must see that the work started and **with whom**. Issue already assigned to someone else or already
in progress: **stop and ask** before coding (two developers on the same issue is the most expensive
rework in the flow). Act and report; do not ask first.

Implement the tasks in order, respecting the per-language conventions (`context`). For each task:
write/adjust the tests, implement, make it pass. Never mark a task done with a failing test.

### 7. Analyze / Preflight — final verification (spotless before the PR)
Review the coherence between **spec ↔ plan ↔ tasks ↔ code**, then run **`preflight`**: the
exhaustive check against ALL the rules + the real tools (build/lint/types/tests/static analysis) +
independent anti-hallucination verification, **looping until zero findings**. Nothing opens a PR
before that. The target is that no automated reviewer has anything to flag and human review is only
code taste and "does anything look off?".

## Expected output

At the end, the repository has `specs/<feature>/` with `spec.md`, `plan.md`, `tasks.md`, the
implemented code with tests, and a summary of what was done mapped against the Definition of Done.
