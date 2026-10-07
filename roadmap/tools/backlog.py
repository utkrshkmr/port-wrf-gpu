#!/usr/bin/env python3
"""Read and update the task cards of roadmap/BACKLOG.md (format: roadmap/TASK_PROTOCOL.md section 3).

  backlog.py check                      validate every card (fields, sizes, needs, dependencies, cycles)
  backlog.py list [--track A] [--area book] [--status todo]
  backlog.py next [--env cpu,net] [--area book]
                                        cards whose dependencies are done, runnable with these needs (and area)
  backlog.py show <ID>
  backlog.py set <ID> <status> [sha]    status: todo | doing | done <sha> | blocked <reason> | split
  backlog.py stats                      cards per track, size and status
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BACKLOG = os.path.join(os.path.dirname(HERE), "BACKLOG.md")

SIZES = {"S", "M"}
NEEDS = {"cpu", "net", "gpu-nv", "gpu-amd", "data", "ccr", "owner"}
FIELDS = ("Read", "Do", "Output", "Done when")
HEAD = re.compile(r"^### ([A-Z]+-\d+[a-z]?) · (.+?)\s*$")
META = re.compile(r"^- \*\*Goal:\*\* (.+?) · \*\*Size:\*\* (\S+) · \*\*Area:\*\* (\S+) · \*\*Needs:\*\* (.+?) · "
                  r"\*\*Depends:\*\* (.+?) · \*\*Status:\*\* (.+?)\s*$")
AREAS = os.path.join(os.path.dirname(os.path.dirname(HERE)), "areas.json")
FIELD = re.compile(r"^- \*\*([A-Za-z ]+):\*\*")


class Card:
    def __init__(self, cid, title, line):
        self.id, self.title, self.line = cid, title, line
        self.goal = self.size = self.status = self.area = ""
        self.needs, self.depends, self.fields = [], [], {}
        self.meta_line = None

    @property
    def track(self):
        return self.id.split("-")[0]

    @property
    def state(self):
        return self.status.split()[0] if self.status else ""


def parse(path=BACKLOG):
    cards, cur, lines = [], None, open(path, encoding="utf-8").read().split("\n")
    for n, text in enumerate(lines):
        m = HEAD.match(text)
        if m:
            cur = Card(m.group(1), m.group(2), n)
            cards.append(cur)
            continue
        if text.startswith("## ") or text.startswith("---"):
            cur = None
            continue
        if cur is None:
            continue
        m = META.match(text)
        if m:
            cur.goal, cur.size, cur.area = m.group(1), m.group(2), m.group(3)
            cur.needs = [x.strip() for x in m.group(4).split(",")]
            dep = m.group(5).strip()
            cur.depends = [] if dep in ("—", "-") else [x.strip() for x in dep.split(",")]
            cur.status, cur.meta_line = m.group(6).strip(), n
            continue
        m = FIELD.match(text)
        if m and m.group(1) != "Goal":
            cur.fields[m.group(1)] = n
    return cards, lines


def area_ids():
    import json
    try:
        return {a["id"]: a for a in json.load(open(AREAS))["areas"]}
    except (OSError, ValueError):
        return {}


def check(cards):
    errs, ids = [], {}
    areas = area_ids()
    for c in cards:
        if c.id in ids:
            errs.append("%s: duplicate ID (line %d and %d)" % (c.id, ids[c.id] + 1, c.line + 1))
        ids[c.id] = c.line
    for c in cards:
        where = "%s (line %d)" % (c.id, c.line + 1)
        if c.meta_line is None:
            errs.append("%s: missing or malformed Goal/Size/Needs/Depends/Status line" % where)
            continue
        if areas and c.area not in areas:
            errs.append("%s: unknown area %r (areas.json)" % (where, c.area))
        if c.size not in SIZES:
            errs.append("%s: size %r is not S or M (split larger tasks)" % (where, c.size))
        for need in c.needs:
            if need not in NEEDS:
                errs.append("%s: unknown need %r" % (where, need))
        for d in c.depends:
            if d not in ids:
                errs.append("%s: depends on unknown card %s" % (where, d))
        if c.state not in ("todo", "doing", "done", "blocked", "split"):
            errs.append("%s: bad status %r" % (where, c.status))
        if c.state == "done" and len(c.status.split()) < 2:
            errs.append("%s: 'done' needs a commit" % where)
        for f in FIELDS:
            if f not in c.fields:
                errs.append("%s: missing field %s" % (where, f))
    # cycles
    graph = {c.id: [d for d in c.depends if d in ids] for c in cards}
    state = {}

    def visit(v, stack):
        state[v] = 1
        for w in graph[v]:
            if state.get(w) == 1:
                errs.append("dependency cycle: %s" % " -> ".join(stack + [v, w]))
            elif not state.get(w):
                visit(w, stack + [v])
        state[v] = 2
    for v in graph:
        if not state.get(v):
            visit(v, [])
    return errs


def runnable(cards, env, area=None):
    done = {c.id for c in cards if c.state == "done"}
    closed = {k for k, v in area_ids().items() if not v.get("open", True)}
    out = []
    for c in cards:
        if c.state != "todo" or c.area in closed:
            continue
        if area and c.area != area:
            continue
        if any(d not in done for d in c.depends):
            continue
        if env is not None and any(n not in env for n in c.needs):
            continue
        out.append(c)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("check")
    sub.add_parser("stats")
    p = sub.add_parser("list")
    p.add_argument("--track")
    p.add_argument("--area")
    p.add_argument("--status")
    p = sub.add_parser("next")
    p.add_argument("--env", help="comma-separated needs available here, e.g. cpu,net (default: any)")
    p.add_argument("--area", help="only cards of this area (areas.json)")
    p = sub.add_parser("show")
    p.add_argument("id")
    p = sub.add_parser("set")
    p.add_argument("id")
    p.add_argument("status", nargs="+")
    a = ap.parse_args()

    cards, lines = parse()
    byid = {c.id: c for c in cards}
    if a.cmd == "check":
        errs = check(cards)
        for e in errs:
            print("ERROR", e)
        print("%d cards, %d errors" % (len(cards), len(errs)))
        return 1 if errs else 0
    if a.cmd == "stats":
        tracks = sorted({c.track for c in cards})
        print("%-6s %5s %3s %3s  %s" % ("track", "cards", "S", "M", "status"))
        groups = [(t, [c for c in cards if c.track == t]) for t in tracks]
        groups += [("area " + ar, [c for c in cards if c.area == ar]) for ar in sorted({c.area for c in cards})]
        for t, cs in groups:
            st = {}
            for c in cs:
                st[c.state] = st.get(c.state, 0) + 1
            print("%-6s %5d %3d %3d  %s" % (t, len(cs), sum(c.size == "S" for c in cs),
                                            sum(c.size == "M" for c in cs),
                                            ", ".join("%s %d" % kv for kv in sorted(st.items()))))
        return 0
    if a.cmd == "list":
        for c in cards:
            if a.track and c.track != a.track:
                continue
            if a.status and c.state != a.status:
                continue
            if a.area and c.area != a.area:
                continue
            print("%-7s %s  %-14s %-22s %s" % (c.id, c.size, c.area, ",".join(c.needs), c.title))
        return 0
    if a.cmd == "next":
        env = None if not a.env else {x.strip() for x in a.env.split(",")}
        for c in runnable(cards, env, a.area):
            print("%-7s %s  %-14s %-22s %s" % (c.id, c.size, c.area, ",".join(c.needs), c.title))
        return 0
    if a.cmd == "show":
        c = byid.get(a.id)
        if not c:
            print("no card %s" % a.id, file=sys.stderr)
            return 2
        end = len(lines)
        for n in range(c.line + 1, len(lines)):
            if lines[n].startswith("### ") or lines[n].startswith("## ") or lines[n].startswith("---"):
                end = n
                break
        print("\n".join(lines[c.line:end]).rstrip())
        return 0
    if a.cmd == "set":
        c = byid.get(a.id)
        if not c:
            print("no card %s" % a.id, file=sys.stderr)
            return 2
        new = " ".join(a.status)
        if new.split()[0] not in ("todo", "doing", "done", "blocked", "split"):
            print("bad status %r" % new, file=sys.stderr)
            return 2
        if new.split()[0] == "done" and len(new.split()) < 2:
            print("'done' needs a commit: set %s done <sha>" % a.id, file=sys.stderr)
            return 2
        old = lines[c.meta_line]
        lines[c.meta_line] = old[:old.index("**Status:** ") + len("**Status:** ")] + new
        open(BACKLOG, "w", encoding="utf-8").write("\n".join(lines))
        print("%s: %s -> %s" % (c.id, c.status, new))
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
