# Roles → skills (manifest)

A map of **who usually uses what**. `start` reads this file to decide what to offer first.

**A role does not restrict, it only orders.** Anyone runs any skill; the role changes the order of
the offer, never the permission. Locking access would freeze the org chart inside the tool — and the
line between QA and dev is exactly the one teams are trying to blur.

A skill can appear under several roles (`preflight` belongs to whoever is about to open a PR). The
names are the folders in `skills/` — in Claude you call them with the plugin prefix
(`ferion-engineering:qa`).

**Invariant:** `scripts/validate-plugin.sh` fails the build if this manifest cites a skill that does
not exist **or** if a skill on disk appears under no role. Without that, a manifest like this goes
stale within two releases.

```yaml
pm:        [epic, discovery, test-strategy, issues, spec-flow]
qa:        [test-strategy, qa, qa-spec, bug, test-data, preflight, quality, design-review]
dev:       [spec-flow, test-data, ship, fullstack, preflight, review, bug, qa-spec, workspace, integrations, design-system, release, incident, agentic-flow, cost]
tech-lead: [approve, health, quality, cost, constitution, release, incident, workspace, agentic-flow, epic]
everyone:  [setup, start, onboard, context, privacy, design-system, issues]
```

## Tracks (what each role's panel shows at the top)

| Role | Track |
|---|---|
| **pm** | `epic` → `test-strategy` → `issues` |
| **qa** | `test-strategy` → `qa-spec` → `bug` → `quality` |
| **dev** | `spec-flow` → `test-data` → `ship` → `preflight` → `review` |
| **tech-lead** | `approve` → `health` → `quality` → `cost` |

Detection, persistence and the panels: `start/references/roles-and-panels.md`.
