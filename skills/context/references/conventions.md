# Engineering conventions per stack

The per-language decisions and, most importantly, **the real commands** — this is where `preflight`
reads what to execute. A missing command means preflight degrades with a warning instead of running
the check, so filling this in is what makes the gate real.

## The commands (per repository)

| Repo | build | typecheck | lint (check mode) | test | e2e | dev server |
|---|---|---|---|---|---|---|
| `<FILL>` | `<FILL>` | `<FILL>` | `<FILL>` | `<FILL>` | `<FILL>` | `<FILL>` |

**Lint in check mode, never `--fix`** in CI or preflight — `--fix` mutates files and hides the
violation from the gate.

## TypeScript / Node

- **Package manager:** `<FILL: pnpm / npm / yarn>` — one per repo, with the lockfile committed.
- **TypeScript:** `strict: true`. `any` requires a justification in the PR.
- **Lint/format:** `<FILL: ESLint + Prettier, or Biome>`.
- **Tests:** `<FILL: Vitest / Jest>` + Testing Library for components; Playwright for e2e.
- **Layout:** `src/`, tests next to the code or in `tests/` — pick one per repo and keep it.
- Typecheck explicitly (`tsc --noEmit`); a bundler build is not a typecheck.

## Python

- **Environment:** `<FILL: uv / poetry>`, with a lockfile.
- **Lint/format:** `ruff` (it replaces flake8/isort/black in most setups).
- **Types:** `mypy` or `pyright` in CI. Type hints are not optional in a codebase with more than one
  author.
- **Tests:** `pytest` + fixtures, in `tests/`.
- **Layout:** `src/<package>/`.

## Go

- **Format:** `gofmt`/`goimports` (non-negotiable, it is the language's culture).
- **Lint:** `golangci-lint` with the team's config; `errcheck` on, because an ignored error is the
  most common Go bug.
- **Tests:** table-driven, `*_test.go`, `go test ./... -race` in CI.
- **Layout:** `cmd/`, `internal/`, `pkg/`.

## Java / .NET

- **Build:** `<FILL: Maven / Gradle / dotnet>`.
- **Format/analyzers:** `<FILL>`.
- **Tests:** JUnit / xUnit, with the coverage threshold enforced in the build.

## Cross-cutting

- **Commits:** Conventional Commits, atomic, referencing the issue (ADR-0001). Enforced with
  `commitlint` + a git hook where possible.
- **Branches:** `<FILL: naming convention, e.g. feat/123-short-description>`.
- **Versioning:** SemVer derived from the commits (`release`).
- **`.editorconfig`** in every repo, so the formatter is not an editor setting.
- **Runtime version pinned** (`.tool-versions`, `engines`, the Dockerfile) **and matching CI** — the
  drift between them is the most common "passes CI, breaks in prod".

## Infrastructure and observability

- **Logs:** structured (JSON), with a correlation id, no PII
  (`integrations/references/observability.md`).
- **Config:** environment variables; secrets from a secret manager, never committed
  (`quality/references/secrets.md`).
- **Containers:** `<FILL: base image policy, multi-stage builds, non-root user>`.

## Keeping this current

`onboard` writes most of this from the code the first time. After that it is a normal part of a
delivery: change the test runner, change the row. A command that is wrong here is worse than a
missing one — preflight will run it, get an error, and the person will learn to ignore the gate.
