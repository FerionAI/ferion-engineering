# The mandatory flow — the 6 steps, the gates and the exceptions

Most standards have the order written down. What is usually missing is **who guarantees the order**:
prose does not hold an agent, a gate does. This playbook is the mechanics — `start` (and any skill
that touches code) operates on top of it.

## The 6 steps (the flow's single vocabulary)

| # | Step | Closes when… | Who stamps it |
|---|---|---|---|
| 1 | **issue** | the issue exists (the person cited it, or you asked and created it) | `gh`/`glab issue create` (auto) or `stamp task <n>` |
| 2 | **in progress** | the issue has an **owner** (assignee = you) and the `status:in-progress` label | `gh issue edit --add-assignee/--add-label` (auto) or `stamp dev` |
| 3 | **implement** | spec/plan in `specs/<feature>/` + code as a vertical slice with tests | — (this is the work) |
| 4 | **local review** | `review` (DoD) + `preflight` (real tools + anti-hallucination) in a **loop until zero findings** | `stamp review` (only the agent knows) |
| 5 | **PR + cost** | PR open with `Closes #N` **for every issue** **and** tokens/USD/hours recorded on each issue | `gh pr create` and `gh issue comment` with the cost marker (auto) |
| 6 | **in review** | issue labelled `status:in-review`, **with the PR's CI green**, and said so in the summary | `gh issue edit --add-label` (auto) |

After step 6 the tech lead takes it to QA (skill `approve`): the agent fixes mechanical gaps on the
PR branch and labels `status:in-qa` only after the tech lead approves on GitHub — the gate checks the
real decision, not the conversation. From there on, humans move things (QA, deploy) — the agent has no
reliable signal and does not invent one.

**GitLab:** identical steps with `glab` — `glab issue create`, `glab issue update --assignee/--label
status::in-progress`, `glab mr create` with `Closes #N`, `glab issue note` for the cost and
`status::in-review`. The hook recognises both CLIs; the forge (remote, or `git config ferion.forge`)
only decides which commands it suggests and how it reads CI — the MR's head pipeline instead of
`gh pr checks`. Command table: `issues/references/forge-commands.md`.

## The gates (hooks — they really block)

`hooks/flow-gate.sh` keeps the state in `<repo>/.git/ferion-flow` and reacts to 5 triggers. Blocking =
`exit 2`, with a message naming **which step is missing and how to close it**:

