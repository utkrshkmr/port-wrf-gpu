#!/usr/bin/env python3
"""Check that a work package changed only what it owns (port/agent/CODE_ONLY.md,
port/agent/WORKPACKAGES.md; ownership from port/tools/wp_def.py).

  check_wp_scope.py <WP-ID> [--base REV] [--head REV | --worktree]

  --base      the commit the work package started from (default: the merge
              base of HEAD and the handoff branch claude/wrf-gpu-port-cpu-7doq8n)
  --head      the commit to check (default HEAD); --worktree checks the working
              tree instead, including uncommitted and untracked files

Every changed path must be owned by the work package: a whole file, its status
file, its arith exceptions file, its work-array include, or a WRF source file in
which it owns routines or the module specification part.  In such a file every
changed hunk must lie inside an owned routine (as it was at --base); new lines
may also be inserted right after the END of an owned routine.  Exit status 0
only if nothing else changed.
"""
import argparse
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import wp_lib  # noqa: E402

REPO = wp_lib.REPO
HUNK = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+\d+(?:,\d+)? @@")


def git(*args):
    r = subprocess.run(["git", "-C", REPO] + list(args), capture_output=True, text=True, errors="replace")
    return r.returncode, r.stdout


def default_base():
    for ref in ("origin/" + wp_lib.HANDOFF_BRANCH, wp_lib.HANDOFF_BRANCH):
        rc, out = git("merge-base", "HEAD", ref)
        if rc == 0 and out.strip():
            return out.strip()
    raise SystemExit("check_wp_scope: no handoff branch to start from; pass --base <commit>")


def changed(base, head, worktree):
    if worktree:
        _, out = git("diff", "--name-status", base)
        _, extra = git("ls-files", "--others", "--exclude-standard")
        rows = [l.split("\t") for l in out.splitlines() if l.strip()]
        rows += [["A", f] for f in extra.splitlines() if f.strip()]
    else:
        _, out = git("diff", "--name-status", base, head)
        rows = [l.split("\t") for l in out.splitlines() if l.strip()]
    paths = []
    rows = [r for r in rows if "__pycache__/" not in r[-1] and not r[-1].endswith(".pyc")]
    for r in rows:
        st = r[0]
        if st.startswith("R"):          # rename: both names count
            paths += [(st, r[1]), (st, r[2])]
        else:
            paths.append((st, r[-1]))
    return paths


def hunks(base, head, worktree, path):
    args = ["diff", "-U0", base] + ([] if worktree else [head]) + ["--", path]
    _, out = git(*args)
    hs = []
    for l in out.splitlines():
        m = HUNK.match(l)
        if m:
            a = int(m.group(1))
            n = 1 if m.group(2) is None else int(m.group(2))
            hs.append((a, n))
    return hs


def inside(a, n, spans):
    """old-file hunk (start a, count n; n == 0 means insertion after line a) inside one span"""
    for s, e in spans:
        if n == 0 and s <= a <= e:
            return True
        if n > 0 and s <= a and a + n - 1 <= e:
            return True
    return False


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("wp")
    ap.add_argument("--base")
    ap.add_argument("--head", default="HEAD")
    ap.add_argument("--worktree", action="store_true")
    a = ap.parse_args()
    own_all = wp_lib.ownership()
    if a.wp not in own_all:
        raise SystemExit(f"check_wp_scope: unknown work package {a.wp} (port/agent/WORKPACKAGES.md)")
    own = own_all[a.wp]
    base = a.base or default_base()
    whole = set(own["files"]) | set(own["aux"])
    per_file = {}
    for f, n, _ in own["routines"]:
        per_file.setdefault(f, {"routines": [], "specs": False})["routines"].append(n)
    for s in own["specs"]:
        per_file.setdefault(s, {"routines": [], "specs": False})["specs"] = True
    bad, nfiles, nh = [], 0, 0
    for st, path in changed(base, a.head, a.worktree):
        nfiles += 1
        if path in whole:
            continue
        if path not in per_file:
            bad.append(f"{path}: not owned by {a.wp}")
            continue
        if st != "M":
            bad.append(f"{path}: {st} (only modifications inside owned routines are allowed in this file)")
            continue
        lines = wp_lib.read_lines(path, base) or []
        spans = []
        for n in per_file[path]["routines"]:
            sp = wp_lib.routine_span(lines, n)
            if sp:
                spans.append(sp)
            else:
                bad.append(f"{path}: owned routine {n} not found at {base[:12]}")
        if per_file[path]["specs"]:
            spans += wp_lib.spec_spans(lines)
        for h0, hn in hunks(base, a.head, a.worktree, path):
            nh += 1
            if not inside(h0, hn, spans):
                what = f"lines {h0}-{h0 + hn - 1}" if hn else f"insertion after line {h0}"
                bad.append(f"{path}: {what} (at {base[:12]}) are outside the routines {a.wp} owns there "
                           f"({', '.join(per_file[path]['routines']) or 'spec part'})")
    for b in bad:
        print("FAIL ", b)
    print(f"check_wp_scope {a.wp}: {nfiles} changed paths, {nh} hunks in shared files since {base[:12]}: "
          f"{'PASS' if not bad else 'FAIL'}")
    return 0 if not bad else 1


if __name__ == "__main__":
    sys.exit(main())
