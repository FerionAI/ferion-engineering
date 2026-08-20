# Design Constitution (v1)

> **Single source of truth for UX/UI** when producing digital products (with AI — Claude Code,
> Cursor, Lovable, Replit — or by hand). The counterpart of the engineering constitution
> (`memory/constitution.md`): that one is the code standard, this one is the design standard.
>
> **How to use it.** These are the **hard rules** (verifiable assertions), always in context when
> working on UI. The numbers (spacing/type/color/motion scales), the per-screen-type patterns and
> the Nielsen heuristics live in reference layers, loaded on demand:
> `skills/design-review/references/` (`visual-references.md`, `screen-patterns.md`,
> `nielsen-heuristics.md`, `delivery-checklist.md`). `design-review` is what **validates** against
> this constitution (the pre-code "UX linter"); `design-system` is what **builds**.
>
> **How to adapt it.** Rules 1–20 are product-agnostic and should survive as they are. Rules 21–24
> bind this constitution to *your* design system and stack — that is where `<FILL: ...>` lives, and
> `design-system` discovers most of it from the codebase.

**Version:** 1.0.0 · **Owner:** `<FILL: who owns design>` · **Complements:** P7 of the engineering constitution.

## Severity
- **[BLOCKING]** violated → does not ship (`design-review`/the linter rejects it).
- **[HIGH]** fix before considering it done.
- **[MEDIUM]** fix when possible; record the debt.

## Non-negotiable principles (tie-breakers)

When two rules collide, decide in this order:

1. **Clarity above all.** If the user has to stop and think, it is wrong.
2. **Prevent error > correct error > visual density.** Never trade error prevention for aesthetics.
3. **Familiar > clever.** A known pattern beats a "creative" solution. Do not reinvent the checkbox.
4. **Consistency > personal preference.** Same problem = same solution across the product.
5. **Always give feedback.** Every action has a visible response within 100ms.
6. **Accessible by default.** Without keyboard operation and sufficient contrast, it is not done.
7. **Start from a good skeleton** (template or pattern), never from a blank screen.

## Rules

### Navigation and information architecture
1. **[BLOCKING]** Every screen answers: where am I (visible title/breadcrumb), where can I go, how do I get back. No orphan screens.
2. **[HIGH]** At most 7 items at the top navigation level; group beyond that.
3. **[HIGH]** Shallow structure: no essential flow deeper than 3 levels; any screen in ≤ 3 clicks.
4. **[HIGH]** The active navigation item is always highlighted. Menu names follow the **user's task**, not the internal team structure.

### Hierarchy and layout
5. **[HIGH]** One single primary action per screen, visually dominant; secondary actions subordinate in weight.
6. **[MEDIUM]** Content grouped by semantic relationship, not as a flat list. Above 7 fields/items in a block, split into sections.
7. **[HIGH]** Spacing on the 4/8px scale via tokens (`space-*`). No arbitrary values (13px, 27px). Numbers in `visual-references.md`.

### Forms and data entry
8. **[BLOCKING]** Every field has a **visible label**. A placeholder is not a label.
9. **[HIGH]** Inline validation on blur, with a specific, actionable message (what is wrong and how to fix it). Never just "invalid field".
10. **[HIGH]** Preserve typed data on error. Never clear the form. Autofocus the first field.
11. **[MEDIUM]** Ask only for what you need; mark what is **optional**, not what is required. A long form becomes steps with progress.

### System states
12. **[HIGH]** An action that takes > 400ms shows feedback (skeleton/spinner/optimistic update). Feedback within ≤ 100ms for any click (button state change). Zero dead clicks.
13. **[HIGH]** Every data container handles **four states**: empty, loading, error, success. The empty state says what to do now (it has an exit action).
14. **[HIGH]** An error shows the cause in the user's language + the next step. Never a raw code, stack trace, enum or database field name.

### Destructive actions and error prevention
15. **[BLOCKING]** A destructive action requires a confirmation that **names the object** and uses a button carrying the action verb ("Delete invoice", not "OK"/"Confirm").
16. **[MEDIUM]** Prefer **undo** over a confirmation dialog when the action is reversible.

### Language and content
17. **[HIGH]** Labels in the user's domain vocabulary; never a database field name, raw enum or internal jargon. Consistent naming across screens (if it is "student" on one screen, it is not "user" on another).
18. **[MEDIUM]** `<FILL: your brand voice — tone, button and confirmation formulas, product language>`. A button describes the action ("Save changes", not "Submit"). Confirmations name the consequence ("Yes, delete 3 items").

### Accessibility
19. **[BLOCKING]** WCAG 2.2 AA: text contrast 4.5:1 (3:1 for large text and functional icons). Information **never** depends on color alone (color + icon + text). Ties into P7 and `quality/references/frontend-ux.md`.
20. **[HIGH]** Every interactive element operable by keyboard with a **visible focus ring**. Minimum touch target 44×44px. Correct HTML semantics (`button` for actions, `a` for navigation, headings in order).

### Consistency and design system

> **Reconciliation (source of truth):** this constitution is the **target**; your design system
> package is a **partial** implementation of it. Where a component **does not exist in code yet**,
> compose it following this constitution — do not improvise outside the standard. Check the app's
> `package.json` for what is actually available. Detail in `design-system`.

21. **[BLOCKING]** Use the project's design system components. Do not recreate what already exists.
    - `<FILL: the component inventory — `design-system` discovers it from the package exports/Storybook and records it here>`.
    - If what you need is not in the inventory → **escalate before recreating**. Do not improvise a substitute.
22. **[BLOCKING]** Color, spacing, typography, radius and width come from the design system's **semantic tokens**. No hardcoded hex, no arbitrary value in `style`, no raw primitive in JSX.
    - **Semantic tokens (use these):** the role-named layer — `border-*`, `fg-*`, `bg-*`, `space-*`, `radius-*`, plus `-hover`/`-disabled`/`-subtle` variants.
    - **Primitives (never used directly):** the raw scales (`gray/500`, `brand/400`) only ever define a semantic token.
    - Dark mode through surface tokens (`bg-primary` responds to the color mode), never a manual inversion.
23. **[BLOCKING]** `<FILL: the front-end stack this constitution assumes — framework, styling, component base, and what is forbidden without approval>`. Whatever it is, it is **fixed**: mixing a second component library or a runtime CSS-in-JS layer into a codebase that already chose one is a consistency violation, not a preference.
24. **[HIGH]** The final look follows the design system's visual language (typography, spacing, density, hierarchy), not the defaults of whichever headless/component library sits underneath it.

## Forbidden anti-patterns (quick linter pass)
- Full-screen spinner for everything (use a skeleton). · Placeholder as label. · Clearing the form when one field fails.
- Color as the only state indicator. · More than one primary action competing. · **Modal on top of modal**.
- Generic buttons ("OK", "Submit", "Confirm", "Click here"). · Destructive action with neither confirmation nor undo.
- Hover as the only way to discover an action. · Technical error exposed ("NullPointerException", "Error 500").
- Media autoplay with sound. · Password field without a visibility toggle. · Generic link text ("click here", "learn more").
- Automatic redirect without feedback. · Continuously looping animation outside of loading.

## How an agent should use this constitution
- **Before building UI:** validate the layout with `design-review` (Figma/screenshot/description) — every open [BLOCKING] is a rejection.
- **While building:** `design-system` (components + tokens); where the code lags behind, compose following §21–24.
- **Before calling it done:** run `delivery-checklist.md`.
