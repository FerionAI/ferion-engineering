# Full pre-PR checklist

Walk all of it. Target: **zero automated findings**. Mark ✅/❌ and fix the ❌ before the PR.
Each block points at the skill that owns the rule (for the detail).

## Issue and scope (`issues`)
- [ ] Every acceptance criterion on the issue is met (with evidence).
- [ ] **The issue's state matrix is covered** — each domain state (unpublished, expired, private, unconfigured, empty) has verified behavior, not just the happy path. State matrix missing from the issue: fill it in before opening the PR (`epic/references/issue-template.md`).
- [ ] **Issue that already failed QA once:** fix the rule (name the invariant) + sweep the siblings with `grep` + a test that fails before the fix — patching only the reported case is forbidden from the second round onward (`qa/references/verify-and-gate.md`).
- [ ] No extra scope beyond what was asked (YAGNI); no dead or duplicated code.
- [ ] PR linked to the issue with `Closes #N`; standard description with the DoD checklist.

## Tests and build (P2/P3, `context`)
- [ ] Build and typecheck with no errors.
- [ ] Unit + integration + relevant e2e passing; edge and negative cases covered.
- [ ] Coverage of new code at target; no flaky test introduced.
- [ ] **Bigger change / touches UI:** validated on a **devserver** with synthetic seed data — the live app driven in the browser (Playwright), happy path + error/empty, **console and network clean**, screenshots on the issue (`references/devserver-validation.md`). Small change with no UI: skip.

## Environment and config consistency (catches "passes CI, breaks in prod")
- [ ] **The runtime version matches between CI and production** (Node/Go/Java): `.tool-versions`/`engines`/Dockerfile == the version in the CI workflow. Drift here is extremely common and invisible until it is not.
- [ ] **Lint run in check mode, not `--fix`** (`--fix` mutates files and masks the violation from the gate). Use the read-only form.
- [ ] **Explicit type check** — `tsc --noEmit` (Node), `go vet ./...` (Go), `./gradlew compileJava` (Java). Do not rely on `build` alone.
- [ ] **Coverage with a threshold that fails the build** (not just a measurement); no analyzer rule disabled without an ADR or a justification.
- [ ] **README/metadata match reality** (package name, test runner, deploy target) — stale docs mislead the next person.

## Style, types, complexity (P4, `quality/references/static-analysis.md`)
- [ ] Lint + format with no violations; strong typing (no unjustified `any`/`interface{}`).
- [ ] Static analysis quality gate (local, if available) green: 0 new blocker/high, duplication ≤ 3%.
- [ ] Complexity within the limit; no giant functions or files.

## Security (P7, `quality/references/security-owasp.md`)
- [ ] No open OWASP Top 10 / API Security item in what you touched.
- [ ] External input validated; object/function level authorization; parameterized queries.
- [ ] No secrets or credentials in code, logs or tests.
- [ ] New dependencies scanned and pinned.

## Privacy (`privacy`)
- [ ] Personal data with a legal basis, minimization and retention; no PII in logs, telemetry or session recordings.
- [ ] Evidence and tests contain no real PII (synthetic data only).

## Front end / design system (`design-system`, `quality/references/frontend-ux.md`)
- [ ] New UI uses the project design system; divergence in legacy is a **warning**, not a deploy blocker (progressive adoption).
- [ ] WCAG 2.2 AA accessibility (keyboard, focus, contrast, accessible names).
- [ ] No Core Web Vitals regression; loading/error/empty states handled.

## Observability and docs (P5)
- [ ] Structured logs/metrics/tracing where the new behavior needs to be observable.
- [ ] Docs/ADR updated where applicable.

## Contract / integration (`fullstack`, `integrations`)
- [ ] Front↔back contract typed and coherent; errors standardized.
- [ ] **Checklist for the endpoint you touched** run (`fullstack/references/contract-and-vertical-slice.md`): request parameter honored, absolute URL, semantic error instead of a generic 400, listing filtered by access rights in the query, optional field with an explicit contract, types regenerated.
- [ ] Integrations decoupled, with timeout and idempotent retry; no PII leaking to third parties.

## Final hygiene
- [ ] No TODO/`<FILL: …>`/placeholder, no debug `console.log`/print, no commented-out code.
- [ ] Clean diff (no accidental file or binary, no unrelated change).
- [ ] Commit/branch/PR messages follow the standard (Conventional Commits, atomic, referencing the issue).
- [ ] **No AI signature** in the commit or PR (P3): no LLM `Co-Authored-By:`, "Generated with…" or bot marker — in the history (`git log`) and in the PR body. Authorship is human.
- [ ] Bug fix: the **feature's spec was updated** (not a new spec) — `spec-flow`.

> If a review bot flags something that is not here, **add the rule to this checklist**.
