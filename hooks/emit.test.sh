#!/usr/bin/env sh
# Checks for emit.sh: hook stdout reaches the agent as valid JSON on both hosts, blocks stay blocks.
# Runs in CI through scripts/validate-plugin.sh. Exit != 0 if any case fails.
set -u
H="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/emit.sh"
fails=0
check() { [ "$1" = "$2" ] || { echo "  x $3 (expected=$1, got=$2)"; fails=$((fails+1)); }; }

# 1) A tagged, multi-line message with quotes, backslashes and tabs becomes valid JSON, intact
msg='[Flow] issue **#42** — "quoted" C:\path	tab
second line'
out=$(echo '{}' | bash "$H" SessionStart printf '%s' "$msg")
got=$(printf '%s' "$out" | python3 -c 'import json,sys;d=json.load(sys.stdin)["hookSpecificOutput"];print(d["hookEventName"]+"|"+d["additionalContext"])' 2>/dev/null)
check "SessionStart|$msg" "$got" "tagged multi-line output becomes valid additionalContext JSON"

# 2) The payload on stdin reaches the wrapped command
got=$(echo '{"tool_name":"Bash"}' | bash "$H" PreToolUse cat | python3 -c 'import json,sys;print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])' 2>/dev/null)
check '{"tool_name":"Bash"}' "$got" "stdin is forwarded to the wrapped command"

# 3) A block keeps its exit code and its stderr, and prints nothing on stdout
out=$(echo '{}' | bash "$H" PreToolUse sh -c 'echo "BLOCKED by the mandatory flow" >&2; exit 2' 2>/dev/null); rc=$?
check 2 "$rc" "exit 2 passes through"
check "" "$out" "a block prints no JSON on stdout"
err=$(echo '{}' | bash "$H" PreToolUse sh -c 'echo "BLOCKED by the mandatory flow" >&2; exit 2' 2>&1 >/dev/null)
check "BLOCKED by the mandatory flow" "$err" "stderr passes through"

# 4) A silent hook stays silent
check "" "$(echo '{}' | bash "$H" SessionStart true)" "no output -> no JSON"

[ "$fails" -eq 0 ] && echo "OK emit: 6 cases" || { echo "x emit: $fails failure(s)"; exit 1; }
