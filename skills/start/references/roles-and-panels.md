# The person's role — detect, confirm, and the entry panel

The plugin is **not** split by actor: every skill stays available to everyone. What the role does is
**order the offer** — what shows up first, what the panel shows, which next step is suggested. Three
rules govern the rest:

1. **A role does not restrict, it only orders.** Anyone runs any skill.
2. **Detecting is not guessing.** Without a reliable signal, **ask once and persist the answer**.
   Never assume a role in silence — getting it wrong on the first interaction burns trust right when
   people are deciding whether to adopt the tool.
3. **The role is per person, not per repository.** Writing it into `config/team-config.md` (which
   belongs to the team) would let the last person who ran `setup` decide everyone's role.

## Where the role lives

**`~/.claude/ferion-profile.md`** — user level, crosses repositories, outside version control.

```yaml
---
role: qa                 # pm | qa | dev | tech-lead
name: <how to address the person>
team: <team or squad>
repos: [owner/api, owner/web]   # tech-lead: the repositories whose review queue `approve` sweeps
detected_on: <YYYY-MM-DD>
confirmed: true          # false = an unconfirmed guess; `start` asks again
---
```

Read it with `Read`. **A missing file is not an error** — it is case 4 in the table below (ask and
create it). Never write a role into `config/team-config.md` or any file in a repository.

## Precedence (strongest to weakest)

| # | Source | Confidence | Action |
|---|---|---|---|
| 1 | `role` in `~/.claude/ferion-profile.md` with `confirmed: true` | high | use it, no question |
| 2 | Role stated in the request ("I'm QA and I want…") | high | use it **and record it** (`confirmed: true`) |
| 3 | A guess from environment signals (below) | **low** | **propose, do not assume** |
| 4 | Nothing | — | ask once (4 options), record the answer |

When recording, write the whole file (the frontmatter above), with `detected_on` set to today.

## Environment signals — only to propose

None decides on its own. They turn the open question ("what is your role?") into a one-click
confirmation ("looks like you are a dev — right?"), which gets answered far more often.

- the directory holds application code, or only tests;
- **the person's own** git history in this repo: commits in `src/` vs `tests/` vs none
  (`git log --author="$(git config user.email)" --name-only -30`);
- the e-mail domain or group in git config, if the team has a convention (`config/team-config.md`);
- the first intent of the session ("I need to automate a test case" → QA; "I'm opening an epic" →
  PM).

**Golden rule:** if the signals disagree, **propose none** — ask openly. A wrong guess delivered with
confidence is worse than a question.

## When behavior contradicts the recorded role

Someone recorded as `qa` running `ship` three times in a row is not an error — it may be a role in
transition, which is the whole point of not restricting. **Do not switch it yourself.** Offer one
discreet line at the end of the answer — *"I noticed you have been using the dev track; want to update
your profile?"* — and move on. Never interrupt the work over it.

## The panel

> On GitLab the panels run the same queries with `glab` (`issues/references/forge-commands.md`);
> the hard dependency becomes `glab auth status`.

**Ceiling: 5 lines of state and ONE next step.** A long panel is not read; a panel that turns into a
report dies. Every line comes from a real source — **no source, no line** (or the line says what is
missing). Never invent a number: the same rule that protects `preflight`.

If `gh` is not authenticated (`gh auth status` — the only hard dependency), **do not render a
panel**: say in two lines what you do not know, what that prevents, and offer `setup`. A label a line
depends on that does not exist in the repo (`gh label list`) removes that line, silently.

The flow state is already in the session banner — do not repeat it in the panel.

### QA

```
Track: qa → preflight → quality

  Waiting for QA       4 issues · oldest 3 days
  Open bugs            9 · 3 untriaged (no assignee)
  Skipped tests        5 · 1 past its expiry date

→ Next step: test #405 (oldest in QA). Shall I build its test cases with `qa`?
```

| Line | Source |
|---|---|
| Waiting for QA | `gh issue list --label status:in-qa --json number,updatedAt` (the label `approve` applies) |
| Open bugs | `gh issue list --label type:bug --state open --json number,assignees` (or the team's bug label) |
| Skipped tests | grep for `test.skip`/`it.skip`/`xit(`/`@Ignore`/`@pytest.mark.skip`/`t.Skip(`; when the team writes an expiry next to it (`quarantine until YYYY-MM-DD`), mark what has expired |

### Dev

```
Track: spec-flow → ship → preflight → review

  Your open PRs                   2 · 1 with a red check
  Reviews requested from you      3
  Test-only PRs awaiting review   1
  CI time (7-day average)         8 min 40 s
```

| Line | Source |
|---|---|
| Your open PRs | `gh pr list --author @me --state open` + `gh pr checks` on each |
| Reviews requested from you | `gh pr list --search "review-requested:@me"` |
| Test-only PRs awaiting review | open PRs whose diff touches **only** test files (`gh pr list --json number,files`) |
| CI time | average duration of the CI runs over 7 days (`gh run list --json startedAt,updatedAt`) |

"Test-only PRs awaiting review" is there **from day one**: a test written by QA that waits a week for
a developer's review is how the collaboration between the two dies — an invisible queue is the most
likely failure of the whole design.

### PM

```
Track: epic → discovery → issues

  Open epics with no child issues   2
  Ready, not picked up              6 · oldest 9 days
  Blocked                           1 (#388)
```

| Line | Source |
|---|---|
| Epics with no child issues | open epics (the team's epic label) whose body has no task list (`- [ ] #`) |
| Ready, not picked up | `gh issue list --label status:ready --json number,createdAt,assignees`, no assignee |
| Blocked | `gh issue list --label blocked` |

### Tech lead

```
Track: approve → health → quality → cost

  Review queue (your repos)        5 · oldest 4 days
  Merged with a red check (7d)     1
  Skipped tests                    12 · 3 past their expiry
  Escaped defects (30d)            4
  Cost capture coverage (30d)      68%
```

| Line | Source |
|---|---|
| Review queue | the `approve` query: `status:in-review` in the profile's `repos` |
| Merged with a red check | PRs merged in 7 days with a failing check (`gh pr list --state merged --json statusCheckRollup`) — the `health` metric |
| Skipped tests | the same sweep as the QA panel, without filtering by owner |
| Escaped defects | bugs opened in 30 days carrying the team's production label (`config/team-config.md`); no such label → the line disappears |
| Cost capture coverage | issues closed in 30 days with a `ferion:cost` comment ÷ issues closed (`health/references/cost-report.md`) |
