# Forge commands — GitHub (`gh`) and GitLab (`glab`)

The standard is written with `gh` examples. On **GitLab** the flow is the same, step for step; only
the CLI, the word (PR → **MR**) and the label separator (`status:` → scoped `status::`) change. This
table is the single translation — skills point here instead of repeating both.

## Which forge is this repo?

The flow hook decides, in this order: `FERION_FORGE` env → `git config ferion.forge` → the `origin`
remote (a host containing "gitlab" → GitLab, anything else → GitHub). A **self-managed GitLab** on
a host that does not say "gitlab" declares it once per clone:

```bash
git config ferion.forge gitlab
```

Either way the hook **recognises the commands of both CLIs**; the forge only picks which commands its
messages suggest and how it reads CI.

## The translation

| Action | GitHub | GitLab |
|---|---|---|
| Auth check | `gh auth status` | `glab auth status` |
| Read an issue (all of it) | `gh issue view 123 --comments` | `glab issue view 123 --comments` |
| Read it structured | `gh issue view 123 --json number,title,body,labels,assignees,state` | `glab issue view 123 --output json` |
| Create an issue | `gh issue create --title "…" --body-file b.md --label type:feature` | `glab issue create --title "…" --description "$(cat b.md)" --label type::feature` |
| **Assume** (step 2) | `gh issue edit 123 --add-assignee @me --add-label status:in-progress` | `glab issue update 123 --assignee <your-username> --label status::in-progress` |
| Comment / **cost** (step 5) | `gh issue comment 123 --body "…"` | `glab issue note 123 -m "…"` |
| **To review** (step 6) | `gh issue edit 123 --add-label status:in-review` | `glab issue update 123 --label status::in-review --unlabel status::in-progress` |
| **To QA** (tech lead, skill `approve`) | `gh issue edit 123 --remove-label status:in-review --add-label status:in-qa` | `glab issue update 123 --label status::in-qa --unlabel status::in-review` |
| List by stage | `gh issue list --label status:in-progress` | `glab issue list --label status::in-progress` |
| Mine | `gh issue list --assignee @me` | `glab issue list --assignee @me` |
| Labels that exist | `gh label list` | `glab label list` |
| Create a label | `gh label create status:in-review --color FBCA04 --description "…"` | `glab label create --name status::in-review --color '#FBCA04' --description "…"` |
| **Open the PR/MR** (step 5) | `gh pr create --title "…" --body "Closes #123"` | `glab mr create --title "…" --description "Closes #123"` |
| Read a PR/MR | `gh pr view 77 --json title,body,files,reviews` | `glab mr view 77 --comments` |
| Diff | `gh pr diff 77` | `glab mr diff 77` |
| CI of the PR/MR | `gh pr checks 77` | `glab ci status` (branch) · `glab mr view 77 --output json` → `head_pipeline.status` |
| Tech lead: **approve** | `gh pr review 77 --approve --body "…"` | `glab mr approve 77` |
| Tech lead: **request changes** | `gh pr review 77 --request-changes --body "…"` | `glab mr note 77 -m "…"` (then return the issue to in progress) |
| Tech lead: the human decision the QA gate reads | `gh pr view 77 --json reviewDecision,latestReviews` | `glab api "projects/:fullpath/merge_requests/77/approvals"` → a name in `approved_by` · `glab mr view 77 --output json` → `detailed_merge_status` |
| Failing CI log | `gh run view <id> --log-failed` | `glab ci trace <job>` |
| Another repo | `--repo org/repo` | `-R group/project` |
| Raw API | `gh api repos/{owner}/{repo}/…` | `glab api projects/:id/…` |
| Read cost comments back | `gh api "repos/{owner}/{repo}/issues/123/comments" --jq '.[].body'` | `glab api "projects/:id/issues/123/notes?per_page=100"` |

`<your-username>`: what `glab auth status` shows. The collision guard (`issues`) still runs first —
`--assignee` **replaces** the assignees on GitLab, which is exactly why you only assume a free issue.

## What differs beyond the command

- **Closing keywords are the same.** `Closes #123` in the MR description closes the issue when the
  MR merges into the default branch — the same traceability link as on GitHub.
- **Scoped labels (`status::…`).** On GitLab Premium a scoped label is exclusive (adding
  `status::in-review` drops `status::in-progress`); on Free it is an ordinary label, which is why the
  review step also passes `--unlabel`. The hook accepts `status:` and `status::` on either forge.
- **Epics.** GitLab epics are a Premium, group-level feature. The standard's portable shape works on
  every tier: a parent issue whose description holds a task list (`- [ ] #124`), plus a real link from
  each child with a quick action — `glab issue note 124 -m "/relate #40"`.
- **The cost comment must carry the marker inline** (`-m "<!-- ferion:cost … -->"`), not from a
  file: the hook stamps the milestone from what it sees in the command.
- **MCP.** The plugin ships the official GitLab MCP (`integrations/references/mcp-catalog.md`). The
  hook recognises its `create_merge_request` / `update_issue` calls, but `glab` remains the path the
  standard is written for — it needs no browser login inside a headless run.
