# Stage 0 handoff: where it stands and how to finish it

Written 2026-10-15 for the coding agent that completes Stage 0 of
[roadmap/plan-4.6/stage-0-ground-truth.md](../../roadmap/plan-4.6/stage-0-ground-truth.md) (phases S0-00 … S0-13) on
the owner's A100 workstation. Read this file after [AGENTS.md](../../AGENTS.md) and before the workbook. It says what
is done (with evidence), what is not, and, for every open task, what to implement, how to test it and when it is
done. Task IDs are those of the stage file; read the stage file's row for each task you start.

Rules that apply to everything below (AGENTS.md):
- **Rule 12, the fix ledger:** every fix that changes or could change what the code computes, how it is built or
  how a test judges it goes into [FIX_LEDGER.md](FIX_LEDGER.md) in the same commit (entries F-01 … F-08 so far).
- `bash port/gates/static.sh` must print `== static: PASS` before every commit. Owner-directed edits of locked files
  are allowed in Stage 0, and each one needs `protected.md5` regenerated:
  `python3 -c "import sys; sys.path.insert(0,'port/tools'); import protect as p; l,i=p.files(); p.write(p.OUT,l)"`
  (never regenerate `infra.md5`; changed infrastructure files are logged in TOOL_FIXES.md instead).
- **Commit and push after every task** to `agent/s0-00` (`git push origin agent/s0-00`; SSH works). The checkout on
  the machine is the working copy; GitHub is the backup. Both must hold every change.
- Update [WORKBOOK.md](WORKBOOK.md) ("Current state" and a log entry) after every task.

---

## 1. The machine and its environment

| Item | Value |
|---|---|
| Checkout | `/home/csgrad/utkarshk/port-wrf-gpu`, branch `agent/s0-00` (remote `git@github.com:utkrshkmr/port-wrf-gpu.git`) |
| Machine | id `3817a30133b2`, profile `a100-40x2`: 2 × A100-PCIE-40GB (cc 8.0, link SYS), 2 × 28-core Xeon Gold 6330, 503 GB RAM, driver 595.91.07 |
| `$WORK` | `<checkout>/work` (git-ignored) |
| Eaton inputs | `<checkout>/EATON/input` (git-ignored; md5s match `cases/eaton_20250108/manifest.md5`); the whole CCR dataset incl. the NCAR run is in `<checkout>/EATON` (147 GB) |
| Toolchain | NVHPC installed natively (no container runtime; `CONTAINER=none`): `<checkout>/Linux_x86_64/{25.1,25.9,26.1,26.5}`. **In use: 25.1** until the decision of §3 |
| netCDF | `$WORK/deps-25.1/netcdf` (+ `netcdf-gnu`) on disk; `$WORK/deps-25.9`, `$WORK/deps-26.1` are symlinks into the RAM disk |
| Python | `$WORK/deps/pyenv` (numpy, netCDF4, mpmath) |
| GDB | `/usr/bin/gdb` |

`port/h100/env.local.sh` is **not in git**. It must contain exactly this (recreate it if it is missing):

```sh
# The owner's A100 workstation (port/agent/ENV_H100.md §2a)
_repo=/home/csgrad/utkarshk/port-wrf-gpu
export WORK=${WORK:-$_repo/work}
export CONTAINER=${CONTAINER:-none}
# NVHPC 25.1, the plan's pin (26.5 crashes on WRF at -O2: BLOCKERS B4); 26.5 stays installed next to it
export NVHPC_ROOT=${NVHPC_ROOT:-$_repo/Linux_x86_64/25.1}
export DEPS=${DEPS:-$WORK/deps-25.1}
export PYENV=${PYENV:-$WORK/deps/pyenv}
# Eaton inputs from CCR (md5s match cases/eaton_20250108/manifest.md5)
export CASE_INPUTS=${CASE_INPUTS:-$_repo/EATON/input}
export CPU_RANKS=${CPU_RANKS:-56}   # physical cores (2 x 28); env.sh would take 64 of the 112 logical CPUs
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
```

