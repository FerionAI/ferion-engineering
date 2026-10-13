# MCP catalog — connecting the tools

MCP (Model Context Protocol) is how the agent operates a tool directly instead of asking you to copy
and paste from it. This plugin ships a minimal `.mcp.json` on purpose — add what your team uses.

## What ships

| Server | Type | Needs | What it unlocks |
|---|---|---|---|
| `github` | http | `GITHUB_PAT` | GitHub operations without `gh` (optional — everything in this standard works through `gh`) |
| `gitlab` | http (OAuth) | browser login — Claude: `/mcp`; Codex: `codex mcp login gitlab` | GitLab projects, issues, merge requests and pipelines (official server, `https://gitlab.com/api/v4/mcp`) |
| `playwright` | npx | — | driving a real browser: `preflight` devserver validation, UX checks |

**GitLab on a self-managed instance:** change the `gitlab` URL host to yours in **both**
`.mcp.json` and `.codex-plugin/mcp.json` (path stays `/api/v4/mcp`). The enforced flow on GitLab is
written for `glab` (`issues/references/forge-commands.md`); the hook also recognises this MCP's
`create_merge_request` / `update_issue` calls.

**Nothing here is required.** `gh` (or `glab` on GitLab) authenticated is the only hard dependency
of the standard (`setup/references/github-setup.md`, `setup/references/gitlab-setup.md`).

## Worth adding, by category

Add the official MCP for whatever your team already uses. The pattern in `.mcp.json`:

```jsonc
{
  "mcpServers": {
    "<name>": {
      "command": "npx",                    // or "type": "http" + "url"
      "args": ["-y", "<package>"],
      "env": { "TOKEN": "${YOUR_ENV_VAR}" } // secrets from the environment, never inline
    }
  }
}
```

| Category | Unlocks in this plugin |
|---|---|
| **Observability** (Datadog, Grafana, …) | `incident` investigation, `health` DORA and error metrics, post-deploy verification |
| **Static analysis** (SonarQube, …) | `quality` gate status, `preflight` step 1, `health` quality block |
| **Product analytics** (GA4, Amplitude, PostHog, …) | `discovery` empathy signals, Core Web Vitals, post-ship validation |
| **Session analytics** (Clarity, FullStory, …) | `discovery` behavior, `qa` reproducing a user-reported bug |
| **Design** (Figma) | `design-review` reading the actual design instead of a description |

## Rules

- **Secrets through environment variables**, never written into `.mcp.json`. The file is committed;
  the environment is not.
- **Least privilege on the token.** A read-only token for a read-only use.
- **An unconnected MCP degrades with a warning**, it never blocks. Every skill that uses one says
  what it could not verify rather than inventing the number — that is a hard rule
  (`preflight`: do not fake green).
- **Interactively-authenticated servers** (OAuth connectors) may be unavailable in headless or
  scheduled runs. Do not build a required step on one.

## Is it working? Ask, do not assume

"Configured", "connected" and "working" are three different things, and the distance between them is
where a report comes out with holes:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/hooks/check-sources.sh live     # real health check: who answers, who fails, and the fix
bash ${CLAUDE_PLUGIN_ROOT}/hooks/check-sources.sh banner   # credential presence only (what runs at session start, no network)
```

`live` runs `claude mcp list` and turns each state into an action. It exits **1** when a server
fails — usable as a gate before a pilot or a `health` report. When a skill needs a source and it is
missing, the right response is to say so and offer `setup`, not to work around it silently.

**Connected is not working:** some servers (analytics ones especially) connect with no credential at
all and only break on the first query. That is why `banner` (an env var is present) and `live` (the
handshake) complement each other — neither alone answers the question.

The errors lie about their cause, so read them through `live`:

- **`HTTP 400: Authorization header is badly formatted`** looks like a server bug and is a **missing
  credential**: the `${VAR}` in the header expanded to nothing.
- **`does not support dynamic client registration`** means the endpoint does not do OAuth — removing
  the header never fixes it; the token is mandatory. For the `github` server shipped here, the token
  `gh` already holds works: `export GITHUB_PAT=$(gh auth token)` in your shell profile.
- **`CONNECTION_CLOSED`** on a server run through Docker is the local process not starting: check the
  daemon (`docker info`), the active Docker context, and — on Linux — that your user's `docker` group
  membership is active (it only applies from the next login).
- **An env var set now does not apply to the open session:** servers start with the session — reopen.
- **A duplicated server does not help:** when the same MCP comes from the plugin and from a project's
  `.mcp.json`, approving both just opens two connections to the same thing. Pick one.
