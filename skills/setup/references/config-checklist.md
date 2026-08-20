# What setup configures — questions and defaults

Ask in short blocks, multiple choice, with the recommended default already selected. Translate into
the person's language (a PM or QA does not need technical terms). Each answer fills the team config
(`config/team-config.md`, from the `.example` template) and replaces the `<FILL: ...>` placeholders
in the standard.

## Block 1 — Tooling
- **GitHub (required):** `gh auth status`. Everything else is optional.
- Optional, by usage: static analysis, observability, product analytics, design tooling.
- Record whatever stayed pending — do not block.

## Block 2 — Issues (the source of truth)
- Which repository (or repositories) the team works in.
- The flow labels: create `status:in-progress` / `status:in-review`, or map to the team's existing
  vocabulary.
- Type labels used (feature/bug/chore) and any required issue template.
- Do they use an epic → sub-issue task list? A Project board?
- Branch/PR convention that references the issue number.

## Block 3 — Quality bar (suggested defaults)
- Tests: **required for new code** (default) / TDD / minimum coverage X%.
- Review: **1 reviewer + green CI** (default).
- Lint/format/types per language (the real tools: ESLint/Prettier or Biome, ruff/black/mypy,
  golangci-lint, …).
- Coverage target on new code (default: 80%).

## Block 4 — Front end / design system
- Is there a design system? Which package? (I can detect it from the code — `design-system`.)
- Adoption: **progressive** (default — new code uses it, legacy migrates without blocking deploy).
- Where the Storybook or component docs live; visual regression tooling.

## Block 5 — Security and privacy
- Do you handle personal data? Which regime applies (GDPR / LGPD / CCPA / none)?
- Who is the data protection contact?
- Rigor level per service (critical vs internal).

## Block 6 — Test tooling (for QA and dev)
- e2e (Playwright/Cypress), unit (Vitest/Jest/pytest/JUnit…), accessibility (axe/Lighthouse).
- The real build/lint/test commands per stack — so `preflight` can actually run them.

## Block 7 — Application context
- The main apps (name + what it does + stack). With a connected repository, offer to run `onboard`
  and discover this from the code instead of asking.

## Block 8 — Infrastructure and observability
- Cloud/infra patterns, observability stack, alert channels.
- Deploy strategy and whether feature flags are available.

## Rules
- **The default rules:** anyone who does not know takes the default; nothing has to be typed.
- **A little at a time:** short blocks; the person does not have to answer everything at once.
- **Shortcut:** with a connected repository, most of blocks 3, 6 and 7 come out of `onboard`
  automatically. Ask only what the code cannot answer.
