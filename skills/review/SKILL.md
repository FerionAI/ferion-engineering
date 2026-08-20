---
name: review
description: Code review against the Definition of Done and the team's engineering standard before merge. Use when someone asks "review this PR/code", "is this ready to merge", "check whether it follows the standard", "review", or before opening/approving a pull request. Applies the constitution principles as an objective checklist.
---

# Review (pre-merge)

You review a code change against the standard. Be specific and actionable: point to the file/snippet,
name the principle violated, and propose the fix.

> **Right order:** `preflight` runs BEFORE the PR and should leave everything spotless (zero
> automated findings). If it did not run, run it first. With preflight clean, this review focuses on
> what is human: clarity, code taste and "does anything look off?".

## Before reviewing
Read the `constitution` skill (principles + Definition of Done) and, if the change is specific to an
application, the `context` skill for that stack's conventions. Load the `quality` skill and, based
on the type of change, the relevant reference: `security-owasp.md` (back/API/data), `frontend-ux.md`
(UI), `static-analysis.md` (quality gate).

## Review script

Walk the **Definition of Done** and report each item as ✅ ok, ⚠️ attention or ❌ blocks merge:

1. **Specification (P1):** does the change match a clear spec/issue? Does it do what was asked, with
   no silent extra scope?
2. **Tests (P2):** are there tests for the new/changed behavior? Do they cover errors and edges, not
   just the happy path? Do they pass?
3. **Review + CI (P3):** is the PR small and focused? Is CI green? Does the PR body carry
   `Closes #N`?
4. **Style/types (P4):** do lint, formatting and typing pass? Strong typing (no unjustified
   `any`/`interface{}`)?
5. **Observability and docs (P5):** logs/metrics/tracing where the new behavior needs to be
   observable? Docs/ADR updated?
6. **Consistency (P6):** does it follow the language conventions and the house style (`context`)? Is
   any divergence from the standard recorded?
7. **OWASP security (P7):** apply the checklist in `quality/references/security-owasp.md` —
   object/function level authorization, input validation, no secrets, dependencies scanned,
   fail-closed errors. Personal data → the `privacy` skill (data map, masking, retention).
8. **Measurable quality (P7):** static analysis quality gate green on new code (0 new blocker/high
   issues, hotspots reviewed, coverage and duplication at target) — `quality/references/static-analysis.md`.
9. **Front/UX (P7), when the UI changed:** new UI in the project design system (divergence in legacy
   is a ⚠️ warning, not a block — progressive adoption), Nielsen heuristics, WCAG 2.2 AA
   accessibility and Core Web Vitals — `quality/references/frontend-ux.md`, `design-system`.
10. **Efficiency (P8):** could this be done with less code? Reuse > rewrite; no silent extra scope;
    no dead code.

## Output

Deliver:
- **Verdict:** ready to merge | needs changes | blocked.
- **Blockers (❌):** an objective list with file, problem and proposed fix.
- **Attention (⚠️):** recommended, non-blocking improvements.
- **Praise (✅):** what is well done (it reinforces the standard).

If there is an issue, review against the **issue's acceptance criteria** and record the review/QA
result **on the issue itself** (skill `issues`) — the issue is the source of truth. For QA work
(test cases, regression, exploratory testing, automation, approval gate), use the `qa` kit.

Never approve with an open ❌. If a blocker is a justified exception, require the justification to be
recorded in the PR or in an ADR (the constitution's exception rule).