| Trigger | Requires | Blocks when |
|---|---|---|
| `Write`/`Edit`/`MultiEdit`/`NotebookEdit` on a repo file | step 2 | code with no assumed issue · another group's code **in the same session** (an unlinked issue needs a new session, § Batch) |
| `Bash` that writes into the repo (`>`, `>>`, `sed -i`, `tee`, `git apply`, `patch`) | step 2 | the same thing, through the back door |
| `gh pr create` / `glab mr create` / the MCP equivalent | steps 3+4 | a PR without the local review closed · a PR **with no spec**: no file under `specs/` changed on the branch since `main` (no remote: no block) · a PR **that misses an issue** (of the group) in the title/body and the branch |
| labelling `status:in-qa` / `status::in-qa` (an issue the tech lead registered with `tl`, or the flow's own issue) | the tech lead's yes | a PR with **no human decision**, with changes requested, or with a **red CI check** (checked live with `gh` or `glab`; no CLI: no block). Works outside a repo too — the tech lead's session crosses repos |
| labelling `status:in-review` (with step 2 done **on that issue**) | steps 4+5 | moving to review without the PR **and** the cost **of that issue** · labelling with a **red CI check** on the PR (the hook reads `gh pr checks` or the MR's head pipeline via `glab`; with no CLI/no network it does not block) |

Outside a git repository, and for files outside the repo root (scratch, `/tmp`), **nothing is
blocked** — there is no delivery there to protect.

`PostToolUse` stamps the milestones from what the tool **actually did** (issue created, label
applied, PR opened, cost comment posted) — not from what the agent says it did. The only
self-declared step is **4** (`stamp review`), because only whoever ran preflight knows whether it
came out green; declaring it without running is the same hallucination preflight exists to catch.

## Commands (the agent uses these; the person never needs to)

```bash
bash <plugin>/hooks/flow-gate.sh status            # ONLY if the session banner did not come — the
                                                   #   SessionStart hook already runs this and injects it
bash <plugin>/hooks/flow-gate.sh stamp task 123    # a new issue = a new flow (clears milestones and bypass,
                                                   #   and opens this issue's cost baseline)
bash <plugin>/hooks/flow-gate.sh stamp task 12 13  # a group: one PR for both (§ Batch). Naming the
                                                   #   current issue extends the group without clearing it
bash <plugin>/hooks/flow-gate.sh stamp dev         # issue assumed outside the agent
bash <plugin>/hooks/flow-gate.sh stamp review      # preflight came out green
bash <plugin>/hooks/flow-gate.sh tl 42 <PR URL>    # the tech lead starts reviewing (skill `approve`): arms
                                                   #   the QA gate, allows fixing the PR branch; the state
                                                   #   lives in ~/.claude/ferion-approvals (per machine)
bash <plugin>/hooks/flow-gate.sh bypass "<reason>" # recorded exception (see below)
bash <plugin>/hooks/flow-gate.sh reset             # back to the flow (ends the bypass)
```

## Resume, never restart

New session, compacted context, a person coming back two days later: the state lives in the repo,
not in the conversation. **`SessionStart` already injects the `status` into the banner — continue
from the step it points to**, without running the command again (a re-query costs a round trip with
the whole context and brings nothing new: the milestones only change through what you did). Do not
redo a closed step (do not recreate the issue, do not re-apply a label) and do not jump ahead.

## Batch — one PR for what is linked

"Take these 4 issues" means neither one at a time nor all at once. Linked issues become a **group**:
one branch, one spec, one local review and one PR. Unlinked ones go one at a time, each with its own
PR. The strength of the signal decides:

| Signal | When | What the agent does |
|---|---|---|
| **Strong** | a dependency between them (one blocked by the other, a task list tying them); one does not compile or test without the other; they touch the same function or screen (separate PRs would conflict and redo work); the person asked for "one PR" | groups and moves on, saying in **one line** which group and why |
| **Weak** | same epic, same module or a similar theme, but each can ship on its own | explains the grouping (which issues, why, estimated size) and **asks** |
| **Never groups** | different repositories (that is `workspace`: one PR per repo); an estimated total well past ~400 lines (P3); one of them is a hotfix (`incident`) | one at a time |

Group mechanics:
- `stamp task 12 13 14`. Assuming any issue of the group clears nothing.
- The PR names **every** issue (`Closes #12, closes #13, closes #14` in the body); the branch carries the first.
- Each issue records **its own** cost before it is labelled for review. The group's cost is measured
  once and split equally across the issues (`cost`), and the comment on each one says so.
- Found out midway that another issue belongs: `stamp task <the current ones> <the new one>` extends
  the group without losing a milestone. The diff grew past P3 midway: say so and propose splitting
  before the PR.

Unlinked issues of the same batch go one at a time, **each in a new session**. The previous issue's
context makes every call of the next one dearer (cost ≈ calls × context), so the gate blocks editing
another group's code in the same session. Once one is labelled `in review`: assume the next and ask
for `/clear` with the sentence ready to paste ("continue the batch: #7, #8, #9"). The state lives in
the repo and the new session resumes from there. To run them in parallel, use one session per
worktree, since each worktree has its own flow state.

## Exceptions — the only honest way out of the flow

Legitimate work exists outside the pipeline: an incident hotfix (`incident`, which opens the issue
and the action items afterwards), a repository with no issue tracker, a change that is not code. In
those cases:

1. `bypass "<reason>"` — recorded in the repo state.
2. **Declare it in the delivery summary.** A silent bypass is exactly the hole this mechanism exists
   to close.
3. `reset` (or a new issue) ends the bypass.

**Never** close a step with `stamp` without doing its work. Stamping `review` without running
preflight is lying to your own team — and the PR's automated reviewer disproves it in five minutes.

## When the person asks to skip

"Just write the code, I'll create the issue later", "open the PR already": answer in **one line**
what is missing and **do the missing step** (creating the issue is one question and one command; the
preflight is what stops the PR from bouncing back). If the person restates that they want to skip,
that is their call: record the `bypass` with their reason and continue — with the note in the
summary, never in silence.

## Why labels and not a Project board

The flow needs a state that is (a) readable in one command, (b) writable in one command, and (c)
visible in the payload of the command that wrote it — that last one is what lets the hook stamp from
reality. Labels satisfy all three with `gh`; a GitHub Project v2 field needs GraphQL and returns
nothing the hook can see. Teams that live in Projects can keep doing so — just map the column to the
label in the team config and let the label be the machine-readable half.
