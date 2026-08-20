# API versioning and evolution

The goal is to change the API without breaking the consumers you cannot deploy in lockstep. In a
polyrepo, that is all of them.

## What is breaking and what is not

| Not breaking (additive) | Breaking |
|---|---|
| Adding an optional field to a response | Removing or renaming a field |
| Adding an optional request parameter | Making an optional parameter required |
| Adding a new endpoint | Changing a field's type or semantics |
| Adding a new value to an output enum* | Adding a value to an **input** enum consumers validate |
| Loosening a validation | Tightening a validation |

\* Adding an output enum value breaks any consumer with an exhaustive switch. In a typed generated
client, that is a compile error — which is a *good* failure, but still a coordinated change.

**Changing semantics without changing the shape is the worst kind of breaking change** — nothing
fails to compile, and the behavior is quietly wrong. If `status: "active"` starts meaning something
different, that is a new field, not a redefinition.

## Expand/contract (the pattern that avoids versions)

Most changes do not need a new version if you do them in two phases:

```
EXPAND    add the new field/endpoint alongside the old; both work
MIGRATE   consumers move, one at a time, at their own pace
CONTRACT  remove the old one, once nothing uses it
```

Deprecate loudly during the middle phase: a `Deprecation`/`Sunset` header, a log line when the old
path is used (so you can *see* who is still on it), and the replacement named in the docs. "Nothing
uses it" should be a measurement, not an assumption.

**Create the contract-phase issue up front.** It is the step everyone forgets, and forgetting it is
how a temporary compatibility shim becomes permanent (`epic/references/cross-team-decomposition.md`).

## When you do need a version

For a genuinely breaking redesign:

- **URL path** (`/v2/orders`) — most visible, easiest to route and to reason about. The default.
- **Header** (`Accept: application/vnd.api.v2+json`) — cleaner URLs, less obvious in logs and to
  humans debugging.

Either way: **run both versions in parallel** during a stated deprecation window, announce the sunset
date up front, and monitor usage of the old one so you know when it is actually safe to remove.

## Events

The same logic, enforced by the schema registry instead of a typecheck: additive fields with defaults
are backward compatible; removing a field or changing a type is not. Run the compatibility check
before shipping the producer (`integrations/references/event-bus.md`).

## Checklist for a contract change

- [ ] Classified: additive or breaking? (When unsure, treat it as breaking.)
- [ ] Consumers listed (`workspace/references/cross-repo-coordination.md`).
- [ ] Additive → expand/contract, with the cleanup issue created.
- [ ] Breaking → new version, deprecation announced, sunset date set, usage monitored.
- [ ] Types regenerated in every consumer; typechecks green.
- [ ] Deploy order written down: producer first, always.
