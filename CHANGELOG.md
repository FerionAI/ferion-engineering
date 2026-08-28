# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1](https://github.com/FerionAI/ferion-engineering/compare/ferion-engineering-v0.2.0...ferion-engineering-v0.2.1) (2026-08-28)


### Bug Fixes

* **health:** read the signal instead of painting it, and connect before giving up ([6a36b4a](https://github.com/FerionAI/ferion-engineering/commit/6a36b4a35c8fe5adf1699d354b498fc6503b5049))
* **health:** read the signal instead of painting it, and connect before giving up ([d1a3829](https://github.com/FerionAI/ferion-engineering/commit/d1a382928729a905f2ed89682fbf4e2c5fc90ee3)), closes [#5](https://github.com/FerionAI/ferion-engineering/issues/5)
* **release:** put the version stamp on the marker line in CLAUDE.md ([7b5078c](https://github.com/FerionAI/ferion-engineering/commit/7b5078c205a0265a57775eb4b2727e7359b6be4b)), closes [#3](https://github.com/FerionAI/ferion-engineering/issues/3)
* **security:** stop check-leaks from publishing the terms it hides ([a89c927](https://github.com/FerionAI/ferion-engineering/commit/a89c927f4d09592ba26e1886ca6157d8486b0ee7)), closes [#2](https://github.com/FerionAI/ferion-engineering/issues/2)
* stop the leak detector from publishing what it hides, and fix the CLAUDE.md version stamp ([9bb2584](https://github.com/FerionAI/ferion-engineering/commit/9bb2584899f8b611ca2720359590b62bdc7ccdf4))

## [0.2.0](https://github.com/FerionAI/ferion-engineering/compare/ferion-engineering-v0.1.0...ferion-engineering-v0.2.0) (2026-08-26)


### Features

* **cost:** measure cost per issue, not per session ([7356985](https://github.com/FerionAI/ferion-engineering/commit/735698515f9ee303b7055fd791d52046a3303033))
* initial open source release of ferion-engineering ([a9ed13a](https://github.com/FerionAI/ferion-engineering/commit/a9ed13a2bac97d528b549da9a68dc377b1f97f11))
* **preflight:** target the reviewer that exists, block PRs with no trail ([3c0bc5c](https://github.com/FerionAI/ferion-engineering/commit/3c0bc5c18ca170ff922b71d7c0e44c32af7e5f50))

## 0.1.0 (2026-08-20)

First open source release.

### Features

* **constitution:** eight non-negotiable principles (P1–P8), Definition of Ready and Definition of
  Done as an objective merge checklist, plus a Design Constitution for UX/UI.
* **flow gate:** a mandatory 6-step flow — issue → in progress → implement → local review →
  PR + cost → in review — enforced by hooks that **block** (exit 2) an out-of-order step. Flow state
  lives per repository in `.git/ferion-flow`; milestones are stamped from what the tool actually did,
  never from a claim. Exceptions require an explicit, recorded `bypass`.
* **issues:** GitHub Issues as the source of truth, operated through `gh` (the GitHub MCP is
  optional). No external tracker required.
* **preflight:** a pre-PR gate that runs the real tools and performs independent
  anti-hallucination verification, looping until zero findings, so that no automated reviewer has
  anything to flag.
* **25 skills** covering the full cycle for PM, QA and dev: `setup`, `start`, `epic`, `discovery`,
  `issues`, `ship`, `spec-flow`, `preflight`, `review`, `qa`, `quality`, `design-review`,
  `design-system`, `privacy`, `agentic-flow`, `cost`, `fullstack`, `workspace`, `integrations`,
  `onboard`, `health`, `context`, `constitution`, `release`, `incident`.
* **playbooks:** the operational detail of every skill in `references/`, loaded on demand
  (progressive disclosure), indexed automatically in `PLAYBOOKS.md`.
* **portable core:** `AGENTS.md` + `memory/constitution.md` carry the standard to Cursor, Gemini and
  Codex, not just Claude.
* **validation:** `scripts/validate-plugin.sh` checks manifests, skill frontmatter, every cited
  reference, constitution sync and version coherence; `scripts/check-leaks.sh` keeps the standard
  generic. Both run in CI.
