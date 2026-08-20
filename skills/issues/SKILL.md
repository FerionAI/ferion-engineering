---
name: issues
description: GitHub Issues are the source of truth of the work — the issue holds everything, from the product intent to the QA review, and the whole flow runs through AI. Use when someone asks to look at issues in a stage ("what's in review / in the sprint / in the backlog", "my issues", "blocked issues"), to take an issue as the basis for work ("take #123 and implement it", "what was asked in this issue"), or to update progress (comment, label, link the PR). Always treat the issue as the base of truth: read from it and write back to it. If a change has no issue, create one (every change becomes an issue, by rule — ask what is missing, do not scan the backlog). Operated through `gh`; the GitHub MCP is optional.
---

# Issues — the source of truth

**The GitHub issue is the source of truth of the work**: the product intent, the acceptance
criteria, the decisions, the PR links and the QA reviews live on the issue. Because the whole flow
runs through AI, the agent always **starts from the issue** and **writes back to it** — it never
works "on the side".

Operate through the **`gh` CLI** (no extra setup: if `gh auth status` is green, everything below
works). The GitHub MCP is an optional alternative, not a requirement.

## Make sure the issue exists before starting (rule: every change becomes an issue)

Every code change is born from an issue — **no issue, no code.** When someone asks for development
work (feature, fix, tweak), before anything else:

1. **Is there an issue?** If the request already cites a number (`#123`), use it. If it **does not
   mention one**, **ask** the person ("does this change have an issue? which one?") — **do not scan
   the backlog** trying to guess.
