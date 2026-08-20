# Tasks — `<feature name>`

- **Related plan:** `specs/<feature>/plan.md`

> Every task should be small, verifiable and accompanied by its tests.
> Mark `[P]` on tasks that can run in parallel. Record dependencies.

## Tasks

- [ ] **T1** — `<description>` · Tests: `<what it proves>` · Depends on: `<—>`
- [ ] **T2 [P]** — `<description>` · Tests: `<...>` · Depends on: `<—>`
- [ ] **T3** — `<description>` · Tests: `<...>` · Depends on: `T1`
- [ ] ...

## Final checklist (summary — full DoD in `constitution`)

- [ ] All tasks complete with tests passing.
- [ ] PR reviewed + CI green.
- [ ] Lint, formatting and types passing.
- [ ] Observability added where needed.
- [ ] Documentation/ADR updated.
- [ ] No secrets or sensitive data exposed.
- [ ] Security/quality (OWASP, quality gate), design system and privacy ok where applicable (P7).
- [ ] Coherence verified: spec ↔ plan ↔ tasks ↔ code (the Analyze step).
- [ ] Passed `preflight` — zero automated findings — before opening the PR.
