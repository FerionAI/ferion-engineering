# Tool — risk and regression (what to retest)

After a change, say objectively **what needs retesting** — risk-based testing, not "test everything
again".

## Impact analysis (from the diff)

1. **Read the PR diff** (`gh pr diff <n>`): which files, modules and services changed.
2. **Map the reach:**
   - What depends on what changed (callers, API contracts, components using the altered code).
   - Which user flows pass through there.
   - Which integrations are affected.
3. **Classify the risk:** high (core, heavily coupled, a history of bugs), medium, low.

## Regression selection

| Tier | What to run |
|---|---|
| **High risk** | the relevant regression suite + manual testing of the affected critical flows + devserver validation |
| **Medium** | the directly related cases + a smoke test of the surrounding area |
| **Low** | smoke test |
| **Always** | the issue's acceptance criteria + a smoke test of the main happy paths |

These tiers are the same ones `preflight` uses to decide whether devserver validation runs
(`preflight/references/devserver-validation.md`).

## Output

- A **prioritized list of what to retest** (with the reason), separating what can be automated
  (`automation.md`) from what needs human eyes.
- **Coverage gaps**: where tests are missing for what changed → propose creating them (P2).
- The regression decision recorded on the issue, for traceability.

## Production signals sharpen the list

If something is heavily used (product analytics) or has already caused friction or errors there
(session analytics, observability), raise the regression priority for that flow. The data you already
have is a better prioritizer than intuition.

## What "low risk" does not mean

Low risk means a smaller regression suite, not skipping the acceptance criteria. Every change gets its
criteria verified — that is the definition of the work being done, not a testing tier.
