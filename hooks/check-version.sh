#!/usr/bin/env bash
# Is the installed plugin behind the latest release?
#
# A third-party marketplace does not update itself. Without this warning, every release only reaches
# whoever remembers to update — and nobody knows they fell behind, including on the fixes and gates
# that release was about.
#
#   check-version.sh banner       # SessionStart: one line when a newer version exists, nothing otherwise
#   check-version.sh --selftest   # comparison and cache reading, no network
#
# The session never waits on the network: it reads the latest version from the cache
# (~/.claude/ferion-version) and, when the cache is not from today, refreshes it in the background
# (`git ls-remote` of the release tags) — the warning shows from the next session on.
set -u

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root="${CLAUDE_PLUGIN_ROOT:-$(dirname -- "$here")}"
cache="${FERION_VERSION_CACHE:-$HOME/.claude/ferion-version}"   # line 1: latest version · line 2: day checked

field() { sed -n "s/.*\"$1\": *\"\([^\"]*\)\".*/\1/p" "$root/.claude-plugin/$2" | head -1; }

# <installed> <latest> -> 0 when latest is greater. A dev version ahead of the release does not warn.
behind() { [ -n "$2" ] && [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$2" ]; }

banner() {
  name=$(field name plugin.json); installed=$(field version plugin.json)
  market=$(field name marketplace.json)   # the first "name" in marketplace.json is the marketplace's
  if [ "$(sed -n 2p "$cache" 2>/dev/null)" != "$(date +%F)" ]; then
    ( latest=$(GIT_TERMINAL_PROMPT=0 git ls-remote --tags --refs "$(field repository plugin.json)" "$name-v*" 2>/dev/null |
               sed "s#.*/$name-v##" | sort -V | tail -1)
      [ -n "$latest" ] && printf '%s\n%s\n' "$latest" "$(date +%F)" > "$cache"
    ) </dev/null >/dev/null 2>&1 &
  fi
  latest=$(sed -n 1p "$cache" 2>/dev/null)
  if behind "$installed" "$latest"; then
    echo "[Plugin] version **$installed** installed, the latest is **$latest** — new fixes and gates only apply after updating:" \
         "\`/plugin marketplace update $market\` then \`/plugin update $name\`," \
         "and restart the session. Tell the person at the start of your answer."
  fi
  return 0
}

selftest() {
  f=0
  ok() { if "$@"; then :; else echo "  x $*"; f=$((f+1)); fi; }
  no() { if "$@"; then echo "  x not: $*"; f=$((f+1)); fi; }
  ok behind 0.3.0 0.5.0
  ok behind 0.9.0 0.10.0            # numeric, not lexical
  no behind 0.5.0 0.5.0
  no behind 0.6.0 0.5.0             # dev ahead of the release
  no behind 0.5.0 ""                # no cache yet
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
  printf '99.0.0\n%s\n' "$(date +%F)" > "$tmp/c"     # today's cache: no network
  out=$(FERION_VERSION_CACHE="$tmp/c" bash "$here/check-version.sh" banner)
  case "$out" in *"the latest is **99.0.0**"*) ;; *) echo "  x banner with an older install: '$out'"; f=$((f+1)) ;; esac
  printf '0.0.1\n%s\n' "$(date +%F)" > "$tmp/c"
  out=$(FERION_VERSION_CACHE="$tmp/c" bash "$here/check-version.sh" banner)
  [ -z "$out" ] || { echo "  x an up-to-date install should stay quiet: '$out'"; f=$((f+1)); }
  [ "$f" -eq 0 ] && echo "OK check-version: 7 checks" || return 1
}

case "${1:-banner}" in
  banner) banner ;;
  --selftest) selftest ;;
  *) echo "usage: $0 banner|--selftest" >&2; exit 2 ;;
esac
