# Tool — UX and accessibility QA

The functional test says the feature works. This says whether a person can actually use it.

## The 10-minute accessibility pass

Do this on every flow with UI. It costs ten minutes and catches most of what matters.

1. **Unplug the mouse.** `Tab` through the whole flow. Can you complete it? Is the focus ring always
   visible? Does the order match the visual layout? Does `Escape` close the overlay? Are you ever
   trapped?
2. **Zoom to 200%.** Does content reflow, or does it get cut off / require horizontal scrolling?
3. **Run axe** (browser extension or the CI integration) — it catches contrast, missing accessible
   names, broken semantics automatically.
4. **Turn on a screen reader** for the key flow (VoiceOver ⌘F5, NVDA). Every control announces a
   meaningful name? Errors are announced? Headings tell the page's structure?
5. **Check state without color** — a grayscale screenshot. Can you still tell error from success?

A finding here is a **blocker**, not a nice-to-have (`quality/references/accessibility-wcag.md`).

## The UX pass (Nielsen, applied)

Walk the flow asking:

- **Do I know what is happening?** Loading, saved, failed — feedback within 100ms of every click.
- **Do I know where I am and how to get back?** Title, breadcrumb, an obvious exit.
- **Can I undo?** Or, for destructive actions, does the confirmation name the object and the verb?
- **Are the errors useful?** Cause in plain language + next step, next to the field, preserving what
  I typed.
- **Are the four states handled** — empty, loading, error, success? The empty state is the most
  frequently missed, and the one a new user hits first.
- **Is the language the user's?** Not the database's enum, not the internal team's jargon.

Full list: `design-review/references/nielsen-heuristics.md`.

## Perceived performance

Test on something realistic, not a fast laptop on fibre: throttle the network and the CPU in devtools
(4x slowdown, "Fast 3G"). Is there a skeleton, or does it hang blank? Does the layout jump when data
arrives (CLS)? Does typing lag (INP)?

## Reporting a UX or a11y finding

Same format as a bug report, with the rule cited: which Nielsen heuristic or WCAG criterion, the
screen, and the fix. A finding tied to a rule is a decision; a finding stated as a preference is an
argument.

> Best case, none of this reaches you: `design-review` validates the layout **before** it is built,
> which is when fixing it is cheap. A repeated finding here is a signal that the design gate is being
> skipped.
