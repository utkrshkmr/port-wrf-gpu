#!/usr/bin/env python3
"""Convert OpenMP offload directives to OpenACC (ADR-001 rev 2: the port uses OpenACC + CUDA Fortran).

  omp2acc.py <file> [...]            rewrite the files in place
  omp2acc.py --check <file> [...]    print what would change and what is left; exit 1 if anything is left
  omp2acc.py --self-test

What it converts (a directive and its '!$omp&' continuation lines are one statement):
  !$omp target teams distribute parallel do / target teams loop / target parallel do / target teams distribute
        -> !$acc parallel loop gang vector
     clauses: if(target: X) -> if(X); shared(X) -> present(X); map(to:X) -> copyin(X); map(from:X) -> copyout(X);
              map(tofrom:X) -> copy(X); map(alloc:X) -> create(X); map(present[,alloc]:X) -> present(X);
              private, firstprivate, reduction, collapse, default(none) unchanged; defaultmap(...) dropped
              (default(none) + present(...) is the rule); num_teams/thread_limit dropped; nowait -> async
  !$omp end target teams distribute parallel do (and the like)  -> removed
  !$omp target enter data map(to:X) / map(alloc:X)            -> !$acc enter data copyin(X) / create(X)
  !$omp target exit data map(delete:X) / map(from:X)          -> !$acc exit data delete(X) / copyout(X)
  !$omp target update to(X) / from(X)                         -> !$acc update device(X) / self(X)
  !$omp target data map(...) ... !$omp end target data        -> !$acc data copyin/copyout/... ... !$acc end data
  !$omp target [map(...)] ... !$omp end target                -> !$acc serial [copy clauses] ... !$acc end serial
  !$omp declare target                 (in a procedure)       -> !$acc routine seq
  !$omp declare target(a, b)           (module data)          -> !$acc declare create(a, b)
  !$omp taskwait                                              -> !$acc wait
and inserts '!$acc loop seq' before every DO loop inside a converted kernel that is not one of its collapsed
loops (CODING_STANDARD.md: inner loops are sequential and say so), except DO WHILE loops and loops with an EXIT at
their own level, which OpenACC does not allow to be annotated (their index must be in private(...)).

Not touched: host OpenMP ('!$omp parallel do', '!$omp end parallel do', '!$omp single', threadprivate, ...), which
WRF uses for tiles and the tests use for host threads.  Left for a human (reported, exit 1 with --check):
omp_* runtime calls of the device API (omp_target_is_present, omp_get_default_device, omp_is_initial_device,
omp_target_alloc, use_device_ptr/is_device_ptr clauses) and any '!$omp target' form not listed above.
"""
import os
import re
import sys

KERNEL_HEAD = re.compile(r"^target\s+(teams\s+distribute\s+parallel\s+do(\s+simd)?|teams\s+distribute|teams\s+loop|"
                         r"teams|parallel\s+do(\s+simd)?|parallel\s+loop|parallel|loop|simd)\b", re.I)
DEVICE_API = re.compile(r"\bomp_(target_\w+|get_default_device|set_default_device|is_initial_device|get_num_devices|"
                        r"get_device_num|get_initial_device)\b|\b(use_device_ptr|use_device_addr|is_device_ptr|"
                        r"has_device_addr)\b", re.I)
DIR = re.compile(r"^(\s*)!\$omp(&?)(\s*)(.*)$", re.I)
DO = re.compile(r"^\s*(\d+\s+)?(\w+\s*:\s*)?do\b(?!\s*=)(?!\s*\w+\s*=[^,]*$)", re.I)
ENDDO = re.compile(r"^\s*(\d+\s+)?end\s*do\b", re.I)


def split_clauses(text):
    """'a(b) c d(e,f(g))' -> ['a(b)', 'c', 'd(e,f(g))']"""
    out, cur, depth = [], "", 0
    for ch in text:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if (ch in " ,\t") and depth == 0:
            if cur.strip():
                out.append(cur.strip())
            cur = ""
            continue
        cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def clause_name(c):
    return re.match(r"^([a-z_]+)", c, re.I).group(1).lower()


