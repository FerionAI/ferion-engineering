# The test-data endpoint — contract, guard and cleanup

The API fixture is what lets a test build state without knowing about the database. It is production
code (it lives in the service, runs in the same process) and therefore has a hard security rule.

## Minimum contract

```http
POST /__test-data/customer
{ "traits": ["past_due", "subscribed"], "runId": "qa-ci-20260313-7", "overrides": { "name": "..." } }

201 { "id": "...", "email": "qa+qa-ci-20260313-7@example.com", "runId": "qa-ci-20260313-7" }
```

- **One endpoint per aggregate** (`/customer`, `/plan`, `/subscription`), mirroring the factories.
- **`runId` is required** in the body — reject (400) without it. It is what makes cleanup possible.
- **Return the whole created object** (ids included): the test should not query the database to find
  out what it just created.
- **`DELETE /__test-data/run/{runId}`** removes everything from that run. It is the spec's `afterAll`.

## The guard goes on the route registration

```ts
// wrong: the route exists in production and "only" answers 403
app.post('/__test-data/customer', (req, res) => {
  if (env.NODE_ENV === 'production') return res.status(403).end()
  ...
})

// right: in production the module is not even registered
if (env.TEST_DATA_ENABLED) app.register(testDataRoutes)
```

Why: a registered route shows up in scans, leaks the schema in validation errors, and depends on **a
condition in the middle of the handler** to not create data — a condition a future refactor removes
without anyone noticing. Conditional registration fails to the safe side.

Complements (not substitutes for the guard): an explicit per-environment flag (`TEST_DATA_ENABLED`,
never defaulting to `true`), a service token, and an alert if the route answers in a production
environment.

## Where to really create it

Order of preference, and why:

1. **The product's use case / service** — the resulting state is possible in the real world.
2. **The service's own public API** — same guarantee, one more network hop.
3. **A direct database insert** — last resort, only where no product path exists. Comment why in the
   factory; it is known debt, not a shortcut.

Path 3 is how the test that passes against a state the system would never produce is born — the kind
of false green that only shows up in production.

## Environments

| Environment | Endpoint | Note |
|---|---|---|
| local / CI | on | where the suite really runs |
| staging | on, with a token | enables the pre-production e2e and exploratory testing with hard-to-build state |
| production | **not registered** | no exception; testing in production uses observability, not fixtures |

## Cleanup — by disposal, in this order

1. **Ephemeral environment** (Testcontainers, a schema per run): cleanup is throwing the environment
   away. The cheapest form, and the only one that never leaves leftovers.
2. **Sweep by `runId` prefix**: a job collects whatever is older than 24h — it covers an interrupted
   run, which is exactly when the teardown does not run.
3. **`DELETE /__test-data/run/{runId}`** at the end of the spec: only where the environment is shared
   and persistent, and even there as a complement to item 2, never as the only net.

Never truncate a table in a shared environment and never wipe the world in `beforeEach`: it takes
down someone else's parallel run (rule 4 in `isolation.md`).
