# Static analysis and the quality gate

"Clean as You Code": the bar applies to **new code**, not to the whole repository. That is what makes
it adoptable in a legacy codebase — you never have to fix everything at once, and quality only goes
up from today.

> `<FILL: which analyzer — SonarQube/SonarCloud, CodeQL, Codacy, or the language's own linters>`.
> The numbers below are the recommended defaults; confirm them with the team.

## The gate on new code

| Condition | Default | Why |
|---|---|---|
| New blocker/high issues | **0** | anything above this is a bug you know about and shipped anyway |
| Coverage on new code | **≥ 80%** | the code you just wrote is the code you understand best; test it now |
| Duplication on new code | **≤ 3%** | copy-paste is where fixes go to die |
| Security hotspots reviewed | **100%** | reviewed, not necessarily changed — a human decided |
| Maintainability/reliability rating on new code | **A** | |

**The gate blocks the merge.** A gate that only warns is a dashboard, not a gate.

## Reading the findings honestly

- **A false positive is a real category.** Mark it as such in the tool with a reason, so it does not
  come back. Never disable the rule globally to silence one instance.
- **Disabling a rule needs an ADR** or at least a recorded justification in the PR. A ruleset that
  quietly erodes is worse than no ruleset — it looks like compliance.
- **Coverage is necessary, not sufficient.** 100% coverage with assertion-free tests proves nothing;
  `preflight/references/anti-hallucination.md` is the counter-check.
- **Complexity findings are usually right.** A function the analyzer calls too complex is the function
  the next person will misread at 3am.
- **A rule that does not fit the language is a configuration bug, not a quality signal.** Tag rules
  written for English (TODO/FIXME) fire on ordinary words in other languages — Portuguese and Spanish
  `todo` ("all"), French `fin` — and then the gate fails on nearly every PR. When **one** rule
  produces most of the findings, fix the rule (scope it, or exclude the pattern) and record why. Do
  not triage the same false positive every week; that is a chore the tool invented for you.
- **A gate that is red every week has stopped being a gate.** People route around a signal that never
  changes, and then miss the one week it was real. Track how often it fails *for the same reason*:
  past roughly half the runs, the thing to report is the misconfiguration, not the code — `health`
  marks that metric **not measuring** rather than "bad".

## Wiring it up

1. **Locally** — the editor plugin, so findings appear while writing, not in CI.
2. **On the PR** — the analysis runs on the diff and posts the gate status as a required check.
3. **On the main branch** — the full scan, to track the trend.

`preflight` runs whatever is available locally before the PR precisely so the bot has nothing to say
afterwards. **A finding that appears after preflight is a preflight defect** — add the rule to the
checklist (`preflight/references/preflight-checklist.md`).

## What this does not replace

Static analysis catches patterns. It does not catch: a wrong business rule, a missing domain state
(`epic/references/issue-template.md`), broken authorization logic that is syntactically fine, or a
design that is unusable. That is what `review`, `qa` and `design-review` are for.