def clause_arg(c):
    m = re.match(r"^[a-z_]+\s*\((.*)\)$", c, re.I | re.S)
    return m.group(1).strip() if m else ""


def convert_map(arg):
    """map argument 'to: a, b' -> ('copyin', 'a, b')"""
    if ":" not in arg:
        return "copy", arg
    kinds, names = arg.split(":", 1)
    kinds = [k.strip().lower() for k in kinds.split(",")]
    names = names.strip()
    if "present" in kinds:
        return "present", names
    kind = (kinds or ["tofrom"])[-1]
    return {"to": "copyin", "from": "copyout", "tofrom": "copy", "alloc": "create", "delete": "delete",
            "release": "delete", "always": "copy"}.get(kind, "copy"), names


def convert_clauses(clauses, kernel):
    out, left = [], []
    for c in clauses:
        n = clause_name(c)
        a = clause_arg(c)
        if n == "if":
            out.append("if(" + re.sub(r"^\s*target\s*:\s*", "", a, flags=re.I) + ")")
        elif n == "shared":
            out.append(f"present({a})")
        elif n == "map":
            k, names = convert_map(a)
            out.append(f"{k}({names})")
        elif n in ("private", "firstprivate", "reduction", "collapse"):
            out.append(c)
        elif n == "default":
            out.append("default(none)" if a.lower() == "none" else f"default({a})")
        elif n in ("defaultmap", "num_teams", "thread_limit", "dist_schedule", "schedule", "num_threads", "simdlen",
                   "order", "bind"):
            continue
        elif n == "nowait":
            out.append("async")
        elif n == "depend":
            left.append(c)
        else:
            left.append(c)
    return out, left


def wrap(indent, head, clauses, width=110):
    """one directive, continued with '!$acc&' lines"""
    lines, cur = [], f"{indent}!$acc {head}"
    for c in clauses:
        if len(cur) + 1 + len(c) > width:
            lines.append(cur + " &")
            cur = f"{indent}!$acc& {c}"
        else:
            cur += " " + c
    lines.append(cur)
    return lines


def has_exit_or_while(src, i):
    """True if the DO loop starting at line i is a DO WHILE or contains an EXIT at its own level: OpenACC does not
    allow '!$acc loop' on it (its index must be listed in private(...) instead)."""
    if re.match(r"^\s*(\d+\s+)?(\w+\s*:\s*)?do\s+while\b", src[i], re.I):
        return True
    depth = 0
    for line in src[i:]:
        if line.lstrip().startswith("!"):
            continue
        if DO.match(line):
            depth += 1
        elif ENDDO.match(line):
            depth -= 1
            if depth == 0:
                return False
        elif depth == 1 and re.match(r"^\s*(\d+\s+)?(if\s*\(.*\)\s*)?exit\b", line, re.I):
            return True
    return False


