#!/usr/bin/env bash
# Are the data sources this standard depends on actually configured?
#
# The list is NOT maintained here: it is derived from the plugin's own .mcp.json. Every ${VAR} a
# server declares is a credential someone has to supply, so an unset one is a source that will fail
# at the handshake — the failure people currently discover halfway through a report.
#
#   check-sources.sh banner            # SessionStart: say what is missing, never block
#   check-sources.sh gate              # PreToolUse on Skill: block a skill that needs a dead source
#   check-sources.sh live              # on demand, NEVER in a hook: who actually answers, and the fix
#   check-sources.sh --selftest        # the classifier and the live reading, no session and no network
#
# `banner` and `gate` do NO network I/O: they run at every session start, on a 10s timeout. Presence
# of a credential is instant and catches the common case (never configured). A credential that exists
# but is wrong still fails later — that is what `live` is for: it runs the real health check.
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

# --- live diagnosis ---------------------------------------------------------------------------
# Reads the output of `claude mcp list` and turns each state into an ACTION. Credential presence
# (classify) says whether it will fail later; the health check says whether it fails now — only the
# two together answer "is it working?".
interpret_live() {
  # The input goes through a file, not stdin: the heredoc below already IS python's stdin.
  _in=$(mktemp) || return 1
  cat > "$_in"
  python3 - "$_in" <<'PY'
import re, sys
lines = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
failed = pending = ok = 0
print("MCP servers — who actually answers:")
for l in lines:
    m = re.match(r"^([A-Za-z0-9_:.\-]+): (.*?) - ([^\n]+)$", l.strip())
    if not m:
        continue
    name, state = m.group(1), m.group(3).strip()
    if "Connected" in state:
        ok += 1; print(f"  ok      {name}"); continue
    if "Pending approval" in state:
        pending += 1
        print(f"  ?       {name} — waiting for approval. Run `claude` and approve it, OR ignore it if the same server already comes with the plugin (a duplicate does not help).")
        continue
    failed += 1
    detail = re.sub(r"^[^A-Za-z0-9]*(Failed to connect\s*[—-]?)?\s*", "", state).strip()
    if "Authorization header is badly formatted" in detail or "401" in detail or "403" in detail:
        fix = "credential missing/invalid in the header — set the variable the server declares and reopen the session"
    elif "Needs authentication" in detail:
        fix = "an OAuth server nobody authorized yet — open `/mcp` in a session and authenticate it"
    elif "dynamic client registration" in detail:
        fix = "this endpoint does NOT do OAuth: it only connects with a token in the header (removing the header does not help)"
    elif "CONNECTION_CLOSED" in detail or "ENOENT" in detail:
        fix = ("the local process did not start — for `docker`, check the daemon (`docker info`), the context and the image; "
               "for `npx`/`uvx`, check the binary")
    else:
        fix = "read the error and fix the cause; do not disable the server to make this pass"
    print(f"  FAILED  {name}\n          error: {detail[:120]}\n          fix:   {fix}")
print(f"\n{ok} connected · {failed} failed · {pending} waiting for approval")
if failed:
    print("A failed server = a skill that reads from it will degrade or block (it does not fake data).")
sys.exit(1 if failed else 0)
PY
  _ec=$?; rm -f "$_in"; return $_ec
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
    # Reading the health check (`live`), with lines in the shape `claude mcp list` prints.
    live_out=$(printf '%s\n' \
      "a: https://x/ (HTTP) - ✔ Connected" \
      "b: https://y/ (HTTP) - ✘ Failed to connect — HTTP 400: bad request: Authorization header is badly formatted" \
      "c: docker run -i --rm z - ✘ Failed to connect — CONNECTION_CLOSED: Connection closed" \
      "d: https://w/ (HTTP) - ⏸ Pending approval (run \`claude\` to approve)" \
      "e: https://v/ (HTTP) - ✘ Failed to connect — Incompatible auth server: does not support dynamic client registration" \
      "f: https://u/ (HTTP) - ! Needs authentication" \
      | bash "$0" __interpret); live_ec=$?
    lt() { printf '%s' "$live_out" | grep -q "$1" || { echo "  x live: missing '$1'"; fails=$((fails + 1)); }; }
    lt "ok      a"; lt "FAILED  b"; lt "set the variable"; lt "daemon"; lt "does NOT do OAuth"; lt "waiting for approval"; lt "authenticate it"
    lt "1 connected · 4 failed · 1 waiting"
    [ "$live_ec" = 1 ] || { echo "  x live: should exit 1 on a failure, exited $live_ec"; fails=$((fails + 1)); }
    [ "$fails" = 0 ] || { echo "x check-sources: $fails selftest failure(s)"; exit 1; }
    echo "OK check-sources: 17 selftest cases (credential presence + reading the health check)"
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

  live)
    # On demand (NEVER in a hook): ask Claude Code itself who actually answers.
    # `claude mcp list` runs the health check; here its output becomes a diagnosis + a fix per server.
    command -v claude >/dev/null 2>&1 || { echo "no claude CLI — without it the connection cannot be checked." >&2; exit 1; }
    timeout 180 claude mcp list 2>&1 | interpret_live
    exit $? ;;

  __interpret)  # internal, for the selftest: reads `claude mcp list` lines from stdin
    interpret_live; exit $? ;;

  *) echo "usage: $(basename "$0") <banner|live|gate|--selftest>" >&2; exit 1 ;;
esac
