#!/usr/bin/env python3
"""Cost of the CURRENT issue — tokens, USD and hours — in the shape the `cost` skill writes onto it.

By default it measures **from this issue's baseline onwards**, not the whole session: `flow-gate.sh`
writes `baseline=<UTC>` into the repo flow state on every new issue, so two issues worked in the same
session do not land in the same bucket.

Usage:
    python3 session-cost.py [<session-id> | <path to .jsonl>]   # no arg: this repo's most recent session
    python3 session-cost.py --whole-session                     # ignore the baseline (the full session)
    python3 session-cost.py --since=2026-08-26T14:00:00Z        # explicit baseline
    python3 session-cost.py --no-usd                            # skip ccusage (offline/fast)
    python3 session-cost.py --selftest                          # checks for time, slicing and proration

Output: one JSON line. A `null` field means the number is unavailable — **do not invent it**: comment
on the issue and say so (`skills/cost/SKILL.md`). Tokens and hours come from the local transcript; the
USD comes from `ccusage` (the same source as `/usage`), prorated onto the issue's slice by the relative
price of its tokens.
"""
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# ponytail: a gap > 5 min between events is a human pause, not AI time. Tune if your team measures differently.
GAP_MAX = 300

# Relative price per token type (the same ratio holds across every Claude model: output 5x input,
# cache write 1.25x for 5 min and 2x for 1 h, cache read 0.1x). It only splits a model's USD between
# this issue's slice and the rest of the session — the dollar base still comes from ccusage.
WEIGHT = {"in": 1.0, "out": 5.0, "cache_w5m": 1.25, "cache_w1h": 2.0, "cache_r": 0.1}


def find_transcript(target=None):
    """The session transcript: explicit path, session id, or the most recent session for the cwd."""
    if target and target.endswith(".jsonl"):
        return Path(target)
    folder = Path.home() / ".claude" / "projects" / re.sub(r"[^A-Za-z0-9]", "-", str(Path.cwd()))
    if target:
        return folder / f"{target}.jsonl"
    files = sorted(folder.glob("*.jsonl"), key=lambda f: f.stat().st_mtime) if folder.is_dir() else []
    return files[-1] if files else None


def flow():
    """(issue, baseline UTC) from this repo's flow state — the baseline resets on every new issue."""
    try:
        gitdir = subprocess.run(["git", "rev-parse", "--absolute-git-dir"],
                                capture_output=True, text=True, timeout=10).stdout.strip()
        lines = (Path(gitdir) / "ferion-flow").read_text(encoding="utf-8").splitlines()
    except Exception:
        return None, None
    pick = lambda k: next((l.split("=", 1)[1] for l in reversed(lines) if l.startswith(k + "=")), None)
    return pick("task"), pick("baseline")


