# ADR-0002: Codex is a first-class plugin host (same tree, two manifests)

- **Status:** accepted
- **Date:** 2026-10-13   ·   **Author(s):** `<FILL>`   ·   **Issue/Epic:** #14

## Context
Until now Codex only received the portable core (`AGENTS.md` + constitution): principles and
process, but no skills and — the important part — no enforced flow. Codex now loads plugins with
skills, MCP servers and lifecycle hooks (`SessionStart`, `PreToolUse`, `PostToolUse`, exit 2 blocks)
and passes `CLAUDE_PLUGIN_ROOT` to hook commands. The gap that justified "outside Claude the order is
the human's responsibility" no longer exists for Codex.

## Decision
Ship the **same plugin tree** to both hosts: `.codex-plugin/plugin.json` next to
`.claude-plugin/plugin.json`, the repo marketplace at `.agents/plugins/marketplace.json`, one
`hooks/hooks.json`, one `skills/`. Host differences are absorbed inside the hooks
(`flow-gate.sh` reads Codex `apply_patch` headers as well as Claude `file_path`), never by forking
files. Versions stay in lockstep (release-please bumps both; `validate-plugin.sh` checks it).

## Alternatives considered
- **Keep Codex on AGENTS.md only** — zero work, but no enforcement: the reason the flow is a hook.
  Rejected.
- **A separate Codex build (generated copy)** — two trees drift. Rejected; one tree, two manifests.

## Consequences
- **Positive:** Codex teams get the full standard, including the blocking gates.
- **Negative / costs:** hooks must be trusted in Codex (`/hooks`) before they run, and re-trusted
  after an update changes them; `PreToolUse` reminders printed to stdout are not shown in Codex;
  `cost` does not read Codex transcripts yet. Documented in `docs/multi-llm-distribution.md`.
- **Impact:** every hook change must be tested with both payload shapes (`hooks/flow-gate.test.sh`).

## Constitution principles involved
- **P6** (consistency): one standard, whichever agent drives.
- **P3** (review + CI): the same gates guard the PR in both hosts.
