# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
