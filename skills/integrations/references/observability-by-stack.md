# Instrumentation per stack

`observability.md` is the what. This is the how, per runtime. `<FILL: your observability vendor>` —
the shape is the same for OpenTelemetry and for a vendor agent.

## The rule that saves the most time

**Auto-instrumentation first.** Every modern APM agent instruments the HTTP server, the database
client and the HTTP client automatically. That covers most of what you need for free. Add manual
spans only for the business step the framework cannot see ("validate the coupon", "call the pricing
engine").

Hand-instrumenting what the agent already does gives you duplicate spans and a worse trace.

## Node / TypeScript

- Initialize the tracer **before any other import** — it patches the modules as they load. Import it
  at the very top of the entry file, or with a `--require`/`--import` flag.
- Structured logging with `pino` or `winston`, with the trace id injected into every line so logs and
  traces correlate.
- In a framework with an interceptor/middleware layer (NestJS, Express), that is the right place for
  the correlation id and the request-scoped context.

## Python

- Auto-instrumentation via the OpenTelemetry distro, or the vendor's, wrapping the entrypoint.
- `structlog` for structured logging; bind the trace id into the context once per request.
- Async: make sure the context propagates across `await` boundaries — a lost context is a trace that
  ends at the first await, which is the most common Python tracing bug.

## Go

- No monkey-patching: instrumentation is explicit. Wrap the HTTP handler and the database driver.
- `context.Context` carries the trace — pass it everywhere, which you should be doing anyway.
- `slog` (stdlib) for structured logs; add the trace id as an attribute.

## Java / .NET

- The agent attaches at startup (`-javaagent`, or the profiler env vars) and instruments the framework
  with no code changes. This is the highest-leverage five minutes in the stack.
- Structured logging through the framework's logger with an MDC/scope carrying the trace id.

## Browser (RUM)

- Real user monitoring gives you Core Web Vitals from actual devices, not a lab score
  (`quality/references/frontend-ux.md`). This is the only way to know what a mid-range phone on 4G
  experiences.
- **Mask PII** in session data and recordings before turning it on, not after (`privacy`).
- Sample. Full-fidelity RUM on every session is expensive and rarely more informative.

## What to instrument in a new feature

Not everything — the following, and stop:

1. The **entry point** (auto-instrumented, verify it appears).
2. The **business decision** that could go wrong ("chose plan X because Y") as a span attribute or a
   log line.
3. The **external call** (auto-instrumented; check the vendor is a tag so you can separate their
   outage from yours).
4. The **error path** with enough context to reproduce — ids, not PII.

## Cost

Observability bills scale with cardinality and volume. A tag with a user id in it is a metric with a
million series. Use ids in logs and traces (where you look one up), not as metric dimensions (where
you aggregate).
