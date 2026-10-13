# ADR-0005: Usage telemetry as a comment on an issue of the plugin's repo — aggregated, and opt-in

- **Status:** accepted
- **Date:** 2026-10-13   ·   **Author(s):** `<FILL>`   ·   **Issue/Epic:** —

## Context
Deciding what to optimize in the plugin needs data from more than one machine: which skills eat the
round trips (ADR-0004), and **where the flow leaks** — spec → preflight → review → PR → cost → in
review. The artifacts the flow already leaves cannot answer that: a cost comment only exists on an
issue that reached the end of the flow, so it counts exactly the people for whom the flow already
works. The leak is in the tail (preflight → cost → label), which is what no artifact records.

The "official" telemetry routes (OpenTelemetry to a collector, an admin console) work technically,
but each needs someone to run and approve infrastructure — a measurement nobody can switch on
measures nothing. Whoever installs this plugin, on the other hand, can already read its repository
and comment on its issues.

## Decision
Telemetry goes out **through the plugin's own repository**, as a comment on a monthly issue
(`[telemetry] YYYY-MM`), posted with the person's own `gh` at `SessionStart`, at most **once a day**,
in the **background** (`hooks/telemetry.py`) — and **only when the person opted in**
(`~/.claude/ferion-telemetry` exists, or `FERION_TELEMETRY=1`).

- **Why opt-in here.** The same mechanism is defensible as opt-out in an internal plugin: the issue
  sits in a private repository that only the team reads, the people sending are colleagues, and
  visibility inside the team is what makes it acceptable. **Here the repository is public.** The
  comment is world-readable and signed by the sender's GitHub account; nobody installing an
  open-source plugin expects their usage posted there. A public, attributed record of someone's work
  pattern needs consent, not an off switch they may never learn about. So the default is off, the
  hook prints nothing while it is off, and turning it on is one deliberate command.
- **Transparency on top of consent:** when it sends, the hook says so in the session; `--preview`
  shows exactly what would leave the machine, with or without opting in.
- **Aggregate only:** per skill of this plugin (invocations, calls, minutes, tokens), flow milestones
  reached (only from calls that succeeded; a call a gate refused counts as `blocked_<category>`),
  surface, version, number of sessions and hours. **Never** a prompt, code, file path, command or
  branch. A repository name leaves only when its remote belongs to the plugin's own organization;
  another plugin's skill becomes `(other)`.
- **The target comes from `plugin.json`:** a fork posts to its own repository, never to this one.
- **Fails silently:** no `gh`, no network or an error → nothing is sent and nothing is marked as sent;
  it tries again next session. One send per day across concurrent sessions (an atomic lock), and the
  report drops repeated sends. Telemetry never breaks or pollutes a session.
- **Read with the same file:** `--report` aggregates a month (people, sessions, the flow funnel,
  surfaces, versions, cost per skill). No ranking per person: **measure to decide, not to punish** (P8).

## Alternatives considered
- **Opt-out (on by default, with an off switch)** — collects far more, which is why it is the right
  default for an internal tool. Rejected here: it publishes, under a person's name, data they never
  agreed to make public.
- **OpenTelemetry to a collector** — technically better (per-event cost and time, no code in the
  plugin) and the natural route for a team that runs one. Rejected as the default because it needs
  infrastructure every user would have to provide; a team can still use it alongside.
- **Counting cost comments on issues** — what already exists, and exactly what undercounts: only
  whoever finishes the flow shows up.
- **Sending the transcript or a raw file** — rejected: it takes code and prompts off the developer's
  machine, with privacy and leak risk, to answer a question aggregated numbers already answer.

## Consequences
- **Positive:** cross-machine data with no infrastructure; the funnel shows where the flow breaks;
  every send is auditable (anyone sees what was sent and by whom); forks measure themselves.
- **Negative / costs:** opt-in collects little and skews toward engaged users — read the numbers as
  a sample of the willing, never as adoption. Only Claude Code users with the plugin and an
  authenticated `gh` are visible; agents that read only `AGENTS.md` are not. No send on Windows (no
  `fork`). One comment per person per day on the monthly issue.
- **Impact:** `hooks/hooks.json` (one `SessionStart` command), `hooks/telemetry.py` (reads the
  per-skill profile from `skills/cost/scripts/skill-profile.py`), README, `cost`, and
  `scripts/validate-plugin.sh` (selftest).

## Constitution principles involved
- **P8** (agentic efficiency): "measure to improve" extends beyond the author's machine — aggregated,
  never a ranking of people.
- **Privacy (P7):** consent before collection, minimization at the boundary (numbers leave, content
  does not), no repository name outside the plugin's organization, and opting out is one command.
