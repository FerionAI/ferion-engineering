#!/usr/bin/env bash
# The whole of preflight step 1 in ONE call: build, types, lint, tests (+ qa-lint) and PR bots.
#
# Why it exists: run by hand, step 1 takes dozens of round trips, and every round trip pays for the
# whole context again (ADR-0004). The work is the same; the waste is the conversation around it.
# One call fixes both axes: less wall time and fewer tokens re-read.
#
# Usage:
#   bash preflight.sh                        # detect this repo's commands and run them all
#   bash preflight.sh --base=origin/main     # diff base for qa-lint, when present (default: its own)
#   bash preflight.sh --no-bots              # skip the reviewer check (offline / no gh)
#   bash preflight.sh --lines=40             # how many lines of a failing log to show (default 25)
#   PREFLIGHT_TIMEOUT=1800 bash preflight.sh # per-step limit in seconds (default 900)
#   bash preflight.sh --selftest             # checks detection and reporting, no repo, no network
#
# Wrong command, or a repo off the usual shape? Override without editing anything:
#   PREFLIGHT_BUILD='pnpm build' PREFLIGHT_LINT='pnpm lint' PREFLIGHT_TEST='pnpm test' \
#   PREFLIGHT_TYPES='tsc --noEmit' bash preflight.sh
#   PREFLIGHT_LINT='-' turns a step off explicitly (reported as "off", never as green).
#
# Output: one line per step (`step · verdict · time · command`) + the log tail of failing steps only.
# Exit 1 when any step is red. A step with no command reports "not configured" — never green:
# faking green is the worst outcome in an agentic flow (SKILL.md, "Do not fake green").
set -uo pipefail

LINES=25
TIMEOUT="${PREFLIGHT_TIMEOUT:-900}"
BASE=""
BOTS=1
SELFTEST=0
for a in "$@"; do
  case "$a" in
    --base=*)   BASE="${a#*=}" ;;
    --lines=*)  LINES="${a#*=}" ;;
    --no-bots)  BOTS=0 ;;
    --selftest) SELFTEST=1 ;;
    *) echo "unknown argument: $a" >&2; exit 1 ;;
  esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
failed=0; green=0; skipped=0

# --- Detection: what THIS repo knows how to run -------------------------------------------------
# Rule: only a command that really exists enters the report (a package.json script, a Makefile
# target, a stack file). No guessed stack matrix — a repo with no lint is common, and an invented
# command produces a hollow report (context/references/conventions.md).
has() { command -v "$1" >/dev/null 2>&1; }

pm() { # package manager from the lockfile, not from what happens to be installed
  [ -f pnpm-lock.yaml ] && { echo pnpm; return; }
  [ -f yarn.lock ] && { echo yarn; return; }
  [ -f bun.lockb ] && { echo bun; return; }
  echo npm
}

npm_script() { # <name> -> prints the command when package.json has that script
  [ -f package.json ] || return 1
  local n="$1" p; p="$(pm)"
  if has jq; then
    jq -e --arg n "$n" '.scripts[$n] // empty' package.json >/dev/null 2>&1 || return 1
  else
    grep -qE "\"$n\"[[:space:]]*:" package.json || return 1
  fi
  case "$p" in
    npm) echo "npm run $n" ;;
    *)   echo "$p $n" ;;
  esac
}

make_target() { # <target> -> "make <target>" when the Makefile has it
  [ -f Makefile ] || return 1
  grep -qE "^$1:" Makefile || return 1
  echo "make $1"
}

