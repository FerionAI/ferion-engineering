---
name: discovery
description: "Design thinking around the delivery pipeline — the user-centered phases that wrap the build: empathize + ideate BEFORE specifying, and test (usability + behavior) AFTER building. Use when someone says 'understand the user', 'what does the data say', 'which problem should we solve', 'is it worth building', 'which solutions', 'how do we decide what to build', 'test with a user', 'usability test', 'did the flow actually work?', 'validate after launch'. It pulls the signals you already have (session analytics, product analytics, issues) and returns an empathy brief; ideation with method (diverge/converge); validation with users (tasks/SUS) and with post-ship behavior. Evidence > opinion; with no real user it is a proxy — and it says so."
---

# discovery — design thinking around the pipeline

The pipeline (`ship`: spec→code→PR→release) builds things **right**; this makes sure you build the
**right thing** and that it **works for the user**. These are the user-centered phases that wrap the
engineering core. It complements `design-review` (critiquing the design against the constitution)
with the **user's voice**.

## When each phase runs (relative to the pipeline)

- **Before `spec-flow`:** empathize + ideate → the brief that becomes the spec (the what/why gains
  evidence).
- **After the build:** test → usability (pre-ship) + behavioral validation (post-ship), closing the loop.

## 1. Empathize — understand the user from the data you already have

Pull the signals (`integrations`): **session analytics** (recordings, rage/dead clicks, drop-off),
**product analytics** (funnels, exits, conversion), **in-app onboarding** (friction), **issues**
(tickets/bugs/requests = reported pain). Synthesize a brief: **who is suffering** (persona/JTBD),
**the pain**, **the evidence** (a number or a quote). Detail in `references/empathy-and-signals.md`.

*Guardrail: evidence > opinion; with no access to the data, mark it as a hypothesis to validate, not
as a fact.*

## 2. Ideate — diverge on solutions, converge with criteria

**Define** (POV / "How Might We") → **diverge** into 2–3 independent approaches (MVP-first /
risk-first / delight-first, without falling in love with the first) → **converge** by impact × effort
× risk → **recommend** (the smallest thing that solves it). The chosen one becomes the what/why of
`spec-flow`. Detail in `references/ideation.md`.

## 3. Test — validate with users (not just heuristics)

**Pre-ship:** 3–5 real tasks + a success criterion; ~5 users catch most problems; measure
success/time/errors + **SUS**. **Post-ship:** close the loop — analytics show whether the pain went
away and conversion moved. Detail in `references/usability-testing.md`.

*Guardrail: a test needs a real user; without one it is heuristics (`design-review`) plus data, and
you say it is a **proxy**.*

## In the flow

- **`epic`:** a **vague epic** enters here before decomposition — discovery gives it the what/why.
- **`spec-flow`:** `specify` starts from the discovery brief (empathize+ideate).
- **`design-review`:** critiques the design against the constitution; discovery brings the user's voice.
- **`integrations`:** the MCPs are the source of the signals; **`privacy`:** user data is PII.
- **`health` / `qa`:** the post-ship test uses the same analytics and feeds the metrics.
