---
name: epic
description: 'The PM tool — from a referenced epic, generates the epic''s issues on GitHub, each already carrying the project stack, testable acceptance criteria, the Definition of Done and the standard flags (security, privacy, design system, observability). Use when a PM references an epic and asks to break it down: "generate the issues for this epic", "break down epic #40", "create the stories", "decompose this initiative". It closes the cycle at the front: the issues are born ready for `ship` to pick up.'
---

# epic — from epic to issues

The PM references an epic and you return **ready issues on GitHub**, inside the standard. Each issue
is born as a good spec: clear scope, testable acceptance criteria, the project stack and the
Definition of Done — so `ship`/a developer can pick it up and execute with no rework. The issue is
the source of truth (`issues`): the children are created there, linked to the epic.

## Step 1 — Understand the epic

- **Read the epic** (`gh issue view <n> --comments`): goal, problem, scope, expected outcome,
  constraints. If the epic is still just an idea in the chat, structure it first (goal/why/scope) and
  offer to create the epic issue.
- **Identify the target project/app** (`context`): that determines the **stack** each issue will
  carry and the conventions that apply.
- **Clarify the essentials** with the PM (a few objective questions) before generating; declare
  whatever you assume. An ambiguous requirement becomes a bad issue.
- **Vague problem (not just missing details)?** If the epic's own problem or value is unclear,
  **stop the decomposition** and run `discovery` (empathize/ideate) first — the brief becomes the
  epic's what/why.

## Step 2 — Decompose into issues (vertical slices, INVEST)

- **Vertical slices of value**, not a separate "back-end issue" plus "front-end issue" — each issue
  delivers an end-to-end slice where possible (`fullstack`).
- **INVEST:** Independent, Negotiable, Valuable, Estimable, Small, Testable.
- **Sequence:** mark dependencies and what can be parallelized; suggest an order (thinnest slice of
  value first, or highest risk reduction first).
- **Non-functionals made explicit:** security, performance, accessibility, data migration and
  observability become criteria on the issue or issues of their own — they do not evaporate.

## Step 3 — Every issue already in the standard (see `references/issue-template.md`)

Every generated issue carries:

- A clear **title** + **body** (what/why — not the "how").
- **Testable acceptance criteria** (the basis for the tests and for QA — `qa`, P2).
- The **state matrix** for every entity touched (the Definition of Ready item that catches the most
  defects).
- The target **stack/app** and conventions (`context`).
- **Definition of Ready + Definition of Done** referenced (`constitution`).
- **Standard flags** based on what it touches: OWASP (auth/data/input), **privacy** (personal data),
  **design system** (front end), observability (P5), API contract (`fullstack`).
- A suggested **size** and its dependencies.

## Step 4 — Create them on GitHub

- **Do not guess the setup:** if the label taxonomy, issue templates or target repository are not in
  the team config, **confirm with the user or run `setup` first** — do not create issues guessing the
  structure.
- **Epic spans repos/teams?** Route each issue to the repository that **owns** the change and open a
  coordination issue where they meet — `references/cross-team-decomposition.md`.
- **Preview first:** show the PM the list of issues (title + summary + criteria) so they can adjust.
- On approval, **create the issues** and link them to the epic through the epic's task list, which is
  what makes GitHub render them as real children:

  ```bash
  gh issue create --title "..." --body-file /tmp/issue-1.md --label type:feature
  # then edit the epic's body to include:  - [ ] #123
  ```

- Each issue is left **ready for `ship`** to pick up and execute inside the standard.

## Closing the cycle

PM (epic → issues, here) → dev (`ship` starts from the issue) → QA (`qa` validates on the issue) →
cost (`cost` records on the issue) → all on GitHub, the source of truth.
