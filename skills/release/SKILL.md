---
name: release
description: Drives shipping to production safely — deploy strategy (canary/blue-green/rolling), feature flags, rollback criteria and mechanics, SemVer releases derived from the commits, and zero-downtime data migration. Use when someone is about to "deploy", "ship to production", "release the feature", "do a canary/rollout", "roll back", "cut a release/tag/version", "turn a feature flag on or off", or plan a risky change (data migration, contract break). Complements preflight (which guarantees the code) by handling HOW it reaches production. If it goes wrong, that is `incident`.
---

# release — shipping to production safely

`preflight` guarantees the **code** is spotless; `release` handles **how it reaches production
without becoming an incident**. Every risky change needs a **rollback plan before the merge**
(declared in the `spec-flow` plan). The release comes out of the **commits** (Conventional Commits →
SemVer — `constitution` P3), so versioning is a consequence, not manual work.

## Deploy strategy (pick by blast radius)

| Risk / blast radius | Strategy |
|---|---|
| Low, reversible | **Rolling** (default) — replace replicas gradually |
| Medium/high, want to validate in prod | **Canary** — a % of traffic on the new version, observe, ramp up |
| Needs an instant switch / A-B | **Blue-green** — bring the new one up in parallel, switch routing |
| Big/uncertain feature | Deploy it **off** behind a **feature flag**, turn it on later |

Detail per platform (canary/blue-green in a GitOps setup, per-environment rollout) in
`references/deploy-strategies.md`. `<FILL: your deploy platform and pipeline>` — `onboard` detects
most of this from the repo (CI workflows, Helm values, IaC).

## Feature flags

- **Ship it off, turn it on gradually** — this decouples deploy from release. A big or risky change
  is born behind a flag.
- Rollout by percentage/cohort/environment; a **kill switch** always available.
- A flag is **temporary**: it has an owner and a removal date (an old flag is debt).
  `<FILL: flag provider, or none>`.

## Rollback (defined BEFORE shipping)

- An **objective rollback criterion** decided up front: errors > X%, latency above the SLO, a
  critical alert.
- **How to revert:** redeploy the previous version, **turn the flag off** (fastest), or restore data.
  Documented on the issue.
- A fast rollback **reduces MTTR** (DORA — `health`). If the rollback does not fix it → `incident`.

## Release and versioning (automatic SemVer)

- The version comes from the commits: `feat` → minor, `fix` → patch, `feat!`/`BREAKING CHANGE` →
  major (`semantic-release`/`release-please`). It generates the tag + CHANGELOG + release notes.
- **Breaking an API contract** requires a new version and an announced deprecation —
  `fullstack/references/api-versioning.md`.

## Data migration (high risk — extra care)

- **Expand/contract (two phases):** add the new thing compatible with the old → migrate → only then
  remove the old. No downtime, and rollback stays possible.
- **Backfill** idempotent, resumable, in batches (do not lock the database). New code reads **both
  old and new** shapes during the transition.
- Every migration has a **way back** (or an explicit plan when it does not). Personal data: `privacy`
  — no PII in migration logs; back up first.

## Observability and DORA

- Alerts and dashboards ready **before** the deploy (`integrations`); watch errors and latency before
  and after. A silent deploy is a blind deploy.
- The release feeds the DORA metrics (deploy frequency, lead time, change failure rate, MTTR) in
  `health`.

## In the flow

- **`ship`:** the risky-change step calls this skill.
- **`workspace`:** when the deploy spans repos (back and front in separate repos), the **order**
  between them comes from there — `release` is per service.
- **`spec-flow` (plan):** rollout, rollback and migration are decided in the plan, not at deploy time.
- **`qa` / `discovery`:** promotion staging → production only after the **human gate** (`qa`) and
  usability checks (`discovery`) in staging.
- **`incident`:** when the deploy causes an incident — rollback + investigation + postmortem.
- **Risky-change checklist:** `references/rollback-and-flags.md`.
