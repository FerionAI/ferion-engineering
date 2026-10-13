---
name: test-data
description: 'Test data factories with traits named after the domain ("past-due customer", "plan at capacity") and a guarded test-data endpoint, so every test creates the state it needs instead of depending on a record that already exists in staging. Use when someone asks for test data, "create a factory", "I need a customer with X", "trait", "API fixture", "test-data endpoint", "seed for the e2e", or when a scenario in the catalog asks for a trait that does not exist yet. It is the prerequisite of qa-spec.'
---

# test-data — state is created, never found

Every test that depends on a record that "is already there" is a time bomb: it breaks when someone
edits the data, it vanishes when the environment is recreated, and it fails in a way that looks like
a product bug. The trade is always the same: **the test creates what it needs, with a domain name,
and cleans up what it created**.

This is the prerequisite of `qa-spec` — which **refuses to generate** a test while the requested trait
does not exist.

## Step 1 — Discover before writing

Before creating a new factory, look for what already exists (`context`): factories, `faker`, test
builders, seeds, and — most important — **the services the product itself uses to create that
aggregate** (sign-up endpoint, back-office use case, domain command).

**Prefer the product's path over writing to the database.** A direct insert builds state the system
would never produce (a subscription with no contract, a customer with no history) and the test starts
proving a reality that does not exist. Use SQL only where there is no product path — and say so in a
comment.

## Step 2 — Trait: the vocabulary

A trait is **a domain name**, not a field setting. `customer.past_due`, `plan.at_capacity`,
`subscription.canceled_by_customer` — not `customer.status = 3`.

```ts
// tests/factories/customer.ts
export const customer = factory({
  base: () => ({ name: faker.person.fullName(), email: `qa+${runId()}@example.com` }),
  traits: {
    past_due:   async (c) => { await billing.issueOverdueInvoice(c.id); return c },
    subscribed: async (c) => { await subscriptions.create({ customerId: c.id, planId: defaultPlan }); return c },
  },
})
```

- **A trait is a state transition made through the product's path**, not an `UPDATE`.
- **Composition is the rule**: `customer.past_due.subscribed` has to work in any order.
- **The name comes from the scenario**: the traits in `given:` in the catalog
  (`qa/references/scenario-catalog.md`) are the work list. A trait that is requested and missing is a
  visible backlog item (an issue), not a silent gap.

## Step 3 — `runId` is mandatory, cleanup by disposal

All created data carries a `runId` (`qa-<person|ci>-<YYYYMMDD>-<n>`) in its own field or in the
name/email suffix. Without it there is no parallel run, no safe cleanup, and no way to know who
dirtied the environment.

Cleanup is **disposal**, not surgical deletion: an ephemeral database/environment first, a sweep by
`runId` prefix next, a per-run `DELETE` only in a shared, persistent environment. Never truncate a
table, never a `beforeEach` that wipes the world.

> The six complete rules — and why together they are what lets the suite run on every PR:
> `references/isolation.md`. Do not repeat them elsewhere; reference them.

## Step 4 — The test-data endpoint (the API fixture)

For e2e, expose creation as an endpoint (`POST /__test-data/customer` with the traits in the body).
The guard goes **on the route registration**, not inside the handler:

```ts
if (env.TEST_DATA_ENABLED) app.register(testDataRoutes)   // in production the route does not exist
```

A route that exists and answers 403 in production is attack surface and a schema leak; a route that is
**not registered** does not exist. This is a security requirement, not style — it counts as a
`quality` (OWASP) item and is never simplified away.

Endpoint detail (contract, environments, cleanup, what never to expose):
`references/factories-and-endpoint.md`.

## Step 5 — Close

- No real PII, ever (`privacy`): synthetic data, email on a test domain.
- Record the factory in the repo conventions (`context/references/conventions.md`) so the next person
  finds it.
- **Acceptance target:** the repo's e2e suite stops referencing **any** preexisting data. `preflight`
  measures it (`preflight/scripts/qa-lint.sh`) and `health` follows the drop.
