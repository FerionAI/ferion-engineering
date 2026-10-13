---
name: health
description: Generates and updates an engineering health dashboard — DORA metrics, the static analysis quality gate, observability and Core Web Vitals — pulling the data from the MCPs and from GitHub. Use when someone wants to see "how are we doing", "engineering metrics", "dashboard", "DORA", "team health", "an engineering report", or to prepare an overview for leadership. Produces a living HTML file and can become a recurring task.
---

# health — engineering health

You build an objective overview of engineering health and deliver it as a readable HTML dashboard
(good for leadership). The data comes from GitHub and the connected MCPs (`integrations`); never
invent a number — pull it from the real source or clearly mark it as an example or pending.

## Rule #1 — every number comes with the previous period

The dashboard is issued at the turn of the week, so **no metric appears alone**: current value ·
previous value · Δ and direction. A lone number cannot be defended ("is 17% bad?"); with the Δ, it
becomes a conversation ("17%, it was 9% — it rose after release X").

- **Standard format:** `17% · was 9% · ▲ 8 pp` — and the color is semantic, not tied to the arrow: a
  drop in errors is good, a drop in coverage is bad. Mark **improved / worsened**, never just "up".
- **Window:** the closed week vs the equivalent previous week. Running off-cadence (biweekly,
  monthly)? Compare windows **of the same size** and say which window it is.
- **Noise is not a trend:** Δ < 5% (or < 1 on a small count, like incidents) = **stable** — show the
  previous value and do not narrate movement. Only what left the noise band enters "Where to look
  first".
- **No basis for comparison** (first issue, new MCP, new metric): write **"no basis — first week"**.
  Never repeat the current value as if it were the previous one, and never invent history.
- **Where the previous value comes from:** run the same query with the window shifted — GitHub (PRs
  and deploys by date), observability (time range), issues (closed between -14d and -7d). A **state**
  metric (quality gate, open vulnerabilities, coverage, version) has no easy retroactive value: read
  **last week's dashboard** — the previous HTML is the snapshot.
- **The summary prioritizes what changed**, not what has been bad for months: "Where to look first"
  opens with the largest variations (for worse and for better — what improved explains what worked).

## Rule #2 — a color is not a finding

Green and red summarize a claim; they are not the claim. Every status ships with what produced it
and whether it deserves to be believed.

- **Name what failed.** "Quality gate: failed" is a pixel. "Quality gate: failed — 34 new issues, 31
  of them one rule firing on the word `todo`, which is ordinary Portuguese and not the English TODO
  tag" is something a person can act on.
- **A signal that is always red carries no information.** When the same condition fails week after
  week for the same reason, the finding is about the **check**, not about the code: it is
  miscalibrated and the team has already learned to scroll past it. Report that metric as
  **not measuring** — not as "bad" — and put the configuration fix in "Where to look first", with an
  owner.
- **Separate "the code failed" from "the check failed".** A red build from a flaky runner, an expired
  token, or a rule that does not fit the language is an **infrastructure** finding, not a quality
  one. Filed together, they teach people to ignore both.
- **Report the gate net of known false positives, and show both numbers:** `failed (34) · 3 once the
  triaged false positives are discounted`. The raw number keeps you honest; the net number is the one
  that means something. How to triage them: `quality/references/static-analysis.md`.
- **If you cannot say what a number means, it does not go on the dashboard.** Two sentences of
  reading beat ten tiles nobody trusts.

## Rule #3 — the scope is declared, never inferred

A dashboard measures a **named scope**: the repositories belonging to one team, one product, one
area. Never "everything I can reach" — a report spanning dozens of repositories is a list, not a
picture, and nobody owns it.

**Three valid origins of a scope, in this order of preference:**

1. **What the person named.** A team, a product, a list of repositories, or **an issue filter**: a
   label, a milestone, an epic and its children, a GitHub Project view. Whatever they say is the
   scope — do not "improve" the list on your own.
