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
| **Process effectiveness** | Pipeline adoption (% of PRs through `ship`/`preflight`) | GitHub (PR pattern/checklist) |
| **Process effectiveness** | Usage per skill · edit acceptance rate | Claude Code analytics / OTel |

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

## Process effectiveness (continuous improvement)

Beyond the **outcomes** (DORA/quality), measure whether the **standard is working** — this is what
closes the loop:

- **⭐ Automated findings AFTER preflight (target: 0).** This is preflight's central promise: no bot or
  reviewer finds what the machine should have caught. Each case = a **new rule in the preflight
  checklist**. The single most important metric to track, and the one that validates the core.
- **Pipeline adoption:** % of PRs that went through `ship`/`preflight` (vs deliveries outside the flow).
- **Usage per skill** and **edit acceptance rate:** from the Claude Code analytics dashboard or OTel
  telemetry. It shows which skills help and which nobody uses.
- **Cost per feature** (`cost`) and **degradation hits** (skills hitting `<FILL: ...>` placeholders —
  a signal of the setup that is still missing).

> The source of these signals is Claude Code usage telemetry — metrics only, no code and no PII.

## How to generate it

1. **Collect** the metrics from the available sources (start with the MCPs already connected in this
   session; the rest per `integrations/references/mcp-catalog.md`). Mark anything absent as "pending
   connection". **Collect both windows** — the current week and the previous one — in the same pass;
   for state metrics, open last week's dashboard and take the values from there.
2. **Compare against the targets** (`quality/references/metrics.md`): good/attention/bad band — and
   against the previous week: each metric ships as `current · was X · Δ` with the
   improved/worsened/stable mark.
3. **Build the HTML** from `references/dashboard-template.html` — replace the example data with the
   real values and adjust the status colors to the targets.
4. **Deliver** it as a file (and, if it is recurring, offer to schedule a weekly task that regenerates
   and sends it).
5. **Not just numbers:** add 2–3 actionable readings anchored in the **variation** ("change failure
   rate 9% → 17% after release X → review the canary") — a metric is a conversation, not a scoreboard.

## Recurrence

Offer to schedule a "weekly pulse" that regenerates the dashboard and highlights what changed.
**Keep the previous dashboard** (a file or an artifact): it is where the previous values of the state
metrics come from — without it, the next issue loses half its comparison.

## Output

An updated HTML dashboard with DORA / Quality / Observability / UX / Security / **Cost & efficiency**
/ **Process effectiveness** blocks, **each metric with its status vs target and vs the previous week**
(current · was X · Δ), and a short summary of what to look at first, opened by the largest variations —
including the **post-preflight findings** (the signal that triggers improving the standard) and the
**cost capture coverage** (without it, the cost block is a sample).
