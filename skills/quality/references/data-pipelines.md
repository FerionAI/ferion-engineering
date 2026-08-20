# Data engineering — DoD and QA

A data repository is not an application, and running the app checklist against it produces noise. The
Definition of Done here is different — and stricter in one place: a silent data bug corrupts decisions
for months before anyone notices.

## The Definition of Done for a pipeline

- [ ] **Tests on the models** — schema, `not_null`, `unique`, `relationships`. A model with no test is
      a table nobody can trust.
- [ ] **Freshness on the sources** — if the source stopped updating, the pipeline must fail loudly,
      not serve stale data quietly.
- [ ] **Idempotent DAG** — running it twice produces the same result. This is the single most valuable
      property; without it, no backfill is safe.
- [ ] **Resumable backfill**, in batches, with no side effects on retry.
- [ ] **Data contract** producer → warehouse: the schema is validated, not assumed.
- [ ] **Traceable lineage** — which model depends on which source, generated not hand-drawn.
- [ ] **PII masked or anonymized** in the lake/warehouse (`privacy`), with the retention rule applied.
- [ ] **Cost checked** — a query that scans the whole table on every run is a bug with an invoice.

## Data quality tests, in priority order

1. **Uniqueness of the key** — duplicated rows silently double every aggregate.
2. **Not null on what the business depends on.**
3. **Referential integrity** between models (an orphan fact row is a lost sale in a report).
4. **Ranges and accepted values** — a negative price, a status outside the enum, a date in 1970.
5. **Row-count anomaly** — today's load is 10% of yesterday's: fail, do not publish.
6. **Freshness** — the source is older than its SLA.

## Reviewing a pipeline change

- **What breaks downstream?** Read the lineage before changing a column. Renaming a field in a bronze
  model can break a dashboard three layers away that nobody in the PR knows about.
- **Is the change backfillable?** If the logic changed, historical data is now inconsistent with new
  data. Say what happens to the history: reprocess, or document the discontinuity.
- **Incremental logic:** does the incremental predicate actually catch late-arriving data? This is the
  most common silent data-loss bug in a pipeline.
- **Timezones.** Almost every date bug in a warehouse is a timezone bug.

## Privacy in the warehouse

The warehouse is where PII accumulates without anyone deciding to accumulate it. Check: is the
personal field needed in this layer, or only upstream? Is it masked in the layer analysts query? Is
there a retention/purge job, and has anyone run it? A copy in a "temporary" analysis dataset is still
personal data (`privacy`).

## Commands (for preflight)

- `dbt deps && dbt build` · `dbt test` · lint via `pre-commit run --all-files`.
- Orchestrator: validate the DAG parses and its dependencies resolve before shipping.
