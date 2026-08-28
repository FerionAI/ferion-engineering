# Engineering Constitution

> **What this document is.** The *source of truth* for your team's engineering standard.
> It is **portable and LLM-agnostic**: the same text is read by Claude (through this plugin),
> by Cursor and by Gemini/Codex (through `AGENTS.md` / Spec Kit). Any agent working in a
> repository that adopts this standard **must** follow these principles.
>
> **How to maintain it.** This file is the only source of truth. Edit here and sync the other
> carriers (see `docs/multi-llm-distribution.md`). Never duplicate a rule somewhere else.
>
> **How to adapt it.** Everything marked `<FILL: ...>` is a decision your team owns — the
> `setup` skill collects them once and `onboard` discovers what can be read from the code.
> A placeholder left unfilled is a known gap, not a default: skills degrade with a warning
> instead of guessing.

**Version:** 0.2.1 · **Last updated:** 2026-08-20 · **Owner:** `<FILL: who owns the standard>` <!-- x-release-please-version -->

---

## Principles (non-negotiable)

These principles take precedence over convenience, one-off speed and individual preference.
When a principle conflicts with a request, the agent must name the conflict and propose a path
that respects the principle.

### P1 — Specification before code

No meaningful feature starts without a clear specification of **what** and **why**
(not "how"). Ambiguous tasks are clarified *before* planning. This is the direct attack on
rework and on "the AI built the wrong thing".

- Every non-trivial change goes through the spec-driven flow (see `skills/spec-flow`).
- Vague requirements → run clarification before the plan.
- The technical plan states architecture decisions and trade-offs explicitly.

### P2 — Tests are mandatory for new code

All new or changed code needs automated tests passing before merge.

- Cover the happy path **and** the main error/edge cases.
- `<FILL: is TDD recommended or required? e.g. "required in core services">`
- No hard global coverage target, but **critical services** demand more rigor:
  `<FILL: list the critical services and the expected level>`.
- Never mark work "done" with failing or broken tests.

### P3 — Code review + green CI

Nothing reaches the main branch without peer review and a green pipeline.

- PR reviewed by at least `<FILL: number of reviewers, e.g. 1>` reviewer(s).
- Required pipeline: lint + build + tests + `<FILL: other gates, e.g. security analysis, SAST>`.
- Small, focused PRs. Target: `<FILL: suggested max size, e.g. < 400 lines>`.
- **Conventional Commits** (`type(scope): summary`) and **atomic** commits — one complete,
  green logical slice per commit. This is what makes automated SemVer/changelog, `revert` and
  `bisect` work.
- **AI does not sign commits or PRs** — never add an LLM `Co-Authored-By:`, "Generated with…"
  or a bot marker. The author is the person; authorship and accountability are human.
- **SemVer releases** derived from the commits (semantic-release/release-please), with
  traceability **commit → PR (issue reference) → issue → deploy**. Enforcement
  (commitlint/husky/CI) and per-stack detail in `skills/context/references/conventions.md`
  (decision recorded in `docs/adr/0001-conventional-commits-semver.md`).

### P4 — Automated style, formatting and typing

Style is not a topic for human review — it is a tool's job.

- TypeScript/Node: `<FILL: ESLint + Prettier (or Biome) config; TS strict mode>`.
- Python: `<FILL: ruff / black / mypy — versions and config>`.
- Go: `gofmt` + `<FILL: golangci-lint config>`.
- Java/.NET: `<FILL: formatter/linter/analyzers>`.
- Strong typing is the rule; `any`/`interface{}`/untyped reflection require justification in the PR.

### P5 — Observability and documentation ship with the change

A feature is not done if you cannot operate and understand it later.

- Structured logs, metrics and tracing following the team standard:
  `<FILL: observability stack — e.g. OpenTelemetry, CloudWatch, Datadog, Grafana>`.
- Relevant architecture decisions become an ADR (Architecture Decision Record):
  `docs/adr/NNNN-title.md` in the affected repository (incremental numbering).
- Service README/docs updated in the same delivery that changes behavior.

### P6 — Consistency across teams over individual preference

The goal is that any person (or LLM) can enter any repository and recognize the standard.
Diverging from the standard requires a recorded justification — it is never a silent decision.

- Follow the conventions in `skills/context/references/conventions.md`.
- New patterns are born from proposal → ADR → update to this constitution.

### P7 — Security and quality are measured, not argued

