# Writing less code — the decision ladder

The best code is the code never written. Every line is a line to review, test, debug at 3am and
eventually delete. Before writing, climb the ladder and stop at the first rung that holds.

## The ladder

1. **Does this need to exist at all?** A speculative need is not a need. Skip it, and say in one line
   that you skipped it.
2. **Is it already in this codebase?** A helper, a util, a type, a pattern that already lives here —
   reuse it. Re-implementing what sits three files over is the most common form of waste.
3. **Does the standard library do it?** Use it.
4. **Does a native platform feature cover it?** `<input type="date">` over a date-picker library, CSS
   over JS, a database constraint over application code.
5. **Does an already-installed dependency solve it?** Use it. Never add a new dependency for what a
   few lines can do.
6. **Can it be one line?** Make it one line.
7. **Only then:** the minimum code that works.

Two rungs work? Take the higher one and move on. The first lazy solution that works is the right one.

## The ladder runs after understanding, never instead of it

This is the part that goes wrong. The ladder shortens the *solution*; it never shortens the *reading*.
Trace the actual flow end to end — every file the change touches — and only then climb. The smallest
change in the wrong place is not efficiency, it is a second bug wearing efficiency's clothes.

**Bug fix = root cause, not symptom.** A report names a symptom. Before editing, grep every caller of
the function you are about to touch. The lazy fix *is* the root-cause fix: one guard in the shared
function is a smaller diff than a guard in every caller — and patching only the path the ticket names
leaves every sibling still broken (`qa/references/verify-and-gate.md`).

## Rules

- **No unrequested abstractions:** no interface with one implementation, no factory for one product,
  no config for a value that never changes.
- **No scaffolding "for later".** Later can scaffold for itself.
- **Deletion over addition.** The best PR in a week is often the one that removes something.
- **Boring over clever.** Clever is what someone decodes at 3am.
- **Fewest files possible.** The shortest working diff wins — once you understand the problem.
- **Two options the same size?** Take the one that is correct on the edge cases. Writing less code
  never means picking the flimsier algorithm.

## What never gets cut

Input validation at trust boundaries, error handling that prevents data loss, security measures,
accessibility basics, and anything explicitly requested. Efficiency that breaks one of those is not
efficiency, it is debt with a nicer name (P8, `quality`).

## Marking a deliberate shortcut

When you knowingly cut a corner with a known ceiling (a global lock, an O(n²) scan over a list you
believe stays small, a naive heuristic), leave a comment naming the ceiling and the upgrade path:

```python
# shortcut: global lock; move to per-account locks if throughput matters
```

A recorded shortcut is a decision. An unrecorded one is a trap for whoever finds it next.

## The token connection

Less code is also fewer tokens: less to generate, less to re-read on every subsequent turn, less to
review, less to maintain. It is the same lever as `efficient-responses.md`, applied to the artifact
instead of the answer — and it is measurable (`cost/references/efficiency-and-pricing.md`).
