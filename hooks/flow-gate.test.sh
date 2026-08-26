#!/usr/bin/env sh
# Checks for flow-gate.sh: the mandatory flow must have no hole and no false block.
# Runs in CI through scripts/validate-plugin.sh. Exit != 0 if any case fails.
set -u
H="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/flow-gate.sh"
T="${TMPDIR:-/tmp}/ferion-flow-test-$$"
fails=0
rm -rf "$T"; mkdir -p "$T"; (cd "$T" && git init -q . 2>/dev/null)

g() { # <gate|post> <mode> <json payload> -> exit code
  (cd "$T" && printf '%s' "$3" | bash "$H" "$1" "$2" >/dev/null 2>&1; echo $?)
}
s() { (cd "$T" && bash "$H" "$@" >/dev/null 2>&1); }
check() { # <expected> <got> <description>
  [ "$1" = "$2" ] || { echo "  x $3 (expected=$1, got=$2)"; fails=$((fails+1)); }
}

edit_repo='{"tool_name":"Edit","tool_input":{"file_path":"'"$T"'/src/a.ts"}}'
edit_out='{"tool_name":"Edit","tool_input":{"file_path":"/tmp/scratch/a.ts"}}'
pr_cmd='{"tool_name":"Bash","tool_input":{"command":"gh pr create --fill"}}'
ls_cmd='{"tool_name":"Bash","tool_input":{"command":"ls -la"}}'
sed_cmd='{"tool_name":"Bash","tool_input":{"command":"sed -i s/a/b/ src/a.ts"}}'
tmp_cmd='{"tool_name":"Bash","tool_input":{"command":"grep -r foo src/ > /tmp/o.txt"}}'
new_issue='{"tool_name":"Bash","tool_input":{"command":"gh issue create --title add-login"},"tool_response":{"stdout":"https://github.com/acme/app/issues/42"}}'
assume='{"tool_name":"Bash","tool_input":{"command":"gh issue edit 42 --add-assignee @me --add-label status:in-progress"}}'
to_review='{"tool_name":"Bash","tool_input":{"command":"gh issue edit 42 --add-label status:in-review"}}'
other_issue='{"tool_name":"Bash","tool_input":{"command":"gh issue edit 99 --add-label status:in-review"}}'
cost_cmd='{"tool_name":"Bash","tool_input":{"command":"gh issue comment 42 --body ferion:cost tokens=1403090 usd=2.05"}}'

# 1) No issue: code is blocked, everything else passes
check 2 "$(g gate edit "$edit_repo")"      "editing without an issue is blocked"
check 2 "$(g gate bash-edit "$sed_cmd")"   "sed -i without an issue is blocked"
check 0 "$(g gate edit "$edit_out")"       "a file outside the repo is not blocked"
check 0 "$(g gate bash-edit "$ls_cmd")"    "a read-only command is not blocked"
check 0 "$(g gate bash-edit "$tmp_cmd")"   "writing to /tmp is not blocked"

# 2) Creating the issue stamps step 1 — but code is still blocked until it is assumed
g post issue "$new_issue" >/dev/null
check 2 "$(g gate edit "$edit_repo")"      "issue created but not assumed still blocks editing"

# 3) Assuming the issue (assignee + label) stamps `in progress` -> code is released
g post issue "$assume" >/dev/null
check 0 "$(g gate edit "$edit_repo")"      "with the issue assumed, editing passes"
check 0 "$(g gate bash-edit "$sed_cmd")"   "with the issue assumed, sed -i passes"

# 4) The PR requires the local review
check 2 "$(g gate pr "$pr_cmd")"           "a PR without local review is blocked"
s stamp review
check 0 "$(g gate pr "$pr_cmd")"           "a PR with local review passes"

# 5) Labelling for review requires PR + cost
check 2 "$(g gate review-label "$to_review")"   "review label without PR/cost is blocked"
check 0 "$(g gate review-label "$other_issue")" "labelling ANOTHER issue is not this flow"
g post issue "$pr_cmd" >/dev/null
check 2 "$(g gate review-label "$to_review")"   "review label without cost is still blocked"
g post issue "$cost_cmd" >/dev/null
check 0 "$(g gate review-label "$to_review")"   "review label with PR and cost passes"

# 6) A recorded bypass releases, and a new issue resets the flow
s reset
check 2 "$(g gate edit "$edit_repo")"      "reset blocks again"
s bypass "incident hotfix"
check 0 "$(g gate edit "$edit_repo")"      "a recorded bypass releases"
s stamp task 43
check 2 "$(g gate edit "$edit_repo")"      "a new issue clears the bypass and the milestones"

# 7) The cost baseline is born with the issue and only moves when the issue does
s stamp task 44
b1=$(sed -n 's/^baseline=//p' "$T/.git/ferion-flow" | tail -1)
check 1 "$(printf '%s' "$b1" | grep -c '^[0-9]')" "a new issue writes the cost baseline"
s stamp task 44
check "$b1" "$(sed -n 's/^baseline=//p' "$T/.git/ferion-flow" | tail -1)" "the same issue keeps its baseline"
printf 'baseline=2000-01-01T00:00:00Z\n' >> "$T/.git/ferion-flow"
s stamp task 45
check 0 "$(grep -c '2000-01-01T00:00:00Z' "$T/.git/ferion-flow")" "a new issue clears the previous baseline"

rm -rf "$T"
[ "$fails" -eq 0 ] && echo "OK flow-gate: 21 cases" || { echo "x flow-gate: $fails failure(s)"; exit 1; }
