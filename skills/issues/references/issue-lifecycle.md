# Issue lifecycle and query recipes

The issue is the source of truth from the moment the intent exists until QA signs off. This is the
lifecycle and the `gh` commands for each stage. Nothing here needs an MCP — `gh` plus a token is the
whole toolchain.

## The lifecycle

```
   idea ──> issue (Ready)  ──> in progress ──> PR open ──> in review ──> QA ──> closed
             │                   │               │            │           │
          epic/issues        assignee +      Closes #N     label +     human gate
                           status:in-progress               cost
```

| Stage | Who moves it | Signal |
|---|---|---|
| Ready | a person (refinement) | the issue meets the Definition of Ready |
| in progress | the agent, automatically | `--add-assignee @me --add-label status:in-progress` |
| PR open | the agent, automatically | `gh pr create` with `Closes #N` |
| in review | the agent, automatically | `--add-label status:in-review` (after PR + cost) |
| QA / closed | **a person** | the agent has no reliable signal that QA passed or the deploy happened |

**From merge onward, humans move it.** The agent does not close issues and does not claim QA
approval. `Closes #N` closes the issue on merge — that is GitHub doing it from a real event, which
is fine; claiming it by hand is not.

## Recipes

```bash
# What is in each stage
gh issue list --label status:in-progress
gh issue list --label status:in-review
gh issue list --assignee @me --state open
gh issue list --search "is:open no:assignee label:status:ready"

# Read everything about one issue (body + comments + linked PRs) in one call
gh issue view 123 --comments

# Structured, for parsing
gh issue view 123 --json number,title,body,labels,assignees,state,comments

# Create a well-formed issue
gh issue create --title "Refresh token rotation" \
  --body-file /tmp/body.md --label type:feature --assignee @me

# Assume it (this is what unlocks the code, via the flow gate)
gh issue edit 123 --add-assignee @me --add-label status:in-progress

# Write back
gh issue comment 123 --body "Clarify: what happens when the token is expired AND revoked?"
gh issue edit 123 --add-label status:in-review

# Epic and children (task list in the parent's body creates real sub-issue links)
gh issue view 40 --json body --jq .body | grep -o '#[0-9]*'

# Cross-repo (workspace)
gh issue list --repo other-org/other-repo --label status:in-progress
```

## Search that actually finds things

`gh issue list --search` takes GitHub's full search syntax. The ones worth knowing:

| Want | Search |
|---|---|
| Stale in progress | `label:status:in-progress updated:<2026-08-01` |
| Never refined | `is:open no:label` |
| Mine, across repos | `gh search issues --assignee @me --state open` |
| Linked to a PR | `linked:pr` |
| Closed last sprint | `is:closed closed:>2026-08-01` |

## Etiquette for writing back

- **Comment the decision, not the narration.** "Chose X over Y because Z" is worth a comment;
  "starting now" is not.
- **Clarify questions go on the issue**, not only in the chat — that is what makes the issue the
  spec (P1).
- **The PR link is automatic** when the body has `Closes #N`; do not paste it by hand as well.
- **Never edit away someone else's text.** Add a comment; the history is part of the truth.
- **No PII in comments** (`privacy`) — reference the record, do not paste the person's data.

## When the repository is not the right place

Some work spans repos (a contract change touching front and back). Keep **one issue in the repo that
owns the change** and reference it from the others (`org/repo#123` renders as a cross-repo link).
Coordination mechanics live in `workspace`.