To use another NVHPC version for one command, override the three variables, e.g. for 26.1:
`NVHPC_ROOT=$PWD/Linux_x86_64/26.1 DEPS=$PWD/work/deps-26.1 NETCDF=$PWD/work/deps-26.1/netcdf bash port/h100/build.sh ...`

### Hazards of this machine (read before running anything long)

1. **The `/home` RAID10 is degraded** (`/proc/mdstat`: `md0 ... sdc[1](F) [4/2] [U_U_]`, since at least 2026-10-11).
   Heavy small-file I/O on `/home` stalls (I/O pressure ~97 %). Therefore:
   - `$WORK/builds` is a symlink to the RAM disk `/dev/shm/utkarshk-wrf/builds` (252 GB tmpfs). **Everything there
     is lost on a reboot**: builds and `deps-25.9`, `deps-26.1` must then be rebuilt (`build.sh`,
     `setup_toolchain.sh deps`; 5–10 min on the RAM disk, an hour or more on `/home`). Old on-disk builds are in
     `$WORK/builds-home`.
   - **Owner's decision (2026-10-15): references and runs go to `/home` anyway** (`$WORK/reference`, `$WORK/runs`;
     nowhere else is available), accepting the risk of the degraded array. Commit the md5 list of every archived
     reference to git (small), so a lost archive is at least known exactly. If `/home` is lost, use the segmented
     procedure of §6 instead of regenerating full archives. Never keep a reference only on the RAM disk.
2. **`make -j` crash cascades:** when one file crashes the compiler, files that USE its half-written module crash
   too. Always find the *first* crash in `compile.log` (`grep -B4 "signal 11" compile.log`) before concluding.
3. Kill jobs by PID (`kill <pid>`), never with `pkill -f <pattern>`: the pattern matches your own shell.
4. `build_cmds.py update` prints `0 files from compile.log merged` for the NVHPC builds made with `CONTAINER=none`:
   `compile_one.sh` and `harness.sh` need that database. Fix it before using them (task S0-00-FIX-1 below).

---

## 2. Status of every Stage 0 phase (2026-10-15)

Legend: **done** (evidence recorded), **partial**, **todo**. "RESULTS" = `port/RESULTS.md`, "ENV" = `port/ENVIRONMENT.md`.

