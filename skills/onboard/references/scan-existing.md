# Scan script — Existing mode

Goal: extract the reality of the repository with the minimum amount of reading. Prefer `Glob`/`Grep`
over `Read`. Read in full only the manifests and 1–2 sample files per language.

## 0. Standard/spec already in the repo — DETECT and ALIGN (before generating anything)

**Before** scanning stack and maturity, look at what standard/spec material already exists. The goal
is to **reuse and update**, **never create a format parallel** to the one the repo already uses:

- **Spec Kit / spec-driven:** `Glob` for `.specify/`, `specs/**/spec.md`, `specs/**/plan.md`,
  `specs/**/tasks.md`, `specs/*/` (feature dirs, often numbered `NNN-name`). If they exist → **the
  repo is already spec-driven**: adopt the SAME folder and numbering, do not invent another.
- **Constitution/standard:** `.specify/memory/constitution.md` **or** `memory/constitution.md`
  **or** `AGENTS.md`/`CLAUDE.md`/`.cursor/rules*`/`.github/copilot-instructions.md`. If one exists →
  **update/extend** it (merge the principles in), do not overwrite it with a new one.
- **Templates/ADRs:** `.specify/templates/`, `docs/adr/`, `docs/decisions/`, `adr/`.
- **Spec slash commands:** `.claude/commands/`, `.github/prompts/` (specify/plan/tasks).

**Rule:** found a spec/constitution structure? **Align with it** and record where it actually lives
for the next steps. Generating a new format on top is the classic mistake — it duplicates and
confuses.

## 1. Stack detection (by manifest)

| Signal (Glob) | Stack | What to read |
|---|---|---|
| `package.json` | TS/Node | scripts, deps (next/react/nest/express), `"type"` |
| `tsconfig*.json` | TypeScript | `strict`, paths |
| `pyproject.toml` / `requirements.txt` / `setup.cfg` | Python | deps (fastapi/django/flask), tool.ruff/black/mypy |
| `go.mod` | Go | module, Go version |
| `pom.xml` / `build.gradle*` | Java | framework (spring), plugins |
| `*.csproj` / `*.sln` | .NET | target framework, packages |

Detect multiple stacks in the same repo (monorepo/polyglot) — record all of them.

## 2. Maturity against the Definition of Done

Mark each axis present/absent:

- **Tests:** `Glob` for `**/*.{test,spec}.{ts,js,tsx}`, `**/*_test.go`, `tests/**`, `**/test_*.py`;
  configs: `jest.config*`, `vitest.config*`, `pytest.ini`, `playwright.config*`.
- **CI:** `.github/workflows/*.yml`, `.gitlab-ci.yml`, `azure-pipelines.yml`, `Jenkinsfile`.
  Read the workflows to see whether they actually run lint/test/build.
- **Lint/format/types:** `.eslintrc*`, `eslint.config.*`, `.prettierrc*`, `biome.json`,
  `ruff.toml`/`[tool.ruff]`, `.flake8`, `mypy.ini`, `.golangci.y*ml`, .NET analyzers.
- **Observability:** `Grep` for libraries — `opentelemetry`, `winston`/`pino`, `structlog`,
  `zap`/`logrus`, `Serilog`; tracing/metrics instrumentation.
- **Infra/IaC:** `*.tf`, `cdk.json`, `serverless.yml`, `template.yaml`, `Dockerfile`,
  `docker-compose*`, k8s manifests.
- **Secrets:** `Grep` for hardcoded credential patterns (flag it, never print the value).

## 3. Domain map (cheap)

- List apps/services by topology: a folder with its own manifest is a unit.
- Read only **entry points** (`main.*`, `index.*`, `cmd/*/main.go`, `Program.cs`, a Next `app/`) and
  route/config files to infer responsibility and integrations.
- Deduce service-to-service communication from deps and clients (cloud SDKs, HTTP clients, gRPC).

## 4. Generating documentation

Fill in from the plugin's base files, replacing `<FILL: ...>` with what you detected:

- **`memory/constitution.md`**: keep the principles; fill in the detected lint/test/CI tooling; mark
  as `<REVIEW: ...>` (not `<FILL: ...>`) the items that need a human decision (number of reviewers,
  critical services).
- **`AGENTS.md`**: point the context path at wherever the docs were generated.
- **`docs/context/conventions.md`**: record the real tools/versions per language.
- **`docs/context/applications.md`**: one entry per detected service, with what was inferred.

## 5. Gap report (deliver this to the user)

Suggested format:

```
## Onboarding — <repo>
Detected stack: <...>
Services/apps: <...>

Definition of Done — current state
✅ <what already complies>
❌ <what is missing> — recommendation: <action> (I can create it through spec-flow)

Items needing a human decision (<REVIEW> in the constitution): <list>
```

Order the recommendations by impact (whatever most reduces risk or inconsistency first).
