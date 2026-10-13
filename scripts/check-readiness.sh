#!/usr/bin/env sh
# Readiness to publish/install through the marketplace — what fails SILENTLY.
#
# Complements `validate-plugin.sh` (JSON, frontmatter, refs, ROLES, constitution sync): these are the
# checks whose failure nobody notices until someone installs — a version that disagrees (nobody gets
# the update and nothing says so), a declared path that does not exist, a skill count the docs get
# wrong, a machine artifact shipped, a committed secret. The manual half lives in READINESS.md.
#
# Usage:  sh scripts/check-readiness.sh          # exit != 0 on any FAIL (a WARN does not fail)
# CI:     .github/workflows/validate.yml
set -e
cd "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

python3 - <<'PY'
import json, glob, os, re, subprocess, sys

fails, warns = [], []
def fail(item, m): fails.append(f"[{item}] {m}")
def warn(item, m): warns.append(f"[{item}] {m}")
def read(p):
    with open(p, encoding="utf-8") as f: return f.read()

# ---- A1: manifests point at things that exist ---------------------------------------------
mk_path, pl_path = ".claude-plugin/marketplace.json", ".claude-plugin/plugin.json"
mk = json.load(open(mk_path, encoding="utf-8")) if os.path.exists(mk_path) else {}
pl = json.load(open(pl_path, encoding="utf-8")) if os.path.exists(pl_path) else {}
if not mk: fail("A1", f"{mk_path} missing")
if not pl: fail("A1", f"{pl_path} missing")
if not mk.get("name"): fail("A1", "marketplace.json has no 'name'")
if not (mk.get("owner") or {}).get("name"): fail("A1", "marketplace.json has no 'owner.name'")
if not mk.get("plugins"): fail("A1", "marketplace.json has no 'plugins'")
if pl.get("name") and not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", pl["name"]):
    fail("A1", f"plugin.json name '{pl['name']}' is not kebab-case")

for p in mk.get("plugins", []):
    src = p.get("source")
    if isinstance(src, str) and not src.startswith(("http", "git@")):
        if not os.path.isdir(src): fail("A1", f"marketplace: source '{src}' is not an existing directory")
    elif not isinstance(src, str):
        warn("A1", f"marketplace: non-string source in '{p.get('name')}' — check it against the schema")

# Paths declared in plugin.json exist. `skills` ADDS to the default; `commands`, `agents` and
# `outputStyles` REPLACE the default when declared — declaring one with a wrong path erases them all.
for key in ("hooks", "mcpServers", "skills", "commands", "agents", "outputStyles"):
    v = pl.get(key)
    if v is None: continue
    for path in (v if isinstance(v, list) else [v]):
        if isinstance(path, str):
            real = re.sub(r"^(\$\{CLAUDE_PLUGIN_ROOT\}/|\./)", "", path)
            if not os.path.exists(real): fail("A1", f"plugin.json '{key}' points at missing '{path}'")
    if key in ("commands", "agents", "outputStyles"):
        warn("A1", f"plugin.json declares '{key}': that REPLACES the default directory — confirm nothing was lost")

# Hooks: a command pointing at a missing script fails only when its event fires. An unquoted
# ${CLAUDE_PLUGIN_ROOT} breaks every hook when the install path has a space in it.
if os.path.exists("hooks/hooks.json"):
    raw = read("hooks/hooks.json")
    try: json.loads(raw)
    except Exception as e: fail("A1", f"hooks/hooks.json is invalid: {e}")
    for target in sorted(set(re.findall(r'\$\{CLAUDE_PLUGIN_ROOT\}/([A-Za-z0-9_./-]+)', raw))):
        if not os.path.exists(target): fail("A1", f"hooks.json references '{target}', which does not exist")
    bare = len(re.findall(r'(?<!\\")\$\{CLAUDE_PLUGIN_ROOT\}', raw))
    if bare: warn("A1", f"hooks.json: {bare} unquoted ${{CLAUDE_PLUGIN_ROOT}} — a space in the install path breaks those hooks")

# ---- A2: one version everywhere — the item that fails silently -----------------------------
versions = {}
if pl.get("version"): versions[pl_path] = pl["version"]
else: fail("A2", "plugin.json has no 'version'")
if (mk.get("metadata") or {}).get("version"): versions[f"{mk_path}:metadata"] = mk["metadata"]["version"]
for i, p in enumerate(mk.get("plugins", [])):
    if p.get("version"): versions[f"{mk_path}:plugins[{i}]"] = p["version"]
