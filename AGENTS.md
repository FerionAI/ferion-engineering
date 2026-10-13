# AGENTS.md — Engineering Standard

> **For any AI agent** (Cursor, Gemini CLI, Codex, Copilot, Claude and others) working in this
> repository. This file is the portable entry point of the standard. `AGENTS.md` is an open format
> read by most agents; in Claude the same content arrives through the `ferion-engineering` plugin.
> **The source of truth is `memory/constitution.md`.**

## Golden rule
Specify before coding. Respect the constitution. Keep the standard consistent, whichever LLM is
driving.

## Starting point (natural language)
You do not need to know skill names. Describe what you need in plain language and the `start` skill
routes you. To deliver a whole feature (idea to PR), use the `ship` combo. First time / configuring /
connecting tools → the `setup` skill (guided, no code).

## Team configuration
Team-specific values (forge and org/group, test tooling, design system, privacy regime, …) come from the
**team config** filled in by `setup` (`config/team-config.md`, git-ignored). **Prefer the team
config** over the `<FILL: ...>` placeholders in the standard. If a needed value is not configured,
say so plainly and offer to run `setup`. Never invent the value.

## What to read before acting
1. `memory/constitution.md` — non-negotiable principles + Definition of Done.
2. The application context and conventions — `<FILL: where context is synced in this repo, e.g. docs/context/>`.

## Principles (summary — detail in the constitution)
- **P1** Specification before code. Vague requirements are clarified before planning.
- **P2** Tests mandatory for new code (happy path + errors/edges).
- **P3** Code review + green CI before merge; **Conventional Commits**, atomic, releases in **SemVer** (traceability commit→PR→issue→deploy). **AI does not sign commits or PRs** (no `Co-Authored-By`, no "Generated with…" — authorship is human).
- **P4** Lint, formatting and typing automated; strong typing is the rule.
- **P5** Observability and docs ship with the change.
- **P6** Consistency across teams over individual preference.
- **P7** Security and quality measured: OWASP Top 10 + API Security Top 10; static analysis quality gate on new code; the front end uses the project's design system (progressive adoption) + Nielsen + WCAG 2.2 AA + Core Web Vitals; delivery tracked with DORA; privacy with a legal basis, minimization, retention and no PII in logs/telemetry. (Detail in `quality`, `design-system` and `privacy`.)
- **P8** Agentic efficiency: write less code (reuse > rewrite; the minimum that works), maximum signal per token, **terse answers by default** (closing a step = up to 3 lines + the link; a report only when asked; essential clarification is never skipped), **fewer round trips** (batch the checks into one call; do not re-query what a hook already injected — spend is `calls × context`, not words), model proportional to the task, subagents with cost discipline — never cutting security, validation, data handling or accessibility. (Detail in `agentic-flow`.)

## Issues as the source of truth — GitHub or GitLab Issues
The flow runs through AI and the issue (GitHub or GitLab) is the source of truth (intent → issues → dev → QA).
**Every code change starts from an issue — no issue, no code:** if the request does not cite one,
ask (do not scan the backlog guessing); if it does not exist, create it with the standard fields
before starting (including small fixes; an emergency hotfix enters through `incident`). An epic
becomes standard-shaped issues (stack, criteria, DoD) via `epic`. Always start from the issue; write
back to it (labels, comments, PR/MR link; on GitLab: `glab`, MRs and scoped `status::` labels); the issue wins on divergences. QA has its own kit (`qa`:
test cases, bug report, regression, exploratory, automation, gate). The issue also carries its own
cost (tokens + time) — the `cost` skill. (Detail in `issues`, `qa` and `cost`.)

## Integrations and tooling — MCP-first
Prefer each tool's official MCP to operate it; write decoupled integration code (anti-corruption
layer, resilience, secrets outside the code); feed analytics and observability through one single
typed event layer. Observability is part of the Definition of Done. (Detail in `integrations`.)

## Working mode — fullstack by default
Aim for people to be fullstack most of the time (front working in back and vice versa) to
parallelize better. Work in vertical slices (contract → back → front → e2e); the contract/types
between the ends is the source of truth. When working outside your domain, act as the senior on the
other side — explain and teach, without relaxing the guardrails on security, validation, data or
accessibility. (Detail in `fullstack`.)

## Flow order — non-negotiable
Every code change goes through **6 steps, in this order**: **1) issue** (the person cites one, or
you ask and create it) → **2) in progress** (assume the issue: assignee + `status:in-progress`) →
**3) implement** (spec-driven; `specs/<feature>/`) → **4) local review** (`review` + `preflight`
looping until zero findings) → **5) PR + cost** (PR linked with `Closes #N` and tokens/USD/hours
recorded on the issue) → **6) in review** (label the issue and say so in the summary). A small
change **condenses** step 3 — it never skips 1, 2, 4, 5 or 6. Flow state is per repository; a new
session **resumes** from the open step instead of restarting. A real exception (hotfix through
`incident`, a repo with no issue tracker) is **recorded and declared in the summary**, never silent.
In Claude, hooks block out-of-order steps (`hooks/flow-gate.sh`); in other agents, keeping the order
is your responsibility. (Detail in `start`.)

