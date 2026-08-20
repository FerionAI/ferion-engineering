# Using the design system — components, tokens and discovery

## Finding the real component names (never guess)

Guessing a component or prop name is hallucination, and `preflight` must block it
(`preflight/references/anti-hallucination.md`). Four ways to get the truth, in order of reliability:

1. **The type definitions.** `node_modules/<package>/dist/index.d.ts` — the exports are the API. This
   is authoritative and takes ten seconds.
   ```bash
   grep -oE 'export (declare )?(const|function|class) [A-Za-z]+' node_modules/<pkg>/dist/index.d.ts
   ```
2. **The Storybook / docs site**, if one is published. Best for props and variants.
3. **The existing usage in this repo.** What the other screens import is what actually works here.
   ```bash
   grep -rhoE "import \{[^}]+\} from ['\"]<pkg>['\"]" src | sort -u
   ```
4. **The repo itself**, if the design system is vendored (shadcn-style, in `src/components/ui`).

**Watch out for naming conventions.** Design systems often prefix their exports (`DSButton`,
`AppButton`, `UIButton`) precisely to avoid colliding with the underlying library. Assuming `Button`
because that is the obvious name is the most common way to generate code that does not compile.

Record what you find in `config/team-config.md` so the next session does not repeat the discovery.

## Tokens, not values

```tsx
// yes — semantic tokens
<div className="bg-surface p-4 text-fg-secondary rounded-md">

// no — hardcoded, unthemeable, breaks in dark mode
<div style={{ background: '#f9fafb', padding: 13, color: '#6b7280', borderRadius: 6 }}>
```

Two layers, and only one of them is for you:

- **Semantic tokens** (`bg-surface`, `fg-primary`, `border-error`, `space-4`) — use these. They carry
  the role, which is what makes theming and dark mode work.
- **Primitives** (`gray-500`, `blue-400`) — these exist to *define* semantic tokens. Using one
  directly in a component hardcodes a decision the design system was supposed to own.

## Composition over customization

Extend through the component's props and variants. Do not reach in and override its internals with
CSS — that couples your screen to the design system's implementation details, and it breaks on the
next minor version.

```tsx
// yes
<DSButton variant="secondary" size="sm" />

// no
<DSButton className="!bg-red-500 [&>span]:text-xs" />
```

If the variant you need does not exist, that is a design system gap: compose it locally, record it,
and propose it upstream. Do not fork the component into your screen.

## Accessibility comes with the component

A design system component ships with roles, ARIA and keyboard behavior. Restyling it is fine;
replacing its semantics is not — `<DSButton as="div">` throws away everything it gave you. When you
compose something new, the accessibility is now your job
(`quality/references/accessibility-wcag.md`).

## When the component does not exist yet

Every design system is a partial implementation of its own target. When the constitution names a
component the code does not have:

1. **Compose it locally**, following the Design Constitution (structure, tokens, states, a11y).
2. **Record the gap** — in the PR and in the team config. A recorded gap becomes a design system
   issue; an unrecorded one becomes five slightly different local implementations.
3. **Do not invent an API on the package.** A local component in your repo is honest; a phantom import
   from the design system is a broken build.
4. **Do not pull in a second UI library** for what the first one covers. That is how a codebase ends
   up with three button implementations.
