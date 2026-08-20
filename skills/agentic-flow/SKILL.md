---
name: agentic-flow
description: How to work WITH AI agents efficiently and cheaply — writing less code, optimizing responses, choosing the right model for each part of the task, summoning subagents with cost discipline, and using the right tools for design, brainstorming and requirements. Use when starting any AI work, deciding which model/agent to use, when something is expensive or slow in tokens, or when someone asks "what's the most efficient way to do this with AI". It is the meta layer that orchestrates the other skills.
---

# Efficient agentic development

You orchestrate AI work for maximum value with minimum waste (tokens, time, code). Efficiency here
is not doing less — it is **not doing the unnecessary**.

This skill is the index of the meta-flow. Load only the reference relevant to the moment.

| When | Reference |
|---|---|
| I am about to write/change code | `references/write-less-code.md` |
| I am about to answer / produce output | `references/efficient-responses.md` |
| Which model to use for this step | `references/model-selection.md` |
| I need to parallelize / verify / research broadly | `references/agent-orchestration.md` (subagents) |
| Design, brainstorming or gathering requirements | `references/tools.md` |
| Parallelize through fullstack people (front↔back) | the `fullstack` skill |

## The lifecycle of a task (overview)

1. **Understand before acting.** Read what you need to genuinely understand the problem. Lazy in the
   solution, never in the reading. Skipping research is negligence, not efficiency.
2. **Pick the right model** for the step (`model-selection.md`): cheap and fast for mechanical work,
   strong for architecture and verification.
3. **Specify** (skill `spec-flow`) when the change is non-trivial.
4. **Write the minimum that works** (`write-less-code.md`), reusing what already exists.
5. **Summon subagents** only when they pay off (`agent-orchestration.md`): real parallelism, isolating
   a large context, or independent verification.
6. **Verify** against the Definition of Done and the `quality` rules.
7. **Answer tersely** (`efficient-responses.md`): high signal, zero filler.

## The three efficiency principles

- **Less code.** The best code is the code you did not write. Reuse > write; stdlib/native > a new
  dependency; one line > a framework. Detail in `write-less-code.md`.
- **Fewer tokens per result.** Progressive disclosure, batched tool calls, never re-reading what you
  already know, minimal context scope, direct answers. `efficient-responses.md`.
- **Model/agent proportional to the task.** Do not use a frontier model to rename a variable, or a
  small one to design a critical architecture. `model-selection.md`.

## Non-negotiable guardrails (do not cut these for efficiency)

Aligned with `quality`: **validation at trust boundaries, data-loss handling, security and
accessibility never go under the knife.** Efficiency that breaks security or a11y is not efficiency —
it is debt.
