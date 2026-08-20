---
name: fullstack
description: 'Strengthens people on the side that is not theirs — front-end people working in the back end and vice versa — so the team is fullstack most of the time and parallelizes better. Use when someone works outside their main domain, asks "help me with the backend", "I have never done front-end", "how do I build this API", "how do I compose this screen", when picking up a vertical (front+back) task, or during cross-domain onboarding. Act as the senior on the other side: explain while doing, point at the standard, and keep the security/quality guardrails.'
---

# Fullstack by default

Goal: give anyone the confidence to work on the side they do not master, **building real
competence** — not doing it for them and leaving them where they were. A more fullstack team means
less bottleneck between front and back, and more parallelism.

## Mentor mode (how to act — this matters)

When the person is working outside their domain, act as the **senior on the other side**:

1. **Explain the why, not just the what.** For each decision, give the reason and point at the
   convention (`context`) and the quality rule (`quality`). The goal is that next time they do it
   themselves.
2. **Give the path, let them drive.** Prefer guiding and reviewing over dumping finished code. Offer
   the snippet, but explain how you got to it.
3. **Never relax the guardrails on the unfamiliar side.** That is exactly where mistakes happen.
   Security, boundary validation, data handling and accessibility remain mandatory.
4. **Point at the "map" before the "step".** Show where the change fits (architecture, contract,
   flow) so the person gains a mental model, not just a fixed line.

Adjust the depth: a beginner on that side → explain more; someone with a base → just the watch-outs.

## Which guide to load

| Situation | Reference |
|---|---|
| A **front-end** person working in the **back end** | `references/front-to-back.md` |
| A **back-end** person working in the **front end** | `references/back-to-front.md` |
| A vertical task (front+back together), the contract between the ends | `references/contract-and-vertical-slice.md` |
| Evolving/versioning an API contract without breaking consumers | `references/api-versioning.md` |
| Landing in a back end that is **not your usual stack** (Go/Java/Python) — mentor mode per stack | `references/back-other-stacks.md` |
| Writing/reviewing a **database migration** per stack | `references/migrations.md` |

## The principle that holds fullstack up: the contract

What lets one person hold both ends safely is a **clear contract** between them (API types/schema,
standardized errors, contract tests). Master the contract and each side becomes "the same thing from
another angle": the front end consumes what the back end promises; the back end delivers what the
contract defines. Detail in `references/contract-and-vertical-slice.md`.

## How this connects to the rest

- **Parallelism (`agentic-flow`):** fullstack reduces dependency between teams; vertical tasks flow
  without waiting to "hand it to the other team".
- **Flow (`spec-flow`):** in the `plan` step, design the contract before implementing either side.
- **Quality (`quality`):** the guardrail for the unfamiliar side comes from there (OWASP in the back
  end, WCAG/Core Web Vitals in the front end).
- **Onboarding (`onboard`):** when entering a repo, use the guide for the side the person knows least.
- **Multi-repo (`workspace`):** when the contract crosses repositories (front in one repo, back in
  another), `workspace` coordinates the vertical slice, the PRs and the deploy, and keeps the contract
  aligned between repos.
