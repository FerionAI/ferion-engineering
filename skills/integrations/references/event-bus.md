# Asynchronous event bus (Kafka/Avro and equivalents)

The asynchronous contract. Everything hard about it comes from one fact: **the producer and the
consumer deploy at different times**, and there is no compiler between them.

## The schema is the contract

- **A schema registry is not optional.** Without it, "the contract" is a shared belief, and it will
  turn out to be wrong under load, in production, at the consumer's end.
- **Compatibility mode:** `BACKWARD` is the usual choice (a new consumer reads old data). If
  consumers upgrade before producers in your organization, you want `FORWARD`. Pick deliberately and
  write it down.
- **Run the compatibility check before shipping the producer** — this is a mandatory preflight step
  when the diff touches a schema (`preflight/references/contract-testing.md`).

## Evolving a schema safely

| Change | Safe? |
|---|---|
| Add an optional field **with a default** | yes |
| Add a required field | no — old messages have no value for it |
| Remove a field with a default | yes, once no consumer reads it |
| Rename a field | no — that is a remove plus an add |
| Change a type | no |

Same expand/contract discipline as an API (`fullstack/references/api-versioning.md`): add, migrate
consumers, then remove.

## Producing

- **Event, not command.** `OrderPlaced` (a fact that happened) rather than `SendEmail` (an
  instruction). Facts have many consumers and age well; commands couple you to one.
- **Include the ids and a timestamp**, plus the correlation id from the originating request —
  otherwise tracing a flow across the bus is impossible.
- **No PII in the payload** unless the consumer genuinely needs it and there is a basis; the topic is
  a data store with a retention period, readable by every team with access (`privacy`).
- **Idempotency key** in the event, so consumers can deduplicate.
- **Outbox pattern** when the event must be consistent with a database write: write the event to an
  outbox table in the same transaction, publish from there. Publishing directly after a commit means
  a crash between them silently loses the event.

## Consuming

- **Assume at-least-once delivery.** The same message will arrive twice. Consumers must be
  **idempotent** — this is the single most important property, and the one most often skipped.
- **Do not assume order** across partitions. Order is guaranteed within a partition key, nothing more.
- **Handle the poison message.** A message that always fails will block the partition forever unless
  you route it to a dead-letter queue after N attempts.
- **Commit the offset after processing**, not before.

## Dead-letter queue

- A DLQ with no alert is a silent data-loss queue. Alert on depth > 0.
- **Never purge it** to clear an alert — those are unprocessed business events.
- Replay only after fixing the cause, and only if the consumer is idempotent
  (`incident/references/runbooks-by-type.md`).

## Observability

Consumer lag is the metric that matters — it tells you the consumer is falling behind before users
notice. Also track: processing time per message, error rate, DLQ depth, and the correlation id
propagated from producer to consumer so a trace spans the bus.
