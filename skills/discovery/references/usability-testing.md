# Test — usability (pre-ship) and behavioral validation (post-ship)

Heuristics say the design *should* work. A test says whether it *does*. They are not substitutes.

## Pre-ship: the usability test

**Five users find most of the problems.** This is the finding that makes usability testing practical:
you do not need a research programme, you need five people and an afternoon.

### Setup

1. **3–5 real tasks**, phrased as goals, never as instructions.
   - Yes: *"You want to cancel your subscription before the next charge."*
   - No: *"Click Settings, then Billing, then Cancel."* (that tests reading, not usability)
2. **A success criterion per task**, decided before the session: completed unaided / completed with a
   hint / not completed.
3. **Participants** who resemble real users. Colleagues who know the product are the worst possible
   sample.

### Running it

- **Say nothing.** The urge to help is overwhelming and it destroys the data. Silence for ten seconds
  is fine.
- **Think-aloud:** "tell me what you are thinking". When they go quiet, ask "what are you looking
  for?" — never "did you see the button?".
- **Watch where they look and what they hesitate over**, not just whether they finish. Hesitation is
  the finding.
- 30–45 minutes maximum.

### Measuring

| Metric | What it tells you |
|---|---|
| Task success rate | does it work at all |
| Time on task | is it painful |
| Errors and recoveries | where the design misleads |
| **SUS** (10 questions, 0–100) | a comparable number over time; ~68 is average |

SUS is worth running because it is comparable across versions and across products — a subjective
impression is not.

### The output

Findings by severity, in the same shape as `design-review`, so they merge into the same backlog:
what happened, how many participants hit it, the rule it breaks, the proposed fix.

## Post-ship: behavioral validation

The loop is not closed at deploy. A week or two later, go back to the data
(`empathy-and-signals.md`):

- Did the drop-off at the step actually fall?
- Did the pain move somewhere else? (The most common outcome of a fix.)
- Did the support tickets on this theme stop?
- Did the metric the spec named as success move?

**Compare with the same window before the change**, and be honest when it did not work. A feature
that shipped and changed nothing is information, not a failure — but only if someone records it.
Instrument in the `plan` (`integrations`), because a comparison you did not instrument for is a
comparison you cannot make.

## Guardrails

- **A test needs a real user.** Without one, you have heuristics (`design-review`) plus data — say it
  is a **proxy** rather than presenting it as validation.
- **No PII in the recordings or the notes** (`privacy`); get consent to record.
- **Five users per round, iterating**, beats twenty users once. The point is to find and fix, then
  find again.