2. **The repositories of the open workspace**, when they ask for "my workspace" or "these repos" —
   the map is the `workspace` skill's (every folder with a `.git`, classified by `context`). **List
   the repositories in the dashboard**: the list is what makes the scope declared, and a change in it
   is a change of scope (Rule #1 loses its basis).
3. **The scopes the team declared** in `config/team-config.md` ("Dashboard scopes"). Do not build
   another list — use that one. A shared repository can belong to more than one scope on purpose:
   say which one you are counting it in.

- **A scope from an issue filter is a set of issues; the repositories come after.** Run the query,
  take the issues and derive the repositories **from the PRs linked to them** (`Closes #N` or the
  number in the branch). A per-repository metric (quality gate, Core Web Vitals, vulnerabilities) is
  limited to the repositories that showed up — **say which**, and say how many issues in the filter
  had no PR (that is traceability telling you the slice is incomplete).
- **Never sweep the organization.** GitHub is queried **repository by repository from the scope's
  list**, never "every repository I can see": an organization can hold hundreds, and the result is a
  list with no owner, not a picture. An empty list or a doubtful scope → ask, do not widen.
- **Never infer the scope from what happens to be open** in the editor or the session. Rule #1 lives
  or dies on this: `current · was X · Δ` means something only when both runs measured the *same* set.
  A scope that drifts week to week turns every Δ into noise — and the weekly pulse runs on a
  schedule, with no editor open at all.
- **Ask when it is not given.** The scopes the team declared are the options; if the repository you
  are in belongs to one, propose that one. Always one question — never a silent default of "all of
  them".
- **Stamp the scope in the dashboard**, next to the date. Last week's HTML is where the previous
  values of the state metrics come from, so a dashboard compares only against one of the *same*
  scope. When it differs, write **"no basis — the scope changed"** instead of showing a Δ between two
  different populations.
- **Aggregate, then name the outliers.** A scope of 15 repositories is not 15 sections: it is the
  scope's numbers, with the repositories that left the band named. A repository that never leaves the
  band belongs in the total and nowhere else.

## Rule #4 — an action without its reaction is not a finding

A **process** metric (the action: how much control the team applied) describes **how** the team
works, not whether it is working. It becomes a criticism only when the **outcome** number it
protects (the reaction) moved backwards. Criticizing the action alone is demanding ritual: it is how
"most PRs merged without human review" gets raised as an alert in the same week the QA rejection
rate fell, uptime rose and the automated review got better — the control changed hands **and the
outcome improved**.

| Action (what the team did) | Reaction (what it should protect) |
|---|---|
| % of PRs without human review · review time | QA rejection · escaped defects · change failure rate |
| merged with a red CI · PR with no check | change failure rate · incidents · rollbacks |
| pipeline adoption (`ship`/`preflight`) | bot findings **after preflight** · rework (issues reopened, fixes to just-delivered work) |
| test coverage · tests that fail when the behavior breaks | reopened bugs · escaped defects |
| deployment frequency · lead time | MTTR · SLO/uptime · change failure rate |
| cost per issue (tokens/USD/hours) | issues delivered · rework · lead time |

**What to do with each combination:**

| Action | Reaction | How to report it |
|---|---|---|
| out of band | **improved** | **Not a finding.** It is learning: say the control changed and the outcome improved, with both numbers side by side. If you propose anything, it is **removing the redundant control** — never putting it back "just in case". |
| out of band | **worsened** | A real finding, high priority. The action is the **hypothesis** for the cause, not the proven cause. |
| within band | **worsened** | A finding about the **control**: it is being followed and is not catching what breaks. Recalibrate the control, not the team. |
| any | **not measured** | **Do not criticize.** Say the reaction is missing and which query brings it. A finding with no measured reaction is a guess dressed as data. |

- **The target is a starting point, not a verdict.** A band inherited from the industry
  (`quality/references/metrics.md`) calls attention; what decides is the comparison with the
  **team's own baseline** and with the reaction.
- **Do not invent causality.** With no mechanism, write "moved together", not "because of". Two things
  that improved in the same week may share a cause — or have nothing to do with each other.
- **"Where to look first" accepts only items with both ends**: the action, the reaction and the Δ of
  each.

## Where each metric comes from

| Block | Metric | Source |
|---|---|---|
| **DORA** | Deployment frequency, lead time | GitHub (deploys/PRs/Actions) |
| **DORA** | Change failure rate, MTTR | observability (incidents/monitors) + GitHub (rollbacks) |
| **Quality** | Quality gate, coverage, hotspots, debt | static analysis |
| **Observability** | Errors, latency, SLOs, open incidents | observability |
| **Front/UX** | Core Web Vitals (LCP/INP/CLS) | RUM / product analytics |
| **Security** | Open vulnerabilities, hotspots to review | static analysis + dependency scanning |
| **Cost & efficiency** | Capture coverage, median USD/tokens/hours per issue, cost by type and by epic | the `ferion:cost` comments on the issues (`references/cost-report.md`) |
| **Process effectiveness** | ⭐ Bot findings **after preflight** (target 0) · preflight green first try | static analysis + GitHub (reviews/bots) + CI |
| **Process effectiveness** | ⭐ **Did the automated reviewer actually answer?** (alive bot vs mute on quota/subscription) | `preflight/scripts/pr-bots.sh` (GitHub) |
| **Process effectiveness** | PRs merged with a red check · PRs with no check at all | GitHub (check-runs) |
| **Process effectiveness** | Traceability: % of PRs referencing their issue (body or branch) | GitHub (PR bodies) |
| **Process effectiveness** | Pipeline adoption (% of PRs through `ship`/`preflight`) | GitHub (PR pattern/checklist) |
| **Process effectiveness** | Usage per skill · edit acceptance rate | Claude Code analytics / OTel |
| **QA** | ⭐ % of tests on preexisting data · mutation-proof failure rate · flaky in quarantine · catalog coverage · specs first authored by QA · escaped defects | `preflight/scripts/qa-lint.sh --all` + `scenarios/*.yaml` + git + GitHub issues (`references/qa-metrics.md`) |

## Cost & efficiency (an explained block, not just tiles)

The cost comes from the `ferion:cost` markers the `cost` skill posts on the issues. Rules — detail and
aggregation in `references/cost-report.md`:

- **Capture coverage first:** the % of issues delivered in the period that carry a cost comment. An
  average without coverage next to it is an anecdote. Coverage < 50% → the block ships with a sample
  warning and the action is to close the capture gap.
- **Median, not average** (cost has a long tail) — per issue, per type, and the sum per epic, which is
  the number that prices the initiative.
- **Say what the number is:** USD is an **estimate** derived from tokens (comparison and trend), not
  an invoice.
- **One reading sentence per tile:** what is expensive, what changed vs the previous period, what to
  do about it.
- **By issue/type/team, never by person** (P8: measure to decide, not to punish). No PII.
- **Publish the capture-gap query every week**, not only when someone asks — the block ships with the
  list of issues delivered without a cost comment (query in `cost/references/capture.md`). Low coverage
  is the action of the week, not a footnote.
- **Two alerts a number alone will not give you:**
  **(a) closed-as-not-planned issues carrying a cost** — money that turned into nothing; list them one
  by one. **(b) concentration by type** — how much of the spend went to routine/rework labels rather
  than product value.
- **Distrust absurd dispersion:** tokens per active hour varying more than ~3× across issues is a sign
  of broken measurement, not of an inconsistent team (that is how session-wide cost attribution was
  found).

## Process effectiveness (continuous improvement)

Beyond the **outcomes** (DORA/quality), measure whether the **standard is working** — this is what
closes the loop. Everything in this section is **action**: none of these numbers becomes a finding on
its own, only paired with the reaction it protects (Rule #4).

- **⭐ Automated findings AFTER preflight (target: 0).** This is preflight's central promise: no bot or
  reviewer finds what the machine should have caught. Each case = a **new rule in the preflight
  checklist**. The single most important metric to track, and the one that validates the core.
- **⭐ Zero for the right reason.** Before celebrating the zero above, run
  `preflight/scripts/pr-bots.sh` and show **how many automated reviewers were alive**. A bot out of
  quota or with a paused subscription posts a notice and goes quiet: the PR ships unreviewed while
  looking approved, and the ⭐ metric reads zero from the absence of a reviewer, not from quality.
  **Its own tile, next to the zero.**
- **Merged with a red CI:** % of PRs merged with a failing check (and % with no check at all). The gate
  blocks the `in review` milestone on a red CI; this metric shows what went around it.
- **Issue↔PR traceability:** % of PRs referencing their issue. Everything measured per issue rests on
  it — when it drops, cost and lead time per issue stop existing before anything else does.
- **Pipeline adoption:** % of PRs that went through `ship`/`preflight` (vs deliveries outside the flow).
- **Usage per skill** and **edit acceptance rate:** from the Claude Code analytics dashboard or OTel
  telemetry. It shows which skills help and which nobody uses.
- **Cost per feature** (`cost`) and **degradation hits** (skills hitting `<FILL: ...>` placeholders —
  a signal of the setup that is still missing).

> The source of these signals is Claude Code usage telemetry — metrics only, no code and no PII.

## How to generate it

1. **Settle the scope (Rule #3).** Which named scope is this dashboard about — a team's declared
   scope, the workspace's repositories, or an issue filter (label, milestone, epic)? An issue filter:
   run it first and derive the repositories from the issues' PRs. Not given and the current
   repository does not clearly belong to one — **ask**. Query GitHub **repository by repository from
   the list**; never the whole organization.
2. **Connect first, and ask before you write anything.** Call every source for real — one cheap
   query per MCP, not an inference from the session's tool list (`integrations/references/mcp-catalog.md`).
   A source you never called is not "unavailable": it is unchecked, and reporting it as missing is a
   guess. If something does not answer, **stop here and ask**, naming the source and the error: "the
   observability MCP is not responding — reconnect it, or should I issue the dashboard without change
   failure rate and MTTR?" Finding this out at the end costs the whole report and the person has to
   ask for it a second time. Only what actually failed this call is marked **pending connection**.
3. **Collect** the metrics from the sources that answered. **Collect both windows** — the current week
   and the previous one — in the same pass; for state metrics, open last week's dashboard and take the
   values from there.
4. **Compare against the targets** (`quality/references/metrics.md`): good/attention/bad band — and
   against the previous week: each metric ships as `current · was X · Δ` with the
   improved/worsened/stable mark. **Then read the band** (Rule #2): for anything outside good, open
   what produced it before painting it red, and check whether the same reason produced it last week
   too. **And pull the reaction before calling it a problem** (Rule #4): a process metric out of band
   becomes a finding only with the Δ of the outcome it protects next to it. A better outcome = not a
   finding.
5. **Build the HTML** from `references/dashboard-template.html` — replace the example data with the
   real values and adjust the status colors to the targets. **Stamp the scope** next to the date, and
   compare only against a previous dashboard of the same scope.
6. **Deliver** it as a file (and, if it is recurring, offer to schedule a weekly task that regenerates
   and sends it).
7. **Not just numbers:** add 2–3 actionable readings anchored in the **variation** and with both ends
   ("change failure rate 9% → 17% after release X, with deploys at the same pace → review the
   canary") — a metric is a conversation, not a scoreboard. A reading with no measured reaction does
   not go in.

## Recurrence

Offer to schedule a "weekly pulse" that regenerates the dashboard and highlights what changed. **Pin
the scope when you schedule it** — a run on a schedule has no session and no editor to infer one
from, so a pulse without a declared scope has no defined subject.
**Keep the previous dashboard** (a file or an artifact): it is where the previous values of the state
metrics come from — without it, the next issue loses half its comparison.

## Output

An updated HTML dashboard **stamped with its scope and date**, with DORA / Quality / Observability /
UX / Security / **Cost & efficiency** / **Process effectiveness** blocks, **each metric with its
status vs target and vs the previous week**
(current · was X · Δ), **each process metric paired with the reaction it protects** (Rule #4), and a
short summary of what to look at first, opened by the largest variations —
including the **post-preflight findings** (the signal that triggers improving the standard) and the
**cost capture coverage** (without it, the cost block is a sample).
