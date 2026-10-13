# GitLab setup — the required dependency, GitLab edition

Same role as `github-setup.md`, for teams whose code, issues and MRs live on GitLab (gitlab.com or
self-managed). Everything rides on `glab`. If it works, the plugin works.

## 1. Install and authenticate

```bash
glab --version || echo "install from https://gitlab.com/gitlab-org/cli"
glab auth status || glab auth login                     # gitlab.com
glab auth login --hostname <FILL: gitlab.your-company.com>   # self-managed
```

**Token scope:** `api` (issues, MRs, labels, notes). Verify with something real:

```bash
glab repo view
glab issue list -P 3
```

**Self-managed host that does not contain "gitlab"?** Tell the flow which forge this is (once per
clone), otherwise it suggests `gh` commands:

```bash
git config ferion.forge gitlab
```

## 2. Create the flow labels (scoped)

```bash
glab label create --name status::in-progress --color '#0E8A16' --description "Someone assumed the issue and is implementing"
glab label create --name status::in-review   --color '#FBCA04' --description "MR open, waiting for review"
```

Scoped labels (`::`) are exclusive on GitLab Premium — a stage replaces the previous one. On Free
they are ordinary labels and the review step removes `status::in-progress` explicitly
(`issues/references/forge-commands.md`). Already have a vocabulary (`workflow::doing`, a board
list)? Map it in `config/team-config.md` instead of creating a second one.

Optional: `status::ready`, `type::feature`, `type::bug`, `type::chore`.

## 3. Project settings the flow assumes

| Setting | Why it matters |
|---|---|
| Issues enabled | the source of truth lives there |
| Default closing pattern (`Closes #N`) on | the MR↔issue traceability link |
| Protected default branch + "Pipelines must succeed" | P3: no merge without review + green CI |
| Approval rules (if your tier has them) | the "reviewed by a peer" half of P3 |

The agent does not change project settings. Report what is missing and let a human decide.

## 4. The GitLab MCP (optional)

The plugin ships the official GitLab MCP (`https://gitlab.com/api/v4/mcp`, OAuth). Log in with
`/mcp` (Claude) or `codex mcp login gitlab` (Codex). Self-managed: change the host in `.mcp.json`
and `.codex-plugin/mcp.json`. It is an alternative to `glab`, not a requirement.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `glab: command not found` | not installed | gitlab.com/gitlab-org/cli |
| `401 Unauthorized` | token missing/expired, or wrong host | `glab auth login --hostname <host>` |
| `404 Project Not Found` | not inside the repo, or no access | run inside the clone, or `-R group/project` |
| The hook suggests `gh` commands | the remote host does not say "gitlab" | `git config ferion.forge gitlab` |
| The flow gate never stamps | the command ran outside the agent, or the cost note came from a file | `flow-gate.sh stamp <step>`, and pass the cost with `-m "…"` |
