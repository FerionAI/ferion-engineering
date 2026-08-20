# Contract testing before the PR — what CI does not do

Be honest about the gap: **ordinary CI does not test contracts**. Each repo's pipeline runs build,
lint, test, static analysis, dependency scanning — all **inside its own repo**. A contract lives
**between** repos (front↔back through OpenAPI; producer↔consumer through a schema registry). A
contract break **is not caught** by the build of the repo that caused it, and it reaches production.
This preflight step covers that hole, by hand, until CI covers it.

## Why it matters (the real hole)

Multi-repo plus asynchronous messaging: whoever changes the back end or the producer has everything
green in their own repo and still breaks the front end or the consumer in **another** repo, owned by
another team. The compiler of the guilty repo cannot see the consumer. With no contract test, the
break only shows up at runtime — in the consumer's environment, not the author's.

## When it runs

In the preflight of any PR that **changes a contract**: you touched an API schema (route, field,
type, error) or an event schema. If the diff does not touch a contract, skip it.

## Synchronous contract (OpenAPI)

The contract is the back end's schema; the front end generates types from it
(`openapi-typescript`/`openapi-fetch`, a `gen:types` script). The full mechanics live in
`workspace/references/cross-repo-coordination.md`. In preflight:

1. **Back end changed → publish the new schema at the source** the front end's generator points at
   (a staging URL or the local schema dump). If the source still serves the old schema, step 2
   generates against the old contract and **will not catch the drift** — this is a real trap, not a
   theoretical one.
2. **Regenerate the types in the front end** — `gen:types` — and **commit** the generated `.d.ts`.
   That command is usually **manual and not part of CI** — which is exactly why it belongs here.
3. **`tsc --noEmit`** in the front end against the new `.d.ts`. Contract drift = a type error = the
   build breaks. That is the only net connecting the two ends today — treat it as a mandatory step
   of the slice.
4. **Consumer-driven where it applies:** if the consumer has expectations the provider must honor,
   write/run the contract test (Pact or equivalent) — `<FILL: does your team run a contract broker?>`.
   With none in place, steps 1–3 (regenerate + typecheck) are the minimum that already pays off.

## Asynchronous contract (event schemas)

There is no typecheck to catch drift here — the guardian is the **registry's compatibility check**.
Before shipping the **producer** with a new schema:

1. **Run the compatibility check** for the schema against the current subject in the schema registry —
   the registry is what says whether the change is BACKWARD/FORWARD/FULL compatible (rules and modes
   in `integrations/references/event-bus.md`).
2. Tooling: the registry API (`POST /compatibility/subjects/<subject>/versions/latest`) or the build
   plugin for your stack. The producer **must not** be deployed with a schema the registry would
   reject.
3. **Incompatible = stop.** Make the field additive with a default (expand) or version it — do not
   force the registry. The producer↔consumer deploy order lives in
   `workspace/references/cross-repo-coordination.md`.

## What fails the gate (checklist)

- [ ] **Sync:** new schema served at the generator's source → types regenerated → generated file
      committed → `tsc --noEmit` **green** in the consuming front end.
- [ ] **Sync (breaking):** versioned + deprecation announced; the consumer does not break during the
      window (`fullstack/references/api-versioning.md`).
- [ ] **Async:** the schema compatibility check **passed** in the registry before shipping the producer.
- [ ] **Async:** new field optional with a default (expand); removal only after consumers migrated.
- [ ] Cross-repo: one PR per repo, linked to the issue; deploy order respected (`workspace`).

## Degrade with a warning

Tool unavailable (registry unreachable, the back end has not published the schema, the consuming repo
is not open in the workspace): **run what you can and say what went unverified** — do not mark the
contract OK without the check. For example: "schema compatibility not verified (registry offline)" or
"type drift not checked (back-end schema not published)". Record it as a pending item before merge.
Do not fake green and do not invent compatibility — this is the key anti-hallucination decision of
preflight (`anti-hallucination.md`).

## Privacy (if the contract carries personal data)

A new contract that starts exposing or emitting PII (a personal field in the API, personal data in an
event) needs a legal basis and minimization **in the contract itself** — do not add a personal field
"because it is easy". Example payloads in contract tests use **synthetic data**, never real PII.
Detail in `privacy` and, for events, in the privacy section of
`integrations/references/event-bus.md`.