Security and quality have an objective, verifiable floor that applies to all new code.

- **Security:** no open item from the **OWASP Top 10**; APIs follow the **API Security Top 10**;
  no secrets in code or logs; every external input validated.
- **Quality:** the **static analysis quality gate on new code** is the floor ("Clean as You Code").
  `<FILL: which analyzer — e.g. SonarQube, CodeQL, none>`.
- **Front/UX:** the project's **design system is the default** for new UI, with **progressive
  adoption** — new code uses it, legacy migrates **without blocking deploy**; **Nielsen**
  heuristics, **WCAG 2.2 AA** accessibility and **Core Web Vitals** in the "good" band. The UX/UI
  standard is the **Design Constitution** (`memory/design-constitution.md`), validated before code
  by `design-review`. Detail in the `design-system` skill.
- **Team:** delivery performance tracked with **DORA metrics**.
- **Privacy:** personal data handled with minimization, a legal basis, a defined retention period
  and no PII in logs or telemetry — detail in the `privacy` skill.
- Operational detail in the `quality` and `privacy` skills.

### P8 — Agentic efficiency (less code, fewer tokens, proportional model)

Working efficiently with AI is part of the standard, not an extra.

- **The best code is the code never written.** Reuse before rewriting; stdlib/native before a new
  dependency; the minimum that works. Never trade away security, validation, data-loss handling
  or accessibility for brevity.
- **Maximum signal per token.** Progressive disclosure, batched tool calls, never re-read what was
  already read. **Terse answers by default** — high signal, zero filler, no preamble or recap;
  a report or walkthrough **only when asked** (requested explanation is not debt). Terseness is
  **not** skipping clarification: ask the essential question (one at a time) whenever something
  is missing.
- **Model proportional to the task.** Cheap and fast for mechanical work; strong for what needs
  reasoning (architecture, debugging, verification). Start cheap, escalate on demand.
- **Subagents with cost discipline.** Only when there is real parallelism, context isolation or
  independent verification.
- **Measure to improve:** cost per task (tokens + time) recorded on the issue itself, to gauge
  efficiency and price features — a signal for improvement, never a stick (`cost` skill).
- Operational detail in the `agentic-flow` and `cost` skills.

---

## Working mode — fullstack by default

The aim is for people to be **fullstack most of the time**: front-end people working in the
back end and vice versa. This reduces dependency between squads and unlocks parallelism (one
person carries a whole vertical slice without waiting to "hand it to the other team").

- **Vertical slice:** deliver end-to-end value in thin slices (contract → back → front → e2e),
  not "all of the back end and then all of the front end".
- **The contract is the source of truth:** the schema/types between front and back are what let
  one person hold both ends safely; design it in the `plan` step.
- **Strengthen the weak side, with guardrails:** when working outside your domain, the AI acts as
  the senior on the other side — it explains and teaches, never relaxing security, validation,
  data handling or accessibility.
- Operational detail in the `fullstack` skill.

This is not dogma: legitimate specializations exist. It is the default direction, not an absolute.

---

## Integrations and tooling — MCP-first

Teams use GitHub plus a set of external tools (observability, analytics, static analysis).
The standard:

- **MCP-first to operate:** prefer the tool's official MCP over improvising outside it.
- **Decoupled integration code:** isolate the vendor behind your own interface (anti-corruption
  layer); resilience (timeout, idempotent retry, graceful degradation); secrets outside the code.
- **One single typed event/telemetry layer** feeds analytics and observability — no vendor SDK
  scattered through the codebase.
- **Observability is part of the Definition of Done (P5).**
- Operational detail in the `integrations` skill.

---

## Issues as the source of truth — GitHub Issues

The whole flow runs through AI, and **the GitHub issue is the source of truth of the work**:
the product intent, the acceptance criteria, the decisions, the PR link and the QA review all
live on the issue — in the same place as the code.

- **Every change starts from an issue (rule).** Before any development, make sure the issue
  exists: if the request does not mention one, **ask** the person (do not scan the backlog
  guessing); if it does not exist, **create it** with the standard fields before starting.
  No issue, no code — including small fixes. An emergency hotfix enters through `incident`,
  which opens the issue. (`issues` skill)
- **Issues are born well-formed:** an epic becomes issues that already carry the project stack,
  testable acceptance criteria and the Definition of Done (`epic` skill). A standalone issue
  follows the same shape.