if os.path.exists(".release-please-manifest.json"):
    for k, v in json.load(open(".release-please-manifest.json", encoding="utf-8")).items():
        versions[f".release-please-manifest.json:{k}"] = v
# Every file release-please stamps must carry the same version.
for f in glob.glob("**/*.md", recursive=True):
    if f.startswith("node_modules/"): continue
    for line in read(f).splitlines():
        if "x-release-please-version" in line:
            m = re.search(r"(\d+\.\d+\.\d+)", line)
            if m: versions[f] = m.group(1)
            else: fail("A2", f"{f}: a release-please marker line with no semver")
distinct = set(versions.values())
if len(distinct) > 1:
    fail("A2", "versions disagree (nobody gets the update and nothing says so): "
               + " · ".join(f"{k}={v}" for k, v in sorted(versions.items())))

# ---- A3: the skill count the docs declare matches the disk ---------------------------------
n_skills = len(glob.glob("skills/*/SKILL.md"))
for f in ["README.md", "CLAUDE.md", "AGENTS.md", "CONTRIBUTING.md", "READINESS.md"] + glob.glob("docs/**/*.md", recursive=True) + glob.glob("skills/**/*.md", recursive=True):
    if f.startswith("docs/adr/") or not os.path.exists(f): continue   # ADRs record the past, not today
    for i, line in enumerate(read(f).splitlines(), 1):
        for m in re.finditer(r"(?<![\w/])(\d{1,3}) skills\b", line):   # does not match 'python3 skills/...'
            if int(m.group(1)) != n_skills:
                fail("A3", f"{f}:{i} says '{m.group(1)} skills', the disk has {n_skills}")

tracked = subprocess.run(["git", "ls-files"], capture_output=True, text=True).stdout.split()

# ---- A3: someone's absolute machine path in a shipped file ---------------------------------
for f in tracked:
    if not os.path.isfile(f) or os.path.splitext(f)[1] not in (".md", ".json", ".sh", ".py", ".html", ".yml", ".yaml"):
        continue
    for i, line in enumerate(read(f).splitlines(), 1):
        if re.search(r"(/home/[a-z]|/Users/[A-Za-z]|[A-Z]:\\\\Users)", line) and "$HOME" not in line:
            fail("A3", f"{f}:{i} an absolute path from someone's machine")

# ---- A6: secrets and credentials ------------------------------------------------------------
SECRET = re.compile(r"AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}"
                    r"|xox[baprs]-[A-Za-z0-9-]{10,}|sk-ant-[A-Za-z0-9-]{20,}"
                    r"|BEGIN [A-Z ]*PRIVATE KEY|://[^/\s'\"]+:[^@/\s'\"]+@")
for f in tracked:
    if not os.path.isfile(f): continue
    try: content = read(f)
    except Exception: continue
    for i, line in enumerate(content.splitlines(), 1):
        if SECRET.search(line): fail("A6", f"{f}:{i} looks like a secret/credential")

# ---- A7: packaging hygiene -------------------------------------------------------------------
JUNK = re.compile(r"(^|/)(node_modules/|\.DS_Store$|dist/|build/|\.env($|\.)|.*\.log$"
                  r"|\.vscode/|\.idea/|__pycache__/|\.venv/)")
for f in tracked:
    if JUNK.search(f): fail("A7", f"an artifact that should not ship is tracked: {f}")
gi = read(".gitignore") if os.path.exists(".gitignore") else ""
if not gi: fail("A7", ".gitignore missing")
for pattern in ("node_modules/", ".DS_Store", "*.log", "dist/", ".claude/settings.local.json", "config/team-config.md"):
    if pattern not in gi: warn("A7", f".gitignore does not cover '{pattern}'")

# ---- A5: placeholders — `<FILL: ...>` is the design in docs, a broken install in a manifest -----
for f in tracked:
    if f.endswith(".json") and os.path.isfile(f) and re.search(r"<FILL|<REVIEW>|<confirm", read(f)):
        fail("A5", f"{f}: placeholder in a manifest — it breaks the install")

# ---- Output -------------------------------------------------------------------------------
for w in warns: print("  ! " + w)
if fails:
    print(f"x check-readiness: {len(fails)} failure(s):")
    for f_ in fails: print("  - " + f_)
    sys.exit(1)
print(f"OK check-readiness: manifests, version ({sorted(distinct)[0] if distinct else '?'}), "
      f"{n_skills} skills, secrets and packaging" + (f" — {len(warns)} warning(s)" if warns else ""))
PY