def moment(t):
    """ISO-8601 (or epoch) -> seconds. None when it cannot be read."""
    try:
        return float(t) if re.fullmatch(r"\d+(\.\d+)?", str(t)) else \
            datetime.fromisoformat(str(t).replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


def only_dict(v):
    """v when it is a dict, {} otherwise — keeps the transcript parsing free of type branches."""
    return v if isinstance(v, dict) else {}


def counts(usage):
    """One API call's tokens, split the way they are priced (5 min and 1 h cache writes differ)."""
    cache = only_dict(usage.get("cache_creation"))
    n = lambda d, k: d.get(k) or 0
    return {
        "in": n(usage, "input_tokens"),
        "out": n(usage, "output_tokens"),
        "cache_r": n(usage, "cache_read_input_tokens"),
        "cache_w5m": n(cache, "ephemeral_5m_input_tokens") or (0 if cache else n(usage, "cache_creation_input_tokens")),
        "cache_w1h": n(cache, "ephemeral_1h_input_tokens"),
    }


def events(transcript):
    """[(moment, model, tokens)] from the transcript; tokens=None on an event with no API usage."""
    out, seen = [], set()
    for line in transcript.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            ev = only_dict(json.loads(line))
        except json.JSONDecodeError:
            continue
        ts = moment(ev.get("timestamp"))
        if ts is None:
            continue
        msg = only_dict(ev.get("message"))
        usage = only_dict(msg.get("usage"))
        key = (msg.get("id"), ev.get("requestId"))
        if not usage or key in seen:       # no usage, or a request already counted (retry/replay)
            out.append((ts, None, None))
            continue
        seen.add(key)
        out.append((ts, msg.get("model"), counts(usage)))
    return out


def hours(evs, since=0):
    """(active hours, wall hours) for the slice — a long pause does not count as AI time."""
    marks = sorted(ts for ts, _, _ in evs if ts >= since)
    if len(marks) < 2:
        return None, None
    active = sum(min(b - a, GAP_MAX) for a, b in zip(marks, marks[1:]))
    return round(active / 3600, 2), round((marks[-1] - marks[0]) / 3600, 2)


def tokens(evs, since=0):
    """The slice's tokens, by type (in/out/cache)."""
    total = dict.fromkeys(WEIGHT, 0)
    for ts, _, tk in evs:
        if tk and ts >= since:
            for k in total:
                total[k] += tk[k]
    return total


def prorate(evs, since, costs):
    """The slice's USD: each model's cost enters in proportion to the relative price of its tokens."""
    weigh = lambda tk: sum(tk[k] * WEIGHT[k] for k in WEIGHT)
    total, sliced = {}, {}
    for ts, model, tk in evs:
        if not tk or model not in costs:
            continue
        total[model] = total.get(model, 0) + weigh(tk)
        if ts >= since:
            sliced[model] = sliced.get(model, 0) + weigh(tk)
    return round(sum(c * sliced.get(m, 0) / total[m] for m, c in costs.items() if total.get(m)), 4)


def baseline(argv):
    """(issue, baseline) in force: --since=<ISO> wins, --whole-session drops it, else the flow state."""
    explicit = next((a.split("=", 1)[1] for a in argv if a.startswith("--since=")), None)
    if explicit:
        return None, explicit
    return (None, None) if "--whole-session" in argv else flow()


def ccusage(session_id):
    """The ccusage entry for this session (tokens + USD per model), or None when unavailable."""
    try:
        out = subprocess.run(
            ["npx", "-y", "ccusage@latest", "session", "--json"],
            capture_output=True, text=True, timeout=180,
        ).stdout
        for s in json.loads(out).get("session", []):
            if s.get("period") == session_id:
                return s
    except Exception:
        pass
    return None


def selftest():
    import tempfile
    usage = lambda i, o, r, w: {"input_tokens": i, "output_tokens": o,
                                "cache_read_input_tokens": r, "cache_creation_input_tokens": w}
    lines = [
        {"timestamp": "2026-08-13T10:00:00.000Z", "message": {"model": "opus", "id": "m1", "usage": usage(10, 100, 0, 0)}},
        {"timestamp": "2026-08-13T10:01:00.000Z"},                                   # +1 active minute
        {"not-an-event-with-a-timestamp": True},                                     # ignored
        {"timestamp": "2026-08-13T11:01:00.000Z"},                                   # +60 min: counts 5 (GAP_MAX)
        {"timestamp": "2026-08-13T11:03:00.000Z", "requestId": "r2",                 # issue 2 starts here
         "message": {"model": "opus", "id": "m2", "usage": usage(10, 300, 0, 0)}},
        {"timestamp": "2026-08-13T11:03:30.000Z", "requestId": "r2",                 # replay: not counted twice
         "message": {"model": "opus", "id": "m2", "usage": usage(10, 300, 0, 0)}},
    ]
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        f.write("\n".join(json.dumps(x) for x in lines) + "\nbroken line\n")
        path = Path(f.name)
    evs = events(path)
    assert hours(evs) == (0.14, 1.06), hours(evs)              # 510 active seconds over 63.5 wall minutes
    cut = moment("2026-08-13T11:02:00Z")
    assert hours(evs, cut) == (0.01, 0.01), hours(evs, cut)    # issue 2 only: 30s, pause excluded
    assert tokens(evs)["out"] == 400 and tokens(evs, cut)["out"] == 300, tokens(evs)   # replay left out
    # weight: issue 1 = 10 + 100*5 = 510; issue 2 = 10 + 300*5 = 1510 -> 74.75% of USD 2.00
    close = lambda a, b: abs(a - b) < 1e-9
    assert close(prorate(evs, cut, {"opus": 2.0}), 1.495), prorate(evs, cut, {"opus": 2.0})
    assert close(prorate(evs, 0, {"opus": 2.0}), 2.0), "whole session = full cost, nothing prorated"
    assert prorate(evs, cut, {"other": 2.0}) == 0, "a model with no event costs nothing"
    empty = path.with_suffix(".empty.jsonl")
    empty.write_text("{}\n", encoding="utf-8")
    assert hours(events(empty)) == (None, None)
    path.unlink(); empty.unlink()
    print("OK session-cost: active time, wall time, issue slice, dedupe and USD proration")


def main(argv):
    if "--selftest" in argv:
        return selftest()
    target = next((a for a in argv if not a.startswith("--")), None)
    transcript = find_transcript(target)
    if not transcript or not transcript.exists():
        print(json.dumps({"error": "session transcript not found", "looked_for": str(transcript)}))
        return 1

    issue, base = baseline(argv)
    since = moment(base) if base else None
    if base and since is None:
        print(json.dumps({"error": f"invalid baseline: {base}"}))
        return 1

    evs = events(transcript)
    active, wall = hours(evs, since or 0)
    tk = tokens(evs, since or 0)
    usage = None if "--no-usd" in argv else ccusage(transcript.stem)
    costs = {b.get("modelName"): b.get("cost") or 0 for b in (usage or {}).get("modelBreakdowns") or []}
    print(json.dumps({
        "session": transcript.stem,
        "scope": "issue" if since else "session",
        "issue": issue,
        "since": base if since else None,
        "tokens": sum(tk.values()),
        "usd": prorate(evs, since or 0, costs) if costs else (usage and round(usage.get("totalCost", 0), 4)),
        "active_hours": active,
        "wall_hours": wall,
        "models": sorted({m for ts, m, t in evs if t and ts >= (since or 0)}),
        "token_detail": {"in": tk["in"], "out": tk["out"],
                         "cache_read": tk["cache_r"], "cache_write": tk["cache_w5m"] + tk["cache_w1h"]},
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]) or 0)