- **Start from the issue:** all work starts from the issue (read or just created) — the
  "what/why" comes from it.
- **Write back:** labels, comments and the PR link stay current — the issue reflects reality.
- **The issue wins:** a divergence between code and acceptance criteria is resolved and recorded
  on the issue, not lost in a chat log.
- **Traceability:** issue → spec/plan → PR (`Closes #N`) → QA (on the issue).
- Operational detail in the `issues` skill.

---

## Ready for PR — the spotless standard (preflight)

Because the flow runs through AI end to end, **nothing opens a PR below standard**. Before any PR,
`preflight` runs the exhaustive check against every rule, executes the real tools
(build/lint/types/tests/static analysis) and performs independent anti-hallucination verification,
**looping until zero findings**.

- **Target:** no automated reviewer (static analysis, linters, PR bots) has anything to flag.
- **Human review is only that:** code taste and "does anything look off?" — not hunting what the
  machine should already have caught.
- **Anti-hallucination:** verify that what the agent generated actually exists (APIs, components,
  imports), compiles, tests and proves something — the agent that wrote the code cannot see its
  own error; independent verification can.
- If a bot flags something afterwards, that is a preflight defect: the rule that slipped through
  joins the checklist.
- Operational detail in the `preflight` skill.

---

## Definition of Ready (before picking up the issue)

An issue/spec is **ready to start** when (this is what prevents "the AI built the wrong thing" — P1):

- [ ] Problem and value are clear — the **what** and the **why**, not the solution.
- [ ] Acceptance criteria are **testable**.
- [ ] **State matrix filled in:** for every entity touched, the domain states
      (published/unpublished, active/expired, public/subscriber-only/private, configured/missing,
      0/1/many) and the expected behavior **in each** — not just the happy path. This is the defect
      class that most often reaches QA (`epic/references/issue-template.md`).
- [ ] Scope and non-scope explicit; dependencies known.
- [ ] Relevant ambiguities already clarified (ran `clarify` if needed).
- [ ] Security/privacy/data risks flagged (P7/privacy).
- [ ] API contract impact identified, when applicable.
- [ ] Sliceable into a thin vertical delivery (not an epic disguised as an issue).

An issue that fails Ready **goes back to refinement** — you do not start in the dark. An epic
processed by `epic` produces issues that are already Ready.

---

## Definition of Done (merge checklist)

Work is **done** only when **every** item below is true:

- [ ] The change is tied to a **GitHub issue** (created before starting, if it did not exist) and
      to its spec (P1).
- [ ] Automated tests covering the new behavior, all passing (P2).
- [ ] PR reviewed and approved by a peer, with green CI (P3).
- [ ] Conventional, atomic commits; SemVer release where applicable (P3).
- [ ] Lint, formatting and type checking passing (P4).
- [ ] Logs/metrics/tracing added when the new behavior needs to be observable (P5).
- [ ] Documentation/ADR updated where applicable (P5).
- [ ] No secrets, credentials or sensitive data in code or logs.
- [ ] OWASP security checklist applied when the change touches auth, data or external input (P7).
- [ ] Static analysis quality gate green on new code (P7).
- [ ] Front-end: new code uses the project design system; legacy migrates progressively without
      blocking deploy; Nielsen heuristics, WCAG 2.2 AA and Core Web Vitals are fine, when the UI
      changed (P7).
- [ ] Privacy: personal data has a legal basis, minimization and retention, and no PII in logs or
      telemetry, when applicable (P7).
- [ ] Passed `preflight` before the PR: real tools green + full checklist + independent
      verification, with zero automated findings.
- [ ] `<FILL: your team's own item, e.g. feature flag for risky changes>`.

---

## Precedence and exceptions

1. Security and privacy of user data come first, always.
2. Then the P1–P8 principles of this constitution.
3. Then the per-language conventions (`conventions.md`).
4. Individual preference last.

Exceptions to any principle must be **explicit**: recorded in the PR or in an ADR, with the reason
and the deadline/condition for returning to the standard. A silent exception is a violation.

---

## How an AI agent should use this constitution

- **Before planning or implementing:** read this constitution and the target application's context.
- **When proposing a plan:** cite which principles drove the decisions.
- **When reviewing code:** use the Definition of Done as the checklist.
- **When a request conflicts with a principle:** do not comply silently. Name the conflict and
  propose the alternative that respects the standard.
