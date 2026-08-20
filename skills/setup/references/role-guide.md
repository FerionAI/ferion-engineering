# Closing by role — what the person can do now

Adapt the end of setup to the role. Speak in outcomes, in plain language.

## PM (does not need to know any code)
Speaking normally, you can ask for:
- **"Break epic #40 into issues"** → I create the issues on GitHub, each in the standard shape
  (stack, criteria, Definition of Done). You review the preview and approve.
- **"Deliver issue #52"** → I take it from zero to a **finished PR** (specify, implement, test, make
  it spotless) — an **engineer only does the final human review**.
- **"How is the epic doing / how are the metrics"** → I show you progress and the dashboard.

You never open the code; you ask and follow along.

## QA (does not need to program to start)
- **"Generate the test cases for issue #52"** → from the acceptance criteria.
- **"Report this bug"** → I write the structured bug report and open the issue.
- **"What do I need to retest for this change?"**, **"can issue #52 go to production?"** → I run the
  QA gate against the Definition of Done.

Test automation, whenever you want it, I write for you.

## Developer
- **"Deliver issue #52"** → the full pipeline (spec → vertical slice → preflight → PR), in the standard.
- Working outside your domain (front/back)? I pair with you as the senior on the other side.
- Everything already connected, and the flow gates keep the order so you do not have to remember it.

## Tech lead
- **Health dashboard** (DORA, quality, cost per feature) for decisions and prioritization.
- The standard holds across Claude, Cursor and Gemini/Codex (portable config).
- Cost per task recorded on the issue, to measure efficiency and price work.
- The constitution is yours to change: it is a file in the repo, not a vendor's opinion.

## Always, at the end
Say: "Just talk to me your way — if I need something that is not configured, I'll tell you simply and
we sort it out on the spot."
