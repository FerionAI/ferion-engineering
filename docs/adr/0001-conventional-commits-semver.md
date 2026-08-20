# ADR-0001: Conventional Commits + SemVer + atomic commits (deploy traceability)

- **Status:** accepted
- **Date:** 2026-08-20   ·   **Author(s):** `<FILL>`   ·   **Issue/Epic:** —

## Context
The flow runs through AI end to end, and we want to **reconstruct any deploy from the history**.
Without a shared convention, commit-message adherence in a multi-repo organization is predictably
uneven: good practice exists as islands (one exemplary repo) rather than as a standard, few repos
enforce anything at commit time, and most services carry no SemVer tags at all. The consequence is
concrete — commit → deploy traceability is not guaranteed, and changelog/versioning cannot be
automated.

Measure your own baseline before adopting this: sample the recent commits across your repos and
count the share that already parse as Conventional Commits, how many repos enforce it
(`commitlint` + a git hook) and how many cut releases automatically. That number is what makes the
migration cost concrete instead of theoretical.

## Decision
Adopt as a rule of the standard (**P3**): **Conventional Commits** required, **atomic commits**,
**SemVer releases derived from the commits** (`semantic-release`/`release-please`) and
**traceability commit → PR (issue reference) → issue → deploy**. Enforcement via `commitlint` plus a
pre-commit hook, and validation in CI. It applies to **all** repos; existing ones migrate.

## Alternatives considered
- **Keep it as an informal recommendation** — pros: zero friction; cons: this is the status quo in
  most organizations, and it guarantees neither traceability nor automation. Rejected.
- **Required only in new repos** — pros: less friction in the existing estate; cons: keeps legacy
  unstandardized and traceability partial for years. Rejected in favor of required-with-migration.
- **A bespoke commit convention** — cons: loses the tooling ecosystem (`commitlint`,
  `semantic-release`, `release-please`). Rejected.

## Consequences
- **Positive:** automatic changelog and SemVer; readable history; reliable `revert`/`bisect`;
  deploys traceable to the issue; the foundation the `release` skill builds on.
- **Negative / costs:** migrating repos that are off-standard (`commitlint`, hooks, CI); initial
  friction; roughly half the team's commit habits have to change.
- **Impact:** all engineering repos; `setup`/`onboard` scaffold the baseline;
  `context/references/conventions.md` carries the per-stack detail.

## Constitution principles involved
- **P3** (code review + CI): the rule lives here — commits, versioning and traceability are a
  quality gate.
- **P6** (consistency): one commit/versioning standard across repos and teams.
- **P5** (observability/traceability): the deploy is reconstructible from the history.

---
> ADRs record relevant architecture decisions (required by P5/P6 and by the Definition of Done).
> Where ADRs live: `docs/adr/NNNN-title.md` in the affected repository (incremental numbering).
