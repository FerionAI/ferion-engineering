# MCP catalog — connecting the tools

MCP (Model Context Protocol) is how the agent operates a tool directly instead of asking you to copy
and paste from it. This plugin ships a minimal `.mcp.json` on purpose — add what your team uses.

## What ships

| Server | Type | Needs | What it unlocks |
|---|---|---|---|
| `github` | http | `GITHUB_PAT` | GitHub operations without `gh` (optional — everything in this standard works through `gh`) |
| `playwright` | npx | — | driving a real browser: `preflight` devserver validation, UX checks |

**Nothing here is required.** `gh` authenticated is the only hard dependency of the standard
(`setup/references/github-setup.md`).

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

## Checking what is available

Ask the agent what MCP tools it can see rather than assuming from the config file — a server can be
configured and not authorized. When a skill needs one and it is missing, the right response is to say
so and offer `setup`, not to work around it silently.
