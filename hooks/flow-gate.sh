#!/usr/bin/env bash
# Mandatory flow: issue -> in progress -> implement -> local review -> PR + cost -> in review.
#
# Prose does not hold an order; a gate does. This hook keeps the flow state per repository and
# BLOCKS (exit 2) the tool when a step is skipped, naming exactly which step is missing.
# Milestones are stamped from what the tool ACTUALLY did (PostToolUse), never from a claim.
#
# State: <gitdir>/ferion-flow (outside version control). Outside a git repo: blocks nothing, stays silent.
# It also keeps each issue's cost `baseline` (UTC) — what `cost` measures from, so one session's
# second issue does not inherit the first one's tokens.
set -uo pipefail

cmd=${1:-status}
arg=${2:-}
self="bash ${BASH_SOURCE[0]}"
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

gitdir=$(git rev-parse --absolute-git-dir 2>/dev/null) || gitdir=""
root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
F="${gitdir:-${TMPDIR:-/tmp}}/ferion-flow"

get() { [ -f "$F" ] && sed -n "s/^$1=//p" "$F" | tail -1; }
put() {
  local k=$1 v=$2 t
  t=$(mktemp 2>/dev/null) || return 0
  { [ -f "$F" ] && grep -v "^$k=" "$F"; printf '%s=%s\n' "$k" "$v"; } >"$t" 2>/dev/null
  mv -f "$t" "$F" 2>/dev/null || rm -f "$t"
}
val() { # pull "key": "value" out of the JSON payload (no jq dependency)
  grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" <<<"$2" | head -1 | sed -E 's/.*"([^"]*)"$/\1/'
}
num_after() { # <regex prefix> <text> -> the first issue/PR number that follows it
  grep -oE "$1[[:space:]]+#?[0-9]+" <<<"$2" | head -1 | grep -oE '[0-9]+$'
}

flow_status() {
  local t b
  t=$(get task); b=$(get bypass)
  if [ -n "$b" ]; then
    echo "[Flow] **BYPASS active** in this repo: $b — declare it in your delivery summary. Back to the flow: \`$self reset\`."
    return
  fi
  if [ -z "$t" ]; then
    echo "[Flow] no issue in progress in this repo. **Step 1 of 6**: make sure the GitHub issue exists (skill \`issues\`) — ask which one, or create it; do not scan the backlog guessing. Editing code before that is blocked."
    return
  fi
  local m="" next=""
  m="issue #$t ok"
  if [ -n "$(get dev)" ]; then m="$m · in progress ok"; else m="$m · in progress MISSING"; next="assume the issue (assignee) and label it \`status:in-progress\` (skill \`issues\`)"; fi
  if [ -n "$(get review)" ]; then m="$m · local review ok"; elif [ -z "$next" ]; then next="implement (spec-flow/ship), then close the local review: \`review\` + \`preflight\` until ZERO findings, then \`$self stamp review\`"; fi
  if [ -n "$(get pr)" ]; then m="$m · PR ok"; elif [ -z "$next" ]; then next="open the PR linked to the issue (\`gh pr create\` with \`Closes #$t\`)"; fi
  local base; base=$(get baseline)
  if [ -n "$(get cost)" ]; then m="$m · cost ok"; elif [ -z "$next" ]; then next="record the dev cost on the issue (skill \`cost\`: tokens, USD and hours${base:+ **for this issue**, measured since $base})"; fi
  if [ -n "$(get in_review)" ]; then m="$m · in review ok"; next="flow closed (QA and deploy are human gates). New issue: \`$self stamp task <number>\`"; elif [ -z "$next" ]; then next="label the issue \`status:in-review\`"; fi
  echo "[Flow] issue **#$t** — $m. Next step: $next."
}

missing_for_review() { # what is still missing before the "in review" milestone
  local f=""
  [ -n "$(get review)" ] || f="$f local review (\`review\`+\`preflight\` green, then \`$self stamp review\`) ·"
  [ -n "$(get pr)" ]     || f="$f PR open and linked to the issue (\`Closes #$(get task)\`) ·"
  [ -n "$(get cost)" ]   || f="$f dev cost recorded on the issue (skill \`cost\`: session-cost.py -> \`gh issue comment\`) ·"
  echo "Missing:${f% ·}"
}

block() { # <title> <steps...>
  local title=$1; shift
  {
    echo "BLOCKED by the mandatory flow: $title"
    echo "$(flow_status)"
    echo "Do this, in order, then repeat the tool call:"
    for p in "$@"; do echo "  - $p"; done
    echo "Legitimate exception (hotfix through \`incident\`, repo with no issue tracker, work outside code): \`$self bypass \"<reason>\"\` — it is recorded and you MUST declare it in the summary. Never claim a step you did not do."
  } >&2
  exit 2
}

bypassed() { [ -n "$(get bypass)" ]; }

ci_red() { # <PR ref> -> 0 when a check IS failing. No gh / no auth / no checks: never blocks.
  local ref=$1 out
  [ -n "$ref" ] && [ "$ref" != "1" ] || return 1
  command -v gh >/dev/null 2>&1 || return 1
  out=$(gh pr checks "$ref" 2>/dev/null) || true
  [ -n "$out" ] || return 1
  grep -qiE '(^|[[:space:]])(fail|failure)([[:space:]]|$)' <<<"$out"
}

case "$cmd" in
  status) [ -n "$gitdir" ] && flow_status ;;

  stamp) # stamp <task|dev|review|pr|cost|in_review> [value]
    case "$arg" in
      task)
        key=${3:-}
        [ -n "$key" ] || { echo "usage: $self stamp task <issue-number>" >&2; exit 1; }
        [ "$key" != "$(get task)" ] && rm -f "$F"   # new issue = new flow (clears milestones and bypass)
        put task "$key"
        # cost baseline: from here on `cost` measures THIS issue only (a session may hold several).
        [ -n "$(get baseline)" ] || put baseline "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ;;
      dev|review|pr|cost|in_review)
        [ -n "$(get task)" ] || { echo "[Flow] register the issue first: \`$self stamp task <number>\`" >&2; exit 1; }
        put "$arg" "${3:-1}" ;;
      *) echo "usage: $self stamp <task|dev|review|pr|cost|in_review> [value]" >&2; exit 1 ;;
    esac
    flow_status ;;

  bypass)
    [ -n "$arg" ] || { echo "usage: $self bypass \"<reason>\"" >&2; exit 1; }
    put bypass "$arg"; flow_status ;;

  reset) rm -f "$F"; flow_status ;;

  gate)
    payload=$(cat)
    [ -n "$gitdir" ] || exit 0            # outside a git repo there is no flow to protect
    case "$arg" in
      edit)
        target=$(val file_path "$payload"); [ -n "$target" ] || target=$(val notebook_path "$payload")
        case "$target" in "$root"/*) ;; *) exit 0 ;; esac   # file outside the repo (scratch/tmp): free
        bypassed || [ -n "$(get dev)" ] || block \
          "editing code before the \`in progress\` milestone." \
          "Make sure the GitHub issue exists (skill \`issues\`): ask which one, or create it. Do not scan the backlog guessing." \
          "Go through \`spec-flow\` (specify->clarify->plan->tasks, which generates \`specs/<feature>/\`) — do not jump from the issue straight to code." \
          "Assume the issue: \`gh issue edit <n> --add-assignee @me --add-label status:in-progress\` — the hook stamps the milestone by itself." \
          "Issue already assumed outside the agent? \`$self stamp task <n>\` and \`$self stamp dev\`."
        cat "$here/edit-reminder.md" ;;

      bash-edit)
        cmdline=$(val command "$payload")
        [ -n "$cmdline" ] || exit 0
        writes=0
        grep -qE '(^|[|;&[:space:]])(sed[[:space:]]+-i|perl[[:space:]]+-i|dd[[:space:]]+of=|tee([[:space:]]|$)|patch([[:space:]]|$)|git[[:space:]]+apply)' <<<"$cmdline" && writes=1
        for target in $(grep -oE '>>?[[:space:]]*[^[:space:];&|)"'"'"']+' <<<"$cmdline" | sed -E 's/^>>?[[:space:]]*//'); do
          case "$target" in
            /dev/*|/tmp/*|"${TMPDIR:-/tmp}"/*) ;;
            /*) case "$target" in "$root"/*) writes=1 ;; esac ;;
            *) writes=1 ;;                               # relative path = inside the repo
          esac
        done
        [ "$writes" = 1 ] || exit 0
        bypassed || [ -n "$(get dev)" ] || block \
          "writing to a repo file (through the shell) before the \`in progress\` milestone." \
          "Same rule as the editor: GitHub issue (\`issues\`) -> spec-flow -> assume the issue and label it \`status:in-progress\`." \
          "Issue already assumed outside the agent? \`$self stamp task <n>\` and \`$self stamp dev\`." ;;

      pr)
        cmdline=$(val command "$payload")
        if [ -n "$cmdline" ]; then grep -qE 'gh +pr +create' <<<"$cmdline" || exit 0; fi
        bypassed || [ -n "$(get review)" ] || block \
          "opening a PR without closing the local review." \
          "Run the local review: \`review\` (Definition of Done) and \`preflight\` (real tools + anti-hallucination) in a LOOP until zero findings." \
          "Only once it is green: \`$self stamp review\`, then open the PR."
        # A PR nobody can trace back to an issue is a PR nobody can measure later (cost, lead time, adoption).
        # Match the whole payload, not the extracted command: escaped quotes in --title truncate the value.
        t=$(get task); branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        [ -z "$t" ] || bypassed || grep -qE "#$t([^0-9]|$)" <<<"$payload" || grep -qE "(^|[^0-9])$t([^0-9]|$)" <<<"$branch" || block \
          "opening a PR that does not reference issue #$t (not in the body, not in the branch)." \
          "Link it in the body: \`gh pr create --body \"Closes #$t\" …\` (or name the branch \`<type>/$t-<slug>\`)." \
          "That reference is the only thread tying PR to issue: without it, cost, lead time and pipeline adoption stop being measurable." ;;

      review-label)
        cmdline=$(val command "$payload")
        body="$cmdline$payload"
        grep -q 'status:in-review' <<<"$body" || exit 0
        n=$(num_after 'gh[[:space:]]+issue[[:space:]]+edit' "$cmdline")
        [ -z "$n" ] && n=$(val issue_number "$payload")
        t=$(get task)
        [ -z "$t" ] || [ -z "$n" ] || [ "$n" = "$t" ] || exit 0   # another issue: not this flow
        if [ -n "$(get dev)" ]; then
          bypassed || { [ -n "$(get review)" ] && [ -n "$(get pr)" ] && [ -n "$(get cost)" ]; } || block \
            "moving the issue to review with the milestone half done." \
            "$(missing_for_review)" \
            "Is this a DIFFERENT move (status regression, manual correction)? \`$self bypass \"out-of-flow move: <reason>\"\`."
          # The gate blocks the PR from OPENING; here it looks again: review with a red CI is guaranteed rework.
          bypassed || ! ci_red "$(get pr)" || block \
            "labelling for review with a failing CI check on PR $(get pr)." \
            "See what broke: \`gh pr checks $(get pr)\` — fix it in the SAME PR and wait for green." \
            "\`preflight\` runs the tools locally; if CI caught what it did not, add that rule to the checklist (\`preflight/references/preflight-checklist.md\`)."
        fi
        cat "$here/issue-transition-reminder.md" ;;
      *) exit 0 ;;
    esac ;;

  post) # stamp the milestone from what the tool REALLY did (PostToolUse)
    payload=$(cat)
    [ -n "$gitdir" ] || exit 0
    cmdline=$(val command "$payload")
    changed=0

    # New issue created (gh prints the URL; the MCP returns "number": N)
    if grep -qE 'gh +issue +create' <<<"$cmdline" || grep -qE '"(create_issue|issues_create)"|create_issue' <<<"$payload"; then
      n=$(grep -oE '/issues/[0-9]+' <<<"$payload" | head -1 | grep -oE '[0-9]+$')
      [ -n "$n" ] || n=$(grep -oE '"number"[[:space:]]*:[[:space:]]*[0-9]+' <<<"$payload" | head -1 | grep -oE '[0-9]+$')
      [ -n "$n" ] && { "$0" stamp task "$n" >/dev/null; changed=1; }
    fi

    # Issue assumed: assignee and/or the in-progress label
    if grep -qE 'gh +issue +edit' <<<"$cmdline" && grep -qE '\-\-add-assignee|status:in-progress' <<<"$cmdline"; then
      n=$(num_after 'gh[[:space:]]+issue[[:space:]]+edit' "$cmdline")
      [ -n "$n" ] && { [ "$n" = "$(get task)" ] || "$0" stamp task "$n" >/dev/null; put dev 1; changed=1; }
    elif grep -q 'status:in-progress' <<<"$payload" && grep -qE 'update_issue|issues_update' <<<"$payload"; then
      n=$(val issue_number "$payload"); [ -n "$n" ] || n=$(get task)
      [ -n "$n" ] && { [ "$n" = "$(get task)" ] || "$0" stamp task "$n" >/dev/null; put dev 1; changed=1; }
    fi

    # Dev cost recorded on the issue (the marker is what makes it machine-readable)
    if grep -q 'ferion:cost' <<<"$payload" && [ -n "$(get task)" ]; then
      put cost 1; changed=1
    fi

    # PR opened
    if grep -qE 'gh +pr +create' <<<"$cmdline" || grep -qE 'create_pull_request|pull_request_create' <<<"$payload"; then
      # keep the PR URL (gh prints it): the in-review milestone checks that PR's CI through it
      ref=$(grep -oE 'https://[^"[:space:]]+/pull/[0-9]+' <<<"$payload" | head -1)
      [ -n "$(get task)" ] && { put pr "${ref:-1}"; changed=1; }
    fi

    # Issue labelled for review (the last milestone)
    if grep -q 'status:in-review' <<<"$payload" && [ -n "$(get dev)" ]; then
      put in_review 1; changed=1
    fi

    [ "$changed" = 1 ] && flow_status
    exit 0 ;;

  *) echo "usage: $self <status|stamp|bypass|reset|gate <edit|bash-edit|pr|review-label>|post>" >&2; exit 1 ;;
esac
