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
#
# Forges: GitHub (`gh`, PRs, `status:` labels) and GitLab (`glab`, MRs, scoped `status::` labels).
# Commands of BOTH are always recognised; the forge only picks which commands the messages suggest
# and how CI is read. Detected from the `origin` remote; a self-managed GitLab whose host does not
# say "gitlab" sets `git config ferion.forge gitlab` (or FERION_FORGE=gitlab).
# Group (one PR resolves N linked issues): `task` holds the numbers separated by spaces; local review
# and PR belong to the group, while dev/cost/in_review are per issue (the list of issues that have it).
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
cmd_of() { # the shell command of a Bash payload (Claude: "command"; Codex exec may send "cmd")
  local c; c=$(val command "$1"); [ -n "$c" ] || c=$(val cmd "$1"); printf '%s' "$c"
}
patch_targets() { # Codex edits through apply_patch: the paths live in the patch headers, not in file_path
  grep -oE '\*\*\* (Add File|Update File|Delete File|Move to): [^\\"]+' <<<"$1" | sed -E 's/^\*\*\* [A-Za-z ]+: //; s/[[:space:]]+$//'
}
in_repo() { # <paths, one per line> -> 0 when any of them is a repo file (relative = inside the repo)
  local p
  while IFS= read -r p; do
    case "$p" in "") ;; "$root"/*) return 0 ;; /*) ;; *) return 0 ;; esac
  done <<<"$1"
  return 1
}
forge() {
  local f=${FERION_FORGE:-$(git config --get ferion.forge 2>/dev/null)}
  case "$f" in github|gitlab) echo "$f"; return ;; esac
  git remote get-url origin 2>/dev/null | grep -qi gitlab && echo gitlab || echo github
}
if [ "$(forge)" = gitlab ]; then
  PR=MR; L_PROG='status::in-progress'; L_REV='status::in-review'
  C_ASSUME='glab issue update <n> --assignee <your-username> --label status::in-progress'
  C_PR='glab mr create --description "Closes #'; C_COMMENT='glab issue note <n> -m'; C_CHECKS='glab ci status'
else
  PR=PR; L_PROG='status:in-progress'; L_REV='status:in-review'
  C_ASSUME='gh issue edit <n> --add-assignee @me --add-label status:in-progress'
  C_PR='gh pr create --body "Closes #'; C_COMMENT='gh issue comment <n> --body'; C_CHECKS='gh pr checks'
fi
# Recognised on either forge (a GitHub repo may still be driven by an agent that tried glab, and vice versa)
RE_ISSUE_EDIT='(gh[[:space:]]+issue[[:space:]]+edit|glab[[:space:]]+issue[[:space:]]+update)'
RE_PR_CREATE='(gh +pr +create|glab +mr +create)'
RE_MCP_PR='create_pull_request|pull_request_create|create_merge_request|merge_request_create'
num_after() { # <regex prefix> <text> -> the first issue/PR number that follows it
  grep -oE "$1[[:space:]]+#?[0-9]+" <<<"$2" | head -1 | grep -oE '[0-9]+$'
}
issue_no() { # <command> <payload> -> the issue a `gh|glab issue <verb> N` or an MCP call acts on
  local n; n=$(num_after '(gh|glab)[[:space:]]+issue[[:space:]]+[a-z]+' "$1")
  [ -n "$n" ] || n=$(grep -oE '"(issue_number|issue_iid)"[[:space:]]*:[[:space:]]*"?[0-9]+' <<<"$2" | head -1 | grep -oE '[0-9]+$')
  echo "$n"
}
has() { case " $1 " in *" $2 "*) ;; *) return 1 ;; esac; }   # has <list> <n>
em() { # em <milestone> [n]: issue n has the milestone. No n: the milestone exists at all.
  local v; v=$(get "$1"); [ "$v" = 1 ] && v=$(get task)        # 1 = the whole group (state from before groups)
  [ -n "$v" ] && { [ -z "${2:-}" ] || has "$v" "$2"; }
}
add() { local v; v=$(get "$1"); has "$v" "$2" || put "$1" "${v:+$v }$2"; }
lacking() { local k; for k in $(get task); do em "$1" "$k" || printf '#%s ' "$k"; done; }   # issues without it

flow_status() {
  local t b
  t=$(get task); b=$(get bypass)
  if [ -n "$b" ]; then
    echo "[Flow] **BYPASS active** in this repo: $b — declare it in your delivery summary. Back to the flow: \`$self reset\`."
    return
  fi
  if [ -z "$t" ]; then
    echo "[Flow] no issue in progress in this repo. **Step 1 of 6**: make sure the issue exists (skill \`issues\`) — ask which one, or create it; do not scan the backlog guessing. Editing code before that is blocked."
    return
  fi
  local m="" next="" f label="issue **#$t**"
  [ "$t" = "${t% *}" ] || label="group **#${t// /, #}** (1 PR)"
  m="issue ok"
  f=$(lacking dev)
  if [ -z "$f" ]; then m="$m · in progress ok"; else m="$m · in progress MISSING"; next="assume ${f% } (assignee) and label \`$L_PROG\` (skill \`issues\`)"; fi
  if [ -n "$(get review)" ]; then m="$m · local review ok"; elif [ -z "$next" ]; then next="implement (spec-flow/ship), then close the local review: \`review\` + \`preflight\` until ZERO findings, then \`$self stamp review\`"; fi
  if [ -n "$(get pr)" ]; then m="$m · $PR ok"; elif [ -z "$next" ]; then next="open the $PR linked to every issue (\`${C_PR}${t// /, closes #}\"\`)"; fi
  local base; base=$(get baseline)
  f=$(lacking cost)
  if [ -z "$f" ]; then m="$m · cost ok"; elif [ -z "$next" ]; then next="record the dev cost on ${f% } (skill \`cost\`: tokens, USD and hours${base:+ measured since $base}, split equally if it is a group)"; fi
  f=$(lacking in_review)
  if [ -z "$f" ]; then m="$m · in review ok"; next="flow closed (QA and deploy are human gates). New issue: \`$self stamp task <number>\`"; elif [ -z "$next" ]; then next="label ${f% } \`$L_REV\`"; fi
  echo "[Flow] $label — $m. Next step: $next."
}

missing_for_review() { # <n> -> what issue n still lacks before its "in review" milestone
  local f=""
  [ -n "$(get review)" ] || f="$f local review (\`review\`+\`preflight\` green, then \`$self stamp review\`) ·"
  [ -n "$(get pr)" ]     || f="$f $PR open and linked to every issue (\`Closes #N\`) ·"
  em cost "$1"           || f="$f dev cost recorded on ${1:+#}${1:-the issue} (skill \`cost\`: session-cost.py -> \`$C_COMMENT\`) ·"
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

fresh() { # a new issue = a new flow; the session is still the same one, so the session <-> group link survives
  local s si; s=$(get session); si=$(get session_issues)
  rm -f "$F"
  [ -z "$s" ] || { put session "$s"; put session_issues "$si"; }
}

one_session_one_group() { # <payload>: a session that already edited one group's code does not start an unlinked one
  local sid t si k linked=""
  sid=$(val session_id "$1"); t=$(get task)
  [ -n "$sid" ] && [ -n "$t" ] || return 0          # no session id (another tool) or no issue: nothing to compare
  if [ "$(get session)" != "$sid" ]; then put session "$sid"; put session_issues "$t"; return 0; fi
  si=$(get session_issues)
  for k in $t; do has "$si" "$k" && linked=1; done
  [ -n "$linked" ] || block \
    "starting #${t// /, #} in the same session that already edited #${si// /, #} (unlinked issue)." \
    "The previous issue's context rides along and makes every call of the new one more expensive (cost ≈ calls × context)." \
    "Ask the person to open a new session (\`/clear\`) and paste \"continue #${t%% *}\" (plus the rest of the batch). The flow lives in the repo: the new session resumes from here." \
    "Same delivery (dependency, same code)? Then it is a group: \`$self stamp task $si $t\` (criteria in \`start/references/mandatory-flow.md\` § Batch)."
  for k in $t; do add session_issues "$k"; done
}

ci_red() { # <PR/MR ref> -> 0 when a check IS failing. No CLI / no auth / no checks: never blocks.
  local ref=$1 out
  [ -n "$ref" ] && [ "$ref" != "1" ] || return 1
  case "$ref" in */merge_requests/*)   # GitLab: the MR's head pipeline
    command -v glab >/dev/null 2>&1 || return 1
    out=$(glab mr view "${ref##*/}" --output json 2>/dev/null | tr -d '\n') || true
    grep -oE '"head_pipeline"[[:space:]]*:[[:space:]]*\{[^{}]*' <<<"$out" | grep -qE '"status"[[:space:]]*:[[:space:]]*"failed"'
    return ;;
  esac
  command -v gh >/dev/null 2>&1 || return 1
  out=$(gh pr checks "$ref" 2>/dev/null) || true
  [ -n "$out" ] || return 1
  grep -qiE '(^|[[:space:]])(fail|failure)([[:space:]]|$)' <<<"$out"
}

