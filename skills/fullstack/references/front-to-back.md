# A front-end person working in the back end

You already know the contract from the consumer side — that is a bigger head start than it feels
like. What is different is that mistakes here are not visual, they are silent and they persist.

## The three shifts in mindset

1. **State is durable.** A front-end bug re-renders; a back-end bug writes wrong data that stays
   wrong. Anything that mutates deserves more care than anything that reads.
2. **Every input is hostile.** The front end validates for usability; the back end validates for
   safety. Both are needed, and the back-end one is the real control — the front end can be bypassed
   with `curl` in five seconds.
3. **Concurrency is real.** Two requests hit the same row at the same time. In the browser you rarely
   feel it; on the server it is Tuesday.

## The shape of a typical endpoint

```
1. Validate the input        → a schema, at the boundary, before anything else
2. Authorize                 → does THIS user have rights to THIS object?
3. Business rule             → the actual work, in a service/domain layer
4. Persist                   → transaction if more than one write
5. Respond                   → the contract's shape, semantic errors
```

Steps 1 and 2 are where the security bugs are. Step 3 is where the business bugs are. Keep them
separate — a handler that does all five inline is the one that gets a `// TODO: check permission`
that never gets done.

## What will bite you

- **Authorization per object, not per route.** `GET /orders/:id` with a valid session is not enough —
  does this user own order `:id`? This is the most common and most expensive API bug there is.
- **N+1 queries.** The loop that looks innocent in code makes 200 database round trips. Look at the
  query log, not at the code.
- **Missing transaction.** Two writes that must both succeed, without a transaction, is a half-written
  state waiting for a bad day.
- **Errors that leak.** A stack trace in the response tells an attacker your framework, your file
  layout and sometimes your query.
- **Nothing is logged.** You will need to debug this in production with no browser devtools. Log the
  decision points, with a correlation id, without PII.

## Testing (different from the front end)

- **Unit** the business rule, with no database — that is where the state matrix lives.
- **Integration** the endpoint against a real database (a container), including the authorization case
  with the *wrong* user. That test is the one that would have caught the expensive bug.
- Do not mock the thing you are testing. Mocking the repository to test the repository proves nothing.

## Before the PR

`quality/references/security-owasp.md` and the security section for your stack
(`security-by-stack.md`). Then the endpoint checklist in `contract-and-vertical-slice.md` — it is a
list of real recurring failures, not a formality.

**The guardrails do not relax because this is not your side.** They tighten, because this is where
you have less intuition for what looks wrong.
