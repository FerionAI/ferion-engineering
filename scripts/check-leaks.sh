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
PATTERNS='(\bg4\b|g4educacao|g4business|gestao-quatro|atlassian|\bjira\b|customfield_[0-9]+|\b(PLA|ACC|MTECH|REV|FIN|SAP|VUL)-[0-9]{2,}\b)'

hits=$(grep -rniE "$PATTERNS" . \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude=check-leaks.sh 2>/dev/null)

if [ -n "$hits" ]; then
  echo "x check-leaks: terms from the private upstream standard found in the public repo:"
  echo "$hits" | head -40
  echo ""
  echo "Nothing company-specific ships. Replace the term with the generic form, or move the"
  echo "value to config/team-config.example.md as a <FILL: ...> placeholder. See CONTRIBUTING.md."
  exit 1
fi

echo "OK check-leaks: no private upstream terms"
