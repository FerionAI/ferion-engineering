# Patterns by screen type

Each screen type has a known solution. Reaching for a creative one is how a product becomes hard to
learn (constitution principle 3: familiar beats clever).

## Form

- **Visible label** on every field; a placeholder is an example, never a label.
- One column. Multi-column forms are misread; the exception is a genuinely paired field
  (city/state, expiry/CVC).
- Group related fields into sections above ~7 fields; a long form becomes steps with visible progress.
- **Validate on blur**, not on every keystroke (which yells at someone mid-typing) and not only on
  submit (which hides the problem until the end).
- The error message says **what is wrong and how to fix it**, next to the field.
- **Never clear the form on error.** Autofocus the first field; on a failed submit, move focus to the
  first error.
- Mark **optional** fields, not required ones — usually there are fewer of them.
- One primary action; cancel is secondary and never the same visual weight.

## List / table

- The **four states** always: empty, loading (skeleton with the shape of the rows), error, populated.
- Pagination or virtualization decided from the start — "it's fine, there won't be many" is a
  prediction, not a design.
- Sortable/filterable columns show their state; the applied filter is visible and clearable.
- Row actions: at most two visible, the rest in an overflow menu. **Never hover-only** — that hides
  the action on touch and from keyboard users.
- Bulk selection shows the count and what will happen.
- Align numbers right, text left. Truncate with a tooltip and the full value available.

## Empty state

The most neglected screen, and the first one a new user sees. It needs: **what this is**, **why it is
empty**, and **an action to fill it**. An empty state that is just "No data" is a dead end.

Distinguish "empty because it is new" from "empty because your filter matched nothing" — the second
needs a clear-filter action, not a create action.

## Modal / dialog

- For a decision or a short focused task. Not for a whole flow — that is a page.
- **Never a modal over a modal.** If you need it, the flow is wrong.
- Focus moves in on open, is trapped, and returns to the trigger on close. `Escape` closes.
- A destructive confirmation **names the object and uses the action verb**: "Delete invoice #123",
  not "OK".
- Non-critical? Prefer an inline expansion or an undo toast over a dialog.

## Toast / notification

- Success: brief, auto-dismissing, non-blocking. Error: persists until dismissed.
- Announce it to screen readers (`aria-live`) or it did not happen for a whole class of users.
- **Undo lives in the toast** — that is the pattern that replaces the confirmation dialog.
- Never put critical information only in a toast; it disappears.

## Search

- Show what was searched and how many results.
- **No results** is an empty state with suggestions (spelling, broader terms, popular items), not a
  blank page.
- Debounce, but show that something is happening.
- Preserve the query in the URL so it can be shared and reloaded.

## Detail page

- Answers immediately: what is this, what state is it in, what can I do with it.
- The primary action is visible without scrolling.
- Related items and history below; do not make the top of the page a wall of metadata.

## Mobile

- Touch targets ≥ 44×44px, with spacing between them.
- The primary action within thumb reach; do not put it in a top corner.
- No hover-dependent interaction, ever.
- Test on a real mid-range device on a throttled connection, not on a simulator on fibre.

## Microcopy

- Buttons describe the **action**: "Save changes", not "Submit". "Delete invoice", not "OK".
- Errors: the cause + the next step, in the user's language, never a code.
- Confirmations name the consequence: "Yes, delete 3 items".
- Consistent vocabulary across screens — if it is a "workspace" here, it is not a "team" there.
