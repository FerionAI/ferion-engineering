#!/usr/bin/env sh
# Checks for flow-gate.sh: the mandatory flow must have no hole and no false block.
# Runs in CI through scripts/validate-plugin.sh. Exit != 0 if any case fails.
set -u
H="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/flow-gate.sh"
T="${TMPDIR:-/tmp}/ferion-flow-test-$$"
fails=0; total=0
rm -rf "$T"; mkdir -p "$T"; (cd "$T" && git init -q . 2>/dev/null)

g() { # <gate|post> <mode> <json payload> -> exit code
  (cd "$T" && printf '%s' "$3" | bash "$H" "$1" "$2" >/dev/null 2>&1; echo $?)
}
s() { (cd "$T" && bash "$H" "$@" >/dev/null 2>&1); }
check() { # <expected> <got> <description>
  total=$((total+1)); [ "$1" = "$2" ] || { echo "  x $3 (expected=$1, got=$2)"; fails=$((fails+1)); }
}

edit_repo='{"tool_name":"Edit","tool_input":{"file_path":"'"$T"'/src/a.ts"}}'
edit_out='{"tool_name":"Edit","tool_input":{"file_path":"/tmp/scratch/a.ts"}}'
pr_cmd='{"tool_name":"Bash","tool_input":{"command":"gh pr create --fill"}}'
pr_link='{"tool_name":"Bash","tool_input":{"command":"gh pr create --body \"Closes #42\""}}'
pr_done='{"tool_name":"Bash","tool_input":{"command":"gh pr create --body \"Closes #42\""},"tool_response":{"stdout":"https://github.com/acme/app/pull/77"}}'
ls_cmd='{"tool_name":"Bash","tool_input":{"command":"ls -la"}}'
sed_cmd='{"tool_name":"Bash","tool_input":{"command":"sed -i s/a/b/ src/a.ts"}}'
tmp_cmd='{"tool_name":"Bash","tool_input":{"command":"grep -r foo src/ > /tmp/o.txt"}}'
new_issue='{"tool_name":"Bash","tool_input":{"command":"gh issue create --title add-login"},"tool_response":{"stdout":"https://github.com/acme/app/issues/42"}}'
assume='{"tool_name":"Bash","tool_input":{"command":"gh issue edit 42 --add-assignee @me --add-label status:in-progress"}}'
to_review='{"tool_name":"Bash","tool_input":{"command":"gh issue edit 42 --add-label status:in-review"}}'
other_issue='{"tool_name":"Bash","tool_input":{"command":"gh issue edit 99 --add-label status:in-review"}}'
# Codex: edits arrive as apply_patch (paths in the patch headers), the shell may come as "cmd"
cx_patch='{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: src/a.ts\n@@\n-a\n+b\n*** End Patch"}}'
cx_patch_out='{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Add File: /tmp/scratch/n.md\n+x\n*** End Patch"}}'
cx_shell_patch='{"tool_name":"Bash","tool_input":{"command":"apply_patch \"*** Begin Patch\n*** Add File: docs/n.md\n+x\n*** End Patch\""}}'
cx_cmd='{"tool_name":"Bash","tool_input":{"cmd":"sed -i s/a/b/ src/a.ts"}}'
cost_cmd='{"tool_name":"Bash","tool_input":{"command":"gh issue comment 42 --body ferion:cost tokens=1403090 usd=2.05"}}'

# 1) No issue: code is blocked, everything else passes
check 2 "$(g gate edit "$edit_repo")"      "editing without an issue is blocked"
check 2 "$(g gate bash-edit "$sed_cmd")"   "sed -i without an issue is blocked"
check 0 "$(g gate edit "$edit_out")"       "a file outside the repo is not blocked"
check 0 "$(g gate bash-edit "$ls_cmd")"    "a read-only command is not blocked"
check 0 "$(g gate bash-edit "$tmp_cmd")"   "writing to /tmp is not blocked"
check 2 "$(g gate edit "$cx_patch")"       "Codex apply_patch on a repo file without an issue is blocked"
check 0 "$(g gate edit "$cx_patch_out")"   "Codex apply_patch outside the repo is not blocked"
check 2 "$(g gate bash-edit "$cx_shell_patch")" "apply_patch through the shell without an issue is blocked"
check 2 "$(g gate bash-edit "$cx_cmd")"    "Codex exec \"cmd\" payload is read like \"command\""

