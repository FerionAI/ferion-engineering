# Cross-repo coordination — the mechanics

A polyrepo setup makes each repo simple and the seams between them dangerous. This is where the
seams are, and how not to get cut.

## The seam: an OpenAPI contract and generated types

The common shape:

```
back end (repo A)                     front end (repo B)
  exposes an OpenAPI schema  ──────>   generates types from it (openapi-typescript)
                                       commits the generated .d.ts
                                       typed client + typecheck
```

The generated file being **committed** is what makes the drift visible: when the back end changes and
the front end regenerates, the diff shows exactly what moved, and the typecheck fails on anything
incompatible.

**The trap, and it is a real one:** if the front end generates against a stale schema source (the
staging deploy has not happened yet, or the local dump is old), regeneration produces the *old* types
and everything looks green. The drift is discovered in production. Always confirm the source is
serving the new schema before regenerating
(`preflight/references/contract-testing.md`).

## Blast radius: one back end serves N front ends

Before changing a back-end contract, find the consumers. There is no registry, so:

```bash
# in each front-end repo you have locally
grep -rl "<the-api-name>" --include=*.yaml --include=*.json . | head
# or search the org
gh search code "<the-api-base-url>" --owner <org> --limit 50
```

Record the result in `context/references/applications.md` — the list changes slowly, and rediscovering
it every time is how a consumer gets missed.

## The order (it is not negotiable)

1. **Contract agreed** in the back end (the source of truth for the type).
2. **Back end implements and ships** — additive only (expand). The old shape keeps working.
3. **Front ends regenerate and consume**, one at a time, at their own pace.
4. **Cleanup** (contract) — the back end removes the old shape only when no consumer uses it.

Shipping the front end first means depending on an API that does not exist yet. Removing the old
shape in step 2 means breaking every consumer that has not migrated. Both are avoidable by keeping
the order.

## One issue, N PRs

- The issue lives in the repo that owns the change; other repos reference it (`org/repo#123`).
- **One PR per repo**, each with its own branch, its own `preflight`, its own review.
- Only the PR in the owning repo uses `Closes #N` — otherwise the first merge closes the issue while
  half the work is still open.
- "Done" means **every** repo is green, not the first one.

## Deploy order

Back end before front end; producer before consumer. `release` handles each service's deploy and
rollback; the order between them is coordinated here. Write the order into the issue before starting
— during the deploy is too late to discover that the front end went first.

## Shared libraries

A library consumed by N services needs its own propagation plan — see `shared-libraries.md`.

## When the seam is asynchronous

For events instead of HTTP, the contract is the message schema and the guardian is the schema
registry's compatibility check, not a typecheck. Same order (producer additive first, consumer
after), different tooling — `integrations/references/event-bus.md`.
