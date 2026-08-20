# Visual references — the numbers

The Design Constitution states the rules; these are the values that make them checkable. Override any
of them with your design system's tokens — what matters is that a scale exists and that nothing is
arbitrary.

## Spacing — the 4/8 scale

```
4  8  12  16  24  32  48  64  96
```

Everything is a token from this scale (`space-1` … `space-n`). **No arbitrary value** — 13px, 27px
and 35px are the signature of a layout assembled by nudging.

Rule of proximity: related elements get a smaller gap than the gap to the next group. A form where
label-to-field and field-to-field use the same spacing reads as one undifferentiated block.

## Typography

| Role | Size | Weight | Line height |
|---|---|---|---|
| Display | 32–40 | 600 | 1.2 |
| H1 | 24–28 | 600 | 1.25 |
| H2 | 20 | 600 | 1.3 |
| H3 | 16–18 | 600 | 1.4 |
| Body | 14–16 | 400 | 1.5 |
| Small / caption | 12–13 | 400 | 1.45 |

- **Body text never below 14px.** 12px is for metadata, not for content.
- **Line length 45–75 characters** for readable prose. A full-width paragraph on a 27" monitor is
  unreadable.
- At most **two typefaces**, and prefer one with a weight range.

## Color

- **Semantic tokens only** in the UI (`fg-primary`, `bg-subtle`, `border-error`). The raw scale
  (`gray/500`) exists to define tokens, never to be used directly — that is what makes theming and
  dark mode possible.
- **Contrast:** 4.5:1 for body text, 3:1 for large text and functional icons/borders. Check it, do
  not eyeball it.
- **Never color alone** to convey state: color + icon + text.
- **Semantic colors** (success/warning/error/info) mean one thing each, everywhere.

## Radius, elevation, borders

- Radius from a scale (`0 / 4 / 8 / 12 / full`) — consistent per component type.
- **Elevation communicates layering**, not decoration: a card is not a modal is not a dropdown. Two or
  three levels are enough; five means none of them mean anything.
- Prefer a border over a shadow for a subtle separation — it survives dark mode better.

## Motion

| Purpose | Duration | Easing |
|---|---|---|
| Micro (hover, focus, toggle) | 100–150ms | ease-out |
| Transition (panel, dropdown) | 200–250ms | ease-in-out |
| Entrance (modal, drawer) | 250–300ms | ease-out |

- **Over 400ms feels slow**; under 100ms is not perceived. Animation is feedback, never decoration.
- Respect `prefers-reduced-motion`.
- **Never loop an animation** outside of a loading state.

## Dark mode

Through surface tokens, never by inverting colors. Pure black (`#000`) and pure white text is harsh —
use a near-black surface and a near-white foreground. Re-check contrast in both themes; a pair that
passes in light frequently fails in dark.

## Perceived performance targets

- Feedback within **100ms** of any click (a state change is enough).
- Skeleton, not spinner, above **400ms**.
- LCP ≤ 2.5s · INP ≤ 200ms · CLS ≤ 0.1 (`quality/references/frontend-ux.md`).
- Reserve space for anything that loads, or you have built a layout shift.
