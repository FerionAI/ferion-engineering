#!/usr/bin/env python3
"""Where the plugin's cost lives — calls, minutes and tokens per skill — read from the local transcripts.

`session-cost.py` answers "how much did this issue cost". This one answers "where does the cost live":
which skill spends the round trips, how much of the time is generation and how much is tools, and how
much of the tokens is only context re-reading. It is the number that says **what to optimize** (P8 —
measure to improve, never to punish; ADR-0004).

Usage:
    python3 skill-profile.py                 # sessions of this repository
    python3 skill-profile.py --all           # every project under ~/.claude/projects
    python3 skill-profile.py <folder> [...]  # specific transcript folders
    python3 skill-profile.py --selftest      # checks, no repo and no network

Attribution: only the requests the harness tagged with `attributionSkill` (an honest floor). Work that
continues after the skill shows up as unattributed instead of inflating the last skill invoked.
"""
import collections
import importlib.util
import json
import re
import statistics
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location("session_cost", Path(__file__).with_name("session-cost.py"))
_sc = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(_sc)
moment, WEIGHT, GAP_MAX = _sc.moment, _sc.WEIGHT, _sc.GAP_MAX

PROJECTS = Path.home() / ".claude" / "projects"


def folders(argv):
    """The transcript folders to read: --all, explicit paths, or this repository's."""
    if "--all" in argv:
        return sorted(p for p in PROJECTS.glob("*") if p.is_dir())
    given = [Path(a) for a in argv if not a.startswith("--")]
    return given or [PROJECTS / re.sub(r"[^A-Za-z0-9]", "-", str(Path.cwd()))]


def events(path):
    """[(moment, skill|None, usage|None, n_tools, text_chars)] in chronological order."""
    out = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        ts = moment(ev.get("timestamp")) if isinstance(ev, dict) else None
        if ts is None:
            continue
        if ev.get("type") != "assistant":
            out.append((ts, None, None, 0, 0))
            continue
        msg = ev.get("message") or {}
        blocks = msg.get("content") or []
        tools = sum(1 for b in blocks if isinstance(b, dict) and b.get("type") == "tool_use")
        chars = sum(len(b.get("text", "")) for b in blocks if isinstance(b, dict) and b.get("type") == "text")
        out.append((ts, ev.get("attributionSkill"), msg.get("usage") or None, tools, chars))
    return sorted(out, key=lambda e: e[0])


def weighted(u):
    """One request's tokens at price weight (cache read is 10x cheaper than input)."""
    c = u.get("cache_creation") or {}
    n = lambda d, k: d.get(k) or 0
    return (WEIGHT["in"] * n(u, "input_tokens") + WEIGHT["out"] * n(u, "output_tokens")
            + WEIGHT["cache_r"] * n(u, "cache_read_input_tokens")
            + WEIGHT["cache_w5m"] * (n(c, "ephemeral_5m_input_tokens") or (0 if c else n(u, "cache_creation_input_tokens")))
            + WEIGHT["cache_w1h"] * n(c, "ephemeral_1h_input_tokens"))


def add_totals(evs, tot, context):
    """Totals for the whole session, attributed to a skill or not."""
    for _, _, usage, _, chars in evs:
        tot["chars"] += chars
        if not usage:
            continue
        tot["req"] += 1
        tot["cache_r"] += usage.get("cache_read_input_tokens") or 0
        tot["out"] += usage.get("output_tokens") or 0
        tot["think"] += (usage.get("output_tokens_details") or {}).get("thinking_tokens") or 0
        context.append((usage.get("input_tokens") or 0) + (usage.get("cache_read_input_tokens") or 0)
                       + (usage.get("cache_creation_input_tokens") or 0))


def runs_of(evs):
    """[(skill, Counter)] — each contiguous run of requests attributed to the same skill.

    An unattributed event in the middle neither breaks the run nor joins it: it does not inflate the skill.
    """
    out, current = [], None
    for i, (ts, skill, usage, tools, chars) in enumerate(evs):
        if not skill:
            continue
        if skill != current:
            current = skill
            out.append((skill, collections.Counter()))
        acc = out[-1][1]
        acc["req"] += 1 if usage else 0
        acc["w"] += weighted(usage) if usage else 0
        acc["sec"] += min(evs[i + 1][0] - ts, GAP_MAX) if i + 1 < len(evs) else 0
        acc["tools"] += tools
        acc["chars"] += chars
    return [(s, a) for s, a in out if a["req"]]