| Task | Status | Evidence / what is missing |
|---|---|---|
| S0-00.1 machine.sh detect | done | `port/h100/machine.sh`, `machine.py`; samples in `port/machines/samples/` |
| S0-00.2 capabilities | done | `port/machines/capabilities.md` (generated), `test_machine.py` 7 tests PASS |
| S0-00.3 scripts read the profile | partial | build.sh (BUILD_JOBS, machine in BUILD_INFO), window.sh (fit check, `GPU_ID=auto`) done. **Missing:** running windows in parallel on several GPUs from the gates; per-GPU-model tuning files (no tuning exists yet: document that the mechanism is "a file per `gpu_key` under `port/machines/tuning/`" and leave it empty) |
| S0-00.4 t_machine.sh | done, **rerun needed** | protocol last FAILED at step b (B3, fixed since). Rerun after the compiler is pinned (§3) |
| S0-00.5 gates refuse unprotocolled machines | done | `port/gates/lib.sh`; results carry `[machine profile]` |
| S0-00.6 archives keyed by host and GPU | done | `DEV_REF=$WORK/reference/eaton_small/<host key>`, `gpu_trace_dir` (common.sh); ENV_H100.md §4 |
| S0-01.1 … .4 | done | sync_tree includers, check_deps physics_mmm, cpu_verify error lines + per-route, TOOL_FIXES rows |
| **S0-01 gate** | **todo** | `cpu_verify.sh` has never run on this machine (task S0-01-G below) |
| S0-02 land run 1 | todo | 19 `agent/wp/*` branches (origin) not merged; see S0-02 below (conflicts with the B3 rewrite) |
| S0-03 work arrays | todo | after S0-02 |
| S0-04.1 … .5 | done | ENV "GPU-M" section; `gpu_hello.sh` PASS on both GPUs; flags spell-checked; device query in `$WORK/gpu_hello/devq_*.txt` |
| S0-04.6 host STREAM bandwidth | todo | `perf/db/hw.csv` (area perf; ask the owner whether to write it from this branch) |
| S0-05 probes | done | `port/tests/acc_features` (17 probes + F-BOUND), all PASS on both GPUs with 25.1, 25.9, 26.1 except known F-BOUND; ENV table. Reviewer still has to carry the results into CODING_STANDARD.md (task S0-05-DOC) |
| S0-06 arithmetic tests | partial | full suites ran with 26.5 (before B3) and 25.1 (after B3); **rerun on both GPUs with the pinned compiler** (§3 step 3); RESULTS section exists |
| S0-07.1 CPU-REF build | done (25.1) | `$WORK/builds/cpu-ref/1da67693e368` (RAM disk), wrf.exe md5 `278297669019e185c0e6eb8902a8eb69`, NVHPC 25.1. **Redo with the pinned compiler** and record the md5 in RESULTS |
| S0-07.2 T-SYM | done (25.1) | PASS on the 25.1 worktree build; redo on the pinned build |
| S0-07.3 WPS + real.exe | partial | `real.exe` builds; WPS not built. The dev and acceptance cases are cut from the full case's inputs (make_dev_case.py), so WPS is only needed if the owner wants geogrid/metgrid runs: ask, else record "not needed" in RESULTS |
| S0-07.4 T-BUILD-REF | todo | the port's own files compile without `-w` |
| S0-08 reproducibility | todo | needs the pinned CPU-REF build and the dev references |
| S0-09.1 eaton_small | done | `cases/eaton_small/` (namelist, manifest, README); `$WORK/cases/eaton_small` |
| S0-09.2 … .4 dev references | todo | started once with 25.1 and cancelled; start after the pin |
| S0-09.5/.6 eaton_mid | done | `cases/eaton_mid/` (d02 523×523, RRTMG 2048, estimate 32.34 GB) |
| S0-09.7 eaton_mid references | todo | after the pin |
| S0-10 long references, E0, E1, Prof-CPU | todo | runs beside Stage 1; owner decides lengths after the cost table (S0-08.5) |
| S0-11 T-UNINIT | todo | `port/gates/t_uninit.sh` (gfortran netCDF is ready: `$WORK/deps-25.1/netcdf-gnu`) |
| S0-12 certify run-1 refactors | todo | after S0-02, S0-03, S0-09 |
| S0-13 sample gating cases T0/T1 | todo | generator, cases, `t_tiers.sh`, precision report |

---

## 3. First: settle the compiler (decision step 1 of FIX_LEDGER F-08)

### Why
Every reference and every bitwise comparison is tied to one compiler version (CPU-REF and GPU-REPRO must use the
same one). Two candidates remain (FIX_LEDGER F-05, F-08; RESULTS; BLOCKERS B4):

| | NVHPC 25.1 | NVHPC 26.1 |
|---|---|---|
| Builds all of WRF at `-O2` | yes | no: fort2 crashes on 11 files at `-O2`, all compile at `-O1` |
| Device code | **silent miscompile**: T-RM-POW crashes (illegal address) through the large dispatcher `eval4` of `rm_testlib.F90` | all device tests PASS |

The 11 files are listed in FIX_LEDGER F-08. Only `dyn_em/nest_init_utils.F` contains model arithmetic of `wrf.exe`.
26.1 with those 11 files at `-O1` is the preferred choice **if** compiling `nest_init_utils` at `-O1` changes no bit.

### Step 1a — implement a per-file `-O1` list in build.sh

