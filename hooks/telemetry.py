#!/usr/bin/env python3
"""Plugin usage telemetry, as a comment on an issue of the plugin's own repo — aggregated, visible,
and OFF unless the person opts in (ADR-0005).

Why opt-in: the target issue lives in a PUBLIC repository, and the comment goes out under the
sender's own GitHub account. Someone who installs an open-source plugin does not expect their usage
posted there. Nothing is sent until they say so.

What goes, once opted in: only aggregated numbers — per skill of this plugin (invocations, calls,
minutes, tokens), the flow milestones reached (spec → preflight → review → PR → cost → in review →
in QA: that is what shows where the flow leaks), the surface (CLI, VS Code, desktop), the plugin
version, and a repository name **only when it belongs to the plugin's own organization**. Never a
prompt, code, file path, command, branch, or another plugin's skill name.

When: at SessionStart, at most once a day, in the background (it does not delay the session or use
context), with the summary of the earlier sessions not sent yet. A resumed session sends only the new
part.

Usage:
    python3 telemetry.py                   # hook mode (SessionStart): sends only when opted in
    python3 telemetry.py --preview         # what WOULD be sent now, without sending (no opt-in needed)
    python3 telemetry.py --report[=YYYY-MM]   # aggregate what was sent in a month (default: this one)
    python3 telemetry.py --selftest        # checks, no network

Opt in:  touch ~/.claude/ferion-telemetry   (or FERION_TELEMETRY=1 in the environment)
Opt out: rm ~/.claude/ferion-telemetry      (FERION_TELEMETRY=0 wins over the file)
"""
import collections
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

MAX_DAYS = 30          # a session older than this never goes in a send

ROOT = Path(os.environ.get("CLAUDE_PLUGIN_ROOT") or Path(__file__).resolve().parents[1])
MANIFEST = json.loads((ROOT / ".claude-plugin/plugin.json").read_text(encoding="utf-8"))
PLUGIN = MANIFEST["name"]
VERSION = MANIFEST.get("version", "?")
REPO = MANIFEST["repository"].removeprefix("https://github.com/").removesuffix(".git")   # owner/repo
ORG = REPO.split("/")[0]
# "The plugin was active in this session" = the SessionStart banner is in the transcript. A session
# without it (another project, plugin disabled) is never read nor sent. Two forms, because a
# transcript may store non-ASCII escaped: looking for one form only would find "no session" silently.
MARK = (ROOT / "hooks/session-banner.md").read_text(encoding="utf-8").split("]", 1)[0] + "]"
MARKS = (MARK, json.dumps(MARK)[1:-1])

CLAUDE = Path.home() / ".claude"
OPT_IN = CLAUDE / "ferion-telemetry"
LEDGER = CLAUDE / "ferion-telemetry-ledger.json"
NOTE = "Opt out: `rm ~/.claude/ferion-telemetry`."

_SP = None
def sp():
    """The per-skill profiler (`skills/cost/scripts/skill-profile.py`), loaded only when needed:
    with telemetry off, the hook never pays for it."""
    global _SP
    if _SP is None:
        spec = importlib.util.spec_from_file_location("skill_profile", ROOT / "skills/cost/scripts/skill-profile.py")
        _SP = importlib.util.module_from_spec(spec); spec.loader.exec_module(_SP)
    return _SP


def opted_in():
    env = os.environ.get("FERION_TELEMETRY", "").lower()
    if env in ("0", "false", "off", "no"):
        return False
    return env in ("1", "true", "on", "yes") or OPT_IN.exists()


