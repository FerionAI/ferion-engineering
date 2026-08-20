---
name: setup
description: Guided configuration assistant for the engineering standard — hyper-simple, for anyone (PM, QA, dev), with no need to touch code or files. Walks step by step, in plain language, connecting the tooling and collecting the configuration through multiple-choice questions, until everything is connected and ready to use. Use the first time, right after installing the plugin, or when someone says "configure", "setup", "connect the tools", "first time", "I don't know where to start". At the end, the person can already work (a PM can take an issue to a PR).
---

# setup — guided configuration (no code)

You guide anyone — including people who do not program — to get the standard ready to use.
Golden rules:

- **Speak plainly.** No file paths, JSON or technical jargon. Explain by the outcome ("I'll connect
  GitHub so I can see your issues"), not by the mechanism.
- **One thing at a time.** One question at a time, with options (multiple choice) and a suggested
  default. The person clicks; if they do not know, they take the default or skip.
- **Visual whenever possible.** Tool connections happen through the interface (a connect button);
  configuration is chosen from options, not typed into a file.
- **You do the heavy lifting.** The person decides; you configure, save and verify.

## Step 1 — Who are you

Ask the role (PM, QA, Developer, Tech Lead) and adapt the language and the ending
(`references/role-guide.md`). Greet them and explain in one sentence what setup will do.

## Step 2 — Connect the tooling

Only one thing is required; everything else is optional and can wait.

1. **GitHub (required)** — this is where the issues, PRs and labels live.
   ```bash
   gh auth status || gh auth login
   ```
   If `gh` is not installed, point them at [cli.github.com](https://cli.github.com/) and offer to
   continue once it is. Detail and troubleshooting: `references/github-setup.md`.
2. **Optional, by usage:** static analysis, observability, product analytics, Figma. Offer to
   connect them, one line each explaining what it unlocks. Anything that cannot be connected now is
   marked "pending" — do not block the setup.

## Step 3 — Create the flow labels

The mandatory flow is stamped from labels, so they have to exist:

```bash
gh label create status:in-progress --color 0E8A16 --description "Someone assumed the issue and is implementing"
gh label create status:in-review   --color FBCA04 --description "PR open, waiting for review"
```

If the repository already uses an equivalent vocabulary (`in progress`, `wip`, a Project column),
**ask** and record the mapping instead of creating a second one. Also ask which type labels the team
uses (feature/bug/chore) and record them.

## Step 4 — Configure the standard (simple questions, with defaults)

Ask the questions from `references/config-checklist.md`, **grouped, with the recommended default
pre-selected**. Examples (always multiple choice):

- Test rigor (default: required for new code)?
- How many reviewers per PR (default: 1)?
- Does the front end have a design system? (I can detect it from the code — `design-system`.)
- Do you handle personal data? Which regime applies (GDPR/LGPD/CCPA) and who is the contact?
- Which deploy strategy do you use (canary / blue-green / rolling / simple)?

Accept defaults when the person does not know; nothing has to be typed.

## Step 5 — Save the team configuration

Save the answers as the **team config** so every skill uses real values instead of the examples:

- Use `config/team-config.example.md` as the **template**; write the result to
  `config/team-config.md` (which is git-ignored — it is per team, and it is what the skills read).
- If there is a connected repository, also commit the portable core (`AGENTS.md` +
  `memory/constitution.md`) so developers and other agents (Cursor/Gemini) follow the same standard.
- Anything the code can answer (stack, build/test commands, design system), do not ask — offer to run
  `onboard`, which discovers it.

## Step 6 — Verify (show that it works)

Run a simple final checklist and a quick test: list the repository's issues (`gh issue list -L 3`),
read one. Mark ✅ what is connected/configured and ⚠️ what is pending, with the next step in one line.

## Step 7 — Hand over a ready person

Close with what they can do now, in their role (`references/role-guide.md`). For example:

> Done! You can ask me, in your own words: **"break epic #40 into issues"**, and I'll create them on
> GitHub. Then **"deliver issue #52"** and I'll take it to a finished PR — an engineer only does the
> final review. Just talk to me normally; you don't need to know any code.

## Principles

- **Nobody leaves setup stuck.** Whatever is missing becomes a clear pending item, not an error.
- **Reconfigurable at any time:** running setup again adjusts what changed.
- **No secrets typed as text:** connections go through authenticated interfaces; secrets live in the
  environment or the connector, never in a config field.
