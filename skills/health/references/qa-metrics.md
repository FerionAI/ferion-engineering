# QA metrics on the dashboard — what shows the suite getting better

A test count is not a metric: it goes up on its own and says nothing about the risk covered. The six
below measure **reliability** and **who is producing what** — and all of them come from sources that
already exist.

| Metric | How to compute it | Good direction | When it is bad, the action is |
|---|---|---|---|
| **Tests depending on preexisting data** | `preflight/scripts/qa-lint.sh --all` → files with a finding ÷ total test files | ↓ to ~0% | a factory with a trait on the most cited aggregate (`test-data`), not silencing the lint |
| **Mutation proof failure rate** | mutations that brought a test down ÷ proofs made in the period (declared on the PRs: `gh pr list --state merged --search "mutation proof in:body"`) | **> 0**, stable | zero is a symptom: the proof is loose, mutating what the test does not look at (`qa-spec/references/mutation-proof.md`) |
| **Flaky in quarantine** | `grep -rn "quarantine until"` in the test dirs, each date compared with today | ↓, and **none expired** | an expired quarantine gets deleted or fixed — a test switched off for 3 months is not a net |
| **Catalog coverage** | `automated` scenarios ÷ (total − `manual-permanent`), in `scenarios/*.yaml` | ↑ | pull the automation queue by level (L0/L1 first) |
| **Specs first authored by QA** | `git log --diff-filter=A --format=%an -- <test paths>`, authors in the team's QA group (team config, or `gh api orgs/<org>/teams/<team>/members`) | ↑ | the sign that the QA/dev boundary is really dissolving; if it does not rise, the bottleneck is usually stalled review |
| **Escaped defects (30d)** | `gh issue list --label type:bug --search "created:>=<date>"`, only the ones found in production (the team's label for it — `gh label list`) | ↓ | each one becomes a catalog scenario with `origin: bug` (`bug`) — the regression grows where it hurt |

## Rules of the block (the same as the rest of the dashboard)

- **Always with the previous week next to it.** A number alone does not say whether it improved.
- **No source, the line disappears** and says what is missing — a repo with no catalog does not
  become "0% coverage", it becomes "the catalog does not exist yet" (`qa/references/scenario-catalog.md`).
  Do not fake green or red.
- **Declared scope**: which repositories, which window. QA metrics aggregated across repositories of
  different maturity mislead more than they inform — name the outliers instead.

## The reading that matters to leadership

Two sentences, not six tiles: **"the suite is no longer depending on the environment"** (preexisting
data going down) and **"what it fails is still real"** (mutation > 0 and escaped defects going down).
If the first goes up and the second goes down, the team is automating theater — and it is better to
find out here than in the next incident.
