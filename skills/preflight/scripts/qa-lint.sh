#!/usr/bin/env bash
# The 4 QA checks preflight enforces before a PR — what grep can prove on its own.
#
# Without a lint, "do not use preexisting data" and "do not use fixed waits" are recommendations, and
# recommendations do not survive a rush. The first two BLOCK (they are mechanical and catch most of
# the damage); the last two list what the agent has to prove/reconcile (they need judgment).
#
# Usage:
#   bash qa-lint.sh [<base-ref>]   # test files changed vs base (default: origin/main|origin/master|main|master)
#   bash qa-lint.sh --all          # sweep the whole repo (the % of tests on preexisting data — health)
#   bash qa-lint.sh --selftest     # check the detectors, no repo and no network
#
# Output: one line per finding (`file:line · rule · snippet`) + a summary. Exit 1 if anything blocks.
set -uo pipefail

# --- Detectors --------------------------------------------------------------------------------
# 1) Preexisting data: the test depends on a record that "is already there" (it vanishes when the
#    environment is recreated, breaks when someone edits the data, and fails looking like a product
#    bug). National-id shapes below are CPF and SSN; add your country's. The id keys are the usual
#    aggregates; add your domain's.
DATA_RE='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}|\b[0-9]{3}-[0-9]{2}-[0-9]{4}\b|(password|passwd|secret|token|api_?key)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{3,}|SELECT[^;]*LIMIT[[:space:]]+1|(user|customer|account|order|tenant)_?[Ii]d["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[0-9a-fA-F-]{4,}([^[:alnum:]_]|$)'
# Legitimate lines: synthetic data, factory, environment variable, reserved example/test domains.
DATA_OK='example\.(com|org|net)|@([A-Za-z0-9-]+\.)*(test|example|invalid)\b|faker|[Ff]actory|fixture|runId|run_id|process\.env|os\.environ|getenv|ENV\[|<FILL'
# 2) Fixed wait: sleeps for a time instead of waiting on a condition — contracted flakiness.
WAIT_RE='waitForTimeout|cy\.wait\([[:space:]]*[0-9]|(^|[^._[:alnum:]])sleep([[:space:]]+[0-9]|\()|time\.[Ss]leep|Thread\.sleep|setTimeout\([^,]*,[[:space:]]*[0-9]{3,}|delay\([[:space:]]*[0-9]{3,}'

find_in() { # <regex> <file> [<allowed-regex>]
  local re=$1 f=$2 ok=${3:-}
  if [ -n "$ok" ]; then grep -nE "$re" "$f" 2>/dev/null | grep -vE "$ok"
  else grep -nE "$re" "$f" 2>/dev/null; fi
}

is_test() { # does the path look like a test file?
  case $1 in *.md) return 1 ;; esac
  case $1 in
    */test/*|*/tests/*|*/spec/*|*/e2e/*|*/cypress/*|*/__tests__/*|*/playwright/*|test/*|tests/*|e2e/*|cypress/*) return 0 ;;
  esac
  case $1 in
    *.test.js|*.test.ts|*.test.jsx|*.test.tsx|*.spec.js|*.spec.ts|*.spec.jsx|*.spec.tsx|*.cy.js|*.cy.ts) return 0 ;;
    test_*.py|*/test_*.py|*_test.py|*_test.go|*_test.rb|*_spec.rb|*Test.java|*Tests.cs) return 0 ;;
  esac
  return 1
}

