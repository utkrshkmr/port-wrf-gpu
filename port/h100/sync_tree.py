#!/usr/bin/env python3
"""Copy a source tree into a build tree, touching only files whose content
changed (like rsync -rl --checksum without preserving times): a copied file
gets the current time, so make rebuilds it and what depends on it, and an
unchanged file keeps its old time.  Files that exist only in the build tree
(objects, generated files) are left alone.

WRF's Makefiles do not know that a source file depends on the files it
includes (#include "x.inc", INCLUDE 'x.inc'), so a changed include file alone
would leave stale objects (S0-01.1: inc/gpu_work_*.inc, island includes).  Every
source file of the build tree that includes a copied include file is therefore
touched as well (listed on stderr).

Usage: sync_tree.py <src dir> <dst dir>      prints the number of copied files
"""
import filecmp
import os
import re
import shutil
import sys

INC_EXT = (".inc", ".h")
SRC_EXT = (".F", ".F90", ".f90", ".f", ".c")
INC_RE = re.compile(r'^\s*(?:#\s*include|include)\s*["\'<]([^"\'>]+)["\'>]', re.I | re.M)


def touch_includers(dst, changed):
    """Touch every source file under dst that includes a file named in changed (basenames)."""
    touched = []
    for root, dirs, files in os.walk(dst):
        dirs[:] = [d for d in dirs if d != ".git"]
        for f in files:
            if not f.endswith(SRC_EXT):
                continue
            p = os.path.join(root, f)
            if os.path.islink(p):
                continue
            try:
                text = open(p, errors="replace").read()
            except OSError:
                continue
            if any(os.path.basename(m) in changed for m in INC_RE.findall(text)):
                os.utime(p)
                touched.append(os.path.relpath(p, dst))
    return touched


def main(src, dst):
    n = 0
    changed_inc = set()
    for root, dirs, files in os.walk(src):
        dirs[:] = [d for d in dirs if d != ".git"]
        rel = os.path.relpath(root, src)
        droot = os.path.join(dst, rel) if rel != "." else dst
        os.makedirs(droot, exist_ok=True)
        for f in files:
            s, d = os.path.join(root, f), os.path.join(droot, f)
            if os.path.islink(s):
                t = os.readlink(s)
                if not (os.path.islink(d) and os.readlink(d) == t):
                    if os.path.lexists(d):
                        os.remove(d)
                    os.symlink(t, d)
                    n += 1
                continue
            if os.path.exists(d) and not os.path.islink(d) and filecmp.cmp(s, d, shallow=False):
                continue
            if os.path.lexists(d):
                os.remove(d)
            shutil.copyfile(s, d)
            shutil.copymode(s, d)
            n += 1
            if f.endswith(INC_EXT):
                changed_inc.add(f)
    if changed_inc and n:
        touched = touch_includers(dst, changed_inc)
        if touched:
            sys.stderr.write(f"sync_tree: {len(changed_inc)} changed include file(s); touched {len(touched)} "
                             f"including source file(s): {' '.join(sorted(touched)[:20])}\n")
    print(n)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