**Done** (commit e8ce9a0, 2026-10-15; `test_agent_tools.py` PASS incl. 4 `--apply-o1` self-tests, re-checked by
the owner's session). Next: step 1b.

Today `port/h100/build.sh` appends one hard-coded line for `module_bittrace.o`. Replace it by a list:

- New file `port/h100/o1_files.txt` (infrastructure): one object name per line with a comment why, e.g.
  ```
  # Files compiled at -O1 instead of -O2 in every nvfortran build (FIX_LEDGER F-08): nvfortran 25.9/26.1/26.5
  # fort2 crashes on them at -O2. Same list in CPU-REF and GPU builds.
  module_bittrace.o
  module_dm.o
  module_cpl.o
  mediation_integrate.o
  module_optional_input.o
  wrf_timeseries.o
  module_wrf_top.o
  nest_init_utils.o
  module_initialize_real.o
  real_em.o
  tc_em.o
  ```
- `build.sh`: for nvfortran modes (not `gnu*`), read the list from `$O1_LIST` (default `port/h100/o1_files.txt`;
  `O1_LIST=none` = no file at -O1) and append for each object
  `<obj> : FCOPTIM := $(subst -O2,-O1,$(FCOPTIM))` to `configure.wrf`, after removing any earlier such lines
  (so a changed list takes effect in an existing tree; then the listed objects must be rebuilt: delete their `.o`).
- `BUILD_INFO` gets a line `o1 files: <md5 of the list or none> (<n> files)` so two builds can be told apart.
- Check `python3 port/tools/check_build_flags.py --build <dir>` on a build with the list. If it fails because of the
  target-specific `FCOPTIM` lines, extend the checker (locked tool, owner-directed): it must accept exactly
  `<obj> : FCOPTIM := $(subst -O2,-O1,$(FCOPTIM))` for objects in `o1_files.txt` and nothing else.
- Log in TOOL_FIXES.md (build.sh, o1_files.txt, the checker) and update FIX_LEDGER F-08 (exact change).
- Self-test in `port/tests/tools/test_agent_tools.py`: build.sh's list handling on a fake `configure.wrf` (the
  appended lines, idempotence, `O1_LIST=none`).

### Step 1b — prove nest_init_utils at -O1 is bit-identical (with 25.1, which compiles it both ways)

1. Two CPU-REF builds of the same commit with **25.1** (its CPU code is fine; its defect is on the device):
   ```sh
   O1_LIST=none                     bash port/h100/build.sh cpu-ref --commit HEAD --tag o2
   printf 'nest_init_utils.o\n' > $WORK/o1_nest.txt
   O1_LIST=$WORK/o1_nest.txt        bash port/h100/build.sh cpu-ref --commit HEAD --tag o1nest
   ```
   Check that only `nest_init_utils.o` differs between the two trees (`cmp` of all `.o` files; list the differing ones).
   If more objects differ, explain why before going on.
2. **Coverage:** find which `nest_init_utils` routines run in the dev case. The callers are
   `share/mediation_integrate.F` (`blend_terrain`, `adjust_tempqv`, `init_domain_constants_em`) and
   `share/mediation_nest_move.F`. Run W-T0 (below) once with 1 rank under gdb, with a breakpoint on every
   subroutine of `nest_init_utils` (`nm $b/dyn_em/nest_init_utils.o | grep ' T '` for the symbol names), and record
   which are hit.
3. **End to end:** W-T0 starts from wrfinput at 00:00 and starts the nest, 9 s, trace level 2:
   ```sh
   b1=$WORK/builds/cpu-ref/<sha12>-o2; b2=$WORK/builds/cpu-ref/<sha12>-o1nest
   bash port/h100/window.sh $b1 W-T0; bash port/h100/window.sh $b2 W-T0
   bash port/h100/compare.sh $WORK/runs/<id of b1>/W-T0 $WORK/runs/<id of b2>/W-T0
   ```
   Pass: `RESULT: IDENTICAL` (traces and every output field).