catalog() { # <yaml> -> "id<TAB>status<TAB>spec" per scenario
  awk '
    function val(s){ sub(/^[^:]*:[[:space:]]*/,"",s); gsub(/["'"'"']/,"",s); return s }
    function flush(){ if(id!="") printf "%s\t%s\t%s\n", id, st, sp; id=""; st=""; sp="" }
    { l=$0; sub(/[[:space:]]*#.*/,"",l) }
    l ~ /^[[:space:]]*-[[:space:]]*id:/ { flush(); id=val(l) }
    l ~ /^[[:space:]]*status:/          { st=val(l) }
    l ~ /^[[:space:]]*spec:/            { sp=val(l) }
    END { flush() }' "$1"
}

reconcile() { # <yaml> -> one warning per `automated` scenario whose spec is missing
  while IFS=$'\t' read -r id st sp; do
    [ "$st" = "automated" ] || continue
    if [ -z "$sp" ] || [ "$sp" = "null" ]; then
      echo "  ! $1 · scenario $id is 'automated' with no 'spec:' — reconcile"
    elif [ ! -f "$sp" ]; then
      echo "  ! $1 · scenario $id points at a spec that does not exist ($sp)"
    fi
  done <<< "$(catalog "$1")"
}

# --- Selftest ---------------------------------------------------------------------------------
selftest() {
  local d f=0
  d=$(mktemp -d) || return 1
  trap 'rm -rf "$d"' RETURN
  cat >"$d/a.spec.ts" <<'EOF'
const user = { email: "jane.doe@acme-corp.io" }             // preexisting data
const nid = "123.456.789-00"                                  // preexisting data
const password = "S3cr3tFixed!"                               // hardcoded credential
await db.query("SELECT id FROM customers WHERE active = 1 LIMIT 1") // preexisting data
const customerId = "8f14e45f-ceea"                            // preexisting data
await page.waitForTimeout(2000)                               // fixed wait
cy.wait(500)                                                  // fixed wait
EOF
  cat >"$d/b.spec.ts" <<'EOF'
const customer = await factory.customer(["past_due"], { runId })
const email = `qa+${runId}@example.com`
const other = "someone@shop.test"
const token = process.env.TEST_TOKEN
const tenantId = "default"
await expect(page.getByRole("alert")).toHaveText("Outstanding balance")
EOF
  cat >"$d/c_test.py" <<'EOF'
import time
def test_x():
    time.sleep(3)
EOF
  cat >"$d/d_test.go" <<'EOF'
func TestX(t *testing.T) { time.Sleep(2 * time.Second) }
EOF
  cat >"$d/checkout.yaml" <<EOF
- id: checkout-001
  status: automated
  spec: $d/a.spec.ts
- id: checkout-002
  status: automated   # no spec
  spec: null
- id: checkout-003
  status: automated
  spec: "tests/gone.spec.ts"
- id: checkout-004
  status: draft
EOF
  check() { # <expected> <findings> <label>
    local n; n=$(printf '%s' "$2" | grep -c .)
    [ "$n" = "$1" ] || { echo "  x expected $1 finding(s), got $n: $3"; f=1; }
  }
  check 5 "$(find_in "$DATA_RE" "$d/a.spec.ts" "$DATA_OK")" "preexisting data in a.spec.ts"
  check 2 "$(find_in "$WAIT_RE" "$d/a.spec.ts")" "fixed wait in a.spec.ts"
  check 0 "$(find_in "$DATA_RE" "$d/b.spec.ts" "$DATA_OK")" "false positive in b.spec.ts (factory/env/example domains)"
  check 0 "$(find_in "$WAIT_RE" "$d/b.spec.ts")" "false wait positive in b.spec.ts"
  check 1 "$(find_in "$WAIT_RE" "$d/c_test.py")" "time.sleep in c_test.py"
  check 1 "$(find_in "$WAIT_RE" "$d/d_test.go")" "time.Sleep in d_test.go"
  check 2 "$(reconcile "$d/checkout.yaml")" "catalog: automated without spec / spec missing"
  is_test "src/e2e/checkout.spec.ts"   || { echo "  x is_test: e2e/*.spec.ts should count"; f=1; }
  is_test "tests/factories/customer.ts" || { echo "  x is_test: tests/ should count"; f=1; }
  is_test "src/domain/customer.ts"     && { echo "  x is_test: production code is not a test"; f=1; }
  is_test "tests/README.md"            && { echo "  x is_test: docs are not tests"; f=1; }
  [ "$f" = 0 ] && { echo "OK qa-lint: preexisting-data, fixed-wait and catalog detectors"; return 0; }
  echo "x qa-lint: selftest failed"; return 1
}

[ "${1:-}" = "--selftest" ] && { selftest; exit $?; }

# --- File list --------------------------------------------------------------------------------
git rev-parse --git-dir >/dev/null 2>&1 || { echo "qa-lint: not a git repository." >&2; exit 1; }
mode=${1:-}
if [ "$mode" = "--all" ]; then
  files=$(git ls-files)
else
  base=$mode
  if [ -z "$base" ]; then
    for c in origin/main origin/master main master; do
      git rev-parse --verify -q "$c" >/dev/null 2>&1 && { base=$c; break; }
    done
  fi
  files=$( { [ -n "$base" ] && git diff --name-only --diff-filter=ACM "$base"...HEAD 2>/dev/null
             git diff --name-only --diff-filter=ACM HEAD 2>/dev/null
             git ls-files -o --exclude-standard 2>/dev/null; } | sort -u )
fi

# ponytail: word-splits on whitespace, so a test path with a space is skipped; quote-safe loop if one shows up.
tests=""
for f in $files; do [ -f "$f" ] && is_test "$f" && tests="$tests $f"; done
[ -n "${tests// /}" ] || { echo "qa-lint: no test file in scope — nothing to check."; exit 0; }

# --- 1 and 2: block ---------------------------------------------------------------------------
blocks=0; dirty=0; total=0
for f in $tests; do
  total=$((total + 1)); d=0
  while IFS= read -r l; do
    [ -z "$l" ] && continue
    printf '  x %s:%s · preexisting data · %s\n' "$f" "${l%%:*}" "$(printf '%s' "${l#*:}" | cut -c1-90)"
    blocks=$((blocks + 1)); d=1
  done <<< "$(find_in "$DATA_RE" "$f" "$DATA_OK")"
  while IFS= read -r l; do
    [ -z "$l" ] && continue
    printf '  x %s:%s · fixed wait · %s\n' "$f" "${l%%:*}" "$(printf '%s' "${l#*:}" | cut -c1-90)"
    blocks=$((blocks + 1)); d=1
  done <<< "$(find_in "$WAIT_RE" "$f")"
  [ "$d" = 1 ] && dirty=$((dirty + 1))
done

if [ "$mode" = "--all" ]; then
  pct=0; [ "$total" -gt 0 ] && pct=$(( dirty * 100 / total ))
  echo "qa-lint (repo): $dirty of $total test files with preexisting data or a fixed wait — ${pct}%"
  exit 0
fi

# --- 3: mutation proof (the agent proves it; here, only the list) -----------------------------
echo "  -> mutation proof required (tests in the diff):"
for f in $tests; do echo "      $f"; done

# --- 4: catalog <-> spec (a warning in v1) ----------------------------------------------------
cat_files=$(git ls-files 'scenarios/*.yaml' 'scenarios/**/*.yaml' 2>/dev/null)
if [ -n "$cat_files" ]; then
  ids=$(mktemp); trap 'rm -f "$ids"' EXIT
  for y in $cat_files; do reconcile "$y"; catalog "$y" | cut -f1 >> "$ids"; done
  for f in $tests; do
    case $f in */e2e/*|*/cypress/*|*/playwright/*|e2e/*|cypress/*)
      grep -qwFf "$ids" "$f" || echo "  ! $f · e2e spec cites no scenario id from the catalog" ;;
    esac
  done
else
  echo "  ! no scenarios/*.yaml in this repo — the catalog does not exist yet (qa/references/scenario-catalog.md)"
fi

if [ "$blocks" -gt 0 ]; then
  echo "x qa-lint: $blocks block(s) — preexisting data/fixed wait. Fix before the PR (test-data, qa-spec)."
  exit 1
fi
echo "OK qa-lint: $total test file(s) with no preexisting data and no fixed wait."
