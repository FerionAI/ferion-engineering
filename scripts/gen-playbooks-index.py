#!/usr/bin/env python3
"""Generate PLAYBOOKS.md — the index of every playbook (reference) per skill.
Generated from disk, so it can never go stale. Usage:
  python3 scripts/gen-playbooks-index.py           # (re)generate PLAYBOOKS.md
  python3 scripts/gen-playbooks-index.py --check   # fail if PLAYBOOKS.md is out of date (CI)
"""
import glob, os, sys, io

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

EXCLUDE = {"skills/constitution/references/constitution.md"}  # synced copy, not a playbook


def title_of(path):
    with open(path, encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if s.startswith("# "):
                return s[2:].strip()
    return os.path.basename(path)


refs = sorted(
    p for p in glob.glob("skills/*/references/**/*.md", recursive=True)
    + glob.glob("skills/*/references/**/*.html", recursive=True)
    if "/templates/" not in p and p not in EXCLUDE
)

by_skill = {}
for p in refs:
    by_skill.setdefault(p.split("/")[1], []).append(p)

out = io.StringIO()
out.write("# Playbook Index — ferion-engineering\n\n")
out.write("> **Generated automatically** by `scripts/gen-playbooks-index.py` — do not edit by hand.\n")
out.write("> Playbooks are the detail (`references/`) each skill loads on demand (progressive\n")
out.write("> disclosure, P8). The SKILL.md is the entry point; the \"how\" lives here.\n\n")
out.write(f"**{len(refs)} playbooks** across **{len(by_skill)}** skills.\n\n")
for skill in sorted(by_skill):
    items = sorted(by_skill[skill])
    out.write(f"## {skill} ({len(items)})\n\n")
    for p in items:
        rel = os.path.relpath(p, f"skills/{skill}")
        out.write(f"- [`{rel}`]({p}) — {title_of(p)}\n")
    out.write("\n")
content = out.getvalue()

if "--check" in sys.argv:
    cur = open("PLAYBOOKS.md", encoding="utf-8").read() if os.path.exists("PLAYBOOKS.md") else None
    if cur != content:
        print("x PLAYBOOKS.md is out of date — run: python3 scripts/gen-playbooks-index.py")
        sys.exit(1)
    print(f"OK PLAYBOOKS.md ({len(refs)} playbooks)")
else:
    open("PLAYBOOKS.md", "w", encoding="utf-8").write(content)
    print(f"PLAYBOOKS.md generated: {len(refs)} playbooks across {len(by_skill)} skills")