# 2) Creating the issue stamps step 1 — but code is still blocked until it is assumed
g post issue "$new_issue" >/dev/null
check 2 "$(g gate edit "$edit_repo")"      "issue created but not assumed still blocks editing"

# 3) Assuming the issue (assignee + label) stamps `in progress` -> code is released
g post issue "$assume" >/dev/null
check 0 "$(g gate edit "$edit_repo")"      "with the issue assumed, editing passes"
check 0 "$(g gate bash-edit "$sed_cmd")"   "with the issue assumed, sed -i passes"
check 0 "$(g gate edit "$cx_patch")"       "with the issue assumed, Codex apply_patch passes"

# 4) The PR requires the local review AND a reference to the issue
check 2 "$(g gate pr "$pr_link")"          "a PR without local review is blocked"
s stamp review
check 2 "$(g gate pr "$pr_cmd")"           "a PR that references no issue is blocked"
check 0 "$(g gate pr "$pr_link")"          "a PR with local review and a Closes #N passes"

# 5) Labelling for review requires PR + cost
check 2 "$(g gate review-label "$to_review")"   "review label without PR/cost is blocked"
check 0 "$(g gate review-label "$other_issue")" "labelling ANOTHER issue is not this flow"
g post issue "$pr_done" >/dev/null
check "https://github.com/acme/app/pull/77" "$(sed -n 's/^pr=//p' "$T/.git/ferion-flow" | tail -1)" "the PR milestone keeps the URL (to check its CI later)"
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

# 8) Group (one PR resolves N linked issues): assuming another issue of the group does not reset the
#    flow; the PR must name every issue, and each issue needs its own cost before review
mk() { sed -n "s/^$1=//p" "$T/.git/ferion-flow" | tail -1; }
as() { printf '{"tool_name":"Bash","tool_input":{"command":"gh issue edit %s --add-assignee @me --add-label status:in-progress"}}' "$1"; }
rv() { printf '{"tool_name":"Bash","tool_input":{"command":"gh issue edit %s --add-label status:in-review"}}' "$1"; }
co() { printf '{"tool_name":"Bash","tool_input":{"command":"gh issue comment %s --body ferion:cost tokens=1 usd=1"}}' "$1"; }
pr_one='{"tool_name":"Bash","tool_input":{"command":"gh pr create --body \"Closes #50\""}}'
pr_group='{"tool_name":"Bash","tool_input":{"command":"gh pr create --body \"Closes #50, closes #51\""},"tool_response":{"stdout":"https://github.com/acme/app/pull/78"}}'
s reset
s stamp task 50 51
g post issue "$(as 50)" >/dev/null
g post issue "$(as 51)" >/dev/null
check "50 51" "$(mk dev)"                       "assuming the 2nd issue of the group does not reset the flow"
check "" "$(mk in_review)"                      "assuming the 2nd issue is not the 1st one's review milestone"
s stamp review
check 2 "$(g gate pr "$pr_one")"                "a PR that misses one issue of the group is blocked"
check 0 "$(g gate pr "$pr_group")"              "a PR naming every issue of the group passes"
g post issue "$pr_group" >/dev/null
g post issue "$(co 50)" >/dev/null
check 0 "$(g gate review-label "$(rv 50)")"     "review of the issue with its own cost passes"
check 2 "$(g gate review-label "$(rv 51)")"     "review of a group issue without its own cost is blocked"
g post issue "$(co 51)" >/dev/null
check 0 "$(g gate review-label "$(rv 51)")"     "with each issue's cost, the whole group goes to review"
g post issue "$(rv 50)" >/dev/null
check "50" "$(mk in_review)"                    "the review milestone is stamped per issue"
s stamp task 50 51 52
check "https://github.com/acme/app/pull/78" "$(mk pr)" "extending the group keeps the milestones"
s stamp dev
check "50 51 52" "$(mk dev)"                    "stamp dev with no number covers the whole group"
s stamp task 53
check "" "$(mk pr)"                             "an issue outside the group opens a new flow"
printf 'dev=1\n' >>"$T/.git/ferion-flow"
check 2 "$(g gate review-label "$(rv 53)")"     "state from before groups (dev=1) still covers the whole group"

