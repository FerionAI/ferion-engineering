# ADR-0003: GitLab is a supported forge (the repo's forge is the tracker)

- **Status:** accepted
- **Date:** 2026-10-13   ·   **Author(s):** `<FILL>`   ·   **Issue/Epic:** #17

## Context
"GitHub Issues is the tracker, operated through `gh`" made the plugin installable by anyone on
GitHub — and unusable as an enforced flow by teams on GitLab. The coupling was narrower than it
looked: the flow state, the milestones, the bypass and `Closes #N` traceability are forge-neutral.
What was GitHub-only was the command recognition in `flow-gate.sh`, the CI check (`gh pr checks`),
the mute-reviewer scan (`pr-bots.sh`) and the `gh` examples across the skills.

## Decision
**The repository's forge is the tracker** — GitHub (`gh`, PRs, `status:` labels) or GitLab (`glab`,
MRs, **scoped** `status::` labels). The flow hook recognises the commands of **both** CLIs (and the
GitHub/GitLab MCP calls) everywhere; the forge — `FERION_FORGE`, `git config ferion.forge`, or the
`origin` remote — only picks which commands its messages suggest and how CI is read (the MR's head
pipeline on GitLab). Skills keep `gh` as the canonical example and point to a single translation
table (`skills/issues/references/forge-commands.md`) instead of duplicating every command.

## Alternatives considered
- **Keep GitHub-only** — GitLab teams get principles but no enforcement. Rejected.
- **Unscoped `status:` labels on GitLab too** — one vocabulary, but ignores GitLab's native,
  exclusive scoped labels that make the board correct by construction. Rejected; the hook accepts
  both separators, so a team that already uses `status:` still works.
- **A forge abstraction script the agent must call** (`ferion issue assume 123`) — hides the real
  CLI, adds a layer to maintain and a new thing to learn. Rejected; the agent uses the native CLI.

## Consequences
- **Positive:** GitLab teams get the full, enforced flow. Forge-neutral state means a mixed
  organisation runs one standard.
- **Negative / costs:** every hook change is tested on both forges (`hooks/flow-gate.test.sh` has a
  GitLab section); `glab`'s JSON output must be re-checked when the CI-read breaks; GitLab epics
  (Premium) are replaced by a parent issue + `/relate`; bot detection on GitLab is by username.
- **Impact:** `hooks/`, `pr-bots.sh`, `issues`/`setup`/`start` references, constitution wording.

## Constitution principles involved
- **P6** (consistency): one flow across forges.
- **P3** (review + CI): the same gates — local review, linked MR, green pipeline — on GitLab.
