# The generated issue template

The shape every issue created from an epic should follow. The goal is for the issue to be a **good
spec** — a developer (or `ship`) picks it up and executes with no rework.

## Template

```markdown
**Epic:** #<n>   **Type:** feature | bug   **Size:** <S/M/L>   **Depends on:** <—>

## Description (what / why)
<Short context + the value. Do not detail the "how" — that belongs to the plan.>

## Acceptance criteria (testable)
- [ ] <verifiable condition 1>   (Given <x>, when <y>, then <z>)
- [ ] <verifiable condition 2>
- [ ] Error/edge cases: <...>

## State matrix (required — the expected behavior in EVERY state)
| Entity/resource | Possible states | Expected behavior in each |
|---|---|---|
| <lesson> | published / unpublished | unpublished counts toward neither progress nor the certificate |
| <access> | active / expired | expired is flagged in the listing and keeps the certificate already issued |
| <content> | public / subscriber-only / private | the listing filters by the user's access rights |
| <configuration> | configured / missing | missing answers "not configured", not a generic error |

## Stack / app
<from `context`>   Front end: uses the project design system (if there is UI)

## Standard flags (check what applies)
- [ ] Security/OWASP — touches auth, data or external input
- [ ] Privacy — handles personal data (legal basis, minimization, no PII in logs)
- [ ] Design system — new UI uses it (progressive adoption)
- [ ] Observability — needs logs/metrics/tracing (P5)
- [ ] API contract — changes or defines a front↔back contract

**Definition of Done:** the standard (see `constitution`) — tests, review + CI, lint/types,
observability, design system, security/privacy, and a spotless preflight before the PR.
```

Create it with `gh issue create --body-file`, then add `- [ ] #<new>` to the epic's body so GitHub
renders the parent/child relationship.

## Quality of the acceptance criteria

- **Verifiable**, not vague: "the user receives a confirmation email within 1 minute", not "it works
  well".
- Cover **happy path + error/edge** (they become the tests — P2, `qa`).
- Tied to the epic's value; no criterion outside the scope.

## The state matrix — why it is mandatory

The defect class that most often reaches QA **is not a coding error: it is a domain state nobody
enumerated**. The code compiles, the tests pass, the analyzer approves — and the product is wrong
because the spec described only the happy path. Real shapes this takes: an unpublished item still
counted in an overview (and blocking a certificate), an expired access with no indication in the
listing, a back-office listing showing subscriber-only content, an eligibility check with no
configuration returning a generic 400.

How to fill it, in two minutes:

1. **List the entities** the issue touches.
2. For each, **the state axes that already exist** in the domain — publication
   (published/draft/unpublished), time (active/expired/future), access
   (public/subscriber/private), configuration (configured/missing/partial), volume (0/1/many).
3. Write **the expected behavior in each state**, not just the happy one. A state with no defined
   behavior is a future bug with a date on it.
4. Each row becomes a **test case** (`qa/references/test-cases.md`) — that is how the matrix leaves
   the page.

Do not know the right behavior in a state? **That is ambiguity, not detail:** ask during refinement
(`clarify`). An issue with an open state is not in the Definition of Ready.

## Good vertical slices

- One issue = one thin slice of end-to-end value (contract → back → front → e2e), not loose layers.
- Prefer several small issues over one big one (better review and delivery; smaller PRs — P3).
- Spikes and investigations are their own issues, with a question and a time-box.

## Non-functionals do not evaporate

Performance, security, accessibility, data migration and observability become acceptance criteria or
dedicated issues — the standard does not become optional just because the work came from an epic.

## Before creating them

- Show the **preview** to the PM (list + criteria) for adjustment.
- Use the right repository, the type label and the team's template
  (`config/team-config.md`; an epic spanning teams: `references/cross-team-decomposition.md`).
- Link each to the epic and leave it **ready for `ship`**.
