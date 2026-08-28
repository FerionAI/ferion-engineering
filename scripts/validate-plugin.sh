#!/usr/bin/env sh
# Validate the plugin end to end before merge or installation.
# Runs in CI (.github/workflows/validate.yml) and locally. Non-zero exit on any failure.
# Covers the class of bugs that breaks an install: JSON, YAML frontmatter, refs, sync, version.
set -e
cd "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

python3 - <<'PY'
import json, glob, os, re, sys
try:
    import yaml
except ImportError:
    print("ERROR: pyyaml missing — pip install pyyaml"); sys.exit(2)

errors = []
def err(m): errors.append(m)

# 1) Manifest JSON
for j in [".claude-plugin/plugin.json", ".claude-plugin/marketplace.json", "hooks/hooks.json", ".mcp.json"]:
    if not os.path.exists(j):
        err(f"missing manifest: {j}"); continue
    try:
        json.load(open(j, encoding="utf-8"))
    except Exception as e:
        err(f"invalid JSON {j}: {e}")

# 2) Skill frontmatter: valid YAML + name == folder + description present
skills = sorted(glob.glob("skills/*/SKILL.md"))
for f in skills:
    folder = os.path.basename(os.path.dirname(f))
    t = open(f, encoding="utf-8").read()
    if not t.startswith("---"):
        err(f"{f}: no frontmatter"); continue
    end = t.find("\n---", 3)
    if end < 0:
        err(f"{f}: unterminated frontmatter"); continue
    try:
        d = yaml.safe_load(t[3:end])
    except Exception as e:
        err(f"{f}: invalid YAML frontmatter: {str(e).splitlines()[0]}"); continue
    if not isinstance(d, dict) or not d.get("name") or not d.get("description"):
        err(f"{f}: frontmatter missing name/description"); continue
    if d["name"] != folder:
        err(f"{f}: name '{d['name']}' != folder '{folder}'")

# 3) Refs: every cited reference exists (local and cross-skill) + no orphan reference
skill_names = sorted({os.path.basename(os.path.dirname(f)) for f in skills}, key=len, reverse=True)
cross_re = re.compile(r'(?<![\w./-])(' + '|'.join(re.escape(n) for n in skill_names) + r')/references/[A-Za-z0-9_./-]+\.(?:md|html)')
for f in skills:
    dirp = os.path.dirname(f); t = open(f, encoding="utf-8").read()
    for m in cross_re.finditer(t):
        if not os.path.exists(os.path.join("skills", m.group(0))):
            err(f"{f}: broken cross-skill ref -> skills/{m.group(0)}")
    for r in set(re.findall(r'(?<![\w./-])references/[A-Za-z0-9_./-]+\.(?:md|html)', t)):
        if not os.path.exists(os.path.join(dirp, r)):
            err(f"{f}: broken local ref -> {r}")
for f in skills:
    dirp = os.path.dirname(f); refdir = os.path.join(dirp, "references")
    if not os.path.isdir(refdir):
        continue
    skilltext = open(f, encoding="utf-8").read()
    for ext in ("*.md", "*.html"):
        for ref in glob.glob(os.path.join(refdir, "**", ext), recursive=True):
            rel = os.path.relpath(ref, dirp).replace(os.sep, "/")
            if rel not in skilltext:
                err(f"{f}: orphan reference (never cited) -> {rel}")

# 4) Constitution: copies identical + stamped version == plugin version
src = "memory/constitution.md"
cop = "skills/constitution/references/constitution.md"
if os.path.exists(src) and os.path.exists(cop):
    ct = open(src, encoding="utf-8").read()
    if ct != open(cop, encoding="utf-8").read():
        err("constitution: source != copy (run scripts/check-constitution-sync.sh)")
    m = re.search(r'\*\*Version:\*\*\s*([0-9]+\.[0-9]+\.[0-9]+)', ct)
    pv = json.load(open(".claude-plugin/plugin.json", encoding="utf-8")).get("version")
    if m and pv and m.group(1) != pv:
        err(f"broken invariant: constitution stamp {m.group(1)} != plugin.json {pv}")

# 5) plugin.json == marketplace.json (versions agree)
try:
    pv = json.load(open(".claude-plugin/plugin.json", encoding="utf-8")).get("version")
    mk = json.load(open(".claude-plugin/marketplace.json", encoding="utf-8"))
    mv = (mk.get("metadata") or {}).get("version")
    pmv = mk.get("plugins", [{}])[0].get("version")
    for label, v in (("metadata.version", mv), ("plugins[0].version", pmv)):
        if v and pv and v != pv:
            err(f"marketplace {label} {v} != plugin.json {pv}")
except Exception as e:
    err(f"failed comparing plugin/marketplace versions: {e}")

# 6) The team config template ships, the real one never does.
if not os.path.exists("config/team-config.example.md"):
    err("missing config/team-config.example.md")
if os.path.exists("config/team-config.md"):
    err("config/team-config.md is committed — that file is per-team and git-ignored on purpose")

if errors:
    print(f"x validate-plugin: {len(errors)} error(s):")
    for e in errors:
        print("  -", e)
    sys.exit(1)
print(f"OK validate-plugin: {len(skills)} skills, manifests, refs and constitution")
PY

# Playbook index (PLAYBOOKS.md) up to date (auto-generated — never edited by hand)
if command -v python3 >/dev/null 2>&1; then
  python3 scripts/gen-playbooks-index.py --check || { echo "PLAYBOOKS.md out of date"; exit 1; }
fi

# Nothing company-specific leaks into the public repo
sh scripts/check-leaks.sh --selftest || exit 1
sh scripts/check-leaks.sh || exit 1

# The hook that blocks AI signatures on commits/PRs (P3) still works
sh hooks/no-ai-signature.test.sh || exit 1

# The mandatory-flow gates (issue -> in progress -> local review -> PR + cost -> in review):
# no hole, no false block
sh hooks/flow-gate.test.sh || exit 1

# The session cost calculation the `cost` skill writes back to the issue
python3 skills/cost/scripts/session-cost.py --selftest || exit 1
bash skills/preflight/scripts/pr-bots.sh --selftest || exit 1

# claude plugin validate (marketplace) — only if the CLI exists (optional in CI)
if command -v claude >/dev/null 2>&1; then
  echo "-> claude plugin validate ."
  claude plugin validate . || { echo "claude plugin validate FAILED"; exit 1; }
else
  echo "-> claude CLI not found; skipping 'claude plugin validate' (fine in CI)"
fi
echo "ALL GREEN"