4. **Per routine** for routines W-T0 does not reach (after S0-00-FIX-1): `bash port/h100/harness.sh
   WRF/dyn_em/nest_init_utils.F <routine> --builds $b1,$b2` for `blend_terrain`, `copy_3d_field`, `adjust_tempqv`,
   `compute_eta`, `compute_vcoord_1d_coeffs`, `vert_cor_vertical_nesting_*`. If harness.sh refuses two CPU-REF
   builds, extend it (tool fix) to compare any two builds (`CPU vs CPU`).
5. Record the result in RESULTS ("Compiler decision") and FIX_LEDGER F-08 (evidence).

Decision:
- **Identical everywhere** → pin 26.1 (step 1c).
- **Any difference** → do not use 26.1 as is. Write BLOCKERS B5 with the differing fields/routines and stop for the
  owner; the options are (a) find the construct of nest_init_utils that crashes fort2 and rewrite it (a certified
  shared refactor), (b) stay on 25.1 and test every kernel on the device for the 25.1 miscompile.

### Step 1c — pin 26.1 (only if step 1b passed)

1. `env.local.sh`: `NVHPC_ROOT=$_repo/Linux_x86_64/26.1`, `DEPS=$WORK/deps-26.1`. Make `deps-26.1` persistent:
   copy `/dev/shm/utkarshk-wrf/deps-26.1` to `$WORK/deps-26.1` on `/home` (replace the symlink by the copy),
   point the symlink there, and build `deps-gnu` with 26.1 (`setup_toolchain.sh deps-gnu`).
2. Full clean CPU-REF build of HEAD with 26.1 and `o1_files.txt`: zero `signal 11`, zero `NVFORTRAN-S`; wrf.exe md5 to
   RESULTS (S0-07.1); T-SYM PASS (`x bash port/sym_audit.sh <build>`, S0-07.2).
3. Device tests with 26.1 on **both** GPUs (S0-06; the machine protocol requires them for a new compiler):
   `port/tests/repro_math/run_tests.sh` (full sizes; ~1–2 h per GPU, both in parallel; set `OMP_NUM_THREADS=28`),
   `run_ref_tests.sh nvhpc`, `acc_features/run.sh`; then `bash port/h100/machine.sh detect` and
   `bash port/gates/t_machine.sh` → PASS. Update RESULTS (S0-06 table per GPU), ENV (toolchain = 26.1, probes).
4. GPU build sanity: `build.sh gpu-repro --worktree` with 26.1 and the list; `gpu_hello.sh` PASS.
5. FIX_LEDGER F-05 (compiler = 26.1 + F-08 list), BLOCKERS B4 resolved, workbook, commit, push.

---

## 4. Then the rest of Stage 0, in this order

Each item: what to do, how to test, done when. Commit and push after each.

**S0-00-FIX-1 build_cmds with CONTAINER=none.** `port/h100/build_cmds.py update <build>` merges 0 files for
NVHPC builds made without a container (compile.log lines start with `time mpif90 ...`). Fix the parser (tool fix),
then check `compile_one.sh cpu-ref <file>` recompiles one file and `harness.sh` runs on a routine of the dev case.
Also: `build.sh` writes an `image: ... sha256` line in BUILD_INFO when `CONTAINER=none`; write it only when a
container image is used. Done when `build_cmds` reports >0 files and `compile_one.sh` works.

**S0-00.3 remainder.** Gates that run several windows (e.g. `g1.sh`, `t_reg20.sh`) start them one per free GPU
(`GPU_ID=auto` exists in window.sh) and wait; on a one-GPU profile run "GPU 0 vs GPU 1" checks as "same GPU twice".
Document the tuning-file mechanism. Test: dry runs on the three recorded profiles (`machine.py detect` on
`port/machines/samples/*` into a temp `$WORK`). Done when the stage file's "Done when" holds.