def ledger_read():
    try:
        led = json.loads(LEDGER.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        led = {}
    return {"day": led.get("day"), "sessions": led.get("sessions") or {}}


def candidates(projects, sent, current=None):
    """{transcript: cut} — sessions with the plugin active and an event newer than the last send."""
    out = {}
    limit = time.time() - MAX_DAYS * 86400
    for f in projects.glob("*/*.jsonl"):
        cut = sent.get(f.stem, 0)
        if f.stem == current or f.stat().st_mtime <= max(cut, limit):
            continue
        text = f.read_text(encoding="utf-8", errors="replace")
        if any(m in text for m in MARKS):
            out[f] = cut
    return out


LABELS = (("status:in-progress", "dev"), ("status:in-review", "in_review"), ("status:in-qa", "in_qa"))


def milestones_of(name, inp, skill):
    """Flow milestones read from what the tool was asked to do (not from what the agent said)."""
    text = json.dumps(inp, ensure_ascii=False)
    cmd = inp.get("command", "") if name == "Bash" else ""
    found = set()
    if name in ("Write", "Edit", "MultiEdit") and "/specs/" in str(inp.get("file_path", "")):
        found.add("spec")
    if (skill or "").endswith(":preflight") or "preflight.sh" in cmd:
        found.add("preflight")
    if re.search(r'flow-gate\.sh"? stamp review', cmd):
        found.add("review")
    if "gh pr create" in cmd or name.endswith(("create_pull_request", "pull_request_create")):
        found.add("pr")
    if "ferion:cost" in text:
        found.add("cost")
    # Only labels ADDED count: `--remove-label status:in-review --add-label status:in-qa` is in QA.
    added = ",".join(re.findall(r"--add-label[= ]+[\"']?([^\"'\s]+)", cmd)) if cmd else ""
    if name.endswith(("update_issue", "issues_update", "issue_write")):
        added = ",".join(map(str, inp.get("labels") or []))
    found |= {m for label, m in LABELS if label in added}
    if re.search(r'flow-gate\.sh"? stamp task( +#?\d+){2,}', cmd):
        found.add("group")                      # one PR for several linked issues
    return found


BLOCK = "BLOCKED by the mandatory flow:"


def blocked(text):
    """Which flow gate refused the call — the category only, never the message. None: not a gate."""
    if BLOCK not in text:
        return None
    title = text.split(BLOCK, 1)[1][:120]
    return next((m for pattern, m in ((r"\bspec", "blocked_spec"), (r"\bsession", "blocked_session"),
                                      (r"opening a PR", "blocked_pr"), (r"\bQA\b|in-qa", "blocked_qa"),
                                      (r"review", "blocked_review"))
                 if re.search(pattern, title)), "blocked_edit")


def raw_events(f):
    for line in f.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(ev, dict):
            yield ev


def tool_calls(ev):
    if ev.get("type") != "assistant":
        return []
    return [b for b in ((ev.get("message") or {}).get("content") or [])
            if isinstance(b, dict) and b.get("type") == "tool_use"]


def text_of(content):
    if isinstance(content, str):
        return content
    return " ".join(x.get("text", "") for x in content or [] if isinstance(x, dict))


def failures(ev):
    """(call id, gate that refused it or None) for each tool_result with an error in a user event."""
    if ev.get("type") != "user":
        return []
    return [(b.get("tool_use_id"), blocked(text_of(b.get("content"))))
            for b in (ev.get("message") or {}).get("content") or []
            if isinstance(b, dict) and b.get("type") == "tool_result" and b.get("is_error")]


def signals(f, cut):
    """(active hours, surfaces, cwds, milestones, last moment) of the part of a session after the cut.

    A milestone counts only when its call succeeded: one refused by a gate (or failed) comes back with
    is_error and becomes `blocked_*`, not `pr`/`in_review`. A call with no result (a session cut
    short) counts as done.
    """
    moments, surf, cwds, blocks = [], set(), set(), set()
    calls, errors = [], set()
    for ev in raw_events(f):
        ts = sp().moment(ev.get("timestamp"))
        if ts is None or ts <= cut:
            continue
        moments.append(ts)
        surf.update(filter(None, [ev.get("entrypoint")]))
        cwds.update(filter(None, [ev.get("cwd")]))
        calls += [(b.get("id"), milestones_of(b.get("name", ""), b.get("input") or {}, ev.get("attributionSkill")))
                  for b in tool_calls(ev)]
        for id_, gate in failures(ev):
            errors.add(id_)
            blocks.update(filter(None, [gate]))
    flow = set().union(*[m for id_, m in calls if id_ not in errors]) | blocks
    moments.sort()
    active = sum(min(b - a, sp().GAP_MAX) for a, b in zip(moments, moments[1:])) / 3600
    return active, surf, cwds, flow, (moments[-1] if moments else cut)


_repos = {}
def repo_in_org(cwd):
    """A repository's name only when its remote belongs to the plugin's org — anything else never leaves."""
    if cwd not in _repos:
        try:
            url = subprocess.run(["git", "-C", cwd, "remote", "get-url", "origin"],
                                 capture_output=True, text=True, timeout=5).stdout.strip()
        except (OSError, subprocess.SubprocessError):
            url = ""
        _repos[cwd] = url.rsplit("/", 1)[-1].removesuffix(".git") if f"{ORG}/" in url else None
    return _repos[cwd]


def summary(cands):
    """(payload, {session: last moment}) — the line for the issue and what to mark as sent."""
    hours, surf, repos, flow, until = 0.0, collections.Counter(), collections.Counter(), collections.Counter(), {}
    active = 0
    for f, cut in cands.items():
        h, s, cwds, m, last = signals(f, cut)
        active += last > cut                     # a candidate with no new event is not a session of this send
        hours += h
        surf.update(s)
        repos.update({r for r in map(repo_in_org, cwds) if r})
        flow.update(m)
        until[f.stem] = last
    runs, tot = sp().profile(list(cands), since=cands)
    skills = {}
    for sk, v in runs.items():
        key = sk if sk.startswith(PLUGIN + ":") else "(other)"   # another plugin's skill never leaves by name
        a = skills.setdefault(key, [0, 0, 0.0, 0.0])
        for r in v:
            a[0] += 1; a[1] += r["req"]; a[2] += r["sec"] / 60; a[3] += r["w"] / 1e6
    payload = {
        "v": 1, "plugin": VERSION, "sessions": active, "hours": round(hours, 2),
        "calls": tot["req"], "context_k": tot["median_context"] // 1000,
        "thinking_pct": round(100 * tot["think"] / max(tot["out"], 1)),
        "surface": dict(surf), "repos": dict(repos), "flow": dict(flow),
        "skills": {k: [a[0], a[1], round(a[2], 1), round(a[3], 2)] for k, a in skills.items()},
    }
    return payload, until


def gh(*args):
    r = subprocess.run(["gh", *args], capture_output=True, text=True, timeout=60)
    if r.returncode:
        raise RuntimeError(r.stderr.strip())
    return r.stdout.strip()


def title(month=None):
    return f"[telemetry] {month or datetime.now(timezone.utc).strftime('%Y-%m')}"


def issues_of_month(t):
    """Numbers of the issues with this exact title. List and filter here instead of GitHub search:
    search tokenizes `[telemetry]` and sometimes misses — and a miss would open a new issue every day."""
    out = gh("issue", "list", "-R", REPO, "--state", "all", "--limit", "100", "--json", "number,title")
    return [i["number"] for i in json.loads(out or "[]") if i["title"] == t]


def send(payload):
    t = title()
    numbers = issues_of_month(t)
    if not numbers:   # the month's first sender opens it; a race makes a duplicate, and the report reads all
        url = gh("issue", "create", "-R", REPO, "--title", t, "--body",
                 "Aggregated plugin usage from people who opted in — one comment per person per day, sent "
                 "by the SessionStart hook (`hooks/telemetry.py`). Numbers only: this plugin's skills, calls, "
                 "minutes, tokens, flow milestones, surface and version. No prompt, code, path or command.\n\n"
                 f"Report: `python3 hooks/telemetry.py --report`. {NOTE}")
        numbers = [int(url.rstrip("/").rsplit("/", 1)[-1])]
    gh("issue", "comment", str(numbers[0]), "-R", REPO, "--body",
       f"Aggregated plugin usage (opted in). {NOTE}\n\n```json\n{json.dumps(payload, ensure_ascii=False)}\n```")


def send_pending(current):
    led = ledger_read()
    cands = candidates(CLAUDE / "projects", led["sessions"], current)
    if not cands:
        return
    payload, until = summary(cands)
    send(payload)                         # failed = nothing marked; it tries again next session
    led["sessions"].update(until)
    led["day"] = datetime.now().strftime("%Y-%m-%d")
    LEDGER.write_text(json.dumps(led), encoding="utf-8")


def has_pending(projects, sent, current=None):
    """stat only: is there a transcript with a new event? The real filter (banner, cut) runs in the child."""
    return any(f.stem != current and f.stat().st_mtime > sent.get(f.stem, 0)
               for f in projects.glob("*/*.jsonl"))


def claim_the_day():
    """Only one session a day gets past here: O_EXCL is atomic, a "sent today?" read of the ledger is
    not — two sessions opened in the same second would send the same thing twice."""
    today = datetime.now().strftime("%Y-%m-%d")
    for old in CLAUDE.glob("ferion-telemetry.*.lock"):
        if today not in old.name:
            old.unlink(missing_ok=True)
    try:
        os.close(os.open(CLAUDE / f"ferion-telemetry.{today}.lock", os.O_CREAT | os.O_EXCL | os.O_WRONLY))
        return True
    except FileExistsError:
        return False


def hook():
    if not opted_in():
        return            # the default: nothing read, nothing sent, nothing printed
    current = None
    if not sys.stdin.isatty():          # the hook passes the session JSON; by hand, do not wait for EOF
        try:
            current = json.loads(sys.stdin.read() or "{}").get("session_id")
        except ValueError:
            current = None
    led = ledger_read()
    if not shutil.which("gh") or led.get("day") == datetime.now().strftime("%Y-%m-%d"):
        return
    if not has_pending(CLAUDE / "projects", led["sessions"], current):
        return
    if not hasattr(os, "fork"):
        return   # ponytail: no fork (Windows) = no send; a detached subprocess if Windows users opt in
    if not claim_the_day():
        return   # another session opened alongside is already sending today's
    print(f"[Telemetry] you opted in: sending the aggregated usage of earlier sessions (skills, calls, "
          f"minutes — no code, no prompt) to a public issue in `{REPO}`, in the background. {NOTE}")
    sys.stdout.flush()
    if os.fork():
        return
    os.setsid()
    null = os.open(os.devnull, os.O_RDWR)
    for fd in (0, 1, 2):
        os.dup2(null, fd)
    try:
        send_pending(current)
    except Exception:
        pass            # telemetry never breaks nor pollutes anyone's session
    os._exit(0)


# --- Reading: what was sent ---------------------------------------------------------------------
def payload_of(body):
    """The payload inside the ```json block of a comment, or None when the comment is something else."""
    if "```json" not in (body or ""):
        return None
    try:
        return json.loads(body.split("```json", 1)[1].split("```", 1)[0])
    except ValueError:
        return None


def aggregate(sends):
    """sends = [(author, payload)] -> totals. Per person, only the count — measure, never rank."""
    t = collections.Counter()
    surf, flow, version = collections.Counter(), collections.Counter(), {}
    skills = collections.defaultdict(lambda: [0, 0, 0.0, 0.0])
    for author, p in sends:
        t["sessions"] += p["sessions"]; t["hours"] += p["hours"]; t["calls"] += p["calls"]
        surf.update(p["surface"]); flow.update(p["flow"])
        version[author] = p["plugin"]
        for k, v in p["skills"].items():
            skills[k] = [a + b for a, b in zip(skills[k], v)]
    return {"people": len(version), **t, "surface": surf, "flow": flow,
            "versions": collections.Counter(version.values()), "skills": dict(skills)}


def report(month):
    sends = []
    for n in issues_of_month(title(month)):
        out = gh("api", "--paginate", f"repos/{REPO}/issues/{n}/comments",
                 "-q", ".[] | {author: .user.login, body: .body}")
        for line in out.splitlines():
            c = json.loads(line)
            p = payload_of(c["body"])
            if p and p.get("v") == 1:
                sends.append((c["author"], p))
    sends = list({(a, json.dumps(p, sort_keys=True)): (a, p) for a, p in sends}.values())   # repeats out
    if not sends:
        print(f"{title(month)}: nothing sent yet.")
        return
    a = aggregate(sends)
    fmt = lambda c: " · ".join(f"{k} {v}" for k, v in c.most_common())
    print(f"{title(month)} — {a['people']} person(s), {a['sessions']} sessions, {a['hours']:.0f}h, {a['calls']} calls")
    print(f"surface: {fmt(a['surface'])}\nversions (people): {fmt(a['versions'])}")
    print("funnel (sessions): " + " → ".join(f"{m} {a['flow'].get(m, 0)}" for m in
                                             ("spec", "preflight", "review", "pr", "cost", "in_review", "in_qa")))
    extra = {k: v for k, v in a["flow"].items() if k in ("dev", "group") or k.startswith("blocked_")}
    if extra:
        print("dev, groups and blocks (sessions): " + " · ".join(f"{k} {v}" for k, v in sorted(extra.items())))
    total = sum(v[2] for v in a["skills"].values()) or 1
    print(f"\n{'skill':32} {'invoc':>6} {'calls/inv':>10} {'min/inv':>8} {'% time':>7}")
    for k, (inv, calls, mins, _) in sorted(a["skills"].items(), key=lambda kv: -kv[1][2]):
        print(f"{k[:32]:32} {inv:6d} {calls / max(inv, 1):10.0f} {mins / max(inv, 1):8.1f} {100 * mins / total:6.0f}%")


def selftest():
    import tempfile
    global CLAUDE, OPT_IN
    T0, T1, T2 = "2026-09-22T10:00:00Z", "2026-09-22T10:01:00Z", "2026-09-22T10:02:00Z"
    HOME_REPO = str(Path.home() / "personal-project")     # a cwd outside the org: its name must not leave
    tmp = Path(tempfile.mkdtemp())
    proj = tmp / "projects" / "-repo"
    proj.mkdir(parents=True)
    ev = lambda ts, **k: json.dumps({"timestamp": ts, **k}, ensure_ascii=False)
    usage = {"input_tokens": 1, "output_tokens": 10, "cache_read_input_tokens": 100}
    tool = lambda name, inp: {"type": "tool_use", "name": name, "input": inp}
    (proj / "s1.jsonl").write_text("\n".join([
        ev(T0, type="attachment", attachment={"content": MARK + " banner"}),
        ev(T1, type="assistant", entrypoint="cli", cwd=HOME_REPO, attributionSkill=f"{PLUGIN}:preflight",
           message={"usage": usage, "content": [tool("Bash", {"command": "bash x/preflight.sh"}),
                                                tool("Write", {"file_path": "/r/specs/001/spec.md"})]}),
        ev(T2, type="assistant", entrypoint="cli", attributionSkill="other:skill",
           message={"usage": usage, "content": [tool("Bash", {"command": "gh issue comment 12 --body '<!-- ferion:cost tokens=1 -->'"})]}),
    ]), encoding="utf-8")
    (proj / "s2.jsonl").write_text(ev(T0, type="user"), encoding="utf-8")            # no banner: out
    (proj / "s3.jsonl").write_text(ev(T0, type="user", x=MARK), encoding="utf-8")   # the current session: out
    (proj / "s4.jsonl").write_text(json.dumps({"timestamp": T0, "type": "user", "x": MARK}), encoding="utf-8")

    checks, failed = [], []
    def t(label, cond):        # a label, not an index: CI has to say WHAT broke
        checks.append(label)
        if not cond:
            failed.append(label)
        return cond

    home, opt = CLAUDE, OPT_IN
    CLAUDE, OPT_IN = tmp, tmp / "ferion-telemetry"
    env = os.environ.pop("FERION_TELEMETRY", None)
    t("off by default", not opted_in())
    hook()
    t("off = the hook touches nothing", not list(tmp.glob("ferion-telemetry*")))
    OPT_IN.touch()
    t("the opt-in file turns it on", opted_in())
    os.environ["FERION_TELEMETRY"] = "0"
    t("FERION_TELEMETRY=0 wins over the file", not opted_in())
    os.environ.pop("FERION_TELEMETRY")
    if env is not None:
        os.environ["FERION_TELEMETRY"] = env
    t("one session a day sends (no duplicate)", claim_the_day() and not claim_the_day())
    CLAUDE, OPT_IN = home, opt

    cands = candidates(tmp / "projects", {}, current="s3")
    if t("scope: only sessions with the banner, never the current one", {c.stem for c in cands} == {"s1", "s4"}):
        p, until = summary(cands)
        t("flow milestones", p["flow"] == {"preflight": 1, "spec": 1, "cost": 1})
        t("another plugin's skill becomes (other)", set(p["skills"]) == {f"{PLUGIN}:preflight", "(other)"})
        t("privacy: no path, no repo outside the org",
          p["repos"] == {} and HOME_REPO not in json.dumps(p) and "/r/specs" not in json.dumps(p))
        t("surface and calls", p["surface"] == {"cli": 1} and p["calls"] == 2)
        t("pending ignores the current session", has_pending(tmp / "projects", {}, current="s3"))
        t("nothing pending once everything was sent",
          not has_pending(tmp / "projects", {f.stem: 9e9 for f in proj.glob("*.jsonl")}))
        t("a resumed session sends only the new part", summary({proj / "s1.jsonl": until["s1"]})[0]["calls"] == 0)
        t("a session with no new event is not counted again",
          summary({proj / "s1.jsonl": until["s1"]})[0]["sessions"] == 0)
        t("reading a comment", payload_of(f"text\n```json\n{json.dumps(p)}\n```") == p)
        a = aggregate([("x", p), ("y", p), ("x", p)])
        t("aggregation per person", a["people"] == 2 and a["sessions"] == 3 * p["sessions"]
          and a["skills"][f"{PLUGIN}:preflight"][0] == 3)

    # A milestone only from a call that succeeded; labels count only when added
    use = lambda id_, name, inp: {"type": "tool_use", "id": id_, "name": name, "input": inp}
    back = lambda id_, text, err: ev(T2, type="user", message={"content": [
        {"type": "tool_result", "tool_use_id": id_, "is_error": err, "content": text}]})
    s5 = proj / "s5.jsonl"
    s5.write_text("\n".join([
        ev(T1, type="assistant", message={"content": [use("u1", "Bash", {"command": "gh pr create --fill"})]}),
        back("u1", "BLOCKED by the mandatory flow: opening a PR without closing the local review.", True),
        ev(T1, type="assistant", message={"content": [
            use("u2", "Bash", {"command": "gh issue edit 1 --add-assignee @me --add-label status:in-progress"}),
            use("u3", "Bash", {"command": "bash /p/hooks/flow-gate.sh stamp task 1 5"})]}),
        back("u2", "ok", False),
        ev(T2, type="assistant", message={"content": [
            use("u4", "Bash", {"command": "gh issue edit 1 --remove-label status:in-review --add-label status:in-qa"})]}),
    ]), encoding="utf-8")
    m5 = signals(s5, 0)[3]
    t("a gate refusal becomes blocked_*, not the milestone", "blocked_pr" in m5 and "pr" not in m5)
    t("labels count only when added", {"dev", "in_qa"} <= m5 and "in_review" not in m5)
    t("stamp task with 2+ issues = group", "group" in m5)
    shutil.rmtree(tmp)
    if failed:
        print(f"x telemetry: {len(failed)} of {len(checks)} checks failed:")
        for f_ in failed:
            print("  -", f_)
        return 1
    print(f"OK telemetry: {len(checks)} checks (opt-in, scope, privacy, milestones, cut, reading)")
    return 0


def main(argv):
    if "--selftest" in argv:
        return selftest()
    if "--preview" in argv:
        print(f"telemetry is {'ON (opted in)' if opted_in() else 'OFF — opt in: touch ~/.claude/ferion-telemetry'}")
        cands = candidates(CLAUDE / "projects", ledger_read()["sessions"])
        print(json.dumps(summary(cands)[0], ensure_ascii=False, indent=2) if cands else "nothing pending")
        return 0
    rep = next((a for a in argv if a.startswith("--report")), None)
    if rep:
        report(rep.split("=", 1)[1] if "=" in rep else None)
        return 0
    hook()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
