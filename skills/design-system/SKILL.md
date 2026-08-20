---
name: design-system
description: 'Makes the agent an expert in the project''s own design system and drives its progressive adoption in the front end — new code is born in the design system; legacy migrates over time, without blocking deploy. Use ALWAYS when there is front-end/UI work — creating a screen, component, form, adjusting layout, colors, spacing, typography — and when detecting code that does not use the design system. If the front end does not use one yet, flag it and plan the incremental migration (do not block the delivery). Triggers: "create a screen/component", "style this", "layout", "button/input/modal/table", "design system", "color/spacing/theme".'
---

# Design system

A ready component beats raw HTML/CSS; a token beats a hardcoded value — it saves development time,
guarantees consistency and already delivers a good part of WCAG.

> **The source of truth for the design standard** is the **Design Constitution**
> (`memory/design-constitution.md`): it defines the UX/UI rules, the **target components** and the
> **tokens**. It is the **target**; the code package is the implementation (always partial). When
> **composing a new component** the code does not have yet, follow the constitution. `design-review`
> **validates** a layout against it; this skill **builds**.

> **Progressive adoption.** The bar is deliberately flexible so it does **not block deploy**: **new**
> UI code is born in the design system; **legacy migrates incrementally**. A design system deviation
> is a **warning (⚠️), not a blocker (❌)** — the rigor rises as the design system matures. (Security,
> tests and privacy remain hard blockers; this one is not.)

## Step 0 — Discover the design system (do not assume)

The standard does not ship a design system; **your project has one, or it does not**. Find out
before writing a single component:

```bash
# 1. Is one declared as a dependency?
grep -iE '"(.*design-system|@.*/ui|@chakra-ui|@mui|antd|@radix-ui|shadcn)' package.json

# 2. Is it vendored in the repo? (shadcn-style: components live in your source tree)
ls src/components/ui 2>/dev/null; ls components/ui 2>/dev/null

# 3. Is there a Storybook or a component doc site?
ls .storybook 2>/dev/null; grep -l storybook package.json

# 4. What do the existing screens actually import?
grep -rhoE "from ['\"][^'\"]*(ui|design-system)[^'\"]*['\"]" src --include=*.tsx | sort | uniq -c | sort -rn | head
```

Then **read the real component names from the types or the Storybook**, and record what you found in
`config/team-config.md` so the next session does not rediscover it. Three outcomes:

| What you found | What to do |
|---|---|
| A design system package or vendored kit | Use it. Read its exports for the **real** names — never guess an API. |
| Several competing libraries | Flag the inconsistency, pick the dominant one for new code, record the debt. |
| None | Say so. Propose the smallest thing that works (a token file + a handful of primitives), do not introduce a heavy dependency to style three screens. |

## Rules of use (for new UI code)

1. **Components first.** Need a button, badge, table, tabs, date picker, chart? Use the project's. For
   what it does not cover, compose locally following the constitution and **flag it** — do not
   recreate what already exists and do not pull in a second UI library for what the first one covers.
2. **Tokens, never loose values.** Colors, spacing, typography, radius and shadows come from tokens.
   No `#hex`, no magic `px`, no ad-hoc fonts.
3. **Composition over customization.** Extend through props/variants; do not override a component's
   internal styles with CSS on top.
4. **Accessibility preserved.** Use the components as they come; do not break roles/aria while
   styling (ties into WCAG in `quality`).
5. **The design system's icon set**, not stray SVGs.
6. **Never invent a component or a prop.** If you cannot inspect the package (types or Storybook) to
   confirm the real name, **do not generate names by assumption** — stop and ask, or install and open
   the types. Guessing a component API is hallucination, and `preflight` must block it. **This one
   blocks** — unlike adoption, which is progressive.

Detail on usage, tokens and how to find the right component in `references/usage-and-components.md`.

## If the front end does not use the design system yet → flag it and migrate incrementally

When you detect raw HTML/CSS, another UI library, or hardcoded values where an equivalent exists:

1. **Flag it (a warning, not a block):** "This front end does not use the design system yet. It can
   be migrated incrementally — this deploy does not need to wait."
2. **Do not force a big bang.** Migrate in pieces, prioritizing **new UI** and high-traffic screens;
   use `references/adoption-without-regression.md` to migrate **without regression** (visual,
   behavior, a11y, tests) when the migration happens.
3. **Where the library does not cover it yet**, compose locally — that is expected at this stage and
   does not count as a violation.
4. **Design system conformance is not a merge/deploy gate** for now (unlike security, tests and
   privacy, which do block). Record the migration debt and move on.

## In the flow

- **`design-review` / Design Constitution:** validate the layout **before** building; here is the build.
- **New UI:** born in the design system — never start from raw HTML.
- **`review`:** design system conformance is a front-end review item — **a warning (⚠️)** for legacy,
  not a blocker; new UI should be born in it.
- **`onboard`:** when entering a front-end repo, measure adherence and record the migration debt.
- **`ship`:** the front-end step uses the design system by default in new code.
