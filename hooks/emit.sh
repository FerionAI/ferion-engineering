#!/usr/bin/env bash
# Run a hook command and hand its stdout to the agent as JSON `additionalContext`.
#
#   emit.sh <HookEvent> <command> [args...]      # stdin (the hook payload) is forwarded
#
# Why: Codex parses hook stdout that starts with `[` or `{` as JSON and fails ("hook returned invalid
# session start JSON output") — and every message here starts with a tag like `[Flow]`. Claude and
# Codex both read `hookSpecificOutput.additionalContext`, so one shape serves both hosts.
# The exit code and stderr pass through untouched: a block (exit 2 + stderr) stays a block.
set -u
ev=${1:?usage: emit.sh <HookEvent> <command> [args...]}; shift

esc() { # JSON string escaping, no python/jq dependency
  local s=$1
  s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\t'/\\t}; s=${s//$'\r'/}; s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

payload=$(cat)
out=$(printf '%s' "$payload" | "$@"); rc=$?
[ -n "$out" ] && printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$ev" "$(esc "$out")"
exit $rc
