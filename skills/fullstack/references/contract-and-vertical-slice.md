# The contract and the vertical slice

What lets one person hold both ends safely is a clear contract between them. Master the contract and
each side becomes the same thing from another angle.

## The order of a vertical slice

```
1. CONTRACT   agree the schema/types — this is the design decision
2. BACK       implement it, with tests against the contract
3. FRONT      consume it with generated types, with tests
4. E2E        one test through the whole flow
```

Designing the contract in step 1 (in the `plan`, not while coding) is what makes steps 2 and 3
parallelizable and what keeps them from disagreeing.

## What a good contract has

- **Explicit types**, generated from a single source (OpenAPI → types, or a shared schema package).
  Two hand-maintained type definitions will diverge; it is a question of when.
- **Standardized errors.** One error shape across the API, with a machine-readable code and a
  human-readable message. The front end cannot handle errors it cannot distinguish.
- **Explicit optionality.** `field?: string` and `field: string | null` mean different things to the
  consumer. Decide which, and say so.
- **Pagination and limits** defined from the start, not added when a list gets long in production.
- **Versioning strategy** for the day it has to change (`api-versioning.md`).

## The endpoint checklist (the bugs that actually happen)

Run this on any endpoint you touch. Every line here is a real recurring failure, not a hypothetical:

- [ ] **The request parameter is honored.** A filter/sort/page parameter the API accepts and silently
      ignores is worse than one it rejects.
- [ ] **Absolute URLs** in responses that contain links, or the consumer builds them wrong.
- [ ] **A semantic error, not a generic 400.** "Configuration missing" is actionable; `400 Bad
      Request` sends the consumer to read your source code.
- [ ] **Listings filter by access rights in the query**, not in the response mapping and certainly not
      in the front end. Filtering after fetching leaks data through pagination counts and timing.
- [ ] **An optional field has an explicit contract** — will it be absent, `null`, or an empty array?
      Pick one and keep it.
- [ ] **Types regenerated and committed** in the consumer, with the typecheck passing
      (`preflight/references/contract-testing.md`).
- [ ] **Empty, one, many** — the response shape works for all three.

## Testing on both sides

| Level | Back end | Front end |
|---|---|---|
| Unit | business rules, the state matrix | components, pure logic |
| Integration | the endpoint against a real database | the client against a stubbed API |
| Contract | the response matches the schema | the generated types compile |
| E2E | one test through the real flow, from the UI | |

The contract level is the cheap one that catches the expensive bug. Skipping it is why "it works in
both repos, it breaks together".

## Thin, not layered

A vertical slice means one complete piece of user-visible value — the contract, the back end, the
front end and the test for **one** behavior. It does not mean "all of the back end, then all of the
front end". Two thin slices delivered are worth more than two halves in progress, and they are far
easier to review (P3: small PRs).