def convert_text(text):
    """returns (new_text, notes); notes lists what a human must look at"""
    src = text.split("\n")
    out, notes = [], []
    i = 0
    in_kernel = 0           # >0: inside a converted kernel; value = remaining collapsed loops to skip
    kernel_depth = 0        # DO depth inside the current kernel
    pending_block = []      # stack of open block constructs ('serial', 'data')
    while i < len(src):
        line = src[i]
        m = DIR.match(line)
        if m and not m.group(2):
            indent = m.group(1)
            stmt = m.group(4)
            j = i
            while j + 1 < len(src) and re.match(r"^\s*!\$omp&", src[j + 1], re.I):
                j += 1
                stmt += " " + re.sub(r"^\s*!\$omp&\s*", "", src[j], flags=re.I)
            stmt = re.sub(r"\s*&\s*", " ", stmt).strip()
            low = stmt.lower()
            new = None
            if low.startswith("declare target"):
                arg = stmt[len("declare target"):].strip()
                if arg.startswith("(") and arg.endswith(")"):
                    new = [f"{indent}!$acc declare create{arg}"]
                elif not arg:
                    new = [f"{indent}!$acc routine seq"]
                else:
                    new = [f"{indent}!$acc routine seq"]
                    notes.append(f"line {i + 1}: 'declare target {arg}' -> routine seq; check the clauses")
            elif low.startswith("end declare target"):
                new = []
            elif re.match(r"^target\s+enter\s+data\b", low):
                cl, left = convert_clauses(split_clauses(stmt[len("target enter data"):]), False)
                cl = [c for c in cl if not c.startswith("copyout")]
                new = wrap(indent, "enter data", cl)
                notes += [f"line {i + 1}: clause {c} not converted" for c in left]
            elif re.match(r"^target\s+exit\s+data\b", low):
                cl, left = convert_clauses(split_clauses(stmt[len("target exit data"):]), False)
                cl = [("delete(" + c[c.index("(") + 1:] if c.startswith(("copy(", "create(", "copyin("))
                       else c) for c in cl]
                new = wrap(indent, "exit data", cl)
                notes += [f"line {i + 1}: clause {c} not converted" for c in left]
            elif re.match(r"^target\s+update\b", low):
                cl = []
                for c in split_clauses(stmt[len("target update"):]):
                    n = clause_name(c)
                    a = clause_arg(c)
                    if n == "to":
                        cl.append(f"device({a})")
                    elif n == "from":
                        cl.append(f"self({a})")
                    elif n == "if":
                        cl.append(f"if({a})")
                    elif n == "nowait":
                        cl.append("async")
                    else:
                        notes.append(f"line {i + 1}: update clause {c} not converted")
                new = wrap(indent, "update", cl)
            elif re.match(r"^target\s+data\b", low):
                cl, left = convert_clauses(split_clauses(stmt[len("target data"):]), False)
                new = wrap(indent, "data", cl)
                pending_block.append("data")
                notes += [f"line {i + 1}: clause {c} not converted" for c in left]
            elif re.match(r"^end\s+target\s+data\b", low):
                new = [f"{indent}!$acc end data"]
            elif re.match(r"^end\s+target\b", low):
                if re.match(r"^end\s+target\s*$", low):
                    new = [f"{indent}!$acc end serial"]
                else:
                    new = []            # end of a combined loop construct: not needed in OpenACC
            elif low.startswith("target"):
                rest = stmt[len("target"):].strip()
                mh = KERNEL_HEAD.match("target " + rest)
                head = mh.group(1).lower() if mh else ""
                clauses_txt = ("target " + rest)[mh.end():] if mh else rest
                is_loop = bool(re.search(r"\b(do|loop|distribute|simd)\b", head))
                cl, left = convert_clauses(split_clauses(clauses_txt), True)
                notes += [f"line {i + 1}: clause {c} not converted" for c in left]
                if is_loop:
                    new = wrap(indent, "parallel loop gang vector", cl)
                    mc = re.search(r"collapse\s*\(\s*(\d+)\s*\)", stmt, re.I)
                    in_kernel = int(mc.group(1)) if mc else 1
                    kernel_depth = 0
                else:
                    new = wrap(indent, "serial", cl)
                    pending_block.append("serial")
                    if head and head not in ("teams", "parallel"):
                        notes.append(f"line {i + 1}: '!$omp {stmt[:60]}' converted to serial; check")
            elif low == "taskwait" or low.startswith("taskwait "):
                new = [f"{indent}!$acc wait"]
            if new is not None:
                if DEVICE_API.search(stmt):
                    notes.append(f"line {i + 1}: device-API clause in '{stmt[:60]}'")
                out += new
                i = j + 1
                continue
        # loop bookkeeping inside a converted kernel
        if in_kernel or kernel_depth:
            s = line
            if DO.match(s) and not s.lstrip().startswith("!"):
                if in_kernel:
                    in_kernel -= 1
                    kernel_depth += 1
                else:
                    prev = out[-1] if out else ""
                    if not re.match(r"^\s*!\$acc\s+loop\b", prev, re.I) and not has_exit_or_while(src, i):
                        ind = re.match(r"^(\s*)", s).group(1)
                        out.append(f"{ind}!$acc loop seq")
                    kernel_depth += 1
            elif ENDDO.match(s) and not s.lstrip().startswith("!"):
                kernel_depth -= 1
                if kernel_depth <= 0:
                    kernel_depth = 0
                    in_kernel = 0
        if DEVICE_API.search(line) and not line.lstrip().startswith("!") or \
                (line.lstrip().lower().startswith("!$omp") and DEVICE_API.search(line)):
            notes.append(f"line {i + 1}: OpenMP device API: {line.strip()[:70]}")
        out.append(line)
        i += 1
    left = [f"line {n}: {l.strip()[:70]}" for n, l in enumerate(out, 1)
            if re.match(r"^\s*!\$omp\s*(target|declare\s+target|end\s+target)", l, re.I)]
    return "\n".join(out), notes + [f"{x} (OpenMP offload left)" for x in left]


