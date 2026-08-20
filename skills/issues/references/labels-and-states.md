# Labels and states — moving the issue as the work moves

An issue that stays in the backlog while the code is being written destroys the team's trust in the
"source of truth". Two milestones are the agent's responsibility, and both are stamped from a real
command.

## The two automatic milestones

| Milestone | When | Command | What the hook does |
|---|---|---|---|
| `in progress` | before the first line of code | `gh issue edit <n> --add-assignee @me --add-label status:in-progress` | stamps step 2 → unlocks editing files |
| `in review` | after the PR is open **and** the cost is recorded | `gh issue edit <n> --add-label status:in-review` | stamps step 6 → closes the flow |

Everything else — QA passed, deployed, done — is a **human gate**. The agent has no reliable signal
and must not guess.

## The label vocabulary

The standard needs exactly two labels to work. Anything else is your team's taxonomy.

```bash
gh label create status:in-progress --color 0E8A16 --description "Someone assumed the issue and is implementing"
gh label create status:in-review   --color FBCA04 --description "PR open, waiting for review"
```

Recommended, not required:

| Label | Use |
|---|---|
| `status:ready` | meets the Definition of Ready — safe to pick up |
| `type:feature` / `type:bug` / `type:chore` | the nature of the work |
| `blocked` | waiting on something external; pair it with a comment saying what |

## If your team already has a vocabulary

Do not impose a second one. Map the existing labels (or the Project column) to the two milestones in
`config/team-config.md`:

```markdown
| Milestone | This team's label |
|---|---|
| in progress | `wip` |
| in review | `needs-review` |
```

Then use those names in the commands. The hook stamps from the label it sees in the command, so any
name works as long as the team config and the commands agree.

## Using a GitHub Project board

Teams that live in Projects v2 can keep the board as the human-facing view and the label as the
machine-readable half. Set the Project's automation to mirror the label (Projects can move a card
when a label is added), and let the agent write the label. The reverse — the agent writing the
Project field — needs GraphQL and produces nothing the hook can observe, which is why the standard
does not depend on it.

## Degradation

- **Cannot label** (no permission, label does not exist): say so and continue — delivery does not
  stall over a label. But say it explicitly, and record it as a pending item; do not stay silent.
- **The issue was moved outside the agent** (someone labelled it by hand): record it so the flow
  state matches reality:
  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/hooks/flow-gate.sh stamp task 123
  bash ${CLAUDE_PLUGIN_ROOT}/hooks/flow-gate.sh stamp dev
  ```
  Never stamp a step that did not happen — that is the exact failure mode the gate exists to prevent.

## The collision guard

Before applying `status:in-progress`, read the real state. If the issue already has **another**
assignee, or is already in progress or beyond, **stop and ask**. This is the only point in the flow
where the agent blocks on a question, and it is worth it: two developers on the same issue is the
most expensive rework there is.