2. **Does not exist? Create it** with the standard fields:
   ```bash
   gh issue create --title "<what>" --body "<why + acceptance criteria + DoD>" \
     --label "type:feature" --assignee @me
   ```
   - **Type** (feature/bug/chore) as a label, and the right repository.
   - **Title** and **body** with the request (what/why), **testable acceptance criteria** and the
     **Definition of Done**; the standard flags where applicable (security/OWASP, privacy, design
     system, observability) — same quality as an issue produced by `epic`. Link it to the parent
     epic when there is one (`- [ ] #123` in the epic's task list).
3. **Labels not set up yet?** If the team config has no label taxonomy, **ask the minimum** (type)
   and create the issue anyway — do not block the work; record what you learned for next time. Do
   not invent a label that does not exist (`gh label list` tells you what does).
4. **This applies to everything** — including a small one-line fix. An emergency hotfix enters
   through `incident` (which opens the issue plus the action items); the exception is always
   recorded, never silent.

Only once the issue exists does the flow continue (`spec-flow`/`ship`).

## Assume the issue before coding (owner + collision guard)

An issue with no owner is an issue two developers pick up. **Before the first line of code** — at
the `in progress` milestone — the agent resolves ownership, not just status:

1. **Read the real state:** `gh issue view <n> --json assignees,labels,state,title,body`.
2. **Collision? Stop and ask.** If the issue already has **another** assignee, or is already
   `status:in-progress` or beyond, **do not start**: say so ("#123 is already assigned to someone
   else and in progress since the 11th — should I continue anyway, take it over, or is it a
   different issue?") and wait for the answer. This is the one point in the flow where the agent
   **blocks**: duplicated work costs more than one question.
3. **Free? Take it.**
   ```bash
   gh issue edit <n> --add-assignee @me --add-label status:in-progress
   ```
   Do not ask first — do it and mention it in the summary.
4. **Cannot assign** (permissions, external contributor): say so and continue — delivery does not
   stall over a field. But the warning is explicit, not silence.

> **The milestone unlocks the code.** Until the issue is assumed and labelled, the flow hook
> **blocks any edit to a repository file** (`start/references/mandatory-flow.md`). The stamp comes
> automatically from the `gh issue edit` above; if the issue was moved **outside the agent** (someone
> did it by hand), record it: `bash ${CLAUDE_PLUGIN_ROOT}/hooks/flow-gate.sh stamp task <n>` and
> `... stamp dev`. Never stamp what did not happen.

Assuming the issue **is part of starting**, like creating the branch. A board where work in progress
has neither owner nor status is a board that coordinates nobody.

## Understanding requests by stage (natural language)

Translate the phrasing into a `gh` query and bring back the essentials of each issue (number, title,
labels, assignee, acceptance criteria):

| The person says… | Query |
|---|---|
| "what's in review" | `gh issue list --label status:in-review` |
| "what's in progress" | `gh issue list --label status:in-progress` |
| "what's in the backlog" | `gh issue list --search "no:label sort:created-asc"` or the backlog label |
| "my issues", "what's mine" | `gh issue list --assignee @me` |
| "blocked issues" | `gh issue list --label blocked` |
| "ready for dev", "refined" | `gh issue list --label status:ready` (see `references/labels-and-states.md`) |
| "#123", "this issue" | `gh issue view 123 --comments` |
| "the epic and its children" | `gh issue view <epic> --json body` and read the task list |

> Do not invent a label: `gh label list` is the authority on what exists in this repository. If the
> label the person means does not exist, say so and offer to create it — do not silently query
> something else. Full lifecycle and query recipes: `references/issue-lifecycle.md`.

## Using the issue as the basis (the flow runs through it)

When you pick up an issue to work on:

1. **Read the whole issue** — body, acceptance criteria, comments, linked PRs, sub-issues. That is
   the real spec. `gh issue view <n> --comments` gives you all of it in one call.
2. **Developing means going through the pipeline, not coding directly.** The issue is the **input**
   to `spec-flow` (specify→clarify→plan→tasks, which **generates `specs/<feature>/`**) and to the
   `ship` combo — **never jump from "I read the issue" to "I implemented it"**. If clarity is
   missing, record the questions **as a comment on the issue** (clarify), not only in the chat.
3. **Run `spec-flow`/`ship`** aimed at the acceptance criteria (the target of the tests — P2): the
   spec/plan are generated and recorded **before** implementing. If the request is a **batch**
   ("work through my issues in state X"), confirm the scope and take **each** issue through the
   pipeline — do not code the batch straight through.
4. **Write back:** link the PR to the issue (`Closes #N` in the PR body — GitHub closes it on merge),
   comment on progress and decisions, and **move the labels** — the issue reflects reality, it never
   sits in the backlog while the agent works. There are 2 automatic milestones:
   `status:in-progress` when implementation starts, and `status:in-review` when the PR opens. The
   agent **acts and reports** (it does not ask first).
5. **QA:** QA reviews also live on the issue. The QA team uses the `qa` kit (test cases from the
   criteria, bug report, regression, exploratory, automation, gate) and records everything on the
   issue. From merge onward **humans move the state** — QA, deploy and closing are human gates and
   the agent has no reliable signal that they happened.

## Writing on GitHub (body, comments)

GitHub takes **GitHub Flavored Markdown** everywhere — no special encoding, unlike most trackers.
Two things worth knowing:

- **Task lists** (`- [ ] #123`) inside an epic's body create real sub-issue relationships in the
  GitHub UI. That is how `epic` links children to parents.
- **Closing keywords** in the PR body (`Closes #123`, `Fixes #123`) are what tie the PR to the issue
  and close it on merge. Use them — this is the traceability link the standard depends on.
- **Long bodies:** `--body-file` avoids shell quoting problems. The one exception is the cost
  comment, which must use `--body` so the flow hook can see the marker (`cost`).

## Principles

- **The issue wins.** If the code diverges from the acceptance criteria, the issue wins — or the
  divergence is discussed and recorded on it (it does not vanish into a chat log).
- **End-to-end traceability:** issue → spec/plan → PR (`Closes #N`) → QA (on the issue). Any
  delivery's history can be reconstructed from the issue.
- **Do not duplicate the truth.** Do not recreate the spec outside the issue; reference and
  complement it.
- **Always current.** Labels and comments up to date — a stale issue destroys the team's trust in
  the "source of truth".
- **The issue carries the cost.** When the PR opens, record tokens, USD and hours as a comment on
  the issue itself (skill `cost`) — cost lives next to scope and QA.

## In the flow

- **`start`:** requests about issues and stages land here.
- **`spec-flow` / `ship`:** they begin by reading the issue.
- **`review` / `qa`:** review results recorded on the issue.
- **`integrations` (GitHub):** the PR references the issue (`Closes #N`), closing the loop between
  the tracker and the code.
