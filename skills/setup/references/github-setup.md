# GitHub setup — the one required dependency

Everything in this standard rides on GitHub Issues and PRs, operated through `gh`. This is the whole
setup. If it works, the plugin works.

## 1. Install and authenticate

```bash
gh --version || echo "install from https://cli.github.com/"
gh auth status || gh auth login
```

`gh auth login` walks through browser or token auth. Choose HTTPS unless the team standardizes on
SSH — it matters only for `git`, not for `gh`.

**Scopes needed:** `repo` (read/write issues, PRs, labels). If the team uses Projects and you want
the agent to read board state, add `read:project`. Nothing in the mandatory flow requires it.

Verify with something real, not just the auth check:

```bash
gh repo view --json nameWithOwner,visibility
gh issue list -L 3
```

## 2. Create the flow labels

The mandatory flow stamps its milestones from labels, so they have to exist:

```bash
gh label create status:in-progress --color 0E8A16 --description "Someone assumed the issue and is implementing"
gh label create status:in-review   --color FBCA04 --description "PR open, waiting for review"
```

Already have an equivalent vocabulary (`wip`, `needs-review`, a Project column)? **Do not create a
second one.** Map yours in `config/team-config.md` and use those names in the commands — the hook
stamps from whatever label it sees (`issues/references/labels-and-states.md`).

Optional, useful:

```bash
gh label create status:ready --color 1D76DB --description "Meets the Definition of Ready"
gh label create type:feature --color C2E0C6
gh label create type:bug     --color D93F0B
gh label create type:chore   --color EDEDED
```

## 3. Check the repository settings that the flow assumes

| Setting | Why it matters |
|---|---|
| Issues enabled | the source of truth lives there |
| `Closes #N` allowed (default) | this is the PR↔issue traceability link |
| Branch protection on the default branch | P3: no merge without review + green CI |
| Required status checks | so "green CI" means something |

The agent does not change repository settings. Report what is missing and let a human decide.

## 4. The GitHub MCP (optional)

`.mcp.json` ships a GitHub MCP entry that needs a `GITHUB_PAT` environment variable. It is an
alternative to `gh`, not a requirement — every command in this standard is written for `gh` precisely
so that a fresh install needs no tokens pasted anywhere. Enable the MCP if you want the agent to work
with GitHub data it cannot reach through the CLI; otherwise leave it alone.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `gh: command not found` | not installed | [cli.github.com](https://cli.github.com/) |
| `HTTP 403` on issue create | token lacks `repo`, or the repo is read-only for you | `gh auth refresh -s repo` |
| `could not determine base repository` | not inside a git repo, or no remote | `gh repo set-default` |
| Label create fails with 422 | the label already exists | fine — that is the idempotent path |
| The flow gate never stamps | the command ran outside the agent, or `--body-file` hid the cost marker | `flow-gate.sh stamp <step>`, and use `--body` for the cost comment |
