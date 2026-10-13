# ferion-engineering

An opinionated engineering standard packaged as a **Claude Code and Codex plugin**: spec-driven development,
a team's good practices, and per-repository context — with **automatic onboarding** and, above all,
**a development flow that is enforced by hooks instead of described in prose**.

> **Status:** `0.6.0`<!-- x-release-please-version --> — 30 skills, 92 playbooks. Covers the full
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

Everything else in this plugin — the constitution, the 30 skills, the playbooks — is what makes
each of those steps worth taking.

## Requirements

- [Claude Code](https://claude.com/claude-code) or [Codex](https://developers.openai.com/codex) (CLI or app)
- [`gh`](https://cli.github.com/) authenticated (`gh auth status`) **or**, on GitLab,
  [`glab`](https://gitlab.com/gitlab-org/cli) (`glab auth status`) — the only hard dependency.
  Issues, PRs/MRs and labels all go through it.
- Python 3 (used by the cost script and the validation script).

## Install

This repository is a **Claude Code marketplace**:

```bash
/plugin marketplace add FerionAI/ferion-engineering
/plugin install ferion-engineering@ferion
```

Reopen the session to load it. Confirm with `/plugin list` (`ferion-engineering@ferion` · enabled) —
the session-start hook appears and the skills become available as `/ferion-engineering:<skill>`
(e.g. `/ferion-engineering:start`) — or just describe what you want, which works everywhere. To
update (the session-start hook tells you when you are behind):

```bash
/plugin marketplace update ferion && /plugin update ferion-engineering
```

**Claude Desktop / Cowork** fetches the marketplace differently, and a private fork needs one extra
setting: [docs/claude-desktop-install.md](docs/claude-desktop-install.md). What is checked before each
release, and what only a real install proves: [READINESS.md](READINESS.md).

### Codex

The same repository is also a **Codex marketplace** (`.agents/plugins/marketplace.json` →
`.codex-plugin/plugin.json`) — same skills, same hooks, same flow gate:

```bash
codex plugin marketplace add FerionAI/ferion-engineering
codex          # then /plugins → install ferion-engineering, and start a new session
```

Then run `/hooks` once and **trust** the plugin hooks — Codex skips untrusted hooks, and without
them the flow is not enforced. For the optional GitHub MCP, export a token before starting Codex
(`export GITHUB_PAT=$(gh auth token)`); without it only that MCP fails — the flow runs on `gh`.
To update: `codex plugin marketplace upgrade`. Differences from
Claude are listed in [docs/multi-llm-distribution.md](docs/multi-llm-distribution.md#3-codex--the-same-plugin).

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
| `start` | Skill | **Natural-language entry point** — understands the request in plain language and routes it, without anyone learning skill names. Opens with a short panel for the person's role (PM, QA, dev, tech lead) — the role orders the offer, it never restricts (`skills/ROLES.md`). |
| `ship` | Skill | **Idea-to-PR combo** — orchestrates spec → vertical slice → integrations → quality → review → PR. |
| `spec-flow` | Skill | Spec-driven flow (specify → clarify → plan → tasks → implement → analyze) anchored in the standard. |
| `issues` | Skill | GitHub or GitLab issues as the source of truth: read from the issue, write back to it, `Closes #N` closes the loop. |
| `epic` | Skill | For PMs: turns an epic into well-formed issues with stack, testable acceptance criteria and the Definition of Done. |
| `discovery` | Skill | **Design thinking around the pipeline** — empathize (analytics → brief), ideate (diverge/converge), test (usability + post-ship behavioral validation). |
| `preflight` | Skill | **Pre-PR gate** — reviews everything against every rule + runs the real tools + independent anti-hallucination verification, looping until zero automated findings. |
| `review` | Skill | Human review after preflight: code taste and "does anything look off?". |
| `approve` | Skill | **The tech lead's phase** — sweeps the issues in review, reviews each PR, fixes the mechanical gaps on the branch, writes the report and, with the tech lead's yes, approves and moves the issue to QA (the gate checks a human approval + CI on GitHub). |
| `qa` | Skill | QA kit: test cases from the issue, bug reports, risk/regression, exploratory testing, automation, UX/a11y QA, production verification and the approval gate. |
| `test-strategy` | Skill | **Test DoR at refinement** — PM, QA and dev decide together the epic's scenarios and the level of each (L0–L4) before the code; without it, everything becomes e2e. |
| `qa-spec` | Skill | Catalog scenario → automated spec at the lowest level that proves the behavior, with an API fixture and a **mutation proof**; refuses to generate if the data trait does not exist. |
| `test-data` | Skill | Factories with domain traits ("past-due customer") + a test-data endpoint guarded at route registration, with a `runId`: the test **creates** its state, never depends on preexisting data. |
| `bug` | Skill | Bug → scenario → **red test** → root-cause fix → green: the regression suite grows where things actually broke; refuses to fix while the test is born green. |
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
| `.mcp.json` | MCP | Optional MCP connections (GitHub, GitLab, Playwright). Codex reads the same servers from `.codex-plugin/mcp.json`. |

## GitHub or GitLab

The flow is the same on both. On GitLab the agent uses `glab`, opens **MRs** and moves scoped labels
(`status::in-progress` → `status::in-review`); the hook recognises both CLIs, reads the MR's
pipeline for the CI check, and picks the forge from the `origin` remote (self-managed host without
"gitlab" in it: `git config ferion.forge gitlab`). Command table:
[`skills/issues/references/forge-commands.md`](skills/issues/references/forge-commands.md).

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

## Usage telemetry (opt-in, aggregated, public)

**Off by default.** If you want to help show where the flow leaks and which skill costs the most,
opt in: the session-start hook then sends, **at most once a day and in the background**, an
aggregated summary as a **comment on a public issue of this repository** (`[telemetry] YYYY-MM`),
through your own `gh` — so it is signed by your GitHub account and anyone can read it.

| Goes | Never goes |
|---|---|
| Per skill of this plugin: invocations, calls, minutes, tokens | Prompts, answers, code |
| Flow milestones reached (spec → preflight → review → PR → cost → in review → in QA) and gate blocks (category only) | File paths, commands, branch names |
| Surface (CLI/VS Code/desktop), plugin version, number of sessions and hours | Any repository name outside the plugin's own organization |
| | Another plugin's skill names (they become `(other)`) |

```bash
python3 hooks/telemetry.py --preview   # see exactly what would leave your machine
touch ~/.claude/ferion-telemetry        # opt in (or FERION_TELEMETRY=1)
rm ~/.claude/ferion-telemetry           # opt out (FERION_TELEMETRY=0 always wins)
python3 hooks/telemetry.py --report    # what was sent this month, aggregated, no ranking
```

A fork posts to its own repository: the target comes from `plugin.json`. Without `gh` it sends nothing.

## Using it in other agents

`AGENTS.md` + `memory/constitution.md` are the **portable core**: drop them into a repository and
Cursor or Gemini CLI get the principles, the Definition of Ready/Done and the spec-driven
process. (Codex does not need this path: it installs the full plugin — see Install.) See
[docs/multi-llm-distribution.md](docs/multi-llm-distribution.md).

## Adapting it to your team

Nothing here is hardcoded to one company. Anything team-specific is either a `<FILL: ...>`
placeholder or lives in `config/team-config.md` (git-ignored), filled by `setup` and `onboard`.
CI enforces that with `scripts/check-leaks.sh`.

Fork it, change the constitution, keep the flow. That is the point.

## License

MIT — see [LICENSE](LICENSE).
