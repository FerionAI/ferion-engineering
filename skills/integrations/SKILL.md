---
name: integrations
description: 'Makes the agent an expert in the project''s external tooling — GitHub, observability, product analytics, static analysis, session analytics — so it writes scalable, decoupled integration code and operates each tool through its MCP. Use when integrating with any of them, instrumenting observability/analytics, configuring CI or a quality gate, connecting an MCP, or when someone asks "how do I integrate with X", "how do I use the X MCP", "send this data to our analytics". MCP-first: prefer the official MCP to operate; decoupled code to instrument.'
---

# Integrations and tooling (MCP-first)

You handle the external tool ecosystem and help the team integrate it in a **scalable, decoupled and
observable** way. Two dimensions, always:

1. **Operating the tool (as an agent):** use the **official MCP** to query and act (logs and metrics,
   GitHub PRs, the quality gate, analytics reports). MCP-first.
2. **Integrating into the product (code):** write the instrumentation decoupled from the rest of the
   system (anti-corruption layer, resilience, config/secrets). See
   `references/integration-architecture.md`.

## Which reference to load

| Situation | Reference |
|---|---|
| Design/assess any integration (the scalable principles) | `references/integration-architecture.md` |
| GitHub and static analysis (dev + quality in CI) | `references/dev-toolchain.md` |
| Observability (logs, metrics, APM, tracing) | `references/observability.md` |
| Product and behavior analytics (funnels, heatmaps, in-app onboarding) | `references/analytics-and-experience.md` |
| Connecting/configuring the MCPs | `references/mcp-catalog.md` |
| **Asynchronous event bus** (Kafka/Avro): produce/consume, evolve a schema, DLQ | `references/event-bus.md` |
| **Observability per stack** (tracing in Node/Go/Java/Python + browser RUM) | `references/observability-by-stack.md` |

## The tool map

Fill this in for your team (`config/team-config.md`); `onboard` detects most of it from the code.

| Category | Role | MCP | Product integration |
|---|---|---|---|
| **GitHub** | code, PRs, CI/CD, issues | ✅ official | Actions/CI, automation |
| **Observability** | logs/metrics/APM | usually ✅ | SDK/OpenTelemetry, RUM |
| **Static analysis** | code quality and security | usually ✅ | analysis in CI (quality gate) |
| **Product analytics** | product/web funnels | often ✅ | a tag or measurement API |
| **Session analytics** | behavior (heatmaps, recordings) | sometimes | a front-end snippet |
| **Design** | design/handoff (layout context) | ✅ (Figma) | Code Connect (optional) |
| _others_ | `<FILL: list yours>` | `<REVIEW>` | `<REVIEW>` |

Only GitHub is required by the standard. Everything else is a capability you add when the team
actually uses it — an unconfigured tool degrades with a warning, it never blocks the flow.

## Principles (they apply to every integration)

- **MCP-first to operate; a decoupled SDK to instrument.** Do not couple business rules to a vendor
  SDK — isolate it behind your own interface (`integration-architecture.md`).
- **One event source.** Analytics comes out of a single typed tracking layer, not scattered through
  the code (`analytics-and-experience.md`).
- **Observability is part of the Definition of Done (P5).** Every new feature is born instrumented.
- **Secrets never in code.** Tokens and keys through a secret manager or the environment
  (`quality/references/secrets.md`).
- **Reuse before integrating again:** if a client or wrapper for the tool already exists in the
  codebase, use it.
- **A source that is not configured is a blocked skill, not a footnote.** `hooks/check-sources.sh`
  reads the credentials each MCP server in `.mcp.json` declares and, at session start, names the ones
  nobody set. A skill that reads from them (today: `health`) is **blocked** rather than allowed to
  ship a report full of holes — the person reconnects once instead of asking for the whole thing
  twice. Servers that authenticate in a browser (OAuth) cannot be checked from a hook: it says so
  instead of pretending, and `/mcp` is the confirmation. Declaring a server in `.mcp.json` is what
  puts it under this check — nothing else to maintain.
