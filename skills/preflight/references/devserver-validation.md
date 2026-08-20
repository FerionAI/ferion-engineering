# Devserver validation — the live app before the PR

Headless tests (unit/e2e in CI) pass and the **real screen** can still be broken — state, data,
layout, a console error no test covers. For a **bigger change, or one touching UI or a flow**, drive
the **live** app with **synthetic data** before the PR. It catches what "compiles and tests" does not.

## When it runs (size-gated)

- **Runs:** a **high/medium** tier change (`qa/references/risk-and-regression.md`) that **touches UI
  or a user flow** — a new screen, a flow change, a form, a visible integration.
- **Skips:** a one-liner, a back-end-only change with no observable UI effect, an internal refactor,
  docs. Unit/e2e are enough there.
- When in doubt between running and not running, **run it** — it is cheap next to a bug that reaches
  the PR or QA.

## How (step by step)

1. **Start the app** — the repo's dev command (see `context/references/conventions.md`). Depends on a
   back end? Run it locally or point at staging (contract and type generation in `workspace`).
2. **Synthetic seed** — a known, deterministic, idempotent state with **no real PII**
   (`context/references/seed-and-environments.md`). Cover the flow's edge cases (empty, error, many
   items).
3. **Drive the flow in the browser (Playwright MCP)** — the agent really navigates and clicks:
   - The **happy path** of the issue's acceptance criterion, end to end.
   - **One error/empty case** (what happens when it fails or there is nothing).
   - Check the **states** (loading/error/empty) and **basic a11y** (focus and keyboard through the flow).
4. **Evidence** — screenshots of the key steps + **console and network clean** (no unexpected
   4xx/5xx, no JS error). Attach it to the issue/PR.

## What fails the gate (back to preflight step 1)

- Broken screen / component does not render / layout broken in the flow.
- Console/JS error or a failing request on the happy path.
- The acceptance criterion's flow **does not complete**.
- Error/empty state not handled (white screen, crash).

## Degradation (do not fake green)

If you cannot start the devserver (no dev command, an external dependency is down) or seed it:
**record what could not be validated**, offer `setup`/`onboard`, and leave the decision to proceed
**explicit (human)**. Do not count it as green **and do not stall** for missing infrastructure — this
is degradation with a warning.

## Privacy

**Synthetic data only** (faker/factories). Never copy production PII into a devserver. No PII in the
screenshots or the evidence.

## Tooling

**Playwright MCP** (`.mcp.json` / `integrations`) for the agent to drive the browser. A flow you
repeat is worth turning into a versioned `playwright test` — the live validation becomes a
**permanent test** (e2e).
