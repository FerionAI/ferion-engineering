# The mandatory flow — the 6 steps, the gates and the exceptions

Most standards have the order written down. What is usually missing is **who guarantees the order**:
prose does not hold an agent, a gate does. This playbook is the mechanics — `start` (and any skill
that touches code) operates on top of it.

## The 6 steps (the flow's single vocabulary)

| # | Step | Closes when… | Who stamps it |
|---|---|---|---|
| 1 | **issue** | the GitHub issue exists (the person cited it, or you asked and created it) | `gh issue create` (auto) or `stamp task <n>` |
| 2 | **in progress** | the issue has an **owner** (assignee = you) and the `status:in-progress` label | `gh issue edit --add-assignee/--add-label` (auto) or `stamp dev` |
| 3 | **implement** | spec/plan in `specs/<feature>/` + code as a vertical slice with tests | — (this is the work) |
| 4 | **local review** | `review` (DoD) + `preflight` (real tools + anti-hallucination) in a **loop until zero findings** | `stamp review` (only the agent knows) |
| 5 | **PR + cost** | PR open with `Closes #N` **and** tokens/USD/hours recorded on the issue | `gh pr create` and `gh issue comment` with the cost marker (auto) |
| 6 | **in review** | issue labelled `status:in-review`, **with the PR's CI green**, and said so in the summary | `gh issue edit --add-label` (auto) |

From merge onward, humans move things (QA, deploy) — the agent has no reliable signal and does not
invent one.

## The gates (hooks — they really block)

`hooks/flow-gate.sh` keeps the state in `<repo>/.git/ferion-flow` and reacts to 4 triggers. Blocking =
`exit 2`, with a message naming **which step is missing and how to close it**:

| Trigger | Requires | Blocks when |
|---|---|---|
| `Write`/`Edit`/`MultiEdit`/`NotebookEdit` on a repo file | step 2 | code with no assumed issue |
| `Bash` that writes into the repo (`>`, `>>`, `sed -i`, `tee`, `git apply`, `patch`) | step 2 | the same thing, through the back door |
| `gh pr create` / the MCP equivalent | step 4 | a PR without the local review closed · a PR **that references no issue** in the body or the branch |
| labelling `status:in-review` (with step 2 done) | steps 4+5 | moving to review without the PR **and** the cost · labelling with a **red CI check** on the PR (the hook reads `gh pr checks`; with no `gh`/no network it does not block) |

Outside a git repository, and for files outside the repo root (scratch, `/tmp`), **nothing is
blocked** — there is no delivery there to protect.

`PostToolUse` stamps the milestones from what the tool **actually did** (issue created, label
applied, PR opened, cost comment posted) — not from what the agent says it did. The only
self-declared step is **4** (`stamp review`), because only whoever ran preflight knows whether it
came out green; declaring it without running is the same hallucination preflight exists to catch.

## Commands (the agent uses these; the person never needs to)

```bash
bash <plugin>/hooks/flow-gate.sh status            # where the flow is and what the next step is
bash <plugin>/hooks/flow-gate.sh stamp task 123    # a new issue = a new flow (clears milestones and bypass,
                                                   #   and opens this issue's cost baseline)
bash <plugin>/hooks/flow-gate.sh stamp dev         # issue assumed outside the agent
bash <plugin>/hooks/flow-gate.sh stamp review      # preflight came out green
bash <plugin>/hooks/flow-gate.sh bypass "<reason>" # recorded exception (see below)
bash <plugin>/hooks/flow-gate.sh reset             # back to the flow (ends the bypass)
```

## Resume, never restart

New session, compacted context, a person coming back two days later: the state lives in the repo,
not in the conversation. **Read `status` and continue from the step it points to.** Do not redo a
closed step (do not recreate the issue, do not re-apply a label) and do not jump ahead.

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
