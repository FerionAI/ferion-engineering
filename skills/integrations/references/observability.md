# Observability

A feature is not done if you cannot operate it (P5). Observability is not "we have logs" — it is
being able to answer, at 2am, what is broken and for whom.

## The three signals

| Signal | Answers | Cost |
|---|---|---|
| **Metrics** | is something wrong, and how much? | cheap, aggregate, no detail |
| **Traces** | where in the request did it break? | medium, sampled |
| **Logs** | what exactly happened in this case? | expensive at volume, full detail |

Use them in that order when investigating: the metric tells you *that*, the trace tells you *where*,
the log tells you *why*.

## Structured logs

JSON, not a formatted string. A log you cannot query is a log you will not read.

```jsonc
{ "level": "error", "msg": "payment declined",
  "trace_id": "abc123",          // the correlation id — the single most valuable field
  "user_id": "u_456",            // an internal id, not an email (privacy)
  "order_id": "o_789",
  "provider": "stripe", "code": "card_declined", "duration_ms": 342 }
```

Rules:

- **A correlation id on everything.** Without it, tracing one user's request across three services is
  archaeology. Propagate it through calls and into async messages.
- **No PII** — not the email, the name, the document number or the card (`privacy`). Mask at the
  logger with a field allowlist, so nobody has to remember at each call site.
- **Log decisions, not narration.** "Chose the discounted path because the coupon was valid" is
  useful; "entering function" is noise you pay to store.
- **Levels mean something:** `error` = someone must look; `warn` = degraded but handled; `info` = a
  business event; `debug` = off in production.

## Metrics — the four golden signals

Latency, traffic, errors, saturation. Per service, and per critical endpoint. Add the business metric
that matters (orders per minute) — it is usually the one that reveals an incident before the technical
ones do.

Alert on **symptoms, not causes**: "checkout error rate > 5%" wakes someone for a real problem; "CPU >
80%" wakes them for a Tuesday.

## Tracing

Spans across service boundaries, with the correlation id. This is what turns "the API is slow" into
"the API is slow because the third database call in the enrichment step takes 800ms".

## Alerts people actually read

An alert that fires daily and is always ignored is worse than no alert — it trains everyone to ignore
the channel, including the day it matters. Every alert should be **actionable** (there is something to
do), **owned** (someone is responsible) and **documented** (a runbook link,
`incident/references/runbooks-by-type.md`). Review the noisy ones periodically and delete them.

## Dashboards before the deploy, not after

`release`: alerts and dashboards ready **before** shipping. A silent deploy is a blind deploy — and
the first thing you want during an incident is a dashboard you already know how to read.

## Per stack

Instrumentation details, auto-instrumentation and browser RUM: `observability-by-stack.md`.
