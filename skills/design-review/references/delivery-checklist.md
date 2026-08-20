# Delivery checklist — run before calling ANY screen done

Ten minutes. It catches the class of problem that otherwise reaches QA, or a user.

## States (the most common gap)

- [ ] **Empty** — says what this is and offers an action. Not "No data".
- [ ] **Loading** — a skeleton shaped like the content; feedback within 100ms of the click.
- [ ] **Error** — the cause in plain language + the next step; nothing typed is lost.
- [ ] **Success** — visible confirmation, and the data actually refreshed.
- [ ] **Partial** — one item failed out of ten: is that visible, or silently swallowed?

## Content and hierarchy

- [ ] One primary action, visually dominant. Secondary actions are subordinate.
- [ ] The user knows where they are (title/breadcrumb) and how to get back.
- [ ] Labels in the user's vocabulary — no enum, no database field name, no internal jargon.
- [ ] Buttons name the action ("Save changes"), not a generic verb ("Submit", "OK").
- [ ] Consistent naming with the rest of the product.

## Forms (if there is one)

- [ ] Every field has a visible label.
- [ ] Validation on blur, with a specific, actionable message next to the field.
- [ ] Data preserved on error; focus moved to the first error on failed submit.
- [ ] Optional fields marked, not required ones.

## Destructive actions

- [ ] Confirmation names the object and the verb, or there is an undo.
- [ ] Undo preferred where the action is reversible.

## Accessibility (blocking)

- [ ] Keyboard: complete the whole flow with `Tab`; focus always visible; `Escape` closes overlays;
      no trap.
- [ ] Contrast 4.5:1 text, 3:1 large text and functional icons.
- [ ] No state conveyed by color alone.
- [ ] Correct semantics (`button` for actions, `a` for navigation, headings in order).
- [ ] Every control has an accessible name (icon-only buttons included).
- [ ] Touch targets ≥ 44×44px.
- [ ] axe clean on the flow.

## Design system

- [ ] Components from the project's design system; nothing recreated that already exists.
- [ ] Tokens for color, spacing, typography, radius — no hex, no magic px.
- [ ] Gaps recorded (what the design needs that the code does not have yet).

## Performance and responsiveness

- [ ] No layout shift when data arrives (space reserved).
- [ ] Works at 320px wide and at 200% zoom.
- [ ] Tested throttled (4x CPU, slow network), not only on a fast machine.
- [ ] Console and network clean — no errors, no unexpected 4xx/5xx.

## Before the PR

- [ ] Screenshots of the key states attached to the issue.
- [ ] Any [BLOCKING] finding from `design-review` resolved.
- [ ] `preflight` step 1.5 (devserver validation) run, if the change is medium or high tier.

> Anything found here that should have been caught at design time is a signal that the design gate
> (`design-review`) was skipped. Fixing it here costs ten times what it would have cost in the mockup.
