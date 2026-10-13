# READINESS — ready to publish and install through the marketplace

What breaks a plugin **after** it ships rarely breaks the build: a version that disagrees between
manifests, a hook pointing at a script that moved, a skill count the README gets wrong, a secret
someone committed. Nobody sees those until a person installs — and then they see them alone, on their
machine.

The rule of this page: **what is verified** and **what is presumed** live in different sections. An
item that cannot be checked offline goes under "Only a real install proves it", never under "OK".

## 1. Checked automatically, every release

`sh scripts/check-readiness.sh` (in CI next to `validate-plugin.sh`). A failure blocks; a warning
does not.

| Check | What fails silently without it |
|---|---|
| **A1** manifests: `marketplace.json` has `name`, `owner.name`, `plugins`; `plugin.json` name in kebab-case; the `source` is an existing directory | the marketplace entry appears and installs nothing |
| **A1** every path `plugin.json` declares exists — `commands`/`agents`/`outputStyles` **replace** the default directory when declared | one wrong path erases every command or agent |
| **A1** every script `hooks.json` calls exists; `${CLAUDE_PLUGIN_ROOT}` quoted (warning) | a hook fails only when its event fires; an install path with a space breaks every unquoted hook |
| **A2** one version in `plugin.json`, both places in `marketplace.json`, `.release-please-manifest.json` and every file with the release-please marker | nobody receives the update, and nothing says so |
| **A3** every "N skills" in the docs matches `skills/*/SKILL.md` | the package's own docs lie about the package |
| **A3** no absolute path from someone's machine in a shipped file | works for the author, breaks for everyone else |
| **A5** no `<FILL: ...>` in a JSON manifest (in docs it is the design) | the install itself breaks |
| **A6** no secret in a tracked file (AWS/GitHub/Slack/Anthropic tokens, private keys, credentials in a URL) | a public repository publishes it |
| **A7** no tracked artifact (`node_modules/`, `dist/`, `build/`, `.env`, logs, `__pycache__/`, editor folders); `.gitignore` covers local config | machine junk ships to every install |

`validate-plugin.sh` covers the rest: JSON, frontmatter, refs, `skills/ROLES.md` in both directions,
the constitution copies, the playbook index, the leak check and the hooks' own tests.

## 2. Decisions (and when to revisit them)

**Do not declare `hooks` in `plugin.json`.** `hooks/hooks.json` is the default location, and the docs
do not describe the merge rule when the manifest also declares the key — declaring it blindly risks
**firing every hook twice**, which is worse than the risk it removes. A real install loads the hooks
without the key. *Revisit if* the docs describe the merge, or a hook stops firing after an update.

**Do not run `claude plugin validate --strict` in CI.** Strict mode turns an unknown field into an
error: it would protect against schema drift, but it breaks CI the day the docs add a field this
repository does not use yet, and the cost lands on whoever only wanted to merge. *Revisit if* a bug
comes from a misspelled manifest field.

## 3. Only a real install proves it

Run once per release, on one machine first. Each step has a pass criterion and, when it fails, the
next check — never "try again". Write down command, output and version: without a record, the second
person repeats the first one's mistake.

| # | Step | Passes when | When it fails |
|---|---|---|---|
| 1 | `/plugin marketplace add <owner>/<repo>` | `/plugin marketplace list` shows the marketplace | a private fork not authenticating — see §4.1 |
| 2 | `/plugin install <plugin>@<marketplace>`, reopen the session | `/plugin list` shows it enabled, **at the version of `main`**, and the session banner appears | no banner = hooks did not load; an old version = a stale cache (`/plugin marketplace update <marketplace>`) |
| 3 | A skill that only reads files: *"what is the engineering standard here?"* | the answer brings the principles **P1–P8** — the skill's body came along, not just its name | "Unknown command" = the content did not come down (an empty Skills tab), not a wrong name |
| 4 | A skill that runs a command: *"run the selftest of the source check"* (`hooks/check-sources.sh --selftest`) | the selftest line prints OK | find which: `${CLAUDE_PLUGIN_ROOT}` did not resolve, `bash`/`python3` missing, or a different working directory (`pwd`) — record all three even when it passes |
| 5 | `bash <plugin>/hooks/check-sources.sh live` | every server declared in `.mcp.json` appears; one asking for a token is expected | none appears = `.mcp.json` did not load (`"mcpServers"` in the installed `plugin.json`) |
| 6 | Steps 1–4 again in the desktop app / Cowork | same results as the CLI | write down exactly what differs — see §4.2 and `docs/claude-desktop-install.md` |

**Stop the rollout — do not work around it — if** installing needs someone's personal token, a secret
shows up in the package, a hook blocks legitimate work for more than one person, a skill runs a
command with an unexpected side effect, or the installed version does not match `main` and nobody can
say why. Treat it as a plugin bug: an issue, a fix, a new version.

## 4. Known risks

**4.1 — Installing from a private fork.** The plugin is public; a team fork may not be. The CLI uses
the git credential helpers already on the machine, and the short `owner/repo` form **clones over SSH
by default** (a key in the agent, the host in `known_hosts`). A token in the environment is not
enough on its own — it only counts through a helper (`gh auth setup-git`). The background refresh of
the marketplace runs without the helpers and, when it fails, may re-clone from scratch: a plugin that
"disappears" or rolls back without anyone touching it is this. The desktop app is different again:
`docs/claude-desktop-install.md`.

**4.2 — The skills' runtime in Cowork is not documented.** Working directory, environment variables
and access to `bash`/`python3` are not described publicly. Several skills here run commands
(`flow-gate`, `session-cost`, `pr-bots`, `check-sources`): they may degrade there and work in the CLI.
Step 6 exists to find out instead of presuming.

**4.3 — Version drift.** If a release does not go out, nobody gets the update. `check-readiness`
catches versions that disagree; `hooks/check-version.sh` tells each installed copy, at session start,
that it is behind the latest tag. Neither detects "the version should have gone up and did not".

**4.4 — A broken MCP server lies about its cause.** `Authorization header is badly formatted` is a
missing credential; `does not support dynamic client registration` means there is no OAuth way out;
`CONNECTION_CLOSED` is a local process that never started. `check-sources.sh live` translates each
into a fix (`integrations/references/mcp-catalog.md`). Connected is not working: some servers connect
without any credential and only fail on the first query.

**4.5 — `${CLAUDE_PLUGIN_ROOT}` is ephemeral.** The path changes on every update; never keep state
there. The flow state lives in `<repo>/.git/ferion-flow` and the per-person files in
`~/.claude/ferion-*` — keep it that way when adding a hook.
