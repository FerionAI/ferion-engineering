---
name: design-review
description: "The pre-code design gate — validates a layout/design against the Design Constitution (memory/design-constitution.md) BEFORE building, catching problems while they are cheap. It is the pre-code 'UX linter', with BLOCKING/HIGH/MEDIUM severities. Use when reviewing a layout or Figma file before coding, when creating a new screen from the spec with no designer, or when someone says 'is this design ready to build?', 'validate this layout', 'review the Figma', 'how would this screen look in our standard'. Accepts a Figma link, a screenshot or a description. Returns a verdict + findings by severity + the design system component plan — it does not generate pixels (that is frontend-design/Figma). The pre-build counterpart of review."
---

# design-review — UX linter (the design gate before coding)

Fixing a layout in a mockup is cheap; refactoring an already-coded component is expensive. This skill
is the **pre-code UX linter**: it validates the design against the **Design Constitution**
(`memory/design-constitution.md`) and is the pre-build counterpart of `review`. It does not generate
the mockup (that is `frontend-design`/Figma); it **validates** and returns a buildable plan in the
standard.

## Input (adapt to whatever exists)

- **Figma:** read it through the **Figma MCP** (`get_design_context`, `get_metadata`,
  `get_screenshot`, `get_variable_defs`) — see `integrations`.
- **Screenshot/image:** analyze the visual directly.
- **Only the spec/description (no designer):** propose the structure in the design system's shape and
  validate that.

## How to validate

Run the **constitution's rules** (`memory/design-constitution.md`), marking each by severity —
**❌ [BLOCKING]** · **⚠️ [HIGH]/[MEDIUM]** · **✅ ok**. Load the reference layers as the screen needs:

| Dimension | Where |
|---|---|
| The hard rules (nav, hierarchy, forms, states, destructive actions, language, a11y, DS) + anti-patterns | `memory/design-constitution.md` |
| Numbers (4/8 spacing, typography, color/contrast, motion, dark mode, perceived performance) | `references/visual-references.md` |
| The pattern for that screen type (form, list/table, empty, modal/toast, search, mobile, microcopy) | `references/screen-patterns.md` |
| Nielsen heuristics (all ten, applied) | `references/nielsen-heuristics.md` |
| Run before calling it done | `references/delivery-checklist.md` |

**The unique value — the design system (constitution §21–24):** does the design map to components
that exist in the project's design system? Where a component **is not in the code yet** (every design
system is a partial implementation of its own target), compose it following the constitution and
**record the gap** — do not improvise outside the standard and do not invent a component (escalate if
needed). Detail in `design-system`.

## Output

- **Verdict:** ready to build · adjust first · **blocked** (any open [BLOCKING] or a11y issue).
- **Findings by severity:** each with the rule (constitution number), the screen/snippet and the fix —
  the linter format.
- **Design system component plan:** the component tree + tokens + the states (empty/loading/error).
- **Design system gap report:** what the design needs that the **code** does not have yet → compose
  it following the constitution and evolve the design system.
- **Next step:** `frontend-design`/Figma to materialize the mockup; `fullstack`/`design-system` to
  build. Nothing moves with an open [BLOCKING] or a11y issue.

## In the flow

- **`ship`:** runs **before the vertical slice** when the change has UI (the design step).
- **`spec-flow` (plan):** new UI → passes through here before implementing.
- **`design-system`:** construction uses the constitution + the design system code (compose where the
  code lags).
- **`discovery`:** brings the user's voice (empathize/test); design-review is the critique against the
  standard.
- **`review`/`qa`:** they pick up code and tests later; design-review keeps design problems from ever
  reaching them.
