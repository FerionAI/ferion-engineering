# Onboarding a NON-app repo (data and infrastructure)

> A meaningful share of most organizations' repositories are not application code: **data**
> (dbt/Airflow/Databricks) and **infrastructure** (Terraform, GitOps, reusable CI workflows). For
> those, the **gap report against the app Definition of Done** (`scan-existing.md`) **does not
> apply** — there is no screen, no unit test runner, no e2e. Running the app checklist there produces
> noise (false ❌). Use the criteria below.

## How to recognize them
- **Data:** `dbt_project.yml`, `dags/` + Airflow, Databricks notebooks / PySpark `.py`, a warehouse
  profile. No application manifest.
- **Infra:** `*.tf`/`*.hcl`, `terragrunt.hcl`, Helm values + an ArgoCD `Application`, reusable
  workflows. No application manifest.

## What to document (instead of an app's `applications.md`)
- **Data:** sources consumed, layers (bronze/silver/gold), lineage (who depends on whom), where it
  runs (managed Airflow / Databricks / a scheduler), datasets and retention.
- **Infra:** what the repo provisions, environments (`development/staging/production`), where the
  state lives, who applies and how (CI or manual).

## Maturity / DoD — a DATA repo
Cross-reference `quality/references/data-pipelines.md` for the detail. Mark present/absent:
- [ ] **Model tests** (schema/not_null/unique/relationships) + freshness on the sources.
- [ ] **Idempotent DAG** + resumable backfill + retries with no side effects.
- [ ] **Data contract** producer → warehouse (schema validated, not implicit).
- [ ] **Traceable lineage** (dbt docs or an equivalent).
- [ ] **PII** masked or anonymized in the lake/warehouse (`privacy`).

> "No tests" in a data repo is **not** an automatic ❌ against the DoD — it becomes ❌ only when the
> model tests or the transform unit tests are missing where there is real logic. Plenty of legitimate
> data repos live without an app test runner.

## Maturity / DoD — an INFRA repo (IaC)
Cross-reference `quality/references/infra-iac.md`. Mark:
- [ ] **Clean `plan`** — no unexpected drift; the PR shows the plan diff.
- [ ] **State isolated per environment**, with the backend and credentials scoped per environment.
- [ ] **No secret in the state** — secrets through a secret manager / external secrets, never in a
      committed `.tfvars` or an exposed state.
- [ ] **Apply discipline** — who applies and when (CI with OIDC vs manual apply — record the owner).
- [ ] **pre-commit** on the modules (`terraform_fmt`/`tflint`/`validate`/`docs`).

## Commands (for preflight, per `conventions.md`)
- **dbt:** `dbt deps && dbt build` · lint `pre-commit run --all-files` · test `dbt test`.
- **Terraform module:** `terraform init && plan` · `fmt -check` + `pre-commit run -a` · `validate`.
- **Terragrunt:** `terragrunt init` · `fmt -check` · `terragrunt plan`.

## Gap report — adapted

Same format as `scan-existing.md`, but replace "Definition of Done (app)" with **"data maturity"** or
**"infrastructure maturity"** as appropriate, using the axes above. Order by risk (a state with an
exposed secret and a non-idempotent DAG come first).
