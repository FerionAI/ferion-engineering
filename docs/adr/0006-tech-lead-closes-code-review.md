# ADR-0006: The tech lead closes the code review; the agent prepares, and moves only on a real approval

- **Status:** accepted
- **Date:** 2026-10-13   ·   **Author(s):** `<FILL>`   ·   **Issue/Epic:** —

## Context
The flow ended at `in review`: the developer opens the PR, records the cost and labels the issue.
From there, the standard said the agent moves nothing else. The review column became a queue with no
owner inside the plugin. The tech leads, who answer for quality and approval, review by hand without
the `review`/`preflight` the developer already had, and the issue only reaches QA when someone
remembers to move it.

## Decision
A new phase, the **`approve`** skill, with a third milestone, **`in QA`** (label `status:in-qa`):

- **Sweep:** issues labelled `status:in-review` in the tech lead's repositories
  (`~/.claude/ferion-profile.md`), each PR found through the issue number the flow gate already
  requires in its body or branch.
- **Hybrid fixing:** a mechanical gap (lint, type, an obvious edge-case test, naming) is fixed by the
  agent on the PR branch, with the tech lead's git identity. A judgment gap (architecture, rule,
  contract) becomes a comment for the developer. A behavior change never counts as mechanical.
- **Human approval, one PR at a time:** the agent shows the report and runs `gh pr review --approve`
  from the tech lead's account only after their "yes" for that PR. There is no "approve them all".
- **Mechanical gate:** `flow-gate.sh tl <issue-number> <PR URL>` registers the review. From then on,
  labelling that issue checks the PR's real `reviewDecision` on GitHub:
  - `APPROVED` with a green CI → `status:in-qa` is allowed;
  - `CHANGES_REQUESTED` → sending it back to `status:in-progress` is allowed;
  - any other state → blocked.

## Alternatives considered
- **The agent approves on its own when the review comes out clean:** rejected. It breaks P3
  (approval is human) and takes from the tech lead exactly the responsibility they carry.
- **A gate written only in the skill's prose:** rejected for the same reason the flow gate exists —
  prose does not hold the order. The cost is small: one `gh` query per label change, and only on
  registered issues.
- **The agent fixes everything on the developer's branch:** rejected. The tech lead would become the
  author of business rules, and the developer would never see the reason.

## Consequences
- **Positive:** the review column has an owner and a rhythm. QA receives only PRs approved by a
  person with a green CI. The report stays on the issue, which remains the source of truth.
- **Negative / costs:** without `gh`, the gate degrades without blocking, like the CI check at
  `in review`. A repository without the `status:in-qa` label gets reviewed and approved, but not
  labelled, until someone creates it.
- **Not covered:** the cost of the tech lead's review. It has no cost marker of its own yet; it can
  reuse the `ferion:cost` comment once the team decides how to split dev and review cost.

## Constitution principles involved
- **P3** (review + CI before merge): approval stays human and per PR; the gate reads the real review
  decision, not the conversation.
- **P8** (efficiency): the agent does the mechanical part of the review so the human time goes to
  judgment.
