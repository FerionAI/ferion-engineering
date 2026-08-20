# Shared libraries — propagating a change to N consumers

A shared library is the highest-leverage code in the organization and the easiest place to break
everyone at once. The cost of a change is not the change — it is the N migrations it triggers.

## Before you change it

- **Who consumes this?** Get the actual list, not an impression:
  ```bash
  gh search code "<package-name>" --owner <org> --limit 100
  ```
- **Is the change additive?** An added function costs nothing to consumers. A changed signature costs
  N migrations. A removed export costs N migrations plus the ones you did not find.
- **Could it live in one consumer instead?** Code used by one service does not belong in the shared
  library. Premature sharing is how a library becomes a dumping ground that nobody can change.

## Versioning is the contract

- **SemVer, strictly.** A breaking change is a major, even if it feels small. Consumers rely on that
  promise to auto-update minors.
- **Deprecate before removing.** Mark it deprecated in a minor, with the replacement named in the
  message, and remove it in the next major — after the consumers have had a release cycle to move.
- **Changelog entries consumers can act on:** "renamed `x` to `y`, replace with…" not "refactoring".

## Propagation

1. **Release the library** with the new version.
2. **Open a PR per consumer**, each linked to the same issue, each with its own `preflight`.
   Automated dependency bots handle patch and minor; a major is a real task per consumer.
3. **Consumers migrate at their own pace** during the deprecation window — that is the whole point of
   deprecating instead of breaking.
4. **Track the migration** with a task list on the parent issue, so "who is still on the old version"
   is visible instead of assumed.

## Private module resolution

For an internal library, make sure the toolchain can reach it consistently in three places — a local
machine, CI, and the Docker build — because the failure mode is always "works locally, fails in CI".
Configure the private registry/auth once, document it in the repo's README, and verify the container
build too. `<FILL: your private registry setup>`.

## The trap: the diamond

Service A depends on lib X v2, and on lib Y which depends on lib X v1. Whether this explodes depends
on your language (Go and npm resolve it differently), but the fix is the same: keep shared libraries
**few, small and additive**, so version skew stays survivable.
