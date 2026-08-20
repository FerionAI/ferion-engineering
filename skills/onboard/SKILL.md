---
name: onboard
description: Initializes the engineering standard in a repository — in an EXISTING project it scans the code, detects the stack and generates the documentation (local constitution, AGENTS.md, context and conventions) from the reality of the code, with a gap report against the Definition of Done; in a NEW project it creates all the bases of the standard. Use when someone asks for "onboarding", "set up the standard here", "evaluate/document this project", "bootstrap", or right after installing the plugin in a repository.
---

# Onboarding the standard

You initialize the engineering standard in a repository. Work **token-economically**: use
`Glob`/`Grep` and read only manifests and representative samples — never the whole codebase.

## Step 0 — Detect the mode (new vs existing)

Check whether there is real source code:
- Look for manifests with `Glob`: `package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`,
  `pom.xml`, `build.gradle*`, `*.csproj`, `*.sln`.
- Look for sources with `Glob`: `**/*.{ts,tsx,js,py,go,java,cs}` (count them, do not read them all).

- **Code exists** → follow **Existing mode**.
- **Empty repository / README only** → follow **New mode**.

If it is ambiguous, ask the user which mode they want.

## Existing mode — evaluate and document

Goal: reflect the reality of the repository in the standard and point out the gaps. Full scan script
in `references/scan-existing.md`. **First, detect what the repo already has** in terms of
standards/specs — Spec Kit's `specs/`, `.specify/`, a constitution, `AGENTS.md`/`CLAUDE.md`, ADRs
(`scan-existing.md` §0) — and **align with it**: reuse the structure/numbering and **update** what
exists; **never create a parallel format**. Only generate what is missing. In short:

1. **Detect the stack** — from the manifests: languages, frameworks, package manager.
2. **Detect maturity** against the Definition of Done:
   - Tests: is there a test directory/config? (`**/*{.test,.spec}.*`, `tests/`, `pytest.ini`, `*_test.go`)
   - CI: `.github/workflows/`, `.gitlab-ci.yml`?
   - Lint/format/types: `.eslintrc*`, `.prettierrc*`, `biome.json`, `ruff.toml`, `mypy.ini`,
     `golangci*`, `tsconfig` strict?
   - Observability and IaC: logging/tracing libraries, `*.tf`, `cdk.json`, Dockerfiles.
3. **Map the domain** — from the folder structure and entry points, infer services/apps and how they
   communicate (read only entrypoints and configs, not the whole base).
4. **Generate OR update the documentation** (reusing the existing structure — do not duplicate):
   - **Constitution:** if `.specify/memory/constitution.md` or `memory/constitution.md` already
     exists, **update it** (merge in the standard's principles); only create
     `memory/constitution.md` if none exists.
   - **`AGENTS.md`/`CLAUDE.md`:** if one exists, extend it; otherwise create the portable core
     pointing at the constitution.
   - **Specs:** if the repo already uses `specs/` (Spec Kit), **keep its folder/numbering** — do not
     create another.
   - `docs/context/applications.md` and `docs/context/conventions.md` — filled with the **detected**
     stack and conventions (do not leave placeholders where the code already answers).
5. **Set up the flow labels** (this is what unlocks the automatic milestones):
   ```bash
   gh label create status:in-progress --color 0E8A16 --description "Someone assumed the issue and is implementing" 2>/dev/null
   gh label create status:in-review   --color FBCA04 --description "PR open, waiting for review" 2>/dev/null
   ```
   If the repo already has an equivalent taxonomy (`in progress`, `wip`, a Project column), **ask
   before creating** and record the mapping in the team config — do not impose a second vocabulary
   on a board that already works. Also record the type labels the team uses (`gh label list`).
6. **Gap report** — deliver an objective summary: what already meets the DoD (✅), what is missing
   (❌) and prioritized recommendations (e.g. "no test CI", "lint missing in service X", "no
   tracing"). Offer to create what is missing (CI/lint/test configs) through `spec-flow`.
7. **A data or infra repo?** If it is a pipeline (dbt/Airflow/Databricks) or IaC (Terraform), the
   app DoD does not apply — use `references/non-app-repos.md` (what to document and what counts as
   maturity there).

> Preserve what the team already has. Where a detected convention conflicts with the standard, point
> out the difference and propose — never overwrite silently.

## New mode — create the bases

Goal: the project is born inside the standard. Detail in `references/scaffold-new.md`. In short:

1. **Confirm the stack** with the user (TS/Node, Python, Go, Java/.NET) and the type (service, front
   end, library).
2. **Scaffold the bases:**
   - `memory/constitution.md` + `AGENTS.md` (from the standard).
   - `specs/` (the spec-driven flow folder) with a `README` explaining the flow.
   - The stack's recommended configs: lint/format/types, tests, minimal CI, `.gitignore`, a base
     Dockerfile — per `references/scaffold-new.md` and the conventions (`context`).
   - The language's initial folder structure.
   - A project `README` with the skeleton and how to run it.
   - The flow labels (see Existing mode, step 5).
3. **First feature through the flow** — offer to start the first piece of functionality through
   `spec-flow`.

## Expected output

- **Existing:** generated, committable documentation + a prioritized gap report.
- **New:** a repository with all the bases of the standard ready for the first commit.

In both cases, make clear what the team should review or confirm (e.g. fields that need a human
decision). Record what you learned in `config/team-config.md` so the next session does not
rediscover it.
