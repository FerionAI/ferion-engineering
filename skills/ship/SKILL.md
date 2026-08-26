---
name: ship
description: 'The full delivery pipeline, from idea to pull request — orchestrates specification, fullstack implementation as a vertical slice, instrumentation (analytics/observability), quality and security checks, review and opening the PR. Use when someone wants a whole feature delivered end to end: "build this feature", "do this from start to finish", "I want to ship X", "take it to the PR". Combines spec-flow, fullstack, integrations, quality, review, preflight and GitHub.'
---

# ship — from idea to PR

You take a feature through the whole pipeline, orchestrating the other skills in a coherent
sequence. Goal: deliver end-to-end value with the standard built into every step — do not skip
steps, but condense when the change is small (say so when you condense).

Before starting: **make sure the GitHub issue exists** (skill `issues`) — if the request does not
cite one, ask; if it does not exist, create it with the standard fields. Every change becomes an
issue (the issue is the source of truth: intent + acceptance criteria). Load `constitution` (the
standards) and `context` (the target app). If the problem or solution is not clear, start with
`discovery` (empathize+ideate → the brief that becomes the spec).

## The pipeline (in order; close each step before the next)

> **The order is enforced, not suggested.** Steps 1–8 below are the 6 steps of the mandatory flow
> (`start/references/mandatory-flow.md`): issue → in progress → implement → local review →
> PR + cost → in review. Start by reading where the flow stopped
> (`bash ${CLAUDE_PLUGIN_ROOT}/hooks/flow-gate.sh status`) and **resume from there**. The hooks block
> code without the in-progress milestone, a PR without local review, and the review label without
> PR + cost — condensing (steps 1/2 on a small change) is allowed; **skipping a step is not**.

1. **Specify** — `spec-flow`: spec of what/why → clarify (remove ambiguity) → technical plan.
   **In the plan, already define:** the API contract (`fullstack`), the analytics events and
   telemetry (`integrations`), and the security/privacy risks (`quality`/`privacy`).
2. **Vertical slice** — `fullstack`: **assume the issue** (the `in progress` milestone — `issues`:
   assign to the current user and label it; an issue with another owner or already in progress =
   **stop and ask**, that is duplicated work) and implement the thin slice end to end (contract →
   back → front → e2e), applying the write-less-code ladder (`agentic-flow`: the minimum that works)
   and a model proportional to each step. **Is there UI? Before coding the front end, validate the
   layout with `design-review`** (the design gate: design system/WCAG/Nielsen/states — cheap to fix
   in the design, expensive in code). The front end is **born in the project's design system**
   (`design-system`) — components and tokens, never raw HTML/CSS.
3. **Instrument** — `integrations`: analytics events and telemetry through the single typed layer.
   Observability is part of "done" (P5).
4. **Quality and security** — `quality`: OWASP checklist when touching auth/data/input; front end
   with Nielsen + WCAG + Core Web Vitals; and `privacy` if personal data is involved.
5. **Review** — `review`: run the Definition of Done over the whole slice; independent verification
   (strong model) when the change is risky.
6. **Preflight — spotless before the PR** — `preflight` (MANDATORY): the final exhaustive check
   against ALL the rules + running the real tools (build/lint/types/tests/static analysis) +
   independent anti-hallucination verification. **Bigger change or UI:** validate the live app on a
   **devserver** with synthetic seed data (Playwright). **Loop until zero findings.** Nothing opens
   a PR without passing here.
7. **Open the PR** — `gh pr create` with `Closes #N` in the body, a standard title/description and
   the DoD checklist. Record the dev cost on the issue (`cost`) — it is part of this milestone.
8. **Confirm the gate** — CI **green** on the PR (`gh pr checks`) and the quality gate green on new
   code, first try (because preflight already guaranteed it). A red check blocks the `in review`
   milestone: fix it in the same PR. If this repo's automated reviewers are mute
   (`preflight/scripts/pr-bots.sh`), say so when recommending the merge (P3) — green with no reviewer
   is an absence of signal, not an approval. Only then label the issue `status:in-review`.

## After the merge — to staging and production

9. **Staging** — `release`: the change is promoted through the environments.
10. **Human validation in staging** — `qa` (gate: test cases from the criteria + exploratory +
    regression, approve/reject) + `discovery` (usability, where it applies). **Nothing reaches
    production without passing here.**
11. **Promote to production** — `release`: only with the human gate green and a rollback/flag plan
    ready. Post-deploy verification closes the loop (`health`/`discovery`).
12. **Close the cost** — `cost`: the dev cost was already recorded on the issue at step 6/7. Here you
    only add the extra sessions (review fixes, deploy work), if there were any — closing the cycle
    issue→dev→QA→**cost**→health and feeding `health`.

## Pipeline rules

- **Scale to the size.** Big feature → every step, rigorously. Small tweak → condense spec+plan and
  simplify, but never skip tests, security/a11y guardrails or the DoD.
- **Non-negotiable guardrails** (`quality`): security, validation, data handling and accessibility
  are never cut for speed.
- **Risky change** (release, data migration, contract break): use the `release` skill — deploy
  strategy, feature flag/canary, rollback plan and expand/contract migration. Nothing irreversible
  without a plan.
- **Close the loop:** when you finish, deliver a short summary mapped against the Definition of Done
  plus the PR link.

## Expected output

`specs/<feature>/` (spec, plan, tasks) + code as a vertical slice with tests + instrumentation +
an open PR with CI and the quality gate green, all within the standard.
