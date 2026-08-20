# Tool — test automation

Automate what repeats and what regresses. Everything else is cheaper as a manual check — an automated
test has a permanent maintenance cost, and a flaky suite is worse than no suite.

## What to automate (in this order)

1. **The critical happy path** of each main flow (smoke). If this breaks, nothing else matters.
2. **Bugs that already happened.** A regression test for every bug that reached QA or production —
   this is the highest return in the whole list.
3. **Business rules with many states.** Exactly the state matrix from the issue — cheap as unit tests,
   expensive to check by hand every release.
4. **Authorization.** "User A cannot see B's data" — tedious manually, critical to never regress.

## What not to automate

- A flow that will change next sprint.
- Exact visual appearance (use visual regression tooling instead of asserting pixel positions).
- Anything you would have to over-mock to test — the mock ends up testing itself.
- One-off validations for a single release.

## The pyramid, honestly

Most tests unit (fast, precise), fewer integration, few e2e (slow, brittle, but the only ones proving
the whole thing works). If your suite is an ice-cream cone (mostly e2e), every failure costs 20
minutes of investigation and people start ignoring red.

## e2e that does not flake

Flakiness is the reason teams abandon e2e suites. It is almost always one of these:

| Cause | Fix |
|---|---|
| Fragile selector (CSS class, nth-child) | `data-testid` or a role/accessible-name selector |
| Fixed `sleep` | wait for the **condition** (element visible, request finished), never for a duration |
| Shared state between tests | each test creates and cleans its own data; tests must run in any order |
| Real external dependency | stub it at the network boundary; keep one contract test for the real thing |
| Animation timing | disable animations in the test environment |

## Test data

**Never real PII** (`privacy`). Factories/faker with a fixed seed, so the run is deterministic and
reproducible. Data setup through the API or a seed script, not through the UI — driving 15 screens to
reach the state you want to test is where e2e suites go to die
(`context/references/seed-and-environments.md`).

## Assertions that prove something

The anti-hallucination rule applies to tests too
(`preflight/references/anti-hallucination.md`): a test that cannot fail is not a test. When you write
one, break the implementation on purpose once and watch it go red. If it stays green, the test is
decoration.
