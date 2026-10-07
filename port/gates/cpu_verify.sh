#!/bin/bash
# CPU-only verification of the code-only parallel run (port/agent/CODE_ONLY.md
# section 7): no GPU and no NVHPC needed, gfortran only.  Run it on the
# integration branch (agent/code) after the work packages are merged.
#
#   cpu_verify.sh [--base REV] [--skip-scope] [--harness]
#     --base     the handoff commit the work packages started from (default: the
#                merge base of HEAD and claude/wrf-gpu-port-cpu-7doq8n)
#     --harness  also run harness.sh (gnu-ref vs gnu-gpu, random inputs) for
#                every routine with an island of the Phase 2 work packages:
#                it reaches code paths the smoke case does not (about 2 min each)
#
#  1. static.sh
#  2. check_wp_scope.py for every work package whose branch agent/wp/<id>
#     exists (local or origin), against --base
#  3. gfortran builds (build.sh, --fire-ideal): gnu-ref and gnu-gpu of the
#     working tree, gnu-ref of --base
#  4. the smoke case S-3M, bit for bit:
#       gnu-ref(base) vs gnu-ref(tree)            CPU view unchanged; shared refactors exact
#       gnu-ref(tree) vs gnu-gpu(tree), 1 thread   the GPU code keeps the arithmetic (its
#                                                  target regions run on the host)
#       gnu-ref(tree) vs gnu-gpu(tree), 4 threads  no data race in the kernels (missing
#                                                  private / wrong data-sharing clauses)
#  5. the reference tests (port/tests/run_ref_tests.sh gnu)
#  6. with --harness: "CPU vs DEVICE" of harness.sh for each Phase 2 routine
#
# What it cannot see (the H100 runs do): data movement and islands (host and
# "device" memory are the same here), GPU-only races and scheduling,
# nvfortran restrictions, device stack size; and code paths the smoke case
# does not run (nest, boundary file, restart start, d02 LES options).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
base=; skip_scope=0; harness=0
while [ $# -gt 0 ]; do
  case $1 in
    --base) base=${2:?}; shift ;;
    --skip-scope) skip_scope=1 ;;
    --harness) harness=1 ;;
    *) echo "usage: cpu_verify.sh [--base REV] [--skip-scope] [--harness]" >&2; exit 2 ;;
  esac
  shift
done
cd "$PORT_REPO"
if [ -z "$base" ]; then
  base=$(git merge-base HEAD origin/claude/wrf-gpu-port-cpu-7doq8n 2>/dev/null || git merge-base HEAD claude/wrf-gpu-port-cpu-7doq8n)
fi
[ -n "$base" ] || { echo "no base commit; pass --base" >&2; exit 2; }
echo "== cpu_verify: HEAD $(git rev-parse --short=12 HEAD), base ${base:0:12}"

out=$(bash "$PORT_REPO/port/gates/static.sh" 2>&1); rc=$?
echo "$out" > "$GATE_DIR/cpu_static.txt"
result static "$([ $rc = 0 ] && echo PASS || echo FAIL)" "$GATE_DIR/cpu_static.txt"

if [ $skip_scope = 0 ]; then
  for id in $(python3 -c "import sys; sys.path.insert(0,'port/tools'); import wp_def; print(' '.join(w['id'] for w in wp_def.WPS))"); do
    br=agent/wp/$(echo "$id" | tr 'A-Z-' 'a-z_')
    ref=
    git rev-parse -q --verify "$br" >/dev/null && ref=$br
    [ -z "$ref" ] && git rev-parse -q --verify "origin/$br" >/dev/null && ref=origin/$br
    if [ -z "$ref" ]; then result "scope:$id" SKIP "no branch $br"; continue; fi
    out=$(python3 port/tools/check_wp_scope.py "$id" --base "$base" --head "$ref" 2>&1); rc=$?
    result "scope:$id" "$([ $rc = 0 ] && echo PASS || echo FAIL)" "$(echo "$out" | tail -1)"
    [ $rc = 0 ] || echo "$out" | grep FAIL | head -10
  done
