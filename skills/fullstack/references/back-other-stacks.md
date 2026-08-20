# Landing in a back end that is not your usual stack

You know how to build a service. What you do not know is this language's idioms and its specific
traps. The concepts transfer; the details do not, and the details are where the bugs are.

## First, read before writing

- **The manifest** (`go.mod`, `pom.xml`, `pyproject.toml`, `*.csproj`) — framework, version, key
  libraries.
- **One representative handler/controller** end to end — that shows you the house style faster than
  any documentation.
- **The test file next to it** — that shows you how to test in this codebase, which is what you will
  need first.
- `context/references/conventions.md` for the team's decisions on this stack.

Do not port your previous language's patterns. Idiomatic beats familiar: the next person to read this
is a native of this stack.

## Go

- **Errors are values.** `if err != nil { return fmt.Errorf("context: %w", err) }` — wrap with context,
  never swallow. An ignored error is the most common Go bug.
- **No exceptions.** A `panic` is for programmer error, not for a failed request.
- **Interfaces are satisfied implicitly** and declared by the consumer, not the producer. Small
  interfaces.
- `context.Context` is the first parameter of anything that does I/O — that is how cancellation and
  timeouts work.
- Concurrency is easy to start and easy to leak. Every goroutine needs a way to stop.
- Table-driven tests are the idiom. `go test ./... -race` catches what review will not.

## Python

- **Type hints are not optional** in a serious codebase — `mypy`/`pyright` in CI. Dynamic typing plus
  no hints is how a rename silently breaks production.
- **Virtual environments and a lockfile.** `uv`/`poetry`, not a global `pip install`.
- Async and sync do not mix casually: a blocking call inside an async handler stalls the event loop.
- Mutable default arguments (`def f(x=[])`) — the classic trap, still catching people.
- `pytest` with fixtures is the idiom; `unittest` classes usually mean the code is old.

## Java / Kotlin (Spring)

- **Dependency injection through the constructor**, not field injection — it makes the dependencies
  visible and the class testable.
- Layers are conventional and enforced socially: controller → service → repository. Business logic in
  a controller will be flagged in review.
- **Method-level authorization** (`@PreAuthorize`), not just URL rules that a refactor can drift from.
- Checked exceptions, transaction boundaries (`@Transactional` and where it actually applies) and lazy
  loading (the N+1 generator) are the three things to understand before writing data access.

## .NET

- `async`/`await` all the way down; blocking on a task (`.Result`, `.Wait()`) deadlocks.
- Dependency injection is built in — register with the right lifetime (singleton/scoped/transient);
  getting this wrong causes bugs that only appear under concurrency.
- LINQ against the database is lazy: the query runs when you enumerate, not where you wrote it.

## Everywhere, whatever the stack

The security checklist does not change (`quality/references/security-by-stack.md` has the per-language
version): validate at the boundary, authorize per object, parameterize queries, no secrets, do not
leak internals in errors.

**Mentor mode:** if you are helping someone here, explain the idiom and *why* it exists, not just the
snippet. The goal is that next time they do it without you.