## Workflow (spec-driven / Spec Kit)
For non-trivial features, follow: **specify → clarify → plan → tasks → implement → analyze**.
Has UI? Validate the layout against the **Design Constitution** (`memory/design-constitution.md`)
**before** implementing — the design gate (`design-review`).
Generate the artifacts in `specs/<feature>/` (spec.md, plan.md, tasks.md). Do not skip the tests or
the Definition of Done.

## Onboarding
If this repository does not document the standard yet, initialize it: in an existing project, scan
the stack and generate the context from the code; in a new project, create the bases (constitution,
this AGENTS.md, `specs/`, lint/test/CI configs). In Claude that is the `onboard` skill; in other
agents, follow the same script manually.

## Ready for PR — spotless (preflight)
Nothing opens a PR below standard. Before any PR, run preflight: the exhaustive check against every
rule + the real tools (build/lint/types/tests/analysis) + independent anti-hallucination
verification, looping until zero automated findings. Target: no automated reviewer has anything to
flag; human review is only code taste and "does anything look off?". (Detail in `preflight`.)

## Tests: a scenario is code, test data is created
Scenarios live versioned in the repo (`scenarios/<journey>.yaml`: stable id, data as **domain traits**, when/then, target level, status) — the artifact PM, QA and dev share, decided at refinement and not after the code. Three non-negotiable rules: **(1) the test creates the state it needs** through a factory/API fixture with a `runId` — no preexisting record, no literal id/email/national id, no `SELECT … LIMIT 1`; **(2) waits are on a condition**, never `sleep`/`waitForTimeout`; **(3) every new test goes through a mutation proof** — break the behavior on purpose and require the test to fail; a test that never fails is cost pretending to be a safety net. Automate at the **lowest level that still proves the behavior** (L0 unit → L1 integration → L2 contract → L3 E2E; L4 is exploratory, human, not automated) and argue for going down, saying the gain and the loss. A defect follows the order **bug → scenario → red test → root-cause fix**: if the test is born green, it does not reproduce the bug and the fix does not start. Without the factory for the trait the scenario needs, **do not generate the test** — ask for the factory. (Detail in the skills `test-strategy`, `qa-spec`, `test-data`, `bug` and `qa`.)

## Definition of Ready (before starting)
An issue/spec is ready when: what/why are clear · acceptance criteria are testable · the state matrix
is filled in · scope and non-scope are explicit · ambiguities are clarified · security/privacy risks
and API contract impact are flagged · it is sliceable into a thin vertical · **test DoR**: every
criterion has at least one scenario in the catalog, with level and criticality, and the data traits
exist (or were requested). Otherwise it goes back to refinement — do not start in the dark.

## Definition of Done (merge checklist)
Clear spec · tests passing · PR reviewed + green CI · lint/format/types ok · observability ·
docs/ADR updated · no secrets or sensitive data exposed · OWASP checklist when touching
auth/data/input · quality gate green on new code · front end with Nielsen + WCAG 2.2 AA + Core Web
Vitals ok · privacy: personal data with legal basis, minimization, retention and no PII in logs,
when applicable.

## Code review → QA (the tech lead's phase)
After `in review`, the tech lead owns the PR. The agent may sweep the review queue, review each PR
against the DoD and the issue's criteria, fix **mechanical** gaps on the PR branch (lint, types,
naming, an obvious edge-case test) and turn **judgment** calls into review comments — but the
approval is human: approve only after the tech lead's explicit yes, one PR at a time, and label the
issue `status:in-qa` only with the PR approved by a person and CI green. (Detail in `approve`.)

## Release and incidents
Deploy is separate from release: prefer a flag/canary and have a rollback plan (criterion + mechanics)
before shipping; data changes go expand/contract; a breaking API contract change needs a new version
plus deprecation. Production incident: **mitigate first** (rollback/flag), communicate, find the root
cause and write a **blameless postmortem** with action items tracked as issues. (`release` and
`incident` skills.)

## Fidelity across LLMs
This file + `memory/constitution.md` are the **portable core**: they give any agent the principles
(P1–P8), the Definition of Ready/Done and the spec-driven process — enough to work **consistently
with the standard**. In Claude and Codex (the plugin), the skills deliver the full operational
playbooks and the hooks enforce the flow; elsewhere (Cursor/Gemini), skill names are conceptual
pointers — apply the principles directly, and for deeper detail (per-language conventions, OWASP
checklists) read the `skills/*/references/` files as plain markdown. **Fidelity: Claude/Codex =
complete; others = principles + process.**
`${CLAUDE_PLUGIN_ROOT}` in a skill means the plugin root; if your agent does not expand it, it is
the folder two levels above that skill's `SKILL.md`.

## When a request conflicts with a principle
Do not comply silently. Name the conflict and propose the path that respects the standard.

---
<!-- This file is generated from the central standard. Do not edit it locally without recording the
     change; sync from the source of truth. See docs/multi-llm-distribution.md. -->