def profile(files, since=None):
    """(per skill, totals). An 'invocation' is a contiguous run of requests of the same skill.

    `since` ({file: epoch}) cuts each session from a point on — for a caller that only wants the part
    of a resumed session it has not seen yet.
    """
    runs = collections.defaultdict(list)
    tot = collections.Counter()
    context = []
    for f in files:
        cut = (since or {}).get(f, 0)
        evs = [e for e in events(f) if e[0] > cut]
        add_totals(evs, tot, context)
        for skill, acc in runs_of(evs):
            runs[skill].append(acc)
    tot["median_context"] = int(statistics.median(context)) if context else 0
    return runs, tot


def show(runs, tot):
    med = lambda v: statistics.median(v) if v else 0
    total_min = sum(r["sec"] for v in runs.values() for r in v) / 60 or 1
    print(f"{'skill':32} {'invoc':>5} {'calls':>6} {'min':>7} {'Mtok*':>7} {'chars':>7} {'% time':>7}")
    for sk, v in sorted(runs.items(), key=lambda kv: -sum(r["sec"] for r in kv[1])):
        spent = sum(r["sec"] for r in v) / 60
        print(f"{sk[:32]:32} {len(v):5d} {med([r['req'] for r in v]):6.0f} "
              f"{med([r['sec'] for r in v]) / 60:7.1f} {med([r['w'] for r in v]) / 1e6:7.2f} "
              f"{med([r['chars'] for r in v]):7.0f} {100 * spent / total_min:6.0f}%")
    if not tot["req"]:
        return
    print(f"\n* price-weighted Mtok per invocation (median). Attributed: {total_min / 60:.1f}h over "
          f"{sum(len(v) for v in runs.values())} invocation(s).")
    print(f"All sessions: {tot['req']} calls · median context {tot['median_context'] / 1000:.0f}k tokens "
          f"· context re-reads {100 * tot['cache_r'] / max(tot['cache_r'] + tot['out'], 1):.0f}% of tokens "
          f"· thinking {100 * tot['think'] / max(tot['out'], 1):.0f}% of output "
          f"· prose ~{tot['chars'] // 4 / 1000:.0f}k tokens")
    print("Read it as: spend is ~(calls x context). Cut a call before cutting a word (P8).")


def selftest():
    import tempfile
    usage = lambda r: {"input_tokens": 1, "output_tokens": 10, "cache_read_input_tokens": r,
                       "output_tokens_details": {"thinking_tokens": 4}}
    lines = [
        {"timestamp": "2026-09-22T10:00:00Z", "type": "assistant", "attributionSkill": "a",
         "message": {"usage": usage(1000), "content": [{"type": "text", "text": "hi"},
                                                       {"type": "tool_use", "name": "Bash"}]}},
        {"timestamp": "2026-09-22T10:00:30Z", "type": "assistant", "attributionSkill": "a",
         "message": {"usage": usage(2000), "content": []}},
        {"timestamp": "2026-09-22T10:01:00Z", "type": "assistant",  # no skill: does not inflate the previous one
         "message": {"usage": usage(3000), "content": []}},
        {"timestamp": "2026-09-22T10:02:00Z", "type": "assistant", "attributionSkill": "b",
         "message": {"usage": usage(4000), "content": []}},
    ]
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        f.write("\n".join(json.dumps(x) for x in lines) + "\nbroken\n")
        path = Path(f.name)
    runs, tot = profile([path])
    assert set(runs) == {"a", "b"}, runs
    assert len(runs["a"]) == 1 and runs["a"][0]["req"] == 2, runs["a"]     # a contiguous run = 1 invocation
    assert runs["a"][0]["tools"] == 1 and runs["a"][0]["chars"] == 2
    assert tot["req"] == 4 and tot["think"] == 16
    assert tot["median_context"] == 2501, tot["median_context"]          # median of 1001, 2001, 3001, 4001
    runs, tot = profile([path], since={path: moment("2026-09-22T10:01:30Z")})
    assert set(runs) == {"b"} and tot["req"] == 1, (runs, tot)           # the cut drops what came before
    path.unlink()
    print("OK skill-profile: attribution per run, no inflating the previous skill, totals and cut")


def main(argv):
    if "--help" in argv or "-h" in argv:
        print(__doc__)
        return 0
    if "--selftest" in argv:
        return selftest()
    files = [f for p in folders(argv) if p.is_dir() for f in sorted(p.glob("*.jsonl"))]
    if not files:
        print("no transcript found (run with --all or pass the folder)")
        return 1
    runs, tot = profile(files)
    print(f"{len(files)} session(s)")
    show(runs, tot)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]) or 0)
