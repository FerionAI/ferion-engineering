# Application inventory

> **This file ships empty on purpose.** The inventory belongs to your project. `onboard` fills it
> from the code, one repository at a time; a human confirms what the code cannot answer.
>
> An empty row is a gap to fill, not permission to guess. If a service is not listed here, say so
> rather than inventing what it does.

## The apps

| App / repo | What it does | Stack | Type | Owner |
|---|---|---|---|---|
| `<FILL>` | `<FILL>` | `<FILL>` | front / back / lib / infra / data | `<FILL>` |

Group them by domain once there are more than a handful — the grouping is the first thing a newcomer
reads.

## How the services talk

| From | To | Through | Contract |
|---|---|---|---|
| `<front>` | `<api>` | HTTP | OpenAPI → generated types |
| `<service A>` | `<service B>` | events | schema in the registry |

Also record: who consumes each API (the blast radius list — see
`workspace/references/cross-repo-coordination.md`), and which repositories share a library.

## Infrastructure

- **Cloud / hosting:** `<FILL>`
- **Deploy:** `<FILL: how code reaches production — the pipeline, the platform>`
- **Environments:** `<FILL: development / staging / production, and what differs between them>`
- **Data stores:** `<FILL>`
- **Async:** `<FILL: queue/bus, if any>`

## Filling this in

Run `onboard` in each repository. It detects the stack from the manifests, infers responsibility from
the entry points, and records the real build/lint/test commands in `conventions.md` — which is what
`preflight` needs to run the actual tools instead of guessing.

Keep it current the way you keep code current: when a service changes shape, the entry changes in the
same delivery (P5). A stale inventory is worse than an empty one, because people trust it.
