# Scalable integration architecture

The vendor you integrate today is the vendor you migrate away from in three years. Everything here is
about making that a contained change instead of a rewrite.

## The anti-corruption layer

Never let a vendor SDK spread through your business logic.

```
domain code  →  your interface  →  adapter  →  vendor SDK
```

- **Your interface speaks your domain**, not the vendor's: `notifier.send(user, message)`, not
  `sendgrid.mail.send({...})`.
- **The adapter is the only file that imports the SDK.** One grep tells you the blast radius of a
  vendor change.
- **Your own types at the boundary.** A vendor's response type leaking into your domain is the
  coupling you were trying to avoid.
- This also makes testing trivial: stub the interface, not the network.

The cost is one small file. The payoff is that swapping the provider, or adding a second one, touches
one directory.

## Resilience (assume it will fail)

Every external call is a network call, and every network call fails eventually.

| Concern | Rule |
|---|---|
| **Timeout** | always set one, explicitly. The default is usually "forever", which exhausts your connection pool and takes down endpoints that have nothing to do with the integration. |
| **Retry** | only for idempotent operations, with exponential backoff and jitter. Retrying a payment is worse than failing it. |
| **Circuit breaker** | after N failures, stop calling and fail fast. This is what keeps one slow dependency from cascading. |
| **Graceful degradation** | what does your feature do when the vendor is down? "500" is rarely the right answer for a non-critical enrichment. |
| **Idempotency key** | on anything that creates or charges, so a retry does not duplicate. |

## Configuration and secrets

- Credentials from the environment or a secret manager, never in code
  (`quality/references/secrets.md`).
- The base URL is configuration, so you can point at a sandbox in staging.
- Feature-flag a new integration so you can turn it off without a deploy.

## Webhooks (the inbound direction)

- **Verify the signature.** An unauthenticated webhook endpoint is a public write API.
- **Respond fast, process asynchronously.** Do the work in a queue; the sender will retry if you are
  slow, and now you have duplicates.
- **Be idempotent.** Providers deliver at-least-once. Deduplicate on the event id.
- **Log the raw payload** (minus PII) — when a webhook does something unexpected, the payload is the
  only evidence.

## Observability

An integration you cannot see is an integration you cannot debug. Instrument at the adapter: latency,
error rate and outcome per external call, with the vendor as a tag. That is what tells you "the
incident is theirs, not ours" in thirty seconds instead of an hour (P5).

## Before adding an integration at all

The ladder applies (`agentic-flow/references/write-less-code.md`): does something already integrated
do this? Is there already a client for this vendor in the codebase? An integration is a permanent
dependency on someone else's uptime, someone else's API changes and someone else's incidents.