# 8) GitLab: glab + MRs + scoped status:: labels, the same gates
L="$T-gitlab"; rm -rf "$L"; mkdir -p "$L/bin"; (cd "$L" && git init -q . && git remote add origin git@gitlab.com:acme/app.git)
gl() { (cd "$L" && printf '%s' "$3" | PATH="$L/bin:$PATH" bash "$H" "$1" "$2" >/dev/null 2>&1; echo $?); }
gl_err() { (cd "$L" && printf '%s' "$2" | bash "$H" gate "$1" 2>&1 >/dev/null); }
gl_edit='{"tool_name":"Edit","tool_input":{"file_path":"'"$L"'/src/a.ts"}}'
gl_new='{"tool_name":"Bash","tool_input":{"command":"glab issue create --title add-login"},"tool_response":{"stdout":"https://gitlab.com/acme/app/-/issues/42\n"}}'
gl_assume='{"tool_name":"Bash","tool_input":{"command":"glab issue update 42 --assignee dev1 --label status::in-progress"}}'
gl_mr='{"tool_name":"Bash","tool_input":{"command":"glab mr create --fill --description \"Closes #42\""}}'
gl_mr_nolink='{"tool_name":"Bash","tool_input":{"command":"glab mr create --fill"}}'
gl_mr_done='{"tool_name":"Bash","tool_input":{"command":"glab mr create --fill --description \"Closes #42\""},"tool_response":{"stdout":"https://gitlab.com/acme/app/-/merge_requests/77\n"}}'
gl_cost='{"tool_name":"Bash","tool_input":{"command":"glab issue note 42 -m \"ferion:cost tokens=1 usd=0.01\""}}'
gl_review='{"tool_name":"Bash","tool_input":{"command":"glab issue update 42 --label status::in-review"}}'
gl_mcp_mr='{"tool_name":"mcp__gitlab__create_merge_request","tool_input":{"title":"x","description":"Closes #42"},"tool_response":{"iid":78,"web_url":"https://gitlab.com/acme/app/-/merge_requests/78"}}'

