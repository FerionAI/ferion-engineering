---
name: start
description: 'Natural-language entry point to the engineering standard — understand what the person wants in plain language and route them to the right flow or check, without them knowing any skill names. Use when someone talks generally about working on code: "help me with a feature", "I need to change this project", "how do I do this here", "where do I start", "what can you do", "I want to create/fix/review something", or any development request with no specific tool named. This is the plugin router.'
---

# Entry point

You are the starting point of the engineering standard. The person **does not need to know the
plugin**: they describe what they want in natural language and you take them down the right path,
explaining in one sentence what you are going to do. Act — do not hand them a menu.

## First: the mandatory flow (any request that touches code)

Before routing, **read where the flow is** and resume from there:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/flow-gate.sh status
```

Every code change goes through 6 steps, **in this order, no skipping and no reordering**:

| # | Step | Closes when… | Where |
|---|---|---|---|
| 1 | **issue** | the GitHub issue exists — the person cited it, or you **asked and created it** (do not scan the backlog guessing) | `issues` |
| 2 | **in progress** | you **assumed** the issue (assignee) and labelled it `status:in-progress` | `issues` |
| 3 | **implement** | spec/plan in `specs/<feature>/` and the code as a vertical slice with tests | `spec-flow` → `ship`/`fullstack` |
| 4 | **local review** | `review` + `preflight` in a **loop until ZERO findings** → `flow-gate.sh stamp review` | `review`, `preflight` |
| 5 | **PR + cost** | PR open with `Closes #N` **and** tokens/USD/hours recorded on the issue | `integrations`, `cost` |
| 6 | **in review** | issue labelled `status:in-review`, and said so in the summary | `issues` |

This is **not a recommendation**: the hooks block (`exit 2`) editing code before step 2, opening a
PR before step 4 and labelling for review before step 5 — and they stamp each milestone from what
the tool actually did. If a gate blocks you, **close the missing step** (the message says which one)
instead of looking for another way around.

- **Resume, do not restart.** State lives in the repo (`.git/ferion-flow`), not in the conversation:
  a new session continues from the step it points to, without redoing what is already closed.
- **One issue at a time.** A new request mid-flow: finish, or record where you stopped — switching
  issues resets the previous flow.
- **Exceptions only when recorded** (hotfix through `incident`, a repo with no issue tracker):
  `flow-gate.sh bypass "<reason>"` and **declare it in the summary**. Never stamp a step that did
  not happen.

> Full mechanics (gates, stamps, degradation, how to leave the flow): `references/mandatory-flow.md`.

## How to route (intent → path)

Read the intent and follow the route. Load the matching skill and follow it. If the request combines
several, use the combo. **The route says where to enter — it does not waive the 6 steps above:**
any route that touches code enters the flow at step 1 (or wherever `status` says it stopped).

| The person wants… (example phrasings) | Route |
|---|---|
| "first time", "configure", "connect the tools", "setup", "help me get started" | `setup` (guided, no code) |
| "I'm a PM", "break down this epic", "generate the issues for epic X", "create the stories" | `epic` (epic → issues) |
| "understand the user", "what does the data say", "which problem to solve", "is it worth building", "test with a user", "did the flow work?" | `discovery` (design thinking: empathize/ideate/test) |
| "look at the issues", "what's in review / in the sprint / in the backlog", "take issue #123", "what was asked here" | `issues` (issues are the source of truth) |
| "create/build a feature", "implement X", "do this from scratch" | **ship** (idea→PR pipeline) — starting from the issue, or `spec-flow` if it is only a spec |
| "fix a bug", "it's broken" | `integrations` (observability investigates) + `spec-flow` (fix the root cause, not the symptom) |
| "production is down", "error in production", "open an incident", "postmortem" | `incident` (response + postmortem; mitigate through `release`) |
| "ship it / deploy", "put it in production", "canary/rollout", "rollback", "feature flag", "cut a release" | `release` (shipping to production safely) |
| "is it ready for a PR?", "review everything before I push", "make sure it's spotless", "check it didn't hallucinate" | `preflight` (pre-PR gate) |
| "review this", "is this ready to merge?", "look at my PR" | `review` (human review, after preflight) |
| "test cases", "test plan", "report a bug", "what to retest", "exploratory testing", "automate tests", "validate this issue", "can this go to production?" | `qa` (QA kit) |
| "get me into this project", "I don't know this repo", "document what's here", "start a new project" | `onboard` |
| "what's the standard", "how do we do it here", "what blocks a merge" | `constitution` |
| "is it secure?", "OWASP", "is the UX good", "accessibility", "quality gate" | `quality` |
| "review this Terraform/IaC", "infra change", "read the plan", "blast radius" | `quality` (→ `quality/references/infra-iac.md`) |
| "data QA", "review my dbt/Airflow pipeline", "PII in the warehouse" | `quality` (→ `quality/references/data-pipelines.md`) |
| "validate this layout", "is this Figma ready to build?", "review the design before coding" | `design-review` (pre-code design gate) |
| "create a screen/component", "style this", "layout", "button/input/modal", "design system", "color/spacing" | `design-system` |
| "I've never done back/front", "help me on the side that isn't mine", "fullstack task" | `fullstack` |
| "change several repos at once", "coordinate front and back in separate repos", "which fronts consume this back", "what order do I deploy them" | `workspace` (multi-repo coordination) |
| "integrate with GitHub/observability/analytics", "send an event/telemetry" | `integrations` |
| "publish/consume a Kafka event", "topic/queue/DLQ", "evolve an Avro schema" | `integrations` (→ `integrations/references/event-bus.md`) |
| "personal data", "GDPR/LGPD", "can this leak PII?", "consent" | `privacy` |
| "how are we doing", "engineering metrics", "dashboard", "DORA" | `health` |
| "how much did this cost", "how many tokens", "efficiency", "what should we charge for this feature" | `cost` |
| "what's the most efficient/cheapest way", "which model should I use", "parallelize with agents" | `agentic-flow` |

## When they ask "what can you do?"

Answer in plain language, no skill jargon. Something like:

> I help you work inside the engineering standard. I can build a feature from start to PR; review
> code before merge; get you into a new or existing project and document it; check security (OWASP),
> UX and accessibility; investigate a production problem; wire up integrations; handle personal data
> properly; and show the engineering metrics on a dashboard. Just tell me what you need, your way.

## Routing principles

- **The flow rules; the route only picks the door.** Any request that touches code runs the 6 steps
  in order — neither the person's hurry nor the change's simplicity reorders or removes a step (a
  small change **condenses** step 3, it does not skip 1, 2, 4, 5 or 6). Asked to skip? One line
  explaining what is missing, **do the step**, and move on; if the person insists, `bypass` with
  their reason plus a note in the summary.
- **If it is not configured yet** (tools not connected, no team config), offer `setup` first, simply.
- **Act with what you have.** If the intent is clear, follow the route and start — do not return a
  list of options.
- **One question only when something essential is missing** (the clarify step). Assume reasonable
  defaults and state the assumption.
- **Always under the standard.** Every route inherits the constitution (P1–P8) and the
  security/quality guardrails.
- **Combine when it makes sense.** A "whole feature" request → the `ship` combo, not one isolated skill.
