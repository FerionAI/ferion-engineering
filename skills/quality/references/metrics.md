# Quality and delivery metrics

Metrics worth tracking to measure (and improve) team performance without falling into vanity. Split
into **delivery** (DORA), **code** and **product**.

## DORA — the four delivery metrics

The industry standard for software delivery performance. Track all four together (speed without
stability does not count):

| Metric | What it measures | Reference range (elite → low) |
|---|---|---|
| **Deployment frequency** | How often you ship to production | on demand/daily → monthly or less |
| **Lead time for changes** | From commit to production | < 1 day → > 1 month |
| **Change failure rate** | % of deploys causing an incident/rollback | 0–15% → high |
| **Failed deployment recovery time** (MTTR) | Time to recover from a failure | < 1h → > 1 week |

Team target: `<FILL: e.g. daily deploys, lead time < 1 day, CFR < 15%, MTTR < 1h>`.
The first two measure speed; the last two measure stability — improve one without sacrificing its pair.

## Code metrics (kept by static analysis + CI)

- **Test coverage** — new code ≥ **80%** (default; see `static-analysis.md`). Meaningful coverage, not
  a number for its own sake.
- **Duplication** — ≤ 3% on new code.
- **Complexity** — cognitive/cyclomatic within limits.
- **Technical debt ratio** — trending down; top rating on new code.
- **Security** — 0 open blocker/high vulnerabilities; hotspots 100% reviewed.

## Product / front-end metrics

- **Core Web Vitals** — LCP/INP/CLS in the "good" band (`frontend-ux.md`).
- **Accessibility** — a11y score in CI (Lighthouse/axe) ≥ `<FILL: target>`.
- **Production error rate** — errors per session/request monitored (observability, P5).

## Process health (optional but recommended)

- **PR cycle time** — open to merge (small PRs → short cycles).
- **PR size** — target **< 400 lines** (it correlates with review quality more than anything else).
- **Flaky tests** — track and fix; an unstable test destroys trust in CI, and a CI nobody trusts is
  a CI nobody reads.

## How to use them

- **Do not become hostage to a number.** A metric is a signal, not a goal in itself. Use it for
  conversations, never to punish (P8).
- **Automate collection** — DORA from CI/CD and the incident tracker; code metrics from the analyzer;
  front-end from RUM. The `health` skill consolidates all of it.
- **Review periodically** — bring the metrics to the retro and tie them to concrete actions.
- **Every number comes with its previous value** — see rule #1 in `health`. A metric with no delta
  cannot be defended or acted on.

## Related practices worth adopting

- **12-Factor App** for services (config, statelessness, logs as streams, dev/prod parity).
- **Conventional Commits + SemVer** — predictable history and versioning (ADR-0001).
- **Lightweight threat modeling** on sensitive features (`threat-modeling.md`).
- **ADRs** — architecture decisions recorded (P5/P6).
