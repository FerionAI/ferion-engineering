---
name: qa
description: 'QA kit — tools for the quality team to move faster, always with the GitHub issue as the source of truth. Use when someone from (or about) QA asks to: generate test cases from the acceptance criteria, write a bug report, decide what to retest (regression) from a PR, plan exploratory testing, automate tests (e2e/unit), do UX/accessibility QA, reproduce or verify a problem in production, or approve/reject a delivery (the QA gate). Triggers: "test cases", "test plan", "report a bug", "what should I retest", "exploratory testing", "automate tests", "validate this issue", "can this go to production?".'
---

# QA kit

Tools for QA to work faster and more consistently inside the standard. Two fixed pillars: **the
GitHub issue is the source of truth** (read from it, write back to it — `issues`) and **the
acceptance criteria are the target** (what is not in the criteria or in the tests is not done —
P2/Definition of Done).

Load only the relevant tool (token economy):

| The person wants… | Tool |
|---|---|
| Test cases/plan from the issue | `references/test-cases.md` |
| To report a bug (well structured, as an issue) | `references/bug-report.md` |
| To know what to retest after a change | `references/risk-and-regression.md` |
| To plan exploratory testing | `references/exploratory.md` |
| To automate tests (e2e / unit) | `references/automation.md` |
| UX and accessibility QA | `references/ux-a11y-qa.md` |
| To verify in staging/production + the approval gate | `references/verify-and-gate.md` |

## How QA enters the flow

- **Start from the issue** (`issues`): acceptance criteria = the basis for the tests. Questions become
  comments on the issue.
- **Cover what the developer delivered** against the criteria and the Definition of Done
  (`constitution`).
- **Use the right signals:** security (OWASP), UX/a11y (Nielsen/WCAG), real behavior (session
  analytics), health (observability), funnel (product analytics) — through `quality` and
  `integrations`.
- **Where:** human validation (cases/exploratory/regression + the **approval gate**) runs in
  **staging** (`release` promotes the change there) **before** production; post-production
  verification closes the loop.
- **Write back:** cases, bugs and the gate verdict live **on the issue**, not in the chat.

## QA principles

- **Shift left:** QA takes part from issue refinement onward (testable criteria), not only at the end.
- **Risk drives effort:** test more where it breaks more (critical/complex/heavily changed).
- **Reproducible > anecdotal:** every bug has clear steps; every automation has a stable selector.
- **No real PII in tests** (`privacy`): use synthetic or masked data.
- **QA is not a bottleneck:** automate the repetitive, keep humans on exploratory work and judgment.
