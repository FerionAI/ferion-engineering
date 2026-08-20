---
name: quality
description: The quality and security rule base — OWASP Top 10 and API Security (security), Nielsen heuristics + WCAG accessibility + Core Web Vitals (front-end/UX), static analysis (Clean Code and the quality gate) and engineering metrics (DORA, coverage, complexity). Use when reviewing security, reviewing UI/UX or front-end work, configuring a quality gate, defining quality targets, or when someone asks "is this secure?", "does this follow OWASP?", "is the UX good?", "what's our quality gate", "which metrics should we track". Load it alongside `review` during reviews.
---

# Quality and security rule base

You apply the quality and security standards. This skill is the index — **load only the relevant
reference** for the task (token economy), never all of them at once.

## When to load which reference

| Situation | Reference |
|---|---|
| Code/API security, vulnerability review, auth, sensitive data | `references/security-owasp.md` |
| Front end, UI/UX, screens, accessibility, perceived performance | `references/frontend-ux.md` |
| Configuring static analysis, defining/checking the quality gate, code smells | `references/static-analysis.md` |
| Team quality targets, delivery, coverage, complexity | `references/metrics.md` |
| Third-party dependencies, dependency vulnerabilities, SCA, automated updates | `references/dependency-security.md` |
| Secrets: where to keep them, rotation, secret scanning, leaks | `references/secrets.md` |
| Security **per language** (Go/Python/Java, not just the OWASP concept) | `references/security-by-stack.md` |
| Threat modeling a sensitive flow (payment, personal data, auth) | `references/threat-modeling.md` |
| Accessibility **how-to** (ARIA, focus/focus-trap, live regions, screen readers) | `references/accessibility-wcag.md` |
| QA/DoD for **data engineering** (dbt/Airflow/pipelines, PII in the warehouse) | `references/data-pipelines.md` |
| Review/preflight of a **Terraform/IaC** change (reading the `plan`, blast radius) | `references/infra-iac.md` |

## Principles of use

- **Security is not optional.** Every change touching authentication, authorization, personal data,
  external input or dependencies goes through the OWASP check (`security-owasp.md`).
- **The front end is the product.** Every screen/flow is assessed against Nielsen heuristics and
  accessibility (WCAG) before it is "done" (`frontend-ux.md`).
- **Quality is measured, not argued.** The static analysis quality gate on new code
  ("Clean as You Code") is the objective floor (`static-analysis.md`).
- **Team improvement is measured with DORA** and sustained with code metrics (`metrics.md`).

## Baseline (the non-negotiable floor)

- **Security:** no open OWASP Top 10 items; APIs follow the API Security Top 10; no secrets in code
  or logs (`secrets.md`); all external input validated; no new high/critical dependency
  vulnerability (`dependency-security.md`).
- **Front/UX:** Nielsen heuristics met; WCAG 2.2 level AA accessibility; Core Web Vitals in the
  "good" band (LCP ≤ 2.5s · INP ≤ 200ms · CLS ≤ 0.1).
- **Static analysis (new code):** 0 new blocking issues · coverage ≥ `<REVIEW: 80%>` · duplication
  ≤ 3% · 100% of security hotspots reviewed.
- **Metrics:** track the four DORA metrics; keep complexity and duplication under control.

Values marked `<REVIEW: ...>` are recommended defaults — confirm them with the team and adjust.
