"""Shared helpers of gen_wp.py and check_wp_scope.py (code-only parallel work,
port/agent/CODE_ONLY.md): work-package definitions (wp_def.py), the routes of
port/agent/ROUTES.md, and the line ranges of routines and module
specification parts in a WRF source file."""

import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
AGENT = os.path.join(REPO, "port", "agent")
WPDIR = os.path.join(AGENT, "wp")
sys.path.insert(0, HERE)
import wp_def  # noqa: E402

HANDOFF_BRANCH = "claude/wrf-gpu-port-cpu-7doq8n"
START = re.compile(r"^\s*(?:(?:recursive|pure|elemental|impure)\s+)*(?:(?:real|integer|logical|double\s+precision)"
                   r"(?:\s*\([^)]*\))?\s+)?(module|subroutine|function|program)\s+(\w+)", re.I)
END = re.compile(r"^\s*end\s*(module|subroutine|function|program)\b", re.I)
CONTAINS = re.compile(r"^\s*contains\s*(!.*)?$", re.I)


def repo_path(p):
    """wp_def path -> repository-relative path"""
    return p if p.startswith(("port/", "cases/")) else "WRF/" + p


def wp_slug(wp_id):
    return wp_id.lower().replace("-", "_")


def status_file(wp_id):
    return f"port/agent/wp/status/{wp_id}.md"


def exceptions_file(wp_id):
    return f"port/agent/arith_exceptions.d/{wp_id}.txt"


def work_include(wp):
    return "WRF/" + wp_def.work_inc(wp["id"]) if has_work(wp) else None


def has_work(wp):
    return wp.get("work", wp["phase"] in (2, 3))


def git(*args, check=False):
    r = subprocess.run(["git", "-C", REPO] + list(args), capture_output=True, text=True, errors="replace")
    if check and r.returncode != 0:
        raise SystemExit(f"git {' '.join(args)} failed: {r.stderr.strip()}")
    return r.stdout


def read_lines(path, rev=None):
    """lines of a repository file in the working tree (rev None) or at a commit"""
    if rev:
        r = subprocess.run(["git", "-C", REPO, "show", f"{rev}:{path}"], capture_output=True, text=True,
                           errors="replace")
        return r.stdout.split("\n") if r.returncode == 0 else None
    full = os.path.join(REPO, path)
    return open(full, errors="replace").read().split("\n") if os.path.exists(full) else None


def units(lines):
    """[(kind, name, first, last, depth)] of modules/subroutines/functions/programs (1-based lines)"""
    stack, out = [], []
    for n, l in enumerate(lines, 1):
        if l.lstrip().startswith("!"):
            continue
        m = START.match(l)
        if m and not re.match(r"^\s*module\s+procedure\b", l, re.I):
            stack.append((m.group(1).lower(), m.group(2), n))
            continue
        if END.match(l) and stack:
            kind, name, a = stack.pop()
            out.append((kind, name, a, n, len(stack)))
    return sorted(out, key=lambda u: u[2])


def routine_span(lines, name):
    """(first, last) of a subroutine/function, or None (first match, any depth)"""
    for kind, nm, a, b, _ in units(lines):
        if kind in ("subroutine", "function") and nm.lower() == name.lower():
            return (a, b)
    return None


def spec_spans(lines):
    """[(first, last)] of the specification parts of the modules (MODULE line .. CONTAINS or END MODULE)"""
    out = []
    for kind, nm, a, b, _ in units(lines):
        if kind != "module":
            continue
        end = b
        for n in range(a + 1, b):
            if CONTAINS.match(lines[n - 1]):
                end = n
                break
        out.append((a, end))
    return out


def parse_routes():
    """{route: {"section":..., "routines": [(file, name, a, b)], "calls": text, "kernels": text}} from ROUTES.md"""
    routes = {}
    for l in open(os.path.join(AGENT, "ROUTES.md")):
        if not l.startswith("| `"):
            continue
        c = [x.strip() for x in l.strip().strip("|").split("|")]
        if len(c) < 5:
            continue
        name = c[0].strip("`")
        defs = [(f, n, int(a), int(b)) for n, f, a, b in re.findall(r"(\w+) WRF/([\w/]+\.F(?:90)?):(\d+)-(\d+)", c[2])]
        routes[name] = dict(section=c[1], routines=defs, calls=c[3], kernels=c[4], raw_defs=c[2])
    return routes


def route_constants():
    """route names declared in WRF/frame/module_gpu_route.F"""
    src = open(os.path.join(REPO, "WRF", "frame", "module_gpu_route.F")).read()
    block = src[src.index("route_name(nroutes)"):src.index("/)", src.index("route_name(nroutes)"))]
    return [x.strip() for x in re.findall(r"'([^']*)'", block)]


def ownership():
    """the ownership of every work package (paths repository-relative):
    {wp_id: {"files": [...], "routines": [(file, name, route)], "specs": [...], "aux": [...]}}"""
    routes = parse_routes()
    own = {}
    for wp in wp_def.WPS:
        files = [repo_path(f) for f in wp.get("files", [])]
        routines = []
        for r in wp.get("routes", []):
            if r not in routes:
                raise SystemExit(f"{wp['id']}: route {r} is not in port/agent/ROUTES.md")
            for f, n, _, _ in routes[r]["routines"]:
                if "WRF/" + f not in files:
                    routines.append(("WRF/" + f, n, r))
        for spec in wp.get("routines", []):
            fpart, rest = spec.split(":", 1)
            name, _, route = rest.partition("@")
            routines.append((repo_path(fpart), name, route or None))
        aux = [status_file(wp["id"]), exceptions_file(wp["id"])]
        if work_include(wp):
            aux.append(work_include(wp))
        own[wp["id"]] = dict(files=files, routines=routines, specs=[repo_path(s) for s in wp.get("specs", [])],
                             aux=aux)
    return own


def collisions(own):
    """list of messages for anything owned twice"""
    seen, bad = {}, []
    for wid, o in own.items():
        keys = [("file", f) for f in o["files"] + o["aux"]] + [("routine", f + ":" + n.lower()) for f, n, _ in
                                                                o["routines"]] + [("spec", s) for s in o["specs"]]
        for k in keys:
            if k in seen and seen[k] != wid:
                bad.append(f"{k[0]} {k[1]} is owned by {seen[k]} and {wid}")
            seen[k] = wid
    whole = {f: wid for wid, o in own.items() for f in o["files"]}
    for wid, o in own.items():
        for f, n, _ in o["routines"]:
            if f in whole and whole[f] != wid:
                bad.append(f"routine {f}:{n} of {wid} is in a file owned whole by {whole[f]}")
        for s in o["specs"]:
            if s in whole and whole[s] != wid:
                bad.append(f"spec part of {s} of {wid} is in a file owned whole by {whole[s]}")
    return bad
