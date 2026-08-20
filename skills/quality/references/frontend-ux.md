# Front end and UX

Every screen and flow is assessed here before it is "done". Three lenses: usability (Nielsen),
accessibility (WCAG) and perceived performance (Core Web Vitals).

## Nielsen's heuristics — the review pass

Applied in full in `design-review/references/nielsen-heuristics.md`. The short version, as a review
checklist:

1. **Visibility of system status** — the user always knows what is happening (loading, saved, failed).
2. **Match with the real world** — the user's vocabulary, not the database's.
3. **User control and freedom** — an obvious way out; undo over confirmation where reversible.
4. **Consistency and standards** — the same problem solved the same way across the product.
5. **Error prevention** — better than a good error message; confirm destructive actions by name.
6. **Recognition over recall** — options visible, not memorized.
7. **Flexibility and efficiency** — shortcuts for frequent users without confusing new ones.
8. **Aesthetic and minimalist design** — every extra element competes with the important one.
9. **Help users recover from errors** — plain language, the cause, and the next step.
10. **Help and documentation** — findable, task-oriented.

## Accessibility — WCAG 2.2 AA (the floor)

The how-to lives in `accessibility-wcag.md`. The non-negotiables:

- **Contrast** 4.5:1 for text, 3:1 for large text and functional icons.
- **Keyboard**: everything operable, with a visible focus ring, in a logical order, with no trap.
- **Semantics**: `button` for actions, `a` for navigation, headings in order, labels tied to inputs.
- **Never color alone** to convey state — color + icon + text.
- **Touch targets** at least 44×44px.
- **Motion** respects `prefers-reduced-motion`.

An open accessibility issue is a **blocker**, not a nice-to-have. It is also the cheapest thing to
get right at design time and the most expensive to retrofit.

## Perceived performance — Core Web Vitals

| Metric | Good | What usually breaks it |
|---|---|---|
| **LCP** (largest contentful paint) | ≤ 2.5s | unoptimized hero image, render-blocking resources, slow API on the critical path |
| **INP** (interaction to next paint) | ≤ 200ms | heavy JS on the main thread, uncontrolled re-renders |
| **CLS** (cumulative layout shift) | ≤ 0.1 | images with no dimensions, fonts swapping, content injected above the fold |

Measure with real user monitoring, not only a lab score. A lab test on a fast laptop hides what a
mid-range phone on 4G experiences.

## The four states, always

Every data container handles **empty, loading, error and success**. This is the single most common
gap between "the demo worked" and "production is broken":

- **Loading** — a skeleton over a spinner; feedback within 100ms of any click.
- **Empty** — say what to do now; an empty state with no exit action is a dead end.
- **Error** — the cause in the user's language plus the next step; never a stack trace or an error code.
- **Success** — visible confirmation, and the data actually refreshed.

## In the flow

- **Before coding:** `design-review` validates the layout against the Design Constitution.
- **While coding:** `design-system` (components and tokens).
- **Before the PR:** `preflight` step 1.5 drives the live app and checks console/network.
- **QA:** `qa/references/ux-a11y-qa.md`.
