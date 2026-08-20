#!/usr/bin/env sh
# Checks for no-ai-signature.sh: blocks AI signatures, gets out of the way otherwise.
# Runs in CI through scripts/validate-plugin.sh. Exit != 0 if any case fails.
set -u
H="$(dirname -- "$0")/no-ai-signature.sh"
OUT="${TMPDIR:-/tmp}/ferion-hook-$$.out"
fails=0

run() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" | bash "$H" >"$OUT" 2>/dev/null; echo $?; }
check() { # <expected exit> <command> <description>
  got=$(run "$2")
  [ "$got" = "$1" ] || { echo "  x $3 (expected exit=$1, got=$got)"; fails=$((fails+1)); }
}

check 0 "ls -la"                                                                  "an ordinary command passes"
[ -s "$OUT" ] && { echo "  x the hook spoke on a non-commit command"; fails=$((fails+1)); }
check 2 "git commit -m 'fix: x\n\nCo-Authored-By: Claude <noreply@anthropic.com>'" "an AI-signed commit is blocked"
check 2 "gh pr create --body 'closes #12\n\n🤖 Generated with Claude Code'"        "an AI-signed PR is blocked"
check 0 "git commit -m 'fix(auth): refresh token rotation (#12)'"                  "a clean commit passes"
check 0 "git commit -m 'feat: pairing\n\nCo-Authored-By: Ada <ada@example.com>'"   "a human co-author is not blocked"

rm -f "$OUT"
[ "$fails" -eq 0 ] && echo "OK no-ai-signature: 5 cases" || { echo "x no-ai-signature: $fails failure(s)"; exit 1; }
