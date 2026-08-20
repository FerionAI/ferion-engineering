# Technical plan — `<feature name>`

- **Related spec:** `specs/<feature>/spec.md`
- **Author:** `<fill>` · **Date:** `<fill>`

## Approach
`<Summary of the chosen technical solution, at a high level.>`

## Architecture decisions (and trade-offs)
> For each relevant decision, cite the constitution principle that drove it.
- **Decision:** `<...>` · **Alternatives considered:** `<...>` · **Why:** `<...>` · **Principle:** `<P#>`
- ...

## Services and components affected
`<Which apps/services change — see context. Contracts between services.>`

## API / contract changes
`<New endpoints, schema changes, versioning. Breaking change? How to mitigate.>`

## Data changes
`<Migrations, new models, impact on existing data. Rollback.>`

## Test strategy (P2)
`<What will be covered by unit/integration/e2e tests. Error and edge cases.>`

## Observability (P5)
`<Logs/metrics/tracing to add. How we will know it works in production.>`

## Security and data
`<Auth/authz, sensitive data, privacy, secrets.>`

## Rollout plan
`<Feature flag? Incremental deploy? How to revert if it goes wrong.>`
