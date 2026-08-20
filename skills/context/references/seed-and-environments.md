# Data seeding and test environments

`preflight` drives the live app before a PR, QA reproduces states, e2e tests need a known starting
point. All three fail for the same reason: getting the system into the state you want to test is
harder than testing it.

## The seed's job

Put the system into a **known, deterministic, reproducible** state in one command.

```bash
<FILL: the seed command, e.g. pnpm seed / make seed / python manage.py seed>
```

Properties that matter:

- **Deterministic.** A fixed random seed, so the same run produces the same data. A flaky test caused
  by random seed data is the worst kind of flaky.
- **Idempotent.** Running it twice does not duplicate or fail.
- **Fast.** If it takes five minutes, nobody runs it and everyone tests against whatever their
  database happens to contain.
- **Covers the edge states**, not just the happy one: an empty account, an expired access, an
  unpublished item, a list with 500 entries, a user with no permissions. Those are the states the
  issue's state matrix names (`epic/references/issue-template.md`) — the seed is how you actually
  reach them.

## Never production data

Copying production into a lower environment is the most common personal data violation in engineering
(`privacy`). It feels harmless and it is a data breach waiting for one misconfigured access rule.

Use factories/faker with a fixed seed. If you genuinely need production-shaped volume, generate it —
or anonymize with a documented, tested process, not a `UPDATE users SET email = ...` someone ran once.

## Environments

| Environment | Purpose | Data |
|---|---|---|
| **local** | development, the preflight devserver check | seed |
| **development/integration** | shared integration | seed |
| **staging** | the human QA gate before production | seed, production-**shaped** |
| **production** | the real thing | real |

Two rules:

- **Nothing reaches production without the human gate in staging** (`qa`).
- **Staging must be close enough to production to be meaningful.** A different runtime version, a
  mocked dependency, or a thousand rows where production has ten million — each of those is a class
  of bug staging will not catch. Note the known differences explicitly; an unknown difference is the
  one that bites.

## Test data in automated tests

Each test creates and cleans up its own data. Tests that share fixtures must pass in any order, or
they will fail in CI's order and pass locally (`qa/references/automation.md`).

Set up state **through the API or the seed script, not through the UI**. Driving fifteen screens to
reach the state under test is how e2e suites become too slow to run and then get deleted.

## Feature flags in lower environments

The flag's state in staging should match what you are about to ship. Testing with the flag off and
shipping with it on tests nothing (`release/references/rollback-and-flags.md`).
