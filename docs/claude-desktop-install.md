# Installing in Claude Desktop / Cowork

The plugin works in Claude Code (CLI) and in Claude Desktop/Cowork, but the **delivery** differs. In
the CLI, `/plugin marketplace add` runs on your machine with your git credentials. In the desktop app,
the marketplace is fetched **by the app, on the host system, outside the Cowork VM** — and, by
default, **with no credential at all**.

For this repository that is fine: it is public, and **Add marketplace → GitHub repo →
`FerionAI/ferion-engineering`** works as is. It stops being fine for a **private fork**: the entry
appears with its name and description and **no skill comes with it**. The symptom is always
`Unknown command: /ferion-engineering:start`, because a plugin's skill becomes `/plugin:skill` **only
when the plugin is loaded**.

> **It is not the command name.** `/<plugin>:<skill>` is the right invocation (plugin skills live in
> a `plugin-name:skill-name` namespace). And adding a `commands/` folder does not help: commands and
> skills were unified — a file in `commands/` and a skill produce the same `/name`.

## Path 1 — a provisioned marketplace (a team, a private fork)

The mechanism built for this case: a private repository, each person with access through their own
account. The key is **`credentialKind: "userGit"`**, which tells the app to use the git credential
helpers already on the machine (Git Credential Manager, Keychain, the `gh` helper).

The setting (`allowedPluginMarketplaces`), with `ref` **pinned to the full SHA** — required when the
preference is `auto_install` or `required`:

```json
[{
  "source": "github",
  "repo": "<owner>/<fork>",
  "ref": "<full commit SHA>",
  "credentialKind": "userGit",
  "expectedName": "<the name in your marketplace.json>",
  "installationPreference": "auto_install"
}]
```

- **macOS (MDM):** the same string inside `<key>allowedPluginMarketplaces</key><string>…</string>`.
- **Windows:** the same value under `HKLM\SOFTWARE\Policies\Claude`.
- **No MDM:** the app's settings window (**Plugins → Add marketplace → GitHub repo**) validates it and
  exports the JSON.

`expectedName` makes the fetch refuse a `marketplace.json` whose `name` changed — it is what stops
another manifest from quietly taking this one's place.

**On every release:** change `ref` to the new SHA and redistribute the setting. Without a new `ref`,
nobody receives the update.

**Per machine:** `git` installed (the app clones with the device's git) and the GitHub credential
already working for that user. Test it with `git clone https://github.com/<owner>/<fork>.git <tmp dir>`:
if the manual clone fails, the app will fail too, and the problem is the credential helper, not the
plugin.

## Path 2 — upload the package (one person, right now)

To unblock one person without MDM:

```bash
git archive --format=zip -o ferion-engineering-<version>.zip HEAD
```

**Customize → Plugins → upload.** The zip needs the plugin at its root (one wrapping folder is
tolerated), with `.claude-plugin/plugin.json` — which is what `git archive` produces.

**The real limitation:** it is a fixed copy. It does not get marketplace updates; to update, upload
the zip again. Use it to validate, not to distribute to a team.

## Path 3 — the organization's plugin folder

When the machines cannot reach git: an admin places the plugin in
`/Library/Application Support/Claude/org-plugins/<name>/` (macOS) or
`C:\Program Files\Claude\org-plugins\<name>\` (Windows), with `.claude-plugin/plugin.json` inside and a
`version.json` — changing that string is what triggers a re-sync. The most manual of the three.

## After installing — the test that proves it loaded

1. **Customize → Plugins → ferion-engineering → Skills tab:** it must list every skill of the version
   you installed (one per `skills/*/SKILL.md`). An entry with no skills = the content did not come
   down; go back to Path 1 or 2, do not keep retrying the command.
2. **Talk, do not type a slash** (works on both surfaces): *"what is the engineering standard here?"*
   → the answer must bring the principles **P1–P8**, which proves the skill's body came along, not just
   its name.
3. Only then try `/ferion-engineering:start`.

## What is still not verifiable

The skills' runtime in Cowork — working directory, environment variables, access to `bash`/`python3`
— is not documented. Several skills here run commands (`flow-gate`, `session-cost`, `pr-bots`,
`check-sources`), so they may degrade there and work in the CLI. Write down what differs: it is step 6
of `READINESS.md` §3.
