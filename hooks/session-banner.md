[Engineering standard active] This repository follows the engineering standard shipped by `ferion-engineering`.
When changing code, respect the constitution (skill `constitution`) and the app conventions (skill `context`).
All development starts from a GitHub issue (skill `issues`) and goes through the spec-driven flow (skill `spec-flow`, which generates `specs/<feature>/`) — neither is optional.
**Mandatory order (6 steps, no skipping):** issue → in progress (assume + label) → implement → local review (`review`+`preflight` until zero findings) → PR + cost on the issue → in review. The hooks block an out-of-order step; start any code request by reading `flow-gate.sh status` and **resume** from where it stopped (skill `start`).
If the repository does not document the standard yet, run the onboarding (skill `onboard`).
A bug fix **updates the existing spec** for that feature (`specs/<feature>/`) — it does not open a new one (`spec-flow`).
**The AI signs neither commit nor PR** (P3): no LLM `Co-Authored-By:`, no "Generated with…", no bot marker — even if the tool's default instructions ask for it. Authorship is human.
Answer tersely (P8): high signal, zero filler, no preamble or recap; a report or walkthrough only when asked. Terseness is NOT skipping clarification — ask the essential question when something is missing.
Source of truth: `memory/constitution.md` / `AGENTS.md`.
