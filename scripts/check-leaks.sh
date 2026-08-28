#!/usr/bin/env sh
# This plugin is generic on purpose: it must work for any team, in any repository.
# Company names, tenant URLs, tracker-specific field ids and internal project keys are the
# kind of thing that creeps back in one commit at a time. This check fails the build when it does.
#
# Rule of thumb: ship the shape, never the values. A value that belongs to one team lives in
# config/team-config.md (git-ignored), discovered at install time by `setup`/`onboard`.
set -u
cd "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)" || exit 2

# Terms that must never appear in the public repository.
# Kept deliberately generic: an enumerated list of a company's own names and tracker keys would
# publish, in the detector, exactly what the detector exists to hide. Any real tracker key matches
# the shape below, so nothing is lost by not naming them.
TERMS='(atlassian|\bjira\b|customfield_[0-9]+)'

# The private term list (a company's own names) travels as an env var, never in the repo: set
# LEAK_PATTERNS as a repository secret and the workflow passes it in. Absent, the generic check
# still runs — it just cannot know your company's name.
[ -n "${LEAK_PATTERNS:-}" ] && TERMS="($TERMS|$LEAK_PATTERNS)"

# The shape of a tracker key (ABC-123). Matched case-SENSITIVELY on purpose: with -i it also
# matches css tokens like `gray-500` and flags for `cut -c1-70`.
KEYS='\b[A-Z][A-Z0-9]{1,7}-[0-9]{2,}\b'
# Standards and specs share that shape and are legitimate here.
NOT_A_KEY='\b(ADR|ISO|RFC|CVE|WCAG|OWASP|UTF|SHA|HTTP|P)-[0-9]'

EXCLUDES="--exclude-dir=.git --exclude-dir=node_modules --exclude=check-leaks.sh"

# The classifier, exercised without touching the tree. The case-sensitivity of KEYS is the whole
# point of these cases: with -i the key shape also swallows css tokens and flag values.
if [ "${1:-}" = "--selftest" ]; then
  fails=0
  t() {  # t <leak|clean> <text>
    if printf '%s\n' "$2" | grep -qiE "$TERMS" ||
       printf '%s\n' "$2" | grep -E "$KEYS" 2>/dev/null | grep -qvE "$NOT_A_KEY"
    then got=leak; else got=clean; fi
    [ "$got" = "$1" ] || { echo "  x expected $1, got $got: $2"; fails=$((fails + 1)); }
  }
  t leak  'blocked by PLA-1234 until friday'
  t leak  'writes to customfield_11403'
  t leak  'the jira board is the source of truth'
  t clean 'className="bg-gray-500 text-red-400"'
  t clean 'head -1 | cut -c1-70'
  t clean 'see ADR-0001, ISO-8601 and RFC-7231'
  t clean 'WCAG-22 AA and OWASP-10'
  [ "$fails" = 0 ] || { echo "x check-leaks: $fails selftest failure(s)"; exit 1; }
  echo "OK check-leaks: 7 selftest cases"
  exit 0
fi

hits=$(
  { grep -rniE "$TERMS" . $EXCLUDES
    grep -rnE  "$KEYS"  . $EXCLUDES | grep -vE "$NOT_A_KEY"
  } 2>/dev/null
)

if [ -n "$hits" ]; then
  echo "x check-leaks: terms from the private upstream standard found in the public repo:"
  echo "$hits" | head -40
  echo ""
  echo "Nothing company-specific ships. Replace the term with the generic form, or move the"
  echo "value to config/team-config.example.md as a <FILL: ...> placeholder. See CONTRIBUTING.md."
  exit 1
fi

echo "OK check-leaks: no private upstream terms"
