#!/usr/bin/env bash
# Are the data sources this standard depends on actually configured?
#
# The list is NOT maintained here: it is derived from the plugin's own .mcp.json. Every ${VAR} a
# server declares is a credential someone has to supply, so an unset one is a source that will fail
# at the handshake — the failure people currently discover halfway through a report.
#
#   check-sources.sh banner            # SessionStart: say what is missing, never block
#   check-sources.sh gate              # PreToolUse on Skill: block a skill that needs a dead source
#   check-sources.sh --selftest        # the classifier, no session and no network
#
# Deliberately does NO network I/O: this runs at every session start, on a 10s timeout. Presence of
# a credential is instant and catches the common case (never configured). A credential that exists
# but is wrong still fails later — that is what `health`'s own connect-first step is for.
set -u

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mcp="${CLAUDE_PLUGIN_ROOT:-$(dirname -- "$here")}/.mcp.json"

# Skills that must not run on a half-configured source. Anything not listed is never blocked.
requires_all() { case "$1" in health) return 0 ;; *) return 1 ;; esac; }

# --- reading .mcp.json ------------------------------------------------------------------------
# "<server> <VAR> <VAR>..." — the ${VAR} placeholders that server declares. No vars = OAuth or none.
server_vars() {
  [ -f "$mcp" ] || return 0
  python3 - "$mcp" <<'PY' 2>/dev/null
import json, re, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
for name, cfg in (d.get("mcpServers") or {}).items():
    found = sorted(set(re.findall(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}", json.dumps(cfg))))
    # A remote server with no placeholder authenticates in a browser; a local one just runs.
    kind = "remote" if (cfg.get("type") or cfg.get("url")) else "local"
    print(name, kind, *found)
PY
}

# --- classification ---------------------------------------------------------------------------
# Echoes "<server>\t<state>\t<detail>". States: ok | missing | unverifiable
classify() {
  server_vars | while read -r name kind vars; do
    if [ -z "${vars:-}" ]; then
      # Nothing to supply: a local server needs no credential, a remote one authenticates in a browser.
      [ "$kind" = remote ] \
        && printf '%s\tunverifiable\tbrowser auth — confirm with /mcp\n' "$name" \
        || printf '%s\tok\tno credential needed\n' "$name"
      continue
    fi
    absent=""
    for v in $vars; do
      eval "val=\${$v:-}"
      [ -n "${val:-}" ] || absent="$absent $v"
    done
    if [ -n "$absent" ]; then
      printf '%s\tmissing\t%s\n' "$name" "${absent# }"
    else
      printf '%s\tok\t%s\n' "$name" "$vars"
    fi
  done
}

# --- commands ---------------------------------------------------------------------------------
case "${1:-banner}" in
  --selftest)
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    mcp="$tmp/.mcp.json"
    cat > "$mcp" <<'JSON'
{"mcpServers":{
  "withvars":{"type":"http","url":"https://x/","headers":{"Authorization":"Bearer ${SELFTEST_TOKEN}"}},
  "twovars":{"command":"x","env":{"A":"${SELFTEST_A}","B":"${SELFTEST_B}"}},
  "oauthy":{"type":"http","url":"https://mcp.example.com/v1/mcp"},
  "localy":{"command":"npx","args":["-y","something"]}
}}
JSON
    fails=0
    t() {  # t <server> <expected state> [env assignments...]
      want_srv=$1; want=$2; shift 2
      got=$(env -u SELFTEST_TOKEN -u SELFTEST_A -u SELFTEST_B "$@" \
            bash "$0" __classify "$mcp" | awk -F'\t' -v s="$want_srv" '$1==s{print $2}')
      [ "$got" = "$want" ] || { echo "  x $want_srv: expected $want, got ${got:-<none>}"; fails=$((fails + 1)); }
    }
    t withvars missing
    t withvars ok           SELFTEST_TOKEN=abc
    t withvars missing      SELFTEST_TOKEN=
    t twovars  missing      SELFTEST_A=a
    t twovars  ok           SELFTEST_A=a SELFTEST_B=b
    t oauthy   unverifiable
    t oauthy   unverifiable SELFTEST_TOKEN=abc
    t localy   ok                                  # local, no credential: not an OAuth server
    [ "$fails" = 0 ] || { echo "x check-sources: $fails selftest failure(s)"; exit 1; }
    echo "OK check-sources: 8 selftest cases"
    exit 0 ;;

  __classify)  # internal, for the selftest: classify an arbitrary .mcp.json
    mcp=$2; classify; exit 0 ;;

  banner)
    out=$(classify)
    [ -n "$out" ] || exit 0
    miss=$(printf '%s\n' "$out" | awk -F'\t' '$2=="missing"{printf "  - %s: set %s\n", $1, $3}')
    unv=$(printf '%s\n' "$out" | awk -F'\t' '$2=="unverifiable"{printf "%s ", $1}')
    [ -n "$miss" ] || [ -n "$unv" ] || exit 0
    echo "[Sources] What the dashboard and the gates read from:"
    [ -n "$miss" ] && {
      echo "NOT configured — these will fail at the handshake, not at the query:"
      printf '%s\n' "$miss"
      echo "  Set them in your shell profile (or the team's secret manager), then reopen the session."
      echo "  A skill that needs one of these is blocked rather than shipping a report with holes."
    }
    [ -n "$unv" ] && echo "Cannot be checked from a hook (browser auth): ${unv% }. Confirm with \`/mcp\` before trusting a report that uses them."
    exit 0 ;;

  gate)
    payload=$(cat)
    skill=$(printf '%s' "$payload" | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
print(((d.get("tool_input") or {}).get("skill") or ""))' 2>/dev/null)
    skill=${skill##*:}                       # plugin:skill -> skill
    [ -n "$skill" ] || exit 0
    requires_all "$skill" || exit 0
    miss=$(classify | awk -F'\t' '$2=="missing"{printf "  - %s: set %s\n", $1, $3}')
    [ -n "$miss" ] || exit 0
    {
      echo "BLOCKED: \`$skill\` reads from sources that are not configured."
      printf '%s\n' "$miss"
      echo ""
      echo "This is the failure that used to surface halfway through the report. Do this first:"
      echo "  1. Set the variables above and reopen the session (a hook reads them at start)."
      echo "  2. Confirm every server answers: \`/mcp\`."
      echo "  3. Genuinely want the partial picture? Say which sources to leave out, and run it again"
      echo "     — the skill marks them 'pending connection' instead of guessing a number."
    } >&2
    exit 2 ;;

  *) echo "usage: $(basename "$0") <banner|gate|--selftest>" >&2; exit 1 ;;
esac
