# Analytics and user experience data

Three different questions, three different tools — and one tracking layer feeding all of them.

| Question | Tool category |
|---|---|
| How many, where do they drop off? | product analytics (funnels, events) |
| Why did they drop off — what did they actually do? | session analytics (recordings, heatmaps) |
| Did they understand the feature? | in-app onboarding / guides |

Quantitative tells you *what* is happening; qualitative tells you *why*. `discovery` uses both.

## One typed tracking layer (the rule that matters)

Never scatter vendor SDK calls through components. One module owns tracking; everything else calls it
with typed events.

```ts
// tracking/events.ts — the single source of truth for what an event is
export type AppEvent =
  | { name: 'checkout_started'; plan: string; source: 'web' | 'app' }
  | { name: 'checkout_completed'; plan: string; value_cents: number };

export function track(e: AppEvent) { /* fan out to the providers here */ }
```

What this buys you:

- **The event schema is typed** — a renamed property breaks the build instead of silently producing an
  unusable funnel three weeks later.
- **Swapping or adding a provider** is one file.
- **Consent and PII rules are enforced in one place** instead of in fifty call sites.
- **The event catalog is greppable** — new people can see what exists instead of inventing a
  near-duplicate.

Analytics debt is invisible until you need the funnel and discover the same step is tracked under
three different names.

## Naming events

`object_action` in the past tense, lowercase, snake_case: `checkout_started`, `plan_upgraded`,
`invoice_downloaded`. Properties carry the detail; the name stays stable. Renaming an event breaks
historical comparison, so decide the name once, with whoever will read the dashboard.

## Privacy (this is where leaks happen)

Analytics is the most common accidental PII pipeline in a product.

- **Never send PII as an event property** — no email, name, document number, or free-text the user
  typed. An internal user id, yes.
- **Respect consent before firing.** The tracking layer checks it; components do not have to know.
- **Mask sensitive fields in session recordings** — that is a configuration you set *before* enabling
  it, not after. Recordings capture forms by default.
- **No PII in URLs**, because URLs end up in every analytics tool you have.
- A data processing agreement with each vendor (`privacy/references/data-map-and-checklist.md`).

## Instrumenting a new feature

In the `plan` step, decide the events (`spec-flow`): what defines success for this feature, and which
events measure it. Two or three events that answer a real question beat twenty that answer none.

Then in `discovery`, after shipping, those events are how you close the loop: did the pain go away,
did the metric move? Instrumentation added afterwards means the before/after comparison is already
lost.
