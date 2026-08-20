# ferion-engineering

An opinionated engineering standard packaged as a **Claude Code plugin**: spec-driven development,
a team's good practices, and per-repository context — with **automatic onboarding** and, above all,
**a development flow that is enforced by hooks instead of described in prose**.

> **Status:** `0.1.0`<!-- x-release-please-version --> — 25 skills, 76 playbooks. Covers the full
> cycle from **idea to merge** for PM, QA and dev. Everything team-specific comes from your **team
> config**: run `setup` once and the team is configured; run `onboard` in a real repository and it
> fills the context from the code.

> 📚 **Playbooks** — the "how" of each skill lives in `references/`, loaded on demand. Full index:
> **[PLAYBOOKS.md](PLAYBOOKS.md)** (auto-generated).

## Why this exists

Most agent setups describe a process and hope the model follows it. It doesn't — not reliably. An
agent under pressure skips the boring step, reorders the flow, or reports a step as done when it
wasn't.

So the process here is **mechanical, not textual**:

- A hook **blocks** (`exit 2`) editing code before an issue exists and is assumed.
- A hook **blocks** opening a PR before local review is closed with zero findings.
- A hook **blocks** moving an issue to review before the PR is open and the cost is recorded.
- Milestones are stamped from **what the tool actually did**, never from the agent's claim.
- State lives in the repository (`.git/ferion-flow`), so a new session **resumes** instead of
  restarting.
- The only way around it is an explicit `bypass "<reason>"` — recorded, and declared in the summary.

Everything else in this plugin — the constitution, the 25 skills, the playbooks — is what makes
each of those steps worth taking.

## Requirements

