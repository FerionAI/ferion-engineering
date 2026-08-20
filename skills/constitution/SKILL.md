---
name: constitution
description: The team's non-negotiable engineering standards — architecture, tests, code review, typing, observability and the Definition of Done. Use when planning features, making architecture decisions, reviewing code, or when someone asks "what's the standard here", "how do we do this", "what blocks a merge" or "is this within the standard". The base of the whole spec-driven flow.
---

# Engineering Constitution

You are working in a repository that follows this engineering standard. These are the team's
non-negotiable rules. They take precedence over convenience and individual preference.

## How to use this skill

1. **Always read the source of truth** before advising on architecture, planning or reviewing:
   `references/constitution.md` (the synced copy of the principles) — or, if the repository has
   one, the versioned `memory/constitution.md` / `AGENTS.md` in the project, which may carry more
   recent local adjustments.
2. **Apply principles P1–P8** and the **Definition of Done** to whatever you are doing.
3. **When a request conflicts with a principle**, do not comply silently: name the conflict in one
   line and propose the path that respects the standard.

## The principles (summary — detail in `references/constitution.md`)

- **P1 — Specification before code.** Nothing meaningful starts without a clear spec of what/why.
  Vague requirements are clarified before planning.
- **P2 — Tests mandatory for new code.** Happy path + errors/edges. Never "done" with a failing test.
- **P3 — Code review + green CI.** Peer review and a green pipeline before merge; Conventional
  Commits, atomic, SemVer releases (traceability commit→PR→issue→deploy). The AI does not sign.
- **P4 — Automated style, formatting and typing.** Lint/format/types are a tool's job, not a human
  reviewer's. Strong typing is the rule.
- **P5 — Observability and docs ship with the change.** Logs/metrics/tracing and ADR/README updated
  in the same delivery.
- **P6 — Consistency across teams over individual preference.** Diverging requires a recorded
  justification (ADR); it is never silent.
- **P7 — Security and quality are measured, not argued.** OWASP Top 10 + API Security, static
  analysis quality gate, the project design system + Nielsen + WCAG 2.2 AA + Core Web Vitals,
  privacy, DORA (skills `quality`, `privacy`, `design-system`).
- **P8 — Agentic efficiency.** Less code (reuse > rewrite), maximum signal per token, model
  proportional to the task, disciplined subagents, cost measured per task — without ever cutting
  security, validation, data handling or accessibility (skills `agentic-flow`, `cost`).

Beyond the principles, the constitution defines working modes (GitHub Issues as the source of truth,
fullstack by default, MCP-first integrations, ready-for-PR/preflight). Read
`references/constitution.md` for the detail.

## Definition of Ready

Before picking up an issue: what/why clear, testable criteria, **the domain state matrix filled in**
(published/unpublished, active/expired, public/private, configured/missing — with the expected
behavior in each), scope and non-scope, ambiguities clarified, security/privacy risks and contract
impact flagged, sliceable into a thin vertical. Otherwise it goes back to refinement — do not start
in the dark.

## Definition of Done

Use it as the merge checklist. Work is only done when **all** of these are true:

- Tied to a clear issue/spec.
- Automated tests covering the new behavior, all passing.
- PR reviewed + green CI.
- Lint, formatting and types passing.
- Observability added when the new behavior needs to be observable.
- Documentation/ADR updated where applicable.
- No secrets, credentials or sensitive data in code or logs.
- OWASP security + privacy checked when touching auth, data or input (P7).
- Static analysis quality gate green on new code (P7).
- New UI uses the project design system (legacy migrates progressively) + WCAG 2.2 AA + Core Web
  Vitals, when there is UI (P7).
- Passed `preflight` before the PR (zero automated findings).

For the full detail, precedence and exception rules, read `references/constitution.md`.

## Adapting it to your team

The constitution ships with `<FILL: ...>` placeholders wherever a decision belongs to your team
(number of reviewers, linters per stack, critical services, observability stack). `setup` collects
them once; `onboard` discovers from the code what the code can answer. **A placeholder left unfilled
is a known gap, not a default** — skills degrade with a warning rather than inventing a value.