SELF_TEST = """      SUBROUTINE k(a, b, n, m)
      REAL :: a(n,m), b(n,m), s
!$omp declare target
!$omp target teams distribute parallel do collapse(1) if(target: gpu_on(R_X)) default(none) &
!$omp& shared(a, b) firstprivate(n, m) private(s)
      DO j = 1, m
        s = 0.
        DO i = 1, n
          s = s + b(i,j)
          a(i,j) = s
        END DO
      END DO
!$omp target update from(a)
!$omp parallel do
      DO j = 1, m
        a(1,j) = 0.
      END DO
!$omp target enter data map(to: b) map(alloc: a)
      END SUBROUTINE k
"""

SELF_EXPECT = """      SUBROUTINE k(a, b, n, m)
      REAL :: a(n,m), b(n,m), s
!$acc routine seq
!$acc parallel loop gang vector collapse(1) if(gpu_on(R_X)) default(none) present(a, b) firstprivate(n, m) &
!$acc& private(s)
      DO j = 1, m
        s = 0.
        !$acc loop seq
        DO i = 1, n
          s = s + b(i,j)
          a(i,j) = s
        END DO
      END DO
!$acc update self(a)
!$omp parallel do
      DO j = 1, m
        a(1,j) = 0.
      END DO
!$acc enter data copyin(b) create(a)
      END SUBROUTINE k
"""


def main():
    a = sys.argv[1:]
    if not a or a[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    if a[0] == "--self-test":
        got, notes = convert_text(SELF_TEST)
        ok = got == SELF_EXPECT and not notes
        print(("ok    " if ok else "FAIL  ") + "omp2acc self-test")
        if not ok:
            import difflib
            print("\n".join(difflib.unified_diff(SELF_EXPECT.split("\n"), got.split("\n"), lineterm="")))
            print(notes)
        return 0 if ok else 1
    check = a[0] == "--check"
    files = []
    for f in (a[1:] if check else a):
        if os.path.isdir(f):
            for root, _, names in os.walk(f):
                files += [os.path.join(root, n) for n in sorted(names)
                          if n.endswith((".F", ".F90", ".f90", ".inc", ".h"))]
        else:
            files.append(f)
    bad = 0
    for f in files:
        text = open(f, encoding="latin-1").read()
        new, notes = convert_text(text)
        changed = new != text
        if check:
            if changed:
                print(f"{f}: would change")
        else:
            if changed:
                open(f, "w", encoding="latin-1").write(new)
                print(f"{f}: converted")
        for n in notes:
            print(f"{f}: {n}")
        bad += len(notes)
    return 1 if (bad and check) else 0


if __name__ == "__main__":
    sys.exit(main())
