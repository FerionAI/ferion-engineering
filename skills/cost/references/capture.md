# Cost capture — measure and write it on the issue

Two steps: get the number, then write it where it belongs. Both are one command.

## Step A — get the number

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/cost/scripts/session-cost.py                 # this issue — the normal case
python3 ${CLAUDE_PLUGIN_ROOT}/skills/cost/scripts/session-cost.py --whole-session  # ignore the baseline
python3 ${CLAUDE_PLUGIN_ROOT}/skills/cost/scripts/session-cost.py --since=2026-08-26T15:49:18Z
```

```json
{"session":"abc123","scope":"issue","issue":"123","since":"2026-08-26T15:49:18Z","tokens":138034,
 "usd":0.1066,"active_hours":0.17,"wall_hours":0.49,"models":["claude-opus-5"],
 "token_detail":{"in":2,"out":271,"cache_read":134504,"cache_write":3257}}
```

What it does:

- **Finds the session** — the most recent transcript for the current repository
  (`~/.claude/projects/<slugified-cwd>/*.jsonl`), or the id/path you pass as an argument.
- **Cuts at the issue's baseline** — `flow-gate.sh stamp task <n>` writes `baseline=<UTC>` into
  `<gitdir>/ferion-flow`, and the script measures from there, so **two issues in one session do not add
  up**. The baseline does not move while the issue is the same (a second session on the same issue is a
  new slice — that one you **do** add on the issue). In `bypass` there is no issue and no baseline: the
  scope falls back to the whole session.
- **Tokens** are summed from the transcript itself (in/out/cache, deduped per request) — they match
  `ccusage` when the scope is the whole session.
- **USD** comes from `ccusage` (the same source as `/usage`), prorated onto the slice by the price
  weight of its tokens (`WEIGHT` in the script: output 5x input, cache write 1.25x at 5 min / 2x at
  1 h, cache read 0.1x). Needs `npx`; without network it degrades to `null` — pass `--no-usd` to skip
  it deliberately.
- **Hours** come from the transcript timestamps. **Active** time caps each gap at 5 minutes
  (`GAP_MAX`), so a coffee break does not get billed as AI time; **wall** time is first to last event.
- `--selftest` checks the time math, the slicing and the proration (it runs in CI through
  `validate-plugin.sh`).

A `null` field means the number is unavailable. **Do not invent it** — comment what you have and say
so in the summary.

## Step B — write it on the issue

At the `in review` milestone, **before** labelling the issue:

```bash
gh issue comment 123 --body '<!-- ferion:cost tokens=1403090 usd=2.05 active_h=0.17 wall_h=0.49 -->
**Dev cost** (estimated, session `abc123`)

| tokens | USD | active | wall | model |
|---|---|---|---|---|
| 1,403,090 | 2.05 | 0.17h | 0.49h | claude-opus-5 |

in 1.2M · out 21k · cache read 180k · cache write 1.1k'
```

Three rules that are not style preferences:

1. **`--body`, never `--body-file`.** The flow hook stamps the cost milestone by seeing the
   `ferion:cost` marker in the command it observes. A file path shows it nothing, and the milestone
   silently never closes. This is the design working as intended: stamp from reality, not from a claim.
2. **The marker carries the numbers**, the table carries the explanation. The marker is what `health`
   parses; keep the `key=value` shape.
3. **Several sessions on the same issue:** post a second comment (and let `health` sum the markers),
   or edit the first and add. Pick one and be consistent — do not mix.

## Where the numbers come from (and their limits)

| Number | Source | Trust it for |
|---|---|---|
| tokens | the local transcript, per issue slice | comparison, trend, per-task ranking |
| USD | `ccusage` price table, prorated onto the slice | estimates, not invoices |
| active hours | transcript timestamps, gap-capped | how long the AI actually worked |
| wall hours | first → last event | elapsed time, useful next to lead time |
| lead time | the issue timeline (`gh issue view --json`) | DORA, the human-side number |

**Authoritative billing is the provider console**, always. This is a signal for improving how you
work, not an invoice.

## When capture does not work

- **Browser-app flow** (typical for a PM): there is no local transcript. Record the lead time from
  the issue and note that the token cost is pending or came from a CLI session.
- **`ccusage` unavailable** (no network, no npx): hours still work. Post them, mark tokens/USD as
  unavailable.
- **Never** fill the gap with an estimate you did not measure. A wrong cost number is worse than no
  cost number: it gets aggregated, trended and used to price work.