case "$cmd" in
  status) [ -n "$gitdir" ] && flow_status ;;

  stamp) # stamp <task|dev|review|pr|cost|in_review> [value]
    case "$arg" in
      task) # task <n> [<n>…] — more than one = a group (one PR)
        shift 2; set -- "${@#\#}"
        [ $# -gt 0 ] || { echo "usage: $self stamp task <issue-number> [<issue-number>…]" >&2; exit 1; }
        # a new issue = a new flow (clears milestones and bypass); a group that includes the current issue extends it
        same=""; for k in "$@"; do has "$(get task)" "$k" && same=1; done
        [ -n "$same" ] || fresh
        put task "$*"
        # cost baseline: from here on `cost` measures THIS issue only (a session may hold several).
        [ -n "$(get baseline)" ] || put baseline "$(date -u +%Y-%m-%dT%H:%M:%SZ)" ;;
      dev|cost|in_review) # per issue: no number = the whole group
        [ -n "$(get task)" ] || { echo "[Flow] register the issue first: \`$self stamp task <number>\`" >&2; exit 1; }
        if [ -n "${3:-}" ]; then add "$arg" "${3#\#}"; else put "$arg" "$(get task)"; fi ;;
      review|pr)
        [ -n "$(get task)" ] || { echo "[Flow] register the issue first: \`$self stamp task <number>\`" >&2; exit 1; }
        put "$arg" "${3:-1}" ;;
      *) echo "usage: $self stamp <task|dev|review|pr|cost|in_review> [value]" >&2; exit 1 ;;
    esac
    flow_status ;;

  bypass)
    [ -n "$arg" ] || { echo "usage: $self bypass \"<reason>\"" >&2; exit 1; }
    put bypass "$arg"; flow_status ;;

  reset) fresh; flow_status ;;   # the session link stays: reset is not a way around the session gate

  gate)
    payload=$(cat)
    [ -n "$gitdir" ] || exit 0            # outside a git repo there is no flow to protect
    case "$arg" in
      edit)
        target=$(val file_path "$payload"); [ -n "$target" ] || target=$(val notebook_path "$payload")
        [ -n "$target" ] || target=$(patch_targets "$payload")
        in_repo "$target" || exit 0                         # file outside the repo (scratch/tmp): free
        bypassed || [ -n "$(get dev)" ] || block \
          "editing code before the \`in progress\` milestone." \
          "Make sure the issue exists (skill \`issues\`): ask which one, or create it. Do not scan the backlog guessing." \
          "Go through \`spec-flow\` (specify->clarify->plan->tasks, which generates \`specs/<feature>/\`) — do not jump from the issue straight to code." \
          "Assume the issue: \`$C_ASSUME\` — the hook stamps the milestone by itself." \
          "Issue already assumed outside the agent? \`$self stamp task <n>\` and \`$self stamp dev\`."
        bypassed || one_session_one_group "$payload"
        cat "$here/edit-reminder.md" ;;

      bash-edit)
        cmdline=$(cmd_of "$payload")
        [ -n "$cmdline" ] || exit 0
        writes=0
        in_repo "$(patch_targets "$payload")" && writes=1   # apply_patch invoked through the shell
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
          "Same rule as the editor: issue (\`issues\`) -> spec-flow -> assume the issue and label it \`$L_PROG\`." \
          "Issue already assumed outside the agent? \`$self stamp task <n>\` and \`$self stamp dev\`."
        bypassed || one_session_one_group "$payload" ;;

      pr)
        cmdline=$(cmd_of "$payload")
        if [ -n "$cmdline" ]; then grep -qE "$RE_PR_CREATE" <<<"$cmdline" || exit 0; fi
        bypassed || [ -n "$(get review)" ] || block \
          "opening a $PR without closing the local review." \
          "Run the local review: \`review\` (Definition of Done) and \`preflight\` (real tools + anti-hallucination) in a LOOP until zero findings." \
          "Only once it is green: \`$self stamp review\`, then open the $PR."
        # A PR nobody can trace back to an issue is a PR nobody can measure later (cost, lead time, adoption).
        # Match the whole payload, not the extracted command: escaped quotes in --title truncate the value.
        t=$(get task); branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        none=""; for k in $t; do
          grep -qE "#$k([^0-9]|$)" <<<"$payload" || grep -qE "(^|[^0-9])$k([^0-9]|$)" <<<"$branch" || none="$none #$k"
        done
        [ -z "$none" ] || bypassed || block \
          "opening a $PR that does not reference${none} (not in the title/body, not in the branch)." \
          "Link every issue in the body: \`${C_PR}${t// /, closes #}\" …\` (or name the branch \`<type>/${t%% *}-<slug>\` and link the rest in the body)." \
          "That reference is the only thread tying $PR to issue: without it, cost, lead time and pipeline adoption stop being measurable."
        # Spec-driven was the rule from day one, yet the only step with no gate — and the one that leaked
        # the most. The proof is the branch's git history, not the conversation. No remote = no base: no block.
        base=$(git merge-base HEAD origin/HEAD 2>/dev/null || git merge-base HEAD origin/main 2>/dev/null ||
               git merge-base HEAD origin/master 2>/dev/null)
        [ -z "$base" ] || bypassed || git diff --name-only "$base" HEAD -- ':(glob)**/specs/**' | grep -q . || block \
          "opening a $PR with no spec: no file under \`specs/\` changed on this branch." \
          "Run \`spec-flow\`: a new feature generates \`specs/<feature>/\`; a bug fix **updates** the feature's existing spec. Commit it and repeat." \
          "A change with no behaviour (dependency, config, docs)? \`$self bypass \"no spec: <reason>\"\` — and declare it in the summary." ;;

      review-label)
        cmdline=$(cmd_of "$payload")
        body="$cmdline$payload"
        grep -qE 'status::?in-review' <<<"$body" || exit 0
        n=$(issue_no "$cmdline" "$payload")
        t=$(get task)
        [ -z "$t" ] || [ -z "$n" ] || has "$t" "$n" || exit 0   # an issue outside the group: not this flow
        if em dev "$n"; then                                    # dev already happened => this is its in-review milestone
          bypassed || { [ -n "$(get review)" ] && [ -n "$(get pr)" ] && em cost "$n"; } || block \
            "moving ${n:+#}${n:-the issue} to review with the milestone half done." \
            "$(missing_for_review "$n")" \
            "Is this a DIFFERENT move (status regression, manual correction)? \`$self bypass \"out-of-flow move: <reason>\"\`."
          # The gate blocks the PR from OPENING; here it looks again: review with a red CI is guaranteed rework.
          bypassed || ! ci_red "$(get pr)" || block \
            "labelling for review with a failing CI check on $PR $(get pr)." \
            "See what broke: \`$C_CHECKS\` ($(get pr)) — fix it in the SAME $PR and wait for green." \
            "\`preflight\` runs the tools locally; if CI caught what it did not, add that rule to the checklist (\`preflight/references/preflight-checklist.md\`)."
        fi
        cat "$here/issue-transition-reminder.md" ;;
      *) exit 0 ;;
    esac ;;

  post) # stamp the milestone from what the tool REALLY did (PostToolUse)
    payload=$(cat)
    [ -n "$gitdir" ] || exit 0
    cmdline=$(cmd_of "$payload")
    changed=0

    # New issue created (gh/glab print the URL; the MCP returns "number"/"iid": N)
    if grep -qE '(gh|glab) +issue +create' <<<"$cmdline" || grep -qE '"(create_issue|issues_create)"|create_issue' <<<"$payload"; then
      n=$(grep -oE '/issues/[0-9]+' <<<"$payload" | head -1 | grep -oE '[0-9]+$')
      [ -n "$n" ] || n=$(grep -oE '"(number|iid)"[[:space:]]*:[[:space:]]*[0-9]+' <<<"$payload" | head -1 | grep -oE '[0-9]+$')
      [ -n "$n" ] && { "$0" stamp task "$n" >/dev/null; changed=1; }
    fi

    # The issue this call acted on; unnamed with a single-issue flow, it can only be that one
    n=$(issue_no "$cmdline" "$payload"); t=$(get task)
    [ -n "$n" ] || [ "$t" != "${t% *}" ] || n=$t

    # Issue assumed: assignee and/or the in-progress label (an issue outside the group = a new flow)
    if { grep -qE "$RE_ISSUE_EDIT" <<<"$cmdline" && grep -qE '\-\-(add-)?assignee|status::?in-progress' <<<"$cmdline"; } ||
       { grep -qE 'status::?in-progress' <<<"$payload" && grep -qE 'update_issue|issues_update' <<<"$payload"; }; then
      [ -n "$n" ] && { has "$(get task)" "$n" || "$0" stamp task "$n" >/dev/null; add dev "$n"; changed=1; }
    fi

    # Dev cost recorded on the issue (the marker is what makes it machine-readable), per issue
    if grep -q 'ferion:cost' <<<"$payload" && [ -n "$n" ] && has "$(get task)" "$n"; then
      add cost "$n"; changed=1
    fi

    # PR / MR opened
    if grep -qE "$RE_PR_CREATE" <<<"$cmdline" || grep -qE "$RE_MCP_PR" <<<"$payload"; then
      # keep the PR/MR URL (gh/glab print it): the in-review milestone checks its CI through it
      ref=$(grep -oE 'https://[^"[:space:]\\]+/(pull|merge_requests)/[0-9]+' <<<"$payload" | head -1)
      [ -n "$(get task)" ] && { put pr "${ref:-1}"; changed=1; }
    fi

    # Issue labelled for review (the last milestone), per issue
    if grep -qE 'status::?in-review' <<<"$payload" && [ -n "$n" ] && has "$(get task)" "$n" && em dev "$n"; then
      add in_review "$n"; changed=1
    fi

    [ "$changed" = 1 ] && flow_status
    exit 0 ;;

  *) echo "usage: $self <status|stamp|bypass|reset|gate <edit|bash-edit|pr|review-label>|post>" >&2; exit 1 ;;
esac
