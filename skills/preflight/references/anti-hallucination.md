# Anti-hallucination — verify that it actually exists

The biggest risk in an agentic flow is the agent **inventing** something plausible that does not
exist, or delivering tests that prove nothing. This is the script for catching that before the PR.
Rule: **trust, but verify at the source** — do not assume what was generated is right just because
it looks right.

## 1. Does the code reference things that exist?

- **Imports/modules:** does every import resolve? (build/typecheck catches most — run it).
- **Functions/methods/types:** do they exist in the codebase or the library? Grep/types. No method
  that "should exist".
- **Design system components/props:** do they exist in the package? Check the types (`.d.ts`) or the
  Storybook — do not invent a component or a prop (`design-system`).
- **API endpoints/fields:** do they match the real contract? (`fullstack`, OpenAPI/types).
- **Config/env/feature flags:** do the keys used actually exist?
- **Libraries:** is the dependency in the manifest? Do not hallucinate a package.

## 2. Do the tests prove anything?

- **Meaningful assertions** about behavior — not `expect(true).toBe(true)`.
- No mock that swallows the real case (mocking the thing under test hides the bug).
- They cover the issue's acceptance criteria, including errors and edges.
- They actually run and pass (run them) — and they fail if the behavior breaks (sanity check: break
  it on purpose and watch the test fail, whenever you are unsure).

## 3. Facts and numbers checked

- Any value or claim in code or docs (limits, calculations, messages) matches the source.
- No unverified "plausible data", especially in business rules.

## 4. Leftovers and noise

- No TODO/`<FILL: …>`, no dead or commented-out code, no debug `console.log`/print, no unused import.
- No accidental file in the diff; no change outside the issue's scope.

## 5. Independent verification (the step that catches the most)

Run a **verifier subagent**, independent of whoever wrote the code, with a strong model
(`agentic-flow`), instructed to **reject**: "find anything invented, off-standard, or that an
automated reviewer would flag". The author cannot see their own error; an independent pass can.

- Found something real → fix it and run preflight again.
- Critical change → multiple verifiers with distinct lenses (correctness · security · standard ·
  does the test actually prove it?).

> The goal is that when the PR opens, the review bot and the human **have nothing to flag**. If they
> do, preflight failed — improve the checklist.
