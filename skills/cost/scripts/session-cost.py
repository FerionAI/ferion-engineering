#!/usr/bin/env python3
"""AI session cost — tokens, USD and hours — in the shape the `cost` skill writes onto the issue.

Usage:
    python3 session-cost.py [<session-id> | <path to .jsonl>]   # no arg: this repo's most recent session
    python3 session-cost.py --no-usd                            # skip ccusage (offline/fast)
    python3 session-cost.py --selftest                          # check the time calculation

Output: one JSON line. A `null` field means the number is unavailable — **do not invent it**:
comment on the issue and say so (`skills/cost/SKILL.md`). Tokens and USD come from `ccusage` (the
same source as `/usage`); the hours come from the local transcript timestamps.
"""
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# ponytail: a gap > 5 min between events is a human pause, not AI time. Tune if your team measures differently.
GAP_MAX = 300


def find_transcript(target=None):
    """The session transcript: explicit path, session id, or the most recent session for the cwd."""
    if target and target.endswith(".jsonl"):
        return Path(target)
    folder = Path.home() / ".claude" / "projects" / re.sub(r"[^A-Za-z0-9]", "-", str(Path.cwd()))
    if target:
        return folder / f"{target}.jsonl"
    files = sorted(folder.glob("*.jsonl"), key=lambda f: f.stat().st_mtime) if folder.is_dir() else []
    return files[-1] if files else None


def hours(transcript):
    """(active hours, wall hours) from the timestamps — a long pause does not count as AI time."""
    marks = []
    for line in transcript.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            t = json.loads(line).get("timestamp")
        except (json.JSONDecodeError, AttributeError):
            continue
        if t:
            marks.append(datetime.fromisoformat(t.replace("Z", "+00:00")).timestamp())
    if len(marks) < 2:
        return None, None
    marks.sort()
    active = sum(min(b - a, GAP_MAX) for a, b in zip(marks, marks[1:]))
    return round(active / 3600, 2), round((marks[-1] - marks[0]) / 3600, 2)


def ccusage(session_id):
    """The ccusage entry for this session (tokens + USD), or None when unavailable."""
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
    lines = [
        {"timestamp": "2026-08-13T10:00:00.000Z"},
        {"timestamp": "2026-08-13T10:01:00.000Z"},   # +1 min active
        {"not-an-event-with-a-timestamp": True},     # ignored
        {"timestamp": "2026-08-13T11:01:00.000Z"},   # +60 min pause -> counts only 5 (GAP_MAX)
        {"timestamp": "2026-08-13T11:03:00.000Z"},   # +2 min active
    ]
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        f.write("\n".join(json.dumps(x) for x in lines) + "\nbroken line\n")
        path = Path(f.name)
    active, wall = hours(path)
    assert active == round((60 + GAP_MAX + 120) / 3600, 2), active   # 8 active minutes, not 63
    assert wall == 1.05, wall                                        # 63 wall minutes
    assert hours(Path(path)) == (active, wall)
    empty = path.with_suffix(".empty.jsonl")
    empty.write_text("{}\n", encoding="utf-8")
    assert hours(empty) == (None, None)
    path.unlink(); empty.unlink()
    print("OK session-cost: active time, wall time and a transcript with no timestamps")


def main(argv):
    if "--selftest" in argv:
        return selftest()
    no_usd = "--no-usd" in argv
    target = next((a for a in argv if not a.startswith("--")), None)
    transcript = find_transcript(target)
    if not transcript or not transcript.exists():
        print(json.dumps({"error": "session transcript not found", "looked_for": str(transcript)}))
        return 1
    active, wall = hours(transcript)
    usage = None if no_usd else ccusage(transcript.stem)
    print(json.dumps({
        "session": transcript.stem,
        "tokens": usage and usage.get("totalTokens"),
        "usd": usage and round(usage.get("totalCost", 0), 4),
        "active_hours": active,
        "wall_hours": wall,
        "models": usage and usage.get("modelsUsed"),
        "token_detail": usage and {
            "in": usage.get("inputTokens"), "out": usage.get("outputTokens"),
            "cache_read": usage.get("cacheReadTokens"), "cache_write": usage.get("cacheCreationTokens"),
        },
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]) or 0)
