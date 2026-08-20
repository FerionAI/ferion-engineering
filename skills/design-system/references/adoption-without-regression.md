# Migrating to the design system without regression

Adoption is progressive and never blocks a deploy — but when a migration does happen, it must not
break what worked. A "pure refactor" that silently changes behavior is the most annoying class of
regression, because nobody is looking for it.

## Where to start

Not with the hardest screen, and not with everything at once:

1. **New UI** — born in the design system. Free, and it stops the debt from growing.
2. **High-traffic screens** — the biggest consistency win per unit of effort.
3. **Leaf components** (button, badge, input) before composites — the composites will inherit.
4. **Never a big-bang rewrite.** A migration PR touching 200 files cannot be reviewed, and it will sit
   open until it conflicts with everything.

## One component at a time

For each component you replace, check the four dimensions:

| Dimension | What to verify |
|---|---|
| **Visual** | before/after screenshots at the same viewport. Small differences are expected; a changed layout is not. |
| **Behavior** | every state: hover, focus, disabled, loading, error, and the actual click handler |
| **Accessibility** | keyboard, focus ring, accessible name, roles — a11y usually *improves*, but verify rather than assume |
| **Tests** | selectors change. A test that used a CSS class breaks; one that used a role or a `data-testid` survives — this migration is a good moment to fix that |

## The traps

- **Props with the same name and different semantics.** `size="small"` in the old library and in the
  new one may be different pixel values. Check, do not assume.
- **Default changes.** The old button was `type="button"` by default; the new one submits the form.
  This one has caused real production bugs.
- **Spacing built into the component.** If the old one had internal margin and the new one does not,
  every layout using it shifts.
- **Event signature.** `onChange(value)` vs `onChange(event)` — the typecheck catches it in TypeScript,
  and nothing catches it otherwise.

## Visual regression

If the project has visual regression tooling (Chromatic, Percy, Playwright screenshots), a migration
PR is exactly what it is for. If it does not, take manual before/after screenshots of the affected
screens and attach them to the PR — it costs two minutes and it is the only evidence a reviewer can
actually check.

## Scope discipline

**A migration PR migrates.** It does not also fix a bug, rename a variable or improve the layout.
Mixing them makes the diff unreviewable and makes a bisect useless when something breaks. If you find
a bug while migrating, open an issue.

## What is not negotiable

Adoption is progressive; **accessibility and behavior are not**. A migration that loses a keyboard
interaction, drops an accessible name or changes what a button does is a regression, not a step
forward — and it does block the merge, unlike design system conformance itself.
