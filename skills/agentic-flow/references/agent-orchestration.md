# Summoning subagents with cost discipline

A subagent is a second context. It pays off in exactly three situations, and it is waste in every
other one.

## When it pays off

1. **Real parallelism.** Several independent tasks with no shared state and no sequential dependency —
   three files to analyze, four dimensions to review. They run concurrently instead of serially.
2. **Context isolation.** A task that requires reading 50 files to produce one paragraph. The
   subagent reads them; only the paragraph comes back. Your context never sees the 50 files — this is
   usually *cheaper* than doing it inline, not more expensive.
3. **Independent verification.** The author cannot see their own error. A verifier that did not write
   the code, with a mission to **reject** it, sees what the author cannot
   (`preflight` step 4).

## When it does not

- A task you could finish in two tool calls. Spawning costs a full context setup.
- Anything needing back-and-forth with the user — the subagent cannot ask.
- Sequential work where each step depends on the last: that is just a slower version of doing it
  yourself.
- Splitting one coherent edit across agents. They will conflict, and merging their output costs more
  than the edit did.

## Writing the prompt

A subagent has no conversation history. Everything it needs goes in the prompt:

```
Context:  <what it needs to know — paths, constraints, what was decided>
Task:     <exactly one objective, stated as a deliverable>
Return:   <the shape of the answer you want back>
Do not:   <the traps — do not modify files, do not expand scope>
```

The most common failure is an under-specified prompt producing a confident, useless answer. The
second most common is a prompt so long it costs more than the work.

## Adversarial verification (the highest-value pattern)

For a risky change, do not ask "is this correct?" — ask the verifier to **refute** it:

> "Try to reject this change. Find anything invented (an API, a component, an import that does not
> exist), any standard violation, anything a review bot would flag. Default to rejecting if you are
> uncertain."

For critical changes, run several verifiers with **different lenses** — correctness, security,
"does the test actually prove anything?" — rather than three identical ones. Diversity finds failure
modes that redundancy cannot.

## Cost discipline

- **Bound the fan-out.** Ten parallel agents on a task worth two is not thoroughness, it is a bill.
- **Do not have an agent do what a `grep` does.** Search is cheap; agents are not.
- **Never fabricate a pending agent's result.** If it has not returned, say it has not returned.
- **Report what was skipped.** If you bounded the coverage (top-N, sampling), say so — silent
  truncation reads as "covered everything" when it did not.

## In this plugin

The one place a subagent is effectively mandatory is `preflight` step 4: independent verification
before the PR. Everywhere else, justify it against the three cases above.
