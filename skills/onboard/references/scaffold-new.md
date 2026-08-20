# Scaffolding blueprint — New mode

Goal: the project is born inside the standard. Confirm the stack with the user before creating
anything. Use the real conventions in `context` for concrete values (the team's tools and versions).

## Common bases (every stack)

- `memory/constitution.md` — the constitution (copy from the plugin).
- `AGENTS.md` — the portable core (copy from the plugin, adjust the context path).
- `docs/context/` — `applications.md` and `conventions.md` (from the templates).
- `specs/README.md` — explains the spec-driven flow and where `spec.md`/`plan.md`/`tasks.md` live.
- `.gitignore`, the project `README.md` (how to run, test, deploy).
- Minimal CI (`.github/workflows/ci.yml` or equivalent): lint + tests + build.
- A base `Dockerfile` when it is a service.
- `.editorconfig`.
- The flow labels (`status:in-progress`, `status:in-review`) — see the `onboard` skill.

## Per stack

### TypeScript / Node (React/Next)
- `package.json` with scripts: `dev`, `build`, `test`, `lint`, `typecheck`.
- `tsconfig.json` with `strict: true`.
- ESLint + Prettier, or Biome. Vitest/Jest + Testing Library.
  `<REVIEW: package manager — pnpm/npm/yarn>`.
- Layout: `src/`, `tests/`; for Next, the app-router layout.

### Python
- `pyproject.toml` with deps, `[tool.ruff]`, `[tool.mypy]`; environment via `uv`/`poetry`.
- `pytest` + `tests/`. Framework: `<REVIEW: FastAPI/Django/Flask>`.
- Layout: `src/<package>/`, `tests/`.

### Go
- `go.mod`; layout `cmd/ internal/ pkg/`.
- `gofmt` + `golangci-lint`. Table-driven tests in `*_test.go`.

### Java / .NET
- Java: Maven/Gradle + a Spring Boot base; JUnit. .NET: `dotnet new` + xUnit.
- Analyzers/formatter for the stack; the framework's standard layout.

## Final scaffold checklist

- [ ] Constitution and AGENTS.md present.
- [ ] Lint/format/type + test + minimal CI configs working (run them once).
- [ ] `specs/` ready for the first feature.
- [ ] README with instructions to run and test.
- [ ] Flow labels created.
- [ ] Offer to start the first feature through `spec-flow`.

Mark with `<REVIEW: ...>` (not `<FILL: ...>`) only what needs a team decision; everything else should
already be filled in from the conventions.