fi

bt=$("$H100/build.sh" gnu-ref --worktree --fire-ideal | tail -1); [ -x "$bt/main/wrf.exe" ] || bt=
bg=$("$H100/build.sh" gnu-gpu --worktree --fire-ideal | tail -1); [ -x "$bg/main/wrf.exe" ] || bg=
bb=$("$H100/build.sh" gnu-ref --commit "$base" --fire-ideal | tail -1); [ -x "$bb/main/wrf.exe" ] || bb=
result build:gnu-ref "$([ -n "$bt" ] && echo PASS || echo FAIL)" "${bt:-see $WORK/builds/gnu-ref/worktree/compile.log}"
result build:gnu-gpu "$([ -n "$bg" ] && echo PASS || echo FAIL)" "${bg:-see $WORK/builds/gnu-gpu/worktree/compile.log}"
result build:gnu-ref-base "$([ -n "$bb" ] && echo PASS || echo FAIL)" "${bb:-base build failed}"

cmp_runs() {   # cmp_runs <name> <run a> <run b>
  if [ -z "$2" ] || [ -z "$3" ] || ! run_ok "$2" || ! run_ok "$3"; then result "$1" FAIL "a run failed ($2 / $3)"; return; fi
  local out rc; out=$("$H100/compare.sh" "$2" "$3" 2>&1); rc=$?
  echo "$out" > "$GATE_DIR/$1.txt"
  result "$1" "$([ $rc = 0 ] && echo PASS || echo FAIL)" "$GATE_DIR/$1.txt"
  [ $rc = 0 ] || echo "$out" | grep -v '^ *common\|records' | head -15
}
rt=; rg=; rg4=; rb=
[ -n "$bt" ] && rt=$(window "$bt" S-3M)
[ -n "$bg" ] && rg=$(window "$bg" S-3M)
[ -n "$bg" ] && rg4=$(window "$bg" S-3M OMP_NUM_THREADS=4)
[ -n "$bb" ] && rb=$(window "$bb" S-3M)
cmp_runs cpu-view "$rb" "$rt"
cmp_runs gpu-view "$rt" "$rg"
cmp_runs gpu-view-4threads "$rt" "$rg4"

out=$(bash "$PORT_REPO/port/tests/run_ref_tests.sh" gnu 2>&1); rc=$?
echo "$out" > "$GATE_DIR/cpu_ref_tests.txt"
result ref_tests "$([ $rc = 0 ] && echo PASS || echo FAIL)" "$GATE_DIR/cpu_ref_tests.txt"
if [ $harness = 1 ] && [ -n "$bt" ] && [ -n "$bg" ] && [ -n "$rt" ]; then
  python3 - > "$GATE_DIR/harness_list.txt" <<'PY'
import json
o = json.load(open("port/agent/wp/ownership.json"))["work_packages"]
for wid, w in o.items():
    if w["phase"] == 2:
        for r in w["routines"]:
            if r["route"]:
                print(wid, r["file"], r["name"])
PY
  while read -r wid f name; do
    out=$(HARNESS_TIMEOUT=${HARNESS_TIMEOUT:-600} bash "$H100/harness.sh" "$f" "$name" --builds "$bt,$bg" \
          --namelist "$rt/namelist.input" 2>&1); rc=$?
    echo "$out" > "$GATE_DIR/harness_$name.txt"
    line=$(echo "$out" | grep -E '^(PASS|FAIL) +CPU vs DEVICE' | head -1)
    if [ $rc = 0 ] && [[ $line == PASS* ]]; then result "harness:$name" PASS "$wid"
    else result "harness:$name" FAIL "$wid: ${line:-see $GATE_DIR/harness_$name.txt}"; fi
  done < "$GATE_DIR/harness_list.txt"
fi
gate_end cpu_verify
