# Writing and reviewing a database migration

A migration is the least reversible thing in a normal delivery. Review it like a deploy, not like code.

## The rules

1. **Additive first.** Add a nullable column, backfill, then make it required — never all at once.
   `ALTER TABLE ... ADD COLUMN x NOT NULL` on a populated table either fails or locks it.
2. **Expand/contract, always** for anything that changes an existing shape
   (`release/references/rollback-and-flags.md`). Renaming a column in one step means the previous
   version of the code cannot read the database — your rollback is gone.
3. **Never destructive in the same release** as the code that stops using it. Drop the column a
   release later, when nothing reads it and you can still roll back.
4. **Reversible, or explicitly not.** Write the `down`. If it genuinely cannot be reversed (a dropped
   column), say so in the PR and make a human acknowledge it.
5. **Test it against production-sized data.** A migration that takes 200ms on 100 rows takes 40
   minutes and a lock on 10 million.

## Locks — the thing that causes the incident

The migration ran fine in staging and took production down for 12 minutes. Almost always one of these:

| Operation | Risk | Safer path |
|---|---|---|
| `ADD COLUMN` with a default (older Postgres/MySQL) | rewrites the table | add nullable, backfill in batches, then set the default |
| `ADD NOT NULL` | full scan + lock | add nullable → backfill → add a validated constraint |
| `CREATE INDEX` | blocks writes | `CREATE INDEX CONCURRENTLY` (and it cannot run in a transaction) |
| `ALTER COLUMN TYPE` | rewrites the table | new column → backfill → swap → drop |
| Long transaction | holds locks, blocks everything | batch it; commit per batch |

Set a `lock_timeout` so a migration that cannot get its lock fails fast instead of queuing every
query behind it.

## Backfill

Separate from the schema migration, always. It is idempotent (safe to re-run), resumable (it will be
interrupted), batched (a few thousand rows at a time, with a pause), and observable (log progress).
Never a single `UPDATE` over the whole table.

**No PII in the backfill logs** (`privacy`).

## Per stack

- **Node (Drizzle/Prisma/TypeORM):** generated migrations are a starting point, not an answer — read
  the SQL they produce before committing it. That is where the accidental table rewrite hides.
- **Python (Alembic):** autogenerate misses constraint and index details; review the diff. `down` is
  generated as a stub and quietly needs writing.
- **Go (goose/migrate):** hand-written SQL, which is honest — the `-- +goose Down` is your problem and
  it will not be generated for you.
- **Java (Flyway/Liquibase):** immutable versioned files; a checksum change on an applied migration
  breaks the deploy. Never edit an applied migration — add a new one.

## Review checklist

- [ ] Additive, or explicitly expand/contract with the phases named.
- [ ] `down` written, or the irreversibility acknowledged in the PR.
- [ ] Locking assessed for the real table size; long operations batched or concurrent.
- [ ] Backfill separate, idempotent, resumable, batched.
- [ ] The previous version of the application still works against the new schema (rollback safety).
- [ ] Tested against a production-sized copy, with the timing recorded in the PR.
- [ ] Backup verified before anything destructive.