check 2 "$(gl gate edit "$gl_edit")"            "GitLab: editing without an issue is blocked"
check 1 "$(gl_err edit "$gl_edit" | grep -c 'glab issue update <n>')" "GitLab: the block suggests glab and status::"
gl post x "$gl_new" >/dev/null
check 2 "$(gl gate edit "$gl_edit")"            "GitLab: issue created but not assumed still blocks"
gl post x "$gl_assume" >/dev/null
check 0 "$(gl gate edit "$gl_edit")"            "GitLab: glab issue update --assignee/--label status:: releases editing"
check 2 "$(gl gate pr "$gl_mr")"                "GitLab: an MR without local review is blocked"
(cd "$L" && bash "$H" stamp review >/dev/null 2>&1)
check 2 "$(gl gate pr "$gl_mr_nolink")"         "GitLab: an MR that references no issue is blocked"
check 0 "$(gl gate pr "$gl_mr")"                "GitLab: an MR with review and Closes #N passes"
check 2 "$(gl gate review-label "$gl_review")"  "GitLab: status::in-review without MR/cost is blocked"
gl post x "$gl_mr_done" >/dev/null
check "https://gitlab.com/acme/app/-/merge_requests/77" "$(sed -n 's/^pr=//p' "$L/.git/ferion-flow" | tail -1)" "GitLab: the MR milestone keeps the MR URL"
gl post x "$gl_cost" >/dev/null
printf '#!/bin/sh\necho "{\\"iid\\": 77, \\"head_pipeline\\": {\\"id\\": 9, \\"status\\": \\"failed\\"}}"\n' >"$L/bin/glab"; chmod +x "$L/bin/glab"
check 2 "$(gl gate review-label "$gl_review")"  "GitLab: a failed MR pipeline blocks status::in-review"
printf '#!/bin/sh\necho "{\\"iid\\": 77, \\"head_pipeline\\": {\\"id\\": 9, \\"status\\": \\"success\\"}}"\n' >"$L/bin/glab"
check 0 "$(gl gate review-label "$gl_review")"  "GitLab: MR + cost + green pipeline passes"
gl post x "$gl_review" >/dev/null
check 1 "$(grep -c '^in_review=' "$L/.git/ferion-flow")" "GitLab: status::in-review closes the flow"
(cd "$L" && bash "$H" stamp task 50 >/dev/null 2>&1 && bash "$H" stamp dev >/dev/null 2>&1)
gl post x "$gl_mcp_mr" >/dev/null
check "https://gitlab.com/acme/app/-/merge_requests/78" "$(sed -n 's/^pr=//p' "$L/.git/ferion-flow" | tail -1)" "GitLab MCP create_merge_request stamps the MR"
# self-managed GitLab on a host that does not say "gitlab": the repo declares its forge
(cd "$T" && git config ferion.forge gitlab)
check 1 "$(cd "$T" && bash "$H" reset >/dev/null 2>&1; printf '%s' "$edit_repo" | bash "$H" gate edit 2>&1 >/dev/null | grep -c 'status::in-progress')" "git config ferion.forge gitlab switches the suggested commands"
(cd "$T" && git config --unset ferion.forge)   # back to GitHub for the sections below
rm -rf "$L"

# 9) One session, one group: an unlinked issue needs a new session (the previous context makes everything dearer)
ed() { printf '{"session_id":"%s","tool_name":"Edit","tool_input":{"file_path":"%s/src/a.ts"}}' "$1" "$T"; }
sh_ed='{"session_id":"S1","tool_name":"Bash","tool_input":{"command":"sed -i s/a/b/ src/a.ts"}}'
s reset; s stamp task 60; s stamp dev
check 0 "$(g gate edit "$(ed S1)")"             "the session's first issue edits"
s stamp task 61; s stamp dev
check 2 "$(g gate edit "$(ed S1)")"             "same session, unlinked issue: blocked"
check 2 "$(g gate bash-edit "$sh_ed")"          "the same through the shell"
check 0 "$(g gate edit "$edit_repo")"           "no session id (another tool): no comparison"
check 0 "$(g gate edit "$(ed S2)")"             "a new session releases the new issue"
s stamp task 61 62
check 0 "$(g gate edit "$(ed S2)")"             "extending the group in the same session passes"
s reset; s stamp task 63; s stamp dev
check 2 "$(g gate edit "$(ed S2)")"             "reset is not a way around the session gate"

# 10) The PR needs a spec on the branch (the proof is git, not the conversation)
gc() { (cd "$T" && git -c user.email=t@t -c user.name=t "$@" >/dev/null 2>&1); }
pr70='{"tool_name":"Bash","tool_input":{"command":"gh pr create --body \"Closes #70\""}}'
gc commit --allow-empty -m base; (cd "$T" && git update-ref refs/remotes/origin/main HEAD)
mkdir -p "$T/src" "$T/specs/001"; echo a >"$T/src/a.ts"; gc add src; gc commit -m code
s reset; s stamp task 70; s stamp dev; s stamp review
check 2 "$(g gate pr "$pr70")"                  "a PR with no spec on the branch is blocked"
echo s >"$T/specs/001/spec.md"; gc add specs; gc commit -m spec
check 0 "$(g gate pr "$pr70")"                  "a PR with a spec on the branch passes"

rm -rf "$T"
[ "$fails" -eq 0 ] && echo "OK flow-gate: $total cases" || { echo "x flow-gate: $fails failure(s)"; exit 1; }
