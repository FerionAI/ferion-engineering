# A back-end person working in the front end

The instinct that serves you well: types, contracts, edge cases. The instinct that does not: assuming
the interesting part is the logic. In the front end, the interesting part is the **states**.

## The three shifts in mindset

1. **Every screen has four states**, not one: empty, loading, error, success. You will build success
   first and it will look done. It is not done. The empty state is what a new user sees first, and
   the error state is what they remember.
2. **The user is unpredictable.** They double-click submit, hit back mid-flow, open two tabs, lose
   the network. There is no "the request completes and then the next line runs".
3. **Accessibility is not optional polish.** It is the equivalent of input validation — a category of
   correctness, not of taste (`quality/references/accessibility-wcag.md`).

## Do not start from raw HTML

Use the project's design system: a component plus tokens, never hand-rolled markup and hardcoded
values (`design-system`). It gives you consistency and a large part of accessibility for free, and it
is the single biggest quality difference between a back-end person's screen and a good one.

If the design is not validated yet, run `design-review` before building — fixing a layout in a mockup
costs minutes; refactoring a built component costs a day.

## The concepts worth twenty minutes

- **Server state vs UI state.** Data from the API is not the same thing as "is this dropdown open".
  Use a data-fetching library (react-query or equivalent) for the former; local state for the latter.
  Mixing them is the source of most front-end complexity you will meet.
- **Re-render on every state change.** Your component function runs again. Do not put side effects in
  the render path.
- **Keys in lists** must be stable ids, never the array index — otherwise the UI reorders wrongly and
  form inputs swap values between rows.
- **Optimistic updates** make things feel instant, and must handle the failure path (roll back and
  tell the user).

## The checklist before you call it done

- [ ] The four states handled (empty with an exit action, loading with a skeleton, error with a cause
      and a next step, success confirmed).
- [ ] Keyboard: `Tab` through the flow, visible focus, `Escape` closes overlays.
- [ ] The design system's components and tokens — no `#hex`, no magic `px`.
- [ ] Error messages in the user's language, preserving what they typed.
- [ ] Works on a mid-range phone on a slow connection (throttle in devtools, do not guess).
- [ ] No secret and no PII in the client bundle or in `localStorage` — everything shipped to the
      browser is public.

## The failure mode to watch for

Back-end people write front ends that are logically correct and unusable: no loading feedback, a raw
error object in an alert, a form that clears on failure. The logic is right; the experience is not.
Walk the flow yourself once, slowly, as a user — that catches most of it
(`preflight` step 1.5 makes this a formal step for bigger changes).
