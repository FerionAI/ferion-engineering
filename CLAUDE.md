# CLAUDE.md — repository context for ferion-engineering

> Read automatically by Claude Code. It carries the working context so any session can continue
> where the last one stopped, without depending on chat history. Keep it short and current.

## What this repository is
The **source of truth of an engineering standard** — a Claude Code plugin plus a portable core
(`AGENTS.md` + `memory/constitution.md`) for Cursor/Gemini/Codex.
**Current version: 0.3.0, 25 skills.** <!-- x-release-please-version -->
Covers the full cycle (idea to merge) for PM, QA and dev.

> Careful: **this repo IS the standard/plugin**, not a product app. When editing it, follow
> `CONTRIBUTING.md` (not the product feature flow). The `AGENTS.md` here is the content of the
> standard, not an instruction for changing the plugin itself.

## How to work in this repo (rules)
- The source of truth for the principles is `memory/constitution.md` (P1–P8 + modes). Edit there,
  never only in a copy.
- When changing the constitution: **sync** the copy at `skills/constitution/references/constitution.md`
  (must be identical) and reflect it in `AGENTS.md`.
- A change to a principle or the architecture → record an **ADR**
  (`skills/spec-flow/references/templates/adr-template.md`).
- Any relevant change: **SemVer bump** in `.claude-plugin/plugin.json` + a `CHANGELOG.md` entry.
- Each skill = `skills/<name>/SKILL.md` (frontmatter `name` = folder name) + `references/` for the
  detail (progressive disclosure, token economy — P8).
- Validate before committing: `sh scripts/validate-plugin.sh` (manifests, frontmatter, refs,
  constitution sync, playbook index, hook tests, leak check).

## The 25 skills (quick map)
Entry/setup: `setup` (guided, no code), `start` (NL router), `epic` (PM: epic→issues),
`discovery` (design thinking), `issues` (source of truth), `ship` (idea→PR), `spec-flow`,
`preflight` (pre-PR gate).
Quality: `qa`, `review`, `design-review` (design gate), `quality`, `privacy`, `design-system`.
Efficiency/tooling: `agentic-flow`, `cost`, `fullstack`, `workspace` (multi-repo), `integrations`.
Operations/base: `onboard`, `health`, `context`, `constitution`.
Delivery/production: `release`, `incident`.
Infra: always-on hooks (`hooks/` — session banner + flow step, edit, commit/PR (blocks AI
signatures, P3) and issue transitions), `.mcp.json`, `config/team-config.example.md`.

**Enforced mandatory flow (`hooks/flow-gate.sh`):** state per repo in `.git/ferion-flow` and gates
that **block (exit 2)** an out-of-order step — editing code without an assumed issue, opening a PR
without local review (`stamp review` from `preflight`) **or without an issue reference**, labelling for
review without PR + cost **or with a red CI check** (it reads `gh pr checks` from the URL kept in the
`pr` milestone; with no `gh` it degrades instead of blocking).
`PostToolUse` stamps the milestones from what the tool actually did; the only exception is
`bypass "<reason>"` (recorded and declared in the summary). The state also holds each issue's cost
`baseline`, so `cost` measures **per issue, not per session**. Mechanics:
`skills/start/references/mandatory-flow.md`; checks: `hooks/flow-gate.test.sh`.

## Key decisions (do not reopen without reason)
- **GitHub Issues is the tracker**, operated through `gh`. The GitHub MCP is optional; no external
  tracker is required. This is what makes the plugin installable by anyone.
- The end of the flow is a spotless `preflight` (zero automated findings + independent
  anti-hallucination verification).
- **Flow order is mechanical, not prose.** The pipeline was already written in every skill and the
  agent still skipped and reordered steps. What guarantees the order is the hook, with the state in
  the repo; the skills describe, the gate enforces.
- **Ship the shape, never the values.** Anything team-specific is a `<FILL: ...>` placeholder or
  lives in `config/team-config.md` (git-ignored). `scripts/check-leaks.sh` enforces it in CI.
- Design system adoption is **progressive** — it never blocks a deploy.
- Write less code, MCP-first, everything actionable in natural language.

## Where the rest is
- `README.md` (overview + component table), `CHANGELOG.md`, `CONTRIBUTING.md`,
  `docs/multi-llm-distribution.md` (governance/distribution).
- `PLAYBOOKS.md` — **auto-generated** index of the playbooks (`references/`) per skill
  (`scripts/gen-playbooks-index.py`; checked in CI). The gold of the plugin, made visible.