**S0-01 gate (cpu_verify).** `bash port/gates/cpu_verify.sh` on this branch (gfortran views; needs
`$WORK/deps-25.1/netcdf-gnu`, built). Expected: builds PASS, `cpu-view` vs the base: see note, `gpu-view` PASS
(S-3M), `ref_tests` PASS. Note: the base of `cpu_verify` defaults to the merge base with the handoff branch, which
predates B3, so `cpu-view` will differ by design (B3 is not bit-neutral); run it with `--base $(cpu_view_base)`.
Record in RESULTS. Fix what fails (ledger entry if it changes numbers).

**S0-02 land run 1.** Merge the 19 `origin/agent/wp/<id>` branches into a local `agent/code` (Phase 1 packages
first, then 2, 3, 4, 5; `cpu_verify.sh` after each group). Specific to this branch:
- The B3 rewrite (`rp_subst.py`) touched the same WRF files. On a conflict in an in-scope file
  (`port/rp_subst_files.txt`): take the work package's version of the file, then rerun
  `python3 port/rp_subst.py <file>` (idempotent) so MAX/MIN and powers are rewritten in the CPU **and** GPU code
  alike; `arith_guard.py` then checks that GPU statements still equal the CPU statements.
- Run-1 kernels must not put `rp_min`/`rp_max` (or any procedure) in a bound of a collapsed loop (F-03): after
  rp_subst, DO bounds keep `MIN`/`MAX`; check every `!$acc ... collapse` loop of the merged files.
- Then tasks S0-02.2 … S0-02.8 as in the stage file. Gate: both gfortran views build, S-3M bitwise in `cpu-view`
  and `gpu-view`, harness CPU vs DEVICE for the run-1 kernels on the smoke path.

**S0-03 work arrays and the step bracket** as in the stage file (gate: `cpu_verify.sh` PASS in full).

**S0-04.6** host STREAM bandwidth (ask the owner whether to write `perf/db/hw.csv` from this branch or a perf card).

**S0-05-DOC** carry the probe results and fallbacks into CODING_STANDARD.md: statement functions, internal
procedures, OPTIONAL, CHARACTER allowed in device code; module PARAMETER arrays in `acc routine` need a local copy
for gfortran; never a procedure call in a collapsed loop bound (F-BOUND); `NV_ACC_CUDA_STACKSIZE` works.

**S0-07.3/.4** WPS (ask whether needed) and T-BUILD-REF: compile the port's own files (`port/agent/` lists them:
`module_gpu_*`, `module_bittrace`, `module_repro_math`, ...) with the CPU-REF flags without `-w`; no warnings.

