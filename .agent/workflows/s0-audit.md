---
description: Re-verify everything Stage 0 has recorded as done, with fresh runs, and correct any record that does not hold
---
Purpose: Stage 0 is the ground truth of the whole port; a wrong record here poisons every later gate. This audit
re-runs the checks behind every "done" item with the **pinned toolchain (NVHPC 26.1, 12 files at -O1)** and fixes
the records where they do not hold. Rules 9–11 apply (git waits for the owner; act without asking otherwise;
evidence, not narration).

How to work:
- Do the items in order; each is cheap unless marked (long). Long ones run under nohup, logs in `$WORK/logs/audit_*.log`;
  do cheap items while they run.
- For each item write one row in `port/RESULTS.md`, section **"Stage 0 audit (YYYY-MM-DD)"**:
  `| item | command | log / file | decisive line | verdict (holds / corrected / not completed) |`.
- If a result differs from the existing record: correct the record in place (RESULTS, WORKBOOK, FIX_LEDGER entry,
  STAGE0_HANDOFF status table), say in the ledger entry what was wrong, and continue. If it changes numbers or a
  decision (compiler, case contract, a refactor), write BLOCKERS and stop.
- Commit after every two or three items (`git add -A`, `git commit -m "S0 audit: <items>"`, `git push origin agent/s0-00`,
  each on its own line).

## A. Environment and tools (minutes)
1. `bash port/h100/machine.sh detect` and `bash port/h100/machine.sh show`: profile a100-40x2, compiler nvfortran 26.1.
   `cat port/h100/env.local.sh`: NVHPC_ROOT and DEPS default to 26.1 (`PORT_NVHPC_ROOT`/`PORT_DEPS` override only).
2. `bash port/h100/setup_toolchain.sh check` → every essential tool found, with 26.1 paths; `$WORK/deps-26.1` is a real
   directory on /home (not a RAM-disk symlink).
3. `bash port/gates/static.sh` → `== static: PASS`. `python3 port/tests/tools/test_agent_tools.py` → `RESULT: PASS`.
   `python3 port/machines/test_machine.py` → all PASS.
4. B3 rewrite complete: copy every file of `port/rp_subst_files.txt` to a scratch directory, run
   `python3 port/rp_subst.py <the copies>`, and `diff -r` the copies against `WRF/` → no difference (a second run
   changes nothing). Any difference means the rewrite is incomplete: record and stop.

## B. The compiler decision (F-08) on the pinned compiler
5. **Clean 26.1 CPU-REF build** (long, ~10 min at -j 20): `bash port/h100/build.sh cpu-ref --clean`. Pass criteria, all
   from files: `grep -c 'signal 11' compile.log` = 0; **every** `time mpif90 -o X.o` in `compile.log` has its `X.o` in
   the tree (missing-object check, script in FIX_LEDGER F-08); `main/wrf.exe` exists; `BUILD_INFO` says `o1 files: ...
   (12 files)` and `build jobs: 20`. Record the wrf.exe md5 in RESULTS (S0-07.1).
6. **Each listed file is a real crash** (minutes): for every object in `port/h100/o1_files.txt`, recompile its `.f90`
   alone in a scratch directory with its logged command at -O2 and at -O1 (output `.o` and `-module` into the scratch
   dir, `-I` the build's `main/` for modules): -O2 must crash, -O1 must compile. A file that does not crash at -O2
   alone does not belong in the list: record it (F-08) and stop for the owner (the list must be minimal).
7. **Nothing else crashes**: item 5's zero-crash and missing-object checks are this proof. Also note in F-08 that
   every -O1 compile prints `nvfortran-Info-Switch -Mvect forces -O2` (see F-08 "Effective level").
8. **Step 1b evidence** (already re-done by the owner's session 2026-10-17; re-check only): `cmp` the W-T0 bit traces
   `work/runs/cpu-ref-0f00b0dfbf/W-T0/bittrace.d0{1,2}.txt` vs `work/runs/cpu-ref-695414d24e/W-T0/...` → identical;
   `grep RESULT work/harness/*/diff_*.txt` → all IDENTICAL with no NaN warning; `work/runs/cpu-ref-0f00b0dfbf/W-T0-gdbcov/gdb_rank0.log`
   → the HIT list recorded in F-08. Requires the 25.1 builds `5c51e28ccc52-o2/-o1nest` (RAM disk); if they are gone,
   record "not re-checked (builds lost)" — do not rebuild them just for this.
9. **Build parallelism (F-10)**: the `-j 20` and `-j 2` 26.1 builds of `0a55046` have identical machine code for every
   object (`objdump -d` minus the 3 header lines). Re-check only if F-10 says "not completed".

## C. GPU-side checks with 26.1 (S0-04, S0-05, S0-06)
10. `bash port/h100/gpu_hello.sh` → PASS on both GPUs.
11. `bash port/tests/acc_features/run.sh` with `CUDA_VISIBLE_DEVICES=0`, then `=1` → all PASS except the known F-BOUND.
12. `port/tests/repro_math/run_tests.sh` (full, long) on GPU 0 and GPU 1 → T-FMA first PASS; T-IEEE, T-IPOW, T-MINMAX,
    T-RM-EXH, T-RM-POW, T-RM-D PASS. T-RM-POW crashed with 25.1/25.9 (F-05): it must PASS with 26.1.
13. `bash port/gates/ref_tests.sh` → PASS (templates, mutants, check_verbatim).
14. `bash port/gates/t_machine.sh --force` → PASS; the machine record now names nvfortran 26.1.

## D. Builds and symbols (S0-07)
15. `bash port/sym_audit.sh <item-5 build>` (T-SYM) → PASS on the 26.1 build.
16. `bash port/h100/build.sh cpu-ref --worktree` then T-SYM on it → PASS (S0-07.2 is defined on the worktree build).

## E. Cases (S0-09)
17. `bash port/h100/dev_case.sh make` into a scratch `DEV_CASE` (e.g. `DEV_CASE=$WORK/audit/eaton_small`) →
    md5 of `wrfinput_d02` = `cases/eaton_small/manifest.md5`; `I_PARENT_START`/`J_PARENT_START` of the file = the
    namelist's d02 `i_parent_start`/`j_parent_start` (215, 215). Same for eaton_mid with the command in
    `cases/eaton_mid/README.md` (196, 196).
18. W-T0 on the item-5 build with the real `$WORK/cases/eaton_small` → `SUCCESS COMPLETE WRF`, run twice → `compare.sh`
    `RESULT: IDENTICAL` (a first determinism check; S0-08 does the full one).

## F. Records
19. STAGE0_HANDOFF §2 status table: every row's status agrees with the audit rows; the "Evidence" column names files
    that exist. WORKBOOK "Current state" agrees with the handoff. Each FIX_LEDGER entry's "Evidence" names a file or
    command that still exists or says where it went (RAM disk lost).
20. Commit, push, then continue with `/s0-run` from the WORKBOOK "Next step".
