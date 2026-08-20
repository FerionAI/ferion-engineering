# Team Config — template

> Copy this file to `config/team-config.md` and fill it in. **That file is git-ignored on purpose**:
> it holds your team's real values and never ships with the plugin.
>
> Every skill reads this file and **prefers it** to the `<FILL: ...>` placeholders in the standard.
> The `setup` skill fills most of it by asking simple questions; `onboard` discovers from the code
> what can be read from the code (stack, build/test commands, design system, conventions).
>
> Marking: **(verified)** = confirmed live or in the code · **(from code)** = inferred by scanning ·
> **`<confirm: …>`** = still to be validated. **No secrets here** — tokens live in the environment.

## Connected tools

- **GitHub:** `<FILL: org/user>` — `gh auth status` must be green. Required.
- **Static analysis:** `<FILL: SonarQube / CodeQL / none>` `<confirm: MCP or CI only>`
- **Observability:** `<FILL: Datadog / Grafana / CloudWatch / none>`
- **Product analytics:** `<FILL: GA4 / Amplitude / PostHog / Clarity / none>`
- **Design:** `<FILL: Figma file or library URL / none>`

## Issues (the source of truth)

- **Where issues live:** the repository itself (`gh issue`). For work that spans repos, see the
  `workspace` skill.
- **Flow labels** (created once by `setup`, used by the flow gate):

| Milestone | Label | Meaning |
|---|---|---|
| `in progress` | `status:in-progress` | someone assumed the issue and started implementing |
| `in review` | `status:in-review` | the PR is open and the issue is waiting for review |

- **Issue types:** `<FILL: label taxonomy — e.g. type:feature, type:bug, type:chore>`
- **Templates:** `<FILL: path to .github/ISSUE_TEMPLATE, if any>`
- **Epics:** an epic is an issue with a task list (`- [ ] #123`) linking its children.
  `<confirm: do you also use a GitHub Project board?>`

## Cost per task

The `cost` skill writes a structured comment on the issue at the `PR + cost` milestone.
No custom fields, no extra system.

- **Capture:** `python3 skills/cost/scripts/session-cost.py` (reads `ccusage` + the session transcript).
- **Marker:** `<!-- ferion:cost ... -->` — what makes the comment machine-readable for `health`.
- `<FILL: does your team price features from this? which model prices do you assume?>`

## Stack and commands (per repository)

`onboard` fills this in from the code. One block per repository.

| Repository | Stack | build | lint | test | e2e |
|---|---|---|---|---|---|
| `<FILL>` | `<FILL>` | `<FILL>` | `<FILL>` | `<FILL>` | `<FILL>` |

## Design system

- **Package:** `<FILL: npm package or path>` · **Version:** `<FILL>`
- **Docs/Storybook:** `<FILL: URL>`
- **Adoption:** progressive — new code uses it, legacy migrates without blocking deploy.
- **Visual regression:** `<FILL: Chromatic / Percy / none>`

## Quality bar

- **Reviewers per PR:** `<FILL: e.g. 1>`
- **Required CI gates:** `<FILL: lint, build, test, sast…>`
- **Quality gate on new code:** `<FILL: tool + threshold>`
- **Critical services** (extra rigor): `<FILL>`

## Privacy

- **Applicable regimes:** `<FILL: GDPR / LGPD / CCPA / none>`
- **Data protection contact:** `<FILL: DPO or the responsible team>`
- **Categories of personal data handled:** `<FILL>`
- **Default retention:** `<FILL>`

## Release and incident

- **Deploy strategy:** `<FILL: canary / blue-green / rolling — and the tool>`
- **Feature flags:** `<FILL: provider or none>`
- **Severity scale:** `<FILL: SEV1..SEV3 definitions>`
- **On-call/escalation:** `<FILL>`
