---
name: approve
description: 'The tech lead''s phase of the flow — sweeps the issues waiting in code review, reviews each PR against the Definition of Done and the issue''s acceptance criteria, fixes the mechanical gaps on the PR branch itself, writes the PR report, helps the tech lead decide and, only with their yes, approves on GitHub and moves the issue to QA. Use when a tech lead asks "review the team''s PRs", "what is waiting for review", "sweep the review queue", "approve the PRs", "send it to QA", "clear the review column".'
---

# Tech lead approval — code review → QA

The developer closes the flow at `in review` (PR open + cost recorded). From there to QA the decision
belongs to the **tech lead**: the agent sweeps the queue, reviews, fixes what is mechanical and writes
the report — but **a person approves**. The agent runs `gh pr review --approve` only after the tech
lead's explicit "yes", **one PR at a time** (P3: authorship and approval are human).

The order does not depend on this prose: `flow-gate.sh` blocks labelling a registered issue
`status:in-qa` without a PR approved by a human and a green CI, and only lets it go back to
`status:in-progress` when the PR has changes requested.

```bash
FG="bash ${CLAUDE_PLUGIN_ROOT}/hooks/flow-gate.sh"
```

> GitLab repo? Same phase with `glab` — `glab mr approve`, `glab mr note`, label `status::in-qa` — and
> the gate reads the MR's approvals instead of the review decision: `issues/references/forge-commands.md`.

## 1. Build the queue

1. **Scope:** the tech lead's repositories live in `~/.claude/ferion-profile.md`
   (`repos: [owner/api, owner/web]`). No such line: ask once and record it. Never sweep every
   repository you can reach.
2. **Query** the `in review` label of each repo (or the label the team mapped to it in
   `config/team-config.md`), oldest first:
   ```bash
   gh search issues --label status:in-review --state open --repo owner/api --repo owner/web \
     --sort updated --order asc --json number,title,repository,updatedAt
   ```
3. **The PR of each issue:** the flow gate requires the issue number in the PR body (`Closes #N`) or
   in the branch, so search for it:
   `gh pr list -R <repo> --state open --search "<n>" --json url,headRefName,author,body` and keep the
   PR whose body cites `#<n>` or whose branch carries the number. None, or more than one: it shows in
   the queue as **⚠️ no single PR** and is not reviewed. Ask which PR it is; do not guess.
4. **Show the queue as a table** (issue · PR · author · +/− lines · CI · days in review) and review
   from the oldest to the newest, unless the tech lead picks another order.

## 2. Review each PR

1. **Register before touching anything:** `$FG tl <issue-number> <PR URL>`. That arms the QA gate for
   this issue and unlocks fixing the branch in this repo.
2. **Checkout:** in the local clone of the repo (`workspace` finds the path), run
   `gh pr checkout <URL>`. No clone: ask where to clone it.
3. **Tools in one call:** run `preflight`'s step 1 (build, types, lint, tests) — the real tools, not
   a reading of the diff.
4. **Review:** run the `review` skill against the Definition of Done **and the issue's acceptance
   criteria** (`gh issue view <n> -R <repo> --comments`). Load `quality`/`privacy`/`design-review` only
   when the diff touches those topics. Read the PR diff (`gh pr diff <URL>`), not the whole
   repository (P8).

## 3. Fix the gaps (hybrid)

Classify each finding:

| Kind | Examples | What the agent does |
|---|---|---|
| **Mechanical** | lint/format, a missing type, a replaceable `any`, a dead import, a name off convention, an obvious missing edge-case test, a forgotten log/metric | **fixes it on the PR branch**: a commit with the tech lead's git identity, `fix(<scope>): <what>` with `Refs #<n>` in the body, no AI signature. Runs step 1 again and `git push` |
| **Judgment** | architecture, a business rule, an API contract, scope added or missing, security with a trade-off | **does not fix it**: it becomes a review comment on the line, with the principle and a proposal, for the developer to decide |

When in doubt, it is judgment. A change that alters behavior is **never** mechanical. List the
mechanical commits in the report, so the developer knows what changed on their branch.

## 4. Report and decision

Write the report from `references/pr-report.md`, post it as a **comment on the issue** (the source
of truth: `gh issue comment <n> -R <repo> --body-file <file>`) and show it to the tech lead. Then ask:
**approve / request changes / skip**.

| Decision | The agent does |
|---|---|
| **approve** | Only with no open ❌; if there is one, name it and do not approve. Run `gh pr review <URL> --approve --body "<verdict + summary>"`, wait for CI (`gh pr checks <URL> --watch`) and label the issue `gh issue edit <n> -R <repo> --remove-label status:in-review --add-label status:in-qa` |
| **request changes** | Run the review with the judgment ❌ as line comments (the GitHub MCP review flow, or `gh api repos/<owner>/<repo>/pulls/<pr>/reviews` with a `comments` array and `"event": "REQUEST_CHANGES"`; no line API at hand → `file:line` in the body of `gh pr review <URL> --request-changes`) and send the issue back: `--remove-label status:in-review --add-label status:in-progress` |
| **skip** | Nothing. The issue stays registered (the gate stays armed for it) and shows up again on the next sweep |

A "yes" counts **only for the PR it was said about**. "Approve them all" is not a valid answer: show
each report. If a gate block appears, close what it asks for instead of looking for another way
around.

## 5. Close the sweep

One table: issue · verdict · mechanical commits · pending items for the developer · final label.
Then, in up to 3 lines, what stayed put and why (no PR, red CI, skipped).

## Degradation

| Situation | Behavior |
|---|---|
| The repo has no `status:in-qa` label | Review and approve, but **do not label**. Say so and offer to create it: `gh label create status:in-qa --color 5319E7 --description "PR approved by the tech lead, waiting for QA"` |
| No `gh`, or not authenticated | Do not review or approve — `gh` does both. List the queue (if the GitHub MCP can) and stop |
| A branch from a fork, or no push permission | Everything becomes a comment, the mechanical gaps included |
| A red CI that is not from the diff (flaky, infrastructure) | Say it is flaky or infrastructure. Do not approve over it: the gate blocks |
| The issue lives in a repo outside the profile's list | Leave it out and mention it once; widening the scope is the tech lead's call |