detect() { # <step> -> command, or empty
  case "$1" in
    build) npm_script build || make_target build || { [ -f go.mod ] && echo "go build ./..."; } \
           || { ls build.gradle build.gradle.kts >/dev/null 2>&1 && echo "./gradlew build -x test"; } \
           || { ls ./*.tf >/dev/null 2>&1 && echo "terraform validate"; } || true ;;
    types) npm_script typecheck || npm_script type-check || npm_script tsc \
           || { [ -f tsconfig.json ] && has npx && echo "npx tsc --noEmit"; } \
           || { [ -f go.mod ] && echo "go vet ./..."; } || true ;;
    lint)  npm_script lint || make_target lint \
           || { [ -f .golangci.yml ] && has golangci-lint && echo "golangci-lint run"; } \
           || { has ruff && [ -f pyproject.toml ] && echo "ruff check ."; } \
           || { ls ./*.tf >/dev/null 2>&1 && echo "terraform fmt -check -recursive"; } || true ;;
    # `test` in a Vite/Vitest repo is watch mode — it hangs the whole session. Prefer a single-pass
    # script; when only `test` exists, CI=true below takes vitest/jest out of interactive mode.
    test)  npm_script test:ci || npm_script test:run || npm_script test || make_target test \
           || { [ -f go.mod ] && echo "go test ./..."; } \
           || { has pytest && echo "pytest -q"; } \
           || { ls build.gradle build.gradle.kts >/dev/null 2>&1 && echo "./gradlew test"; } || true ;;
  esac
}

command_for() { # the environment override wins over detection; '-' turns the step off
  local var="PREFLIGHT_$(echo "$1" | tr '[:lower:]' '[:upper:]')"   # one line at a time: bash expands before assigning
  local v="${!var:-}"
  [ -n "$v" ] && { echo "$v"; return; }
  detect "$1"
}

# --- Execution ----------------------------------------------------------------------------------
run() { # <label> <command>
  local label="$1" cmd="$2" log="$TMP/$1.log" t0 dt
  if [ -z "$cmd" ]; then
    printf '%-6s --  not configured in this repo (degrades with a warning; do not count it as green)\n' "$label"
    skipped=$((skipped+1)); return
  fi
  if [ "$cmd" = "-" ]; then
    printf '%-6s --  off by PREFLIGHT_%s=-\n' "$label" "$(echo "$label" | tr '[:lower:]' '[:upper:]')"
    skipped=$((skipped+1)); return
  fi
  t0=$SECONDS
  # ponytail: sequential. Parallel only pays once the suite passes ~5 min — and then build and test
  # fight over the same output directory, which costs more than it saves.
  # CI=true: takes vitest/jest/playwright out of watch mode. Timeout: a hung step is worse than a red
  # one — it freezes the session and does not say why.
  if has timeout; then CI=true timeout -k 10 "$TIMEOUT" bash -c "$cmd" >"$log" 2>&1
  else CI=true bash -c "$cmd" >"$log" 2>&1; fi
  local rc=$?; dt=$((SECONDS-t0))
  [ $rc -eq 124 ] && echo "    | (hit the ${TIMEOUT}s limit — PREFLIGHT_TIMEOUT adjusts it)" >>"$log"
  if [ $rc -eq 0 ]; then
    printf '%-6s ok  %ss · %s\n' "$label" "$dt" "$cmd"; green=$((green+1))
  else
    printf '%-6s FAIL %ss · %s  (exit %s)\n' "$label" "$dt" "$cmd" "$rc"; failed=$((failed+1))
    tail -n "$LINES" "$log" | sed -e 's/^/    | /'
  fi
}

# --- Selftest (no repo, no network) -------------------------------------------------------------
if [ "$SELFTEST" = 1 ]; then
  ok=0; bad=0
  t() { if [ "$2" = "$3" ]; then ok=$((ok+1)); else bad=$((bad+1)); echo "  x $1: expected [$3], got [$2]"; fi; }
  d="$(mktemp -d)"; pushd "$d" >/dev/null
    printf '{"scripts":{"build":"vite build","lint":"biome check"}}' > package.json
    : > pnpm-lock.yaml
    t "build detected (pnpm)"   "$(detect build)" "pnpm build"
    t "lint detected (pnpm)"    "$(detect lint)"  "pnpm lint"
    t "missing test = empty"    "$(detect test)"  ""
    rm pnpm-lock.yaml; : > yarn.lock
    t "lockfile picks the pm"   "$(detect build)" "yarn build"
    printf '{"scripts":{"test":"vitest","test:run":"vitest run"}}' > package.json
    t "watch mode is skipped"   "$(detect test)"  "yarn test:run"
    t "environment override"    "$(PREFLIGHT_BUILD='make all' command_for build)" "make all"
    printf 'build:\n\techo hi\ntest:\n\techo hi\n' > Makefile; rm package.json yarn.lock
    t "Makefile as fallback"    "$(detect build)" "make build"
    out="$(run step 'exit 3')"
    case "$out" in *FAIL*'exit 3'*) ok=$((ok+1));; *) bad=$((bad+1)); echo "  x failure not reported: $out";; esac
    out="$(run step '')"
    case "$out" in *'not configured'*) ok=$((ok+1));; *) bad=$((bad+1)); echo "  x empty step should degrade: $out";; esac
    out="$(run step '-')"
    case "$out" in *'off by'*) ok=$((ok+1));; *) bad=$((bad+1)); echo "  x '-' should turn the step off: $out";; esac
  popd >/dev/null; rm -rf "$d"
  [ "$bad" -eq 0 ] && echo "OK preflight.sh: $ok selftest cases" || echo "x preflight.sh: $bad selftest failure(s)"
  [ "$bad" -eq 0 ]; exit $?
fi

# --- Report -------------------------------------------------------------------------------------
echo "preflight — $(basename "$(pwd)") · $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no git')"
for p in build types lint test; do run "$p" "$(command_for "$p")"; done

# Test-quality lint ships with the QA kit; run it when this plugin has it.
if [ -f "$HERE/qa-lint.sh" ]; then
  echo "-- test quality (qa-lint)"
  if bash "$HERE/qa-lint.sh" ${BASE:+"$BASE"} > "$TMP/qa.log" 2>&1; then green=$((green+1)); else failed=$((failed+1)); fi
  sed -e 's/^/  /' "$TMP/qa.log"
fi

if [ "$BOTS" = 1 ] && has gh; then
  echo "-- this repo's automated reviewers (step 1.2)"
  bash "$HERE/pr-bots.sh" 2>&1 | sed -e 's/^/  /'
fi

echo "--"
if [ "$failed" -gt 0 ]; then
  echo "x preflight: $failed red step(s), $green green, $skipped with no command. Fix and run again — the gate is a loop, not a report."
  exit 1
fi
echo "OK preflight: $green green, $skipped with no command. Steps 2–4 (anti-hallucination, checklist, adversarial verification) are yours — the script does not replace them."
[ "$skipped" -gt 0 ] && echo "  ! $skipped step(s) with no command: say so in the summary and offer onboard. Do not count them as green."
exit 0
