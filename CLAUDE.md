# CLAUDE.md — repository context for ferion-engineering

> Read automatically by Claude Code. It carries the working context so any session can continue
> where the last one stopped, without depending on chat history. Keep it short and current.

## What this repository is
The **source of truth of an engineering standard** — one plugin for Claude Code **and Codex**
(`.claude-plugin/` + `.codex-plugin/`, same skills and hooks) plus a portable core
(`AGENTS.md` + `memory/constitution.md`) for Cursor/Gemini.
**Current version: 0.4.0, 25 skills.** <!-- x-release-please-version -->
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
- Hooks must work in both hosts: Claude sends `Edit`/`Write` with `file_path`, Codex sends
  `apply_patch` with the paths in the patch headers (`flow-gate.sh` handles both; cover new cases
  in `hooks/flow-gate.test.sh`). Codex manifest version is bumped by release-please. An MCP server change goes in **both**
  `.mcp.json` and `.codex-plugin/mcp.json` (Codex ignores `headers`; it uses `bearer_token_env_var`).
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
that **block (exit 2)** an out-of-order step — editing code without an assumed issue **or another group's
in the same session**, opening a PR without local review (`stamp review` from `preflight`), **with no spec
on the branch** **or without every issue's reference**, labelling for
review without PR + cost (of that issue) **or with a red CI check** (it reads `gh pr checks` from the URL kept in the
`pr` milestone; with no `gh` it degrades instead of blocking), labelling for QA an issue the tech lead
registered (`tl`, skill `approve`) without the PR approved by a human + CI green.
`PostToolUse` stamps the milestones from what the tool actually did; the only exception is
`bypass "<reason>"` (recorded and declared in the summary). The state also holds each issue's cost
`baseline`, so `cost` measures **per issue, not per session**. Mechanics:
`skills/start/references/mandatory-flow.md`; checks: `hooks/flow-gate.test.sh`.

## Key decisions (do not reopen without reason)
- **The repo's forge is the tracker** — GitHub Issues through `gh`, or GitLab issues through `glab`
  (MRs, scoped `status::` labels; ADR-0003). MCPs are optional; no external tracker is required.
  This is what makes the plugin installable by anyone. Hook changes are tested on both forges.
- The end of the flow is a spotless `preflight` (zero automated findings + independent
  anti-hallucination verification).
- **Flow order is mechanical, not prose.** The pipeline was already written in every skill and the
  agent still skipped and reordered steps. What guarantees the order is the hook, with the state in
  the repo; the skills describe, the gate enforces.
- **One PR can resolve several linked issues** (ADR-0007). Working a batch in series was the hook's
  fault: the state held one issue and assuming the second cleared the first. Linked issues are now a
  **group** (`stamp task A B`): one branch, one review, one PR naming every issue; dev/cost/review are
  per issue and the cost is split equally. The **signal strength** decides: strong (dependency, one
  will not compile without the other, same code, explicit ask) groups and says so; weak (same epic or
  theme) explains and asks. Different repos or a total well above 400 lines (P3) never group.
- **The spec and the session became gates** (ADR-0008). The spec was the only step with no gate and
  the one that leaked the most; a PR now needs a file under `specs/` changed on the branch. Sessions
  that ran through several unlinked issues dragged their context into every call, so **one session
  edits one group**: an unlinked issue asks for `/clear`. And `review` stopped telling the agent to run
  `preflight` first — the contradiction that made it skip the Definition of Done.
- **Ship the shape, never the values.** Anything team-specific is a `<FILL: ...>` placeholder or
  lives in `config/team-config.md` (git-ignored). `scripts/check-leaks.sh` enforces it in CI.
- Design system adoption is **progressive** — it never blocks a deploy.
- Write less code, MCP-first, everything actionable in natural language.

## Where the rest is
- `README.md` (overview + component table), `CHANGELOG.md`, `CONTRIBUTING.md`,
  `docs/multi-llm-distribution.md` (governance/distribution).
- `PLAYBOOKS.md` — **auto-generated** index of the playbooks (`references/`) per skill
  (`scripts/gen-playbooks-index.py`; checked in CI). The gold of the plugin, made visible.
