# Dev toolchain — GitHub and static analysis in CI

The two tools every repo in this standard touches: GitHub (code, issues, PRs, CI) and whatever runs
the quality gate.

## GitHub through `gh`

Everything the flow needs works through the CLI, which is why the plugin has no hard MCP dependency.

```bash
# PRs
gh pr create --title "feat(auth): rotate refresh tokens" --body-file /tmp/pr.md
gh pr view <n> --json title,body,files,reviews,statusCheckRollup
gh pr diff <n>
gh pr checks <n>                      # CI status, for preflight and review

# CI
gh run list --limit 5
gh run view <id> --log-failed         # the failing step's log, without opening a browser

# Search across the org (blast radius, finding consumers)
gh search code "<symbol>" --owner <org> --limit 50
```

**The PR body is a contract.** It carries `Closes #N` (the traceability link the standard depends on),
what changed and why, and the DoD checklist. A PR body that says "fixes stuff" costs the reviewer
twenty minutes.

## Branch protection (what makes P3 real)

A standard that says "review + green CI before merge" and does not enforce it is a suggestion:

- Require a pull request before merging, with at least `<FILL: N>` approval.
- Require status checks to pass (lint, build, test, the quality gate).
- Require the branch to be up to date before merging.
- Dismiss stale approvals when new commits land.
- No force push to the default branch.

The agent does not change repository settings — it reports what is missing and a human decides.

## Static analysis in CI

The analyzer runs on the PR and reports the gate as a required check
(`quality/references/static-analysis.md`). Two things worth getting right:

- **Analyze the diff, not the world.** "Clean as You Code" only works if the gate is scoped to new
  code; a gate over a legacy codebase is a gate everyone learns to override.
- **The gate blocks the merge.** Otherwise it is a dashboard.

## The CI pipeline shape

```
lint (check mode, not --fix)  →  typecheck  →  test (+ coverage threshold)  →  build  →  analyze
```

Two failure modes worth designing against:

- **`--fix` in CI.** It mutates files and masks the violation, so the gate passes and the problem
  ships. Read-only in CI, always.
- **Runtime version drift between CI and production.** The most common "passes CI, breaks in prod"
  cause; it is in the `preflight` checklist for a reason.

## The relationship with preflight

`preflight` runs these same tools **locally, before the PR**, so CI comes out green first try. If CI
or a bot finds something afterwards, that is a preflight defect and the rule goes into the checklist
(`preflight/references/preflight-checklist.md`). CI is the safety net, not the primary check —
discovering it in CI means a round trip that was avoidable.