**S0-09.2 … .4 dev references** (on `/home`, owner's decision; see hazards):
`bash port/h100/dev_case.sh reference <pinned CPU-REF build of the base commit>` under nohup (hours; writes
`$DEV_REF/run0220` and `win1h`), then S0-09.3 (17 h dev run) and S0-09.4 (`manifest.py check`; every window of
`windows.txt` once with CPU-REF). Done when `dev_case.sh status` shows both references OK and every window has a run.

**S0-08 reproducibility** (T-DET twice the same; T-DEC-A 1 vs 56 ranks; T-DEC-B 14/28/56 ranks; T-RST restart vs
continuous; the cost table; the CPU profile with `prof_cpu.sh`), each with its gate script where one exists
(`t_dec.sh`) and RESULTS rows.

**S0-09.7, S0-10** eaton_mid references and the long runs (owner sets lengths after the cost table).

**S0-11 T-UNINIT** `bash port/gates/t_uninit.sh` on W-T0 (gfortran builds with NaN and zero fills).

**S0-12** certify the nine run-1 refactor families (after S0-02/S0-03 and the dev references), as in the stage file.

**S0-13** sample gating cases: `port/make_test_cases.py t0` (four ideal cases), T1 from the owner's small fire inputs
(ask for them), CPU-REF references at 1 and 8 ranks, `windows.txt` entries and `port/gates/t_tiers.sh` (locked:
owner-directed), the precision report of `compare_fields.py --report`, cpu_verify and t_reg20 running T0. Gate:
every T0/T1 case bitwise CPU-REF vs GPU-REPRO with every route off, on both GPUs.

**Stage gate G0** (stage file, last section): check every item and write the G0 summary in RESULTS.

---

## 5. Scope reminder (owner, 2026-10-15)

The port is **`wrf.exe` only**. WPS and `real.exe` stay precompiled CPU programs that produce the input files
([ADR-007](../../roadmap/decisions/ADR-007-wps-real-port.md), deferred). Do not start work on them.

## 6. Fallback if `/home` is lost: segmented comparison on the RAM disk

The RAM disk (`/dev/shm`, 252 GB, volatile) cannot hold a 17 h reference archive, but a bitwise comparison does
not need the whole archive at once. What the gates compare is (a) the bit-trace files (`bittrace.d0X.txt`:
small text, one hash line per field and step) and (b) the history and restart fields of a window. Both can be
produced and compared segment by segment, keeping only what the next segment needs.

Procedure (implement as `port/h100/segment_compare.sh` when first needed; infrastructure, tool fix logged):

1. `export WORK_RUNS=/dev/shm/utkarshk-wrf/runs` and make `window.sh`/`dev_case.sh` put run directories under it
   (a `RUNS_DIR` variable in `common.sh`, default `$WORK/runs`); keep `$WORK` itself on a persistent disk for the
   small files (gate results, md5 lists, traces).
2. Segment the run into chained restart windows of at most the model time whose outputs fit the RAM disk with
   room for both builds (for `eaton_small` an hour per segment is a few GB per build; for `eaton_mid` size it from
   one history file). Segment k starts from the restart files written at the end of segment k−1.
3. For each segment, in order: run CPU-REF (host, `$CPU_RANKS` ranks) and GPU-REPRO (one GPU) from the same restart
   files; `compare.sh` the two run directories (traces, every history and restart field); append the result line and
   the md5 list of both runs' outputs to a persistent log (`$WORK/gates/.../results.txt`, `$WORK/reference/<case>/
   <host key>/segments.md5`); copy both builds' bit-trace files to `$WORK/reference/...` (small); then delete every
   output of segment k−1 and keep only segment k's final restart pair (CPU-REF's; after a bitwise PASS the GPU's are
   identical).
4. A segment that is not bitwise stops the chain: keep its two run directories for DEBUGGING.md, do not go on.
5. The archived "reference" is then the persistent small set: md5 lists, bit-trace files, results, plus the last
   restart pair. A full-field archive can be rebuilt later by rerunning CPU-REF from any kept restart.

Also run the CPU-REF reproducibility tests of S0-08 this way when needed (T-DET: the same segment twice; T-DEC:
the same segment with different rank counts).

## 7. Where to look

| Question | File |
|---|---|
| Why a fix was made, what it changed | `port/agent/FIX_LEDGER.md` |
| Open problems | `port/agent/BLOCKERS.md` (B1–B4 resolved; B4 decision pending in F-08) |
| Toolchain, probes, device query | `port/ENVIRONMENT.md` |
| Test results | `port/RESULTS.md` |
| Machine profile and capabilities | `bash port/h100/machine.sh show`, `port/machines/capabilities.md` |
| CPU-view base moves | `port/agent/REFACTORS.md` (base `1f1f452835c4`, B3) |
| Infrastructure tool fixes | `port/agent/TOOL_FIXES.md` |
| Logs of the work so far | `$WORK/logs/` (builds, rp_subst runs, crash classification, static runs) |
| Compiler-crash reductions | `/dev/shm/utkarshk-wrf/red2/` (RAM disk; `crash.sh`, `reduce.py`) |
