#!/usr/bin/env bash
# Who REALLY reviews this repo's PRs — and who only looks like it.
#
# `preflight` promises "zero automated findings on the PR". That only means something while the
# automated reviewers are alive: a bot out of quota or with a paused subscription posts a notice and
# goes quiet, and the PR sails through looking reviewed. This script separates the two cases.
#
# Usage:
#   bash pr-bots.sh [<owner/repo>] [<how many PRs>]   # default: current repo, last 20 merged PRs
#   bash pr-bots.sh --selftest                        # checks the classifier (no network)
#
# Output: one line per bot — `<login> · <n> comment(s) · ALIVE|MUTE (<reason>)`.
set -uo pipefail

# Phrases reviewers use to say they did NOT review (quota, subscription, seat, trial).
MUTE_RE='reached your monthly limit|reviews are paused|quota (exceeded|reached)|upgrade (your|to a) plan|no (available )?seats|trial (has )?expired|subscription (is )?(inactive|expired)|billing'

classify() { grep -qiE "$MUTE_RE" <<<"$1" && echo MUTE || echo ALIVE; }

selftest() {
  local f=0
  want() { [ "$(classify "$2")" = "$1" ] || { echo "  x expected $1: $2"; f=1; }; }
  want MUTE  "You have reached your monthly limit for code reviews."
  want MUTE  "### Qodo reviews are paused for this user."
  want MUTE  "Your trial has expired — upgrade your plan to continue."
  want ALIVE "Found 2 issues: SQL injection risk in line 42."
  want ALIVE "LGTM. Nothing blocking in this change."
  want ALIVE ""
  [ "$f" = 0 ] && echo "OK pr-bots: mute-reviewer classifier" || { echo "x pr-bots: failed"; return 1; }
}

[ "${1:-}" = "--selftest" ] && { selftest; exit $?; }

command -v gh >/dev/null 2>&1 || { echo "gh not found — without it there is no way to know who reviews (integrations)." >&2; exit 1; }
repo=${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)}
[ -n "$repo" ] || { echo "repo not identified: pass <owner/repo>." >&2; exit 1; }
n=${2:-20}

prs=$(gh pr list -R "$repo" --state merged -L "$n" --json number -q '.[].number' 2>/dev/null)
[ -n "$prs" ] || { echo "no merged PR found in $repo." >&2; exit 1; }

tmp=$(mktemp) || exit 1
trap 'rm -f "$tmp"' EXIT
for pr in $prs; do
  gh api "repos/$repo/issues/$pr/comments" \
     --jq '.[]|select(.user.type=="Bot")|[.user.login,(.body|gsub("[\n\t]";" ")|.[0:200])]|@tsv' 2>/dev/null
done >"$tmp"

[ -s "$tmp" ] || { echo "$repo · $(wc -w <<<"$prs") PRs: no bot comments — there is no automated reviewer configured."; exit 0; }

echo "$repo · $(wc -w <<<"$prs") merged PRs analysed:"
cut -f1 "$tmp" | sort -u | while read -r bot; do
  total=$(grep -cP "^\Q$bot\E\t" "$tmp")
  mutes=$(grep -P "^\Q$bot\E\t" "$tmp" | cut -f2- | grep -ciE "$MUTE_RE")
  if [ "$mutes" -gt 0 ] && [ "$mutes" -ge $((total / 2)) ]; then
    why=$(grep -P "^\Q$bot\E\t" "$tmp" | cut -f2- | grep -iE "$MUTE_RE" | head -1 | cut -c1-70)
    printf '  %-28s · %2d comment(s) · MUTE — %s\n' "$bot" "$total" "$why"
  else
    printf '  %-28s · %2d comment(s) · ALIVE\n' "$bot" "$total"
  fi
done
echo "ALIVE bots = what preflight has to anticipate. MUTE bots = this PR ships unreviewed: say so in the summary."
