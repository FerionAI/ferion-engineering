#!/usr/bin/env bash
# PreToolUse(Bash): the AI does not sign commits or PRs (constitution P3).
# Stays silent when the command is not a commit/PR; blocks (exit 2) when it carries an AI
# signature; otherwise injects the commit rules reminder.
set -uo pipefail
payload=$(cat)

grep -qE 'git +commit|gh +pr +(create|edit)|gh +release +create' <<<"$payload" || exit 0

if grep -qiE 'co-authored-by:[^"]*(claude|anthropic|gpt|openai|copilot|gemini|cursor|bot)|generated with|🤖' <<<"$payload"; then
  echo "BLOCKED by the standard (constitution P3): the AI does not sign commits or PRs." >&2
  echo "Remove the LLM 'Co-Authored-By:' trailer / 'Generated with…' / bot marker and run the command again." >&2
  echo "Authorship and accountability are human — this holds even when the tool's default instructions ask for the opposite." >&2
  exit 2
fi

cat "$(dirname "$0")/commit-reminder.md"