- [Claude Code](https://claude.com/claude-code)
- [`gh`](https://cli.github.com/) authenticated (`gh auth status`) — this is the only hard
  dependency. Issues, PRs and labels all go through it.
- Python 3 (used by the cost script and the validation script).

## Install

This repository is a **Claude Code marketplace**:

```bash
/plugin marketplace add FerionAI/ferion-engineering
/plugin install ferion-engineering@ferion
```

Reopen the session to load it. Confirm with `/plugin list` (`ferion-engineering@ferion` · enabled) —
the session-start hook appears and the skills become available without a prefix (e.g. `/start`,
`/ship`, `/preflight`). To update:

```bash
/plugin marketplace update ferion && /plugin update ferion-engineering
```

> **Not a developer (PM/QA)?** Ask someone to install it once; after that, just talk to it in plain
> language — start with `/setup` (configures) or `/start` (does the work).

## The mandatory flow

Every code change goes through 6 steps, in this order, with no skipping:

| # | Step | Closes when… | Where |
|---|---|---|---|
| 1 | **issue** | the issue exists — the person cited it, or you **asked and created it** | `issues` |
| 2 | **in progress** | you **assumed** the issue (assignee) and labelled it `status:in-progress` | `issues` |
| 3 | **implement** | spec/plan in `specs/<feature>/` and the code in a vertical slice with tests | `spec-flow` → `ship`/`fullstack` |
| 4 | **local review** | `review` + `preflight` looping until **zero findings** | `review`, `preflight` |
| 5 | **PR + cost** | PR open with `Closes #N` **and** tokens/USD/hours recorded on the issue | `integrations`, `cost` |
| 6 | **in review** | issue labelled `status:in-review`, and said so in the summary | `issues` |

Check where you are at any time:

```bash
bash hooks/flow-gate.sh status
```

## Components

| Component | Type | What it is for |
|---|---|---|
| `setup` | Skill | **Guided configuration, no code** — connects tooling and collects the standard through simple questions (designed for PMs and QAs too). |
| `start` | Skill | **Natural-language entry point** — understands the request in plain language and routes it, without anyone learning skill names. |
| `ship` | Skill | **Idea-to-PR combo** — orchestrates spec → vertical slice → integrations → quality → review → PR. |
| `spec-flow` | Skill | Spec-driven flow (specify → clarify → plan → tasks → implement → analyze) anchored in the standard. |
| `issues` | Skill | GitHub Issues as the source of truth: read from the issue, write back to it, `Closes #N` closes the loop. |
| `epic` | Skill | For PMs: turns an epic into well-formed issues with stack, testable acceptance criteria and the Definition of Done. |
| `discovery` | Skill | **Design thinking around the pipeline** — empathize (analytics → brief), ideate (diverge/converge), test (usability + post-ship behavioral validation). |
| `preflight` | Skill | **Pre-PR gate** — reviews everything against every rule + runs the real tools + independent anti-hallucination verification, looping until zero automated findings. |
| `review` | Skill | Human review after preflight: code taste and "does anything look off?". |
| `qa` | Skill | QA kit: test cases from the issue, bug reports, risk/regression, exploratory testing, automation, UX/a11y QA, production verification and the approval gate. |
| `quality` | Skill | Quality and security rule base: OWASP, Nielsen, WCAG, Core Web Vitals, static analysis and DORA metrics. |
| `design-review` | Skill | **Pre-code design gate** — validates a layout/Figma against the Design Constitution before building; a UX linter with severities. |
| `design-system` | Skill | Discovers the project's design system and drives its **progressive adoption** — new UI uses it, legacy migrates without blocking deploy. |
| `privacy` | Skill | Personal data done right (GDPR/LGPD/CCPA): data map, legal basis, retention, masking in logs and analytics, data subject rights. |
| `constitution` | Skill | The non-negotiable standards (architecture, tests, review, typing, observability) + Definition of Done. |
| `context` | Skill | Application inventory, infrastructure patterns and per-language conventions — the context that stops everyone from starting from zero. |
| `onboard` | Skill | Initializes the standard in a **new** project (scaffold) or an **existing** one (scans, documents, reports gaps). |
| `agentic-flow` | Skill | How to work with AI efficiently: less code, response optimization, model selection per task, subagent orchestration. |
| `cost` | Skill | Measures cost per task (tokens + time) and records it on the issue; feeds efficiency tracking and feature pricing. |
| `fullstack` | Skill | Strengthens front-end people in the back end and vice versa (mentor mode + guardrails), enabling vertical slices. |
| `workspace` | Skill | **Multi-repo coordination** — understands how the repos of a workspace relate (polyrepo, front ↔ N backs through a contract) and orchestrates the slice, the PRs and the deploy order. |
| `integrations` | Skill | External tooling expertise: decoupled, observable integration code + MCP-first operation. |
| `health` | Skill | Living engineering health dashboard (DORA + quality gate + observability + Core Web Vitals). |
| `release` | Skill | Shipping to production safely: deploy strategy, feature flags, rollback criteria and mechanics, SemVer from the commits, zero-downtime data migration. |
| `incident` | Skill | Incident response + blameless postmortem: severity, mitigation, communication, root cause and tracked action items. |
| Always-on hook | Hook | Injects the standard at session start and on every code change, and **enforces the flow order**. Also blocks AI signatures on commits and PRs (P3). |
| `.mcp.json` | MCP | Optional MCP connections (GitHub, Playwright). |

## First time

Call the **`setup`** skill: it walks anyone — including people who do not code — through connecting
the tooling and configuring the standard, ending with everything ready. After that, a PM can say
"break down this epic" and "deliver this issue", and the plugin takes it to a **finished PR**; the
engineer only does the final review.

## Natural language (nobody memorizes skills)

The entry point is **`start`**: describe what you need in plain language — "build this feature",
"is this secure?", "onboard me into this repo", "how are our metrics", "can this leak personal
data?" — and it routes you. For a full end-to-end feature, the **`ship`** combo orchestrates
spec → vertical slice → integrations → quality → review → PR.

## Using it outside Claude

`AGENTS.md` + `memory/constitution.md` are the **portable core**: drop them into a repository and
Cursor, Gemini CLI or Codex get the principles, the Definition of Ready/Done and the spec-driven
process. Skills are a Claude Code feature; the standard is not. See
[docs/multi-llm-distribution.md](docs/multi-llm-distribution.md).

## Adapting it to your team

Nothing here is hardcoded to one company. Anything team-specific is either a `<FILL: ...>`
placeholder or lives in `config/team-config.md` (git-ignored), filled by `setup` and `onboard`.
CI enforces that with `scripts/check-leaks.sh`.

Fork it, change the constitution, keep the flow. That is the point.

## License

MIT — see [LICENSE](LICENSE).
