# Accessibility — the how-to (WCAG 2.2 AA)

`frontend-ux.md` says what the floor is. This is how to actually build it.

## Semantics first (it does 80% of the work)

Native HTML is accessible by default; every ARIA attribute you add is a chance to break that.

```html
<!-- yes -->
<button type="button" onclick="save()">Save changes</button>
<a href="/settings">Settings</a>
<label for="email">Email</label><input id="email" type="email" />

<!-- no -->
<div class="btn" onclick="save()">Save changes</div>   <!-- not focusable, not a button -->
<span onclick="navigate()">Settings</span>              <!-- not a link, no keyboard -->
<input placeholder="Email" />                            <!-- placeholder is not a label -->
```

**Rule of thumb:** the first rule of ARIA is not to use ARIA. Reach for it only when no native
element expresses the pattern.

## Keyboard

- Every interactive element reachable with `Tab`, in a logical order (DOM order = visual order).
- **Visible focus ring** — never `outline: none` without a replacement. `:focus-visible` is your friend.
- `Escape` closes overlays; `Enter`/`Space` activate; arrow keys move within a composite widget
  (tabs, menu, listbox).
- **Focus trap in a modal:** focus moves into the dialog on open, cycles inside it, and returns to the
  trigger on close. Without this, a screen reader user is left behind the overlay.
- Skip link to the main content on pages with heavy navigation.

## Screen readers

- **Headings in order** (`h1` → `h2` → `h3`), one `h1` per page. They are the navigation structure.
- **Accessible name** on every control: visible label, `aria-label`, or `aria-labelledby`. An icon-only
  button with no name is unusable.
- **Landmarks**: `main`, `nav`, `header`, `footer`, `aside`.
- **Live regions** for async updates: `aria-live="polite"` for status, `assertive` only for errors
  that interrupt. A toast nobody announces did not happen.
- **`aria-describedby`** to tie a field to its error message and helper text.
- Decorative images `alt=""`; meaningful images get a real description; complex images get a longer
  description nearby.

## Forms

- Visible label, always. `aria-required`, and errors tied with `aria-describedby` + `aria-invalid`.
- The error message says **what is wrong and how to fix it**, in text, next to the field — not only in
  red.
- On submit failure, move focus to the first error (or to a summary at the top listing them).

## Color and motion

- Contrast: 4.5:1 body text, 3:1 large text (≥ 24px, or ≥ 19px bold) and functional icons/borders.
- **Never color alone**: state = color + icon + text.
- `@media (prefers-reduced-motion: reduce)` disables non-essential animation.

## Testing it

| Level | Tool | Catches |
|---|---|---|
| Automated | axe / Lighthouse in CI | ~30–40% of issues (contrast, missing names, bad semantics) |
| Keyboard | your own `Tab` key, 2 minutes | focus order, traps, invisible focus |
| Screen reader | NVDA / VoiceOver on the key flow | names, order, live regions |

Automated testing alone is not accessibility testing. The keyboard pass costs two minutes and finds
what axe cannot.
