# Toolkit by phase — design, brainstorming and requirements

The right tool for the moment, so the agent stops defaulting to "write code" for problems that are
not code problems yet.

## Understanding the problem (before any spec)

| Need | Tool |
|---|---|
| The problem itself is vague | `discovery` — empathize with the data you already have |
| The data exists but nobody read it | product/session analytics through `integrations` |
| The requirement is clear but ambiguous in the details | the `clarify` step of `spec-flow` — questions on the issue |
| It is a bug, not a feature | observability first (find the real failure), then `spec-flow` for the root cause |

**The signal that you are in the wrong phase:** you are writing code and still discovering what the
thing should do. Stop and go back to the spec.

## Brainstorming and deciding

- **Diverge before converging.** Two or three genuinely different approaches, from different angles
  (smallest thing that works / lowest risk / best experience), before evaluating any of them. The
  first idea evaluated alone always wins by default.
- **Converge on criteria, not enthusiasm:** impact × effort × risk. State the recommendation and the
  reason, not a survey of options.
- **YAGNI ruthlessly** at this stage — it is far cheaper to remove a feature from a design than from
  a codebase.
- **Record the decision** in the plan, and as an ADR when it is architectural (P5/P6).

## Asking the user

One question at a time, and only when the answer **changes what you build**. Prefer multiple choice
with a recommended default — it is faster to answer and it surfaces the trade-off.

Do not ask about: something the code can answer (read it), something you can reasonably default
(default it and say so), or something already settled earlier in the conversation.

Do ask about: which of two materially different designs, anything irreversible, anything where being
wrong wastes the whole task.

## Design and UI

| Need | Tool |
|---|---|
| Validate a layout before building | `design-review` (the pre-code UX linter) |
| Build UI in the project's system | `design-system` |
| Read a Figma file | the Figma MCP (`integrations`) |
| Drive the live app to check it | Playwright MCP (`preflight` step 1.5) |

## Working with the repository

- **`glob`/`grep` to locate, read to understand.** In that order.
- **`gh` for everything GitHub** — issues, PRs, labels, search. No MCP required.
- **The flow gate tells you where you are:** `flow-gate.sh status` before assuming anything about
  what is done.

## The meta-rule

Every tool here exists to avoid writing code you would later delete. The expensive mistake in agentic
development is not slow code — it is fast code that solved the wrong problem.
