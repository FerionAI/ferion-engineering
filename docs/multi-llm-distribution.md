# Distributing the standard across LLMs

How to keep **one standard** for architecture and development, delivered through **several
vehicles** (Claude, Codex, Cursor, Gemini), without duplicating rules or depending on which LLM each
person picks.

## Mental model

```
        ┌──────────────────────────────────────────┐
        │   SOURCE OF TRUTH (this repository)      │
        │   memory/constitution.md + your context  │
        └──────────────────────────────────────────┘
                          │  syncs to
      ┌───────────────────┼─────────────────────────┐
      ▼                   ▼                         ▼
  Claude / Codex      Cursor / Gemini             Any repo
  (the same plugin    (Spec Kit `specify init`    (AGENTS.md +
   from this repo's    + committed AGENTS.md)      constitution
   marketplace)                                    versioned)
```

The architecture rule is **one** (the constitution). What changes is only the **file/vehicle** each
tool reads. That is what solves "one standard across different LLMs".

## 1. Source of truth

This repository. Every change to the standard happens **here**, through a PR plus an ADR when it
touches a principle. Never edit loose copies inside product repositories.

## 2. Claude — plugin through the marketplace

**This repository is itself the marketplace** (`.claude-plugin/marketplace.json` — marketplace
`ferion`, listing the plugin `ferion-engineering` with `source: "./"`).

1. Add the marketplace and install:
   ```bash
   /plugin marketplace add FerionAI/ferion-engineering
   /plugin install ferion-engineering@ferion
   ```
2. You now have all the skills plus the always-on hooks automatically.
3. Updating: merge to main → release-please publishes a new version → the team runs
   `/plugin marketplace update ferion` + `/plugin update ferion-engineering`.

Forking is a first-class path: point the marketplace at your fork, change the constitution, keep the
flow.

## 3. Codex — the same plugin

Codex reads the same tree: `.codex-plugin/plugin.json` (skills `./skills/`, MCP
`./.codex-plugin/mcp.json`) and
the default `hooks/hooks.json`. The repo marketplace is `.agents/plugins/marketplace.json`. Codex
hands hook commands `CLAUDE_PLUGIN_ROOT` for compatibility, so the hooks are not duplicated.

```bash
codex plugin marketplace add FerionAI/ferion-engineering
codex                      # /plugins → install ferion-engineering → start a new session
                           # /hooks   → review and TRUST the plugin hooks (required)
codex plugin marketplace upgrade   # later, to update
```

What differs from Claude, and how the plugin absorbs it:

| Topic | Claude | Codex | Handling |
|---|---|---|---|
| File edits | `Edit`/`Write` with `file_path` | `apply_patch`, paths in the patch headers | `flow-gate.sh` reads both (`patch_targets`); tested in `flow-gate.test.sh` |
| Hook trust | runs once installed | skipped until trusted in `/hooks` (and re-trusted after a hook changes) | install step above; a changed hook after an update must be trusted again |
| Context from `PreToolUse` | plain stdout reaches the model | plain stdout is ignored | the blocks (exit 2 + stderr) still work; only the soft edit/commit reminders are lost |
| `${CLAUDE_PLUGIN_ROOT}` in skill text | expanded | not expanded | `start` and `AGENTS.md` tell the agent to resolve it to the plugin root |
| MCP auth | `headers` with `${GITHUB_PAT}` (`.mcp.json`) | ignores `headers`; uses `bearer_token_env_var` | `.codex-plugin/mcp.json` (same servers — `validate-plugin.sh` checks it); export `GITHUB_PAT` before `codex` |
| `cost` | reads the Claude transcript | `session-cost.py` does not read Codex sessions yet | record time + the token count Codex reports (`/status`) by hand |

## 4. Cursor / Gemini — Spec Kit + AGENTS.md

[Spec Kit](https://github.com/github/spec-kit) is agent-agnostic. Use it to materialize the standard
in other agents, from the same source of truth.

1. **Install Spec Kit** (once, per machine or in CI):
   ```bash
   uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
   ```
2. **Initialize in each repository**, choosing the agent(s) that team uses:
   ```bash
   specify init --here            # then choose Cursor / Gemini
   ```
   This creates the command/skill files in each agent's directory (`.cursor/`, the Gemini
   files), with the `speckit.*` commands.
3. **Commit `AGENTS.md` and `constitution.md`** into the repository. Most agents (Cursor,
   Gemini) read `AGENTS.md` automatically; the Spec Kit constitution is filled with the content of
   `memory/constitution.md`.

> Several agents coexist in the same repo (Spec Kit declares its integrations "multi-install safe").
> One team can use Cursor and another Claude on the same code, following the same standard.

## 5. Keeping it in sync

Be honest about what is automatic and what is not:

- **Claude/Codex side (automatic):** release-please on main bumps both manifests; teams run
  `/plugin marketplace update ferion` + `/plugin update ferion-engineering` (Claude) or
  `codex plugin marketplace upgrade` (Codex). This is the main path.
- **Non-Claude side (semi-automatic):** each product repo commits `AGENTS.md` +
  `memory/constitution.md` (through `specify init` or a copy) with a "generated — do not edit
  locally" header, and **pins the version** (the constitution stamp). When the core changes, a
  script or CI job in the standard's repo opens update PRs in the product repos.
  `<FILL: the sync-PR automation is not built here — today it is a manual copy on update. Build it
  when your first non-Claude team joins.>`

## 6. What each vehicle actually delivers

| Vehicle | Principles + Definition of Done | Spec-driven process | Operational playbooks | Flow enforced by hooks |
|---|---|---|---|---|
| Claude (plugin) | yes | yes | yes | **yes** |
| Codex (plugin) | yes | yes | yes | **yes** — once the hooks are trusted in `/hooks` |
| Cursor / Gemini | yes | yes | as plain markdown, read on demand | no — order is the human's responsibility |
| Any repo (AGENTS.md only) | yes | yes | no | no |

Hook enforcement ports to Codex, not to Cursor/Gemini. Everything else ports everywhere. Be explicit about that with
teams so nobody assumes a guarantee they do not have.

## 7. Governance

- Changes to the standard are born from **proposal → ADR → merge → propagation**.
- Version the constitution (SemVer in the header). Communicate breaking changes.
- Standard owner: `<FILL: who owns the standard>`.

## Rollout checklist

- [ ] Fill in the `<FILL: ...>` placeholders in the constitution, the context and the conventions.
- [ ] Install the plugin for one pilot team and run the flow on one real feature.
- [ ] Install it in Codex, trust the hooks, and confirm an edit before `in progress` is blocked.
- [ ] Run `specify init` in one repo that uses Cursor and validate the same flow.
- [ ] Adjust based on the pilot, then roll out to everyone.
