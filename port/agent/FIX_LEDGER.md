# Fix ledger

Every fix made to get the port running that changes, or could change, what the code computes, how it is
built, or how a test judges it. One entry per fix, with the exact change, so that if numbers do not match
(between builds, machines, compilers, or against an archived reference) the cause can be found by reading
this file instead of reconstructing history. Newest last; never delete an entry; mark a fix that is later
undone `[reverted <date>: <how>]`.

Each entry:
- **What failed:** the symptom, with the command and the output.
- **Root cause:** what was actually wrong.
- **Exact change:** commit(s), files, and the change itself (a diff for small changes; for mechanical
  rewrites, the command that reproduces them, and how many sites changed).
- **Effect on numbers:** whether model results can change, by how much, and in which build (CPU-REF,
  GPU-REPRO, gfortran views).
- **Evidence:** the tests that show the fix works and how far it moves results.
- **If numbers do not match:** what to check first.

Related records:
- [REFACTORS.md](REFACTORS.md): CPU-view base moves;
- [TOOL_FIXES.md](TOOL_FIXES.md): infrastructure tool fixes;
- [BLOCKERS.md](BLOCKERS.md): open problems;
- [port/ENVIRONMENT.md](../ENVIRONMENT.md): toolchain versions and probe results;
- [port/RESULTS.md](../RESULTS.md): test results.

Machine: A100 workstation `3817a30133b2` (profile `a100-40x2`), checkout `/home/csgrad/utkarshk/port-wrf-gpu`,
branch `agent/s0-00`.

---

## F-01 2026-10-11 MIN/MAX of signed zeros differ between host and GPU → rp_max/rp_min

- **What failed:** `port/tests/repro_math/run_tests.sh` (T-SIGNZERO/T-MINMAX specials REAL(4)): 3 of 6912 values
  differ, identically on GPU 0 and GPU 1, with NVHPC 26.5 (2026-10-10) and again 25.1, 25.9 and 26.1. For equal
  zeros, the host returns one operand and the device orders −0 < +0: `MIN(+0,−0)` is +0 on the host and −0 on the
  device. The host is not even self-consistent: in a plain scalar loop `MAX(+0,−0)` gives −0, in the T-IEEE loop
  +0 (`$WORK/b3/mm.F90`).
- **Root cause:** MIN/MAX of equal values (and NaN) are processor-dependent in Fortran; nvfortran's host code and
  its device code choose differently. A −0 where the reference has +0 is one differing bit.
- **Exact change:** commits `75c28b7` (module and rewrite) and `1f1f452` (DO-bound rule, see F-03); CPU-view base
  moved to `1f1f452` in `45ee341`.
  - `WRF/frame/module_repro_math.F`: new generics `rp_max`, `rp_min` (specifics REAL(4), REAL(8), INTEGER(4),
    INTEGER(8), with 2, 3 and 4 arguments). With `-DREPRO_MATH` the REAL specifics are, for `rp_max(a,b)`:
    `a>b → a; b>a → b; a==b → (sign bit of a set ? b : a); b is a number → b; a is a number → a; else the
    canonical NaN` (`rp_min` mirrored: equal → sign bit of a set ? a : b). So −0 < +0, a NaN argument is skipped,
    two NaNs give Z'7FC00000' / Z'7FF8000000000000'. 3 and 4 arguments are taken left to right. INTEGER
    specifics are `MAX`/`MIN`. Without `REPRO_MATH` every specific is the intrinsic.
  - The in-scope files (`port/rp_subst_files.txt`, 49 files) rewritten by `port/rp_subst.py`: `MAX MIN AMAX1 AMIN1
    DMAX1 DMIN1` → `rp_max`/`rp_min`, except in DO-loop bounds. 2377 calls rewritten, 1182 in DO bounds kept.
    Reproduce: `git checkout ae18264 -- <the files>; cd WRF; python3 ../port/rp_subst.py <files>` (the tool is
    idempotent and deterministic). Log of the run: `$WORK/logs/rp_subst_b3_v2.log`.
  - The reference-test copies of WRF code rewritten the same way (`port/tests/pdlim/t_pdlim.F90`,
    `port/tests/templates/t_tmpl_{b,c,g,cp}.F90`; 58 calls) and linked with module_repro_math (their Makefiles,
    `port/tests/mutants_lib.py`), in `45ee341`.
- **Effect on numbers:** CPU-REF changes only where MAX/MIN see equal zeros or NaN (on 2^27 random host pairs
  `rp_max/rp_min` = `MAX/MIN` exactly). Host and device now agree by construction. Not bit-neutral against the old
  base; no CPU-REF reference existed on this machine before it.
- **Evidence:** T-IEEE with `rp_max/rp_min` plus their rules (`T-MINMAX rules of rp_max/rp_min`) PASS on GPU 0 and 1
  with 25.1, 25.9 and 26.1; `run_ref_tests.sh nvhpc` PASS (mutants caught) on GPU 0 and 1.
- **If numbers do not match:** check that both builds use the same `module_repro_math.F` and `-DREPRO_MATH`
  (`ARCH_LOCAL` in `configure.wrf`); that no `MAX(`/`MIN(` outside DO bounds remains in an in-scope file
  (`python3 port/rp_subst.py --check <file>`); a −0/+0 difference in a field points here.

## F-02 2026-10-11 Integer powers x**n differ between host and GPU → explicit products

- **What failed:** T-IPOW: 3 984 817 592 of 6 576 668 672 values differ (26.5, both GPUs); `x**3`, `x**4`, `x**8`,
  `x**(-1.0)` and `rp_pow(x,n)` for n = −8..32 except 0, 1 (`x**2` is equal).
- **Root cause:** nvfortran (25.1, 25.9, 26.1, 26.5) compiles host integer powers to calls of its CPU math library
  (`__py_powi1_4`, `__pmth_i_dpowi`, `__gd_pow_4_p`, `__pd_powi1_4`, ...; `nm` shows them), which round correctly,
  while device code multiplies (`x**3` = `(x*x)*x`). Example x = Z'3F164CC2': host Z'3E4F3B3D', device Z'3E4F3B3E'.
  The library symbols would also fail T-SYM.
- **Exact change:** commits `75c28b7`, `1f1f452`; base `1f1f452`.
  - `module_repro_math.F`, with `REPRO_MATH`: `rp_pow_r4i4`, `rp_pow_r8i4` are `m = |n|; m = 0 → 1; else p = x,
    then p = p*x (m−1 times, left to right); n < 0 → 1/p, else p`. INTEGER base (`rp_pow_i4i4`) stays `x**n`.
  - `port/rp_subst.py`: only exponents 0, 1, 2 stay powers (literal, or named constant with that value); every other
    integer exponent and a REAL constant −1 → `rp_pow`. 66 powers in the in-scope files; afterwards
    `port/ipow_scan.py` finds only `**2` (347).
- **Effect on numbers:** CPU-REF changes: `rp_pow(x,3/4/8)` differs from the old host `x**n` in 2.4 / 3.8 / 6.8 % of
  values by at most 1 / 2 / 4 ulps (host, 2^27 values, `$WORK/b3/ev.F90`). S-3M (gfortran CPU view, first version
  of the rewrite) differs from the pre-refactor run from step 1, first in RTHRATEN (RRTMG uses `**4`), and runs to
  completion (`$WORK/logs/s3m_compare_b3.txt`).
- **Evidence:** T-IPOW (rewritten forms) PASS on GPU 0/1 with 25.1, 25.9, 26.1; T-SYM PASS on the 25.1 CPU-REF build.
- **If numbers do not match:** an integer power left in an in-scope file (`python3 port/ipow_scan.py`), or a file
  that is not in `rp_subst_files.txt` but runs in the case.

## F-03 2026-10-11 rp_min in a collapsed-loop bound runs no iteration on the GPU → DO bounds keep MIN/MAX

- **What failed:** after the first rewrite (`75c28b7`), T-TMPL-C (29640 values) and T-TMPL-G (162975 values) failed
  on the GPU only; the gfortran host runs passed.
- **Root cause:** with NVHPC 25.1 and 26.5 (also 25.9, 26.1), `rp_min(...)` in the inner bound of a `collapse(2)`
  loop with variable lower bounds and `default(none)` runs no iteration, silently (`$WORK/b3/lb4.F90`: sum 0 instead
  of 1044). The same loop with intrinsic `MIN` works, and with a second kernel in the program it can work too: the
  behaviour depends on context.
- **Exact change:** `port/rp_subst.py` (`DO_STMT`, `rewrite_calls(..., in_do=...)`): MAX/MIN in a DO statement stay
  intrinsics (loop bounds are INTEGER, exact). WRF rewrite redone from `ae18264` → `1f1f452`. Probe
  `port/tests/acc_features/f_bound.F90` records the bug; `run.sh` lists it in `KNOWN` (reported, not fatal).
- **Effect on numbers:** none (integer bounds); it removes a wrong-iteration-count bug.
- **Evidence:** T-TMPL-C/G PASS again; F-BOUND reproduces on GPU 0/1 with every version tested.
- **If numbers do not match:** a kernel that does too few iterations: look for a procedure call in a bound of a
  collapsed loop (rule in CODING_STANDARD.md: never).

## F-04 2026-10-11 isnan is not an NVHPC intrinsic → ieee_is_nan in module_wind_mav.F

- **What failed:** `NVFORTRAN-S-0038-Symbol, isnan, has not been explicitly declared (module_wind_mav.f90: 1166)`
  in the CPU-REF build (25.1, 25.9, 26.1, 26.5 all reject `isnan`).
- **Exact change:** `75c28b7`, `WRF/phys/module_wind_mav.F`, function `find_turb`:
  ```
  +  use, intrinsic :: ieee_arithmetic, only: ieee_is_nan   ! isnan is not an NVHPC 26.5 intrinsic (GPU port)
  -      if (isnan(angle)) then
  +      if (ieee_is_nan(angle)) then
  ```
- **Effect on numbers:** none (same test; the wind-farm scheme is not used by the Eaton case).

## F-05 2026-10-11 Compiler: NVHPC 25.1 for builds (26.5 cannot build WRF)

- **What failed:** with 26.5 (the owner's install) the CPU-REF build stops: `fort2 TERMINATED by signal 11` on 22
  files; 25.9 and 26.1 the same (see F-08 for the cause).
- **Exact change:** NVHPC 25.1 (the plan's pin, ENV_H100.md §1) installed in `<checkout>/Linux_x86_64/25.1`;
  `port/h100/env.local.sh` (not in git) sets `NVHPC_ROOT=<checkout>/Linux_x86_64/25.1`,
  `DEPS=$WORK/deps-25.1` (netCDF built with 25.1). Commit `ae18264` records it (ENVIRONMENT.md, BLOCKERS B4).
- **Effect on numbers:** every NVHPC result depends on the compiler version; CPU-REF and GPU-REPRO must use the same
  one, and an archived reference is valid only for its version (`machine.sh` records the compiler, F-07).
- **Known defect of 25.1:** T-RM-POW crashes on the device (CUDA_ERROR_ILLEGAL_ADDRESS in `rp_atan2_r4` reached
  through the large dispatcher `eval4` of `rm_testlib.F90`; small dispatchers and direct calls work). 25.9 the same;
  26.1 and 26.5 pass. Compiler sweep in progress (F-08).
- **If numbers do not match:** compare `nvfortran --version` in both builds' `BUILD_INFO` (`compiler:` line).

## F-06 2026-10-11 Mutants built with OpenMP flags → OpenACC flags

- **What failed:** after F-01 the mutants of the reference tests did not compile (no module_repro_math); reading
  `port/tests/mutants_lib.py` showed nvhpc mutants were built with `-mp=gpu` (OpenMP) and gnu with `-fopenmp`, so
  the OpenACC kernels of a mutant ran on the host.
- **Exact change:** `45ee341`, `mutants_lib.py`: flags `-acc=gpu` / `-fopenacc` (as the test Makefiles);
  module_repro_math compiled once (REPRO_MATH) and linked when the test source USEs it.
- **Effect on numbers:** none on the model; the negative controls now run where the tests run.

## F-07 2026-10-11 Machine records: compiler version, and a FAILED protocol reported as passed

- **What failed:** `machine.sh detect` printed "protocol passed" after a FAILED protocol; switching 26.5 → 25.1 did
  not trigger the machine-change protocol, although the device tests hold for one compiler.
- **Exact change:** `ae18264`, `port/h100/machine.sh`, `machine.py` (compiler recorded, `diff` reports `compiler`),
  `port/gates/t_machine.sh` (device-test key `<gpu>-<driver>-nvfortran<version>`).
- **Effect on numbers:** none; references and device tests are now tied to the compiler that made them.

## F-08 2026-10-11 fort2 crashes at -O2 (NVHPC 25.9, 26.1, 26.5): 12 files at -O1   [resolved 2026-10-17: NVHPC 26.1 approved; list and rules corrected 2026-10-17, see "Corrections"]

- **What failed:** the CPU-REF build with 26.5, 25.9 and 26.1: `fort2 TERMINATED by signal 11` on 22 files.
- **Root cause (found 2026-10-11):** only the first crash is real: `frame/module_bittrace.f90` (the port's
  bit-tracer). Every later crash is a file that USEs a module left half-written by it; such a file compiles
  normally once rebuilt alone (checked: `module_comm_dm.f90`). In module_bittrace the crash needs `-O2` (not
  `-O1`/`-O0`; `-Mrecursive`, `-Mvect=noassoc`, `-Kieee`, `-tp=haswell` do not matter) and the inlining of several
  helpers into each other: a procedure-level reduction keeps `bt_field3`, `want`, `upcase` (automatic-length
  character result), `emit`, `emit_id` (MPI_Allreduce + OPEN + WRITE); removing any one of them, or the MPI call,
  the OPEN or the WRITE, avoids the crash in the reduced module, but in the full module other combinations still
  crash, also with `!DIR$ NOINLINE` on all five helpers and with `upcase` as a subroutine. Reduction files:
  `/dev/shm/utkarshk-wrf/red2/` (RAM disk, lost on reboot).
- **Exact change:** `port/h100/o1_files.txt` lists the 11 files compiled at -O1 instead of -O2 in every nvfortran
  build (not gnu). `port/h100/build.sh` reads `$O1_LIST` (default `port/h100/o1_files.txt`; `O1_LIST=none` turns it
  off) and appends for each object:
  ```
  <obj> : FCOPTIM := $(subst -O2,-O1,$(FCOPTIM))
  ```
  (idempotent; deletes `.o` of affected files if the list changes in an existing tree; `BUILD_INFO` records `o1 files:`).
  All other files keep `-O2`.
- **Effect on numbers:** none on the model: module_bittrace computes only integer hashes of fields (exact at any
  optimization level) and is compiled the same way in CPU-REF and GPU builds. The trace hashes it writes must be
  identical with and without the override (to be checked once a build exists).
- **Evidence:** with the override, `module_bittrace.o` compiles with 26.1, but the clean build still has 20
  crashes and an incremental resume 21: module_bittrace was not the only real crash.
- **Classification (2026-10-11, NVHPC 26.1, `$WORK/logs/classify_crashes.sh` → `classify_crashes.txt`):** every
  file that crashed in the build, recompiled alone with its exact logged command after the build, at -O2 and -O1:

  | File | Alone at -O2 | Alone at -O1 | In wrf.exe model arithmetic? |
  |---|---|---|---|
  | frame/module_bittrace.f90 | crash | ok | no (integer trace hashes) |
  | frame/module_dm.f90 | crash | ok | no (MPI halo/communication layer; moves data) |
  | frame/module_cpl.f90 | crash | ok | no (coupler stubs) |
  | share/mediation_integrate.f90 | crash | ok | no (I/O and driver mediation) |
  | share/module_optional_input.f90 | crash | ok | no (input) |
  | share/wrf_timeseries.f90 | crash | ok | no (time-series diagnostics output) |
  | main/module_wrf_top.f90 | crash | ok | no (top-level driver) |
  | dyn_em/nest_init_utils.f90 | crash | ok | **yes** (nest initialization; in rp_subst_files.txt) |
  | dyn_em/module_initialize_real.f90 | crash | ok | no (real.exe only) |
  | main/real_em.f90 | crash | ok | no (real.exe only) |
  | main/tc_em.f90 | crash | ok | no (tc.exe only) |
  | share/module_trajectory.f90, share/start_domain.f90, phys/module_fr_fire_model.f90, dyn_em/adapt_timestep_em.f90 | ok | ok | crashed only during the build (side effects of the parallel build) |

  Not the cause: the MPI headers (module_cpl crashes with 26.1 against HPC-X 2.20's mpif.h of 25.1 too), make
  parallelism (crashes are reproducible alone), `-Mrecursive`/`-Mvect=noassoc`/`-Kieee`/`-tp=haswell`.
- **Decision (resolved 2026-10-17, Step 1b):** NVHPC 26.1 with the 11 files in `port/h100/o1_files.txt` at -O1.
  Bitwise verification with NVHPC 25.1 comparing clean build 5c51e28ccc52-o2 (all -O2) against 5c51e28ccc52-o1nest (nest_init_utils.o at -O1):
  1. Object disassembly diff across all 707 `.o` files: 705 files have 100% identical machine code; only dyn_em/nest_init_utils.o (explicit -O1 vs -O2) and share/set_timekeeping.o (length of __FILE__ tag: 15 vs 19 chars) differ.
  2. End-to-end W-T0 run (9s model time, 27 nest steps) with hand-patched eaton_small (attributes 215/215): compare.sh confirmed RESULT: IDENTICAL / PASS across all 1,269 d01 records, 14,175 d02 nest records, and all 4 history/restart NetCDF output files.
  3. Per-routine harness tests: copy_3d_field (PASS), blend_terrain (PASS), adjust_tempqv (PASS), compute_eta (PASS), compute_vcoord_1d_coeffs (PASS) bit-for-bit identical.
- **Corrections (2026-10-17, owner's session), found by the first full 26.1 build with the list
  (`$WORK/builds/cpu-ref/0a55046de6f0`, step 1c; `compile.log` lines 2840, 4944, 4982):**
  1. **A 12th real crash, `share/dfi.F`** (digital filter initialization): alone, with its logged command, 26.1
     crashes at -O2 and compiles at -O1. The 2026-10-11 classification missed it: `classify_crashes.sh` took the
     file name from the 4 log lines before each `signal 11`, and with `make -j 2` those lines belonged to the
     interleaved `mediation_wrfmain` compile (which compiles fine alone). Method from now on: a crashed file is one
     whose `time mpif90 -o X.o` has no `X.o` after the build (missing-object check, `.agent/workflows/s0-audit.md` B5).
     `dfi.o` added to `o1_files.txt`. DFI runs only with `dfi_opt > 0`; the Eaton cases leave it at 0.
  2. **Rules that did not apply.** `main/Makefile` builds `../main/module_wrf_top.o` and real.exe builds
     `../dyn_em/module_initialize_real.o`; a rule `module_wrf_top.o : FCOPTIM := ...` does not match a target
     named with a path, so both were compiled at -O2 and crashed (in the 25.1 builds of step 1b this did not show:
     25.1 compiles them at -O2, and only `nest_init_utils.o`, built without a path, was listed). `build.sh`
     `apply_o1_list` now writes for each object `<obj> : FCOPTIM := $(subst -O2,-O1,$(FCOPTIM))` **and**
     `%/<obj> : FCOPTIM := ...`, and deletes the listed objects whenever the rules change. Self-test 5 of
     `test_agent_tools.py` runs make on a path-prefixed target. Check in any build: every listed object's
     `time mpif90 -o ...<obj> -c -O1` line in `compile.log`.
  3. **Effective level.** Every -O1 compile prints `nvfortran-Info-Switch -Mvect forces -O2` (the locked
     `-Mvect=noassoc` asks for the vectorizer, which NVHPC runs at -O2). The result is still not -O2: the machine
     code of `nest_init_utils.o` differs from its -O2 build and the 12 crashes disappear. The proof of step 1b is
     for exactly this flag combination, which is what every build uses; this note only says "-O1" here means
     "-O1 with -Mvect=noassoc".
- **If numbers do not match:** check the per-file `FCOPTIM` lines in both builds' `configure.wrf`.

## F-09 2026-10-17 dev-case cut wrfinput_d02 I_PARENT_START and J_PARENT_START metadata fix

- **What failed:** WRF startup with `work/cases/eaton_small` and `work/cases/eaton_mid` failed with fatal error:
  `Nest start locations do not match: namelist.input vs gridded input file`.
- **Root cause:** `port/make_dev_case.py` calculated `new_ips` and `new_jps` (215 for `eaton_small`, 196 for `eaton_mid`)
  and updated `namelist.input`, but `cut()` copied global NetCDF attributes `I_PARENT_START` and `J_PARENT_START` directly
  from full `wrfinput_d02` where both were 180.
- **Exact change:** `port/make_dev_case.py`: `cut()` updated to take `new_ips, new_jps` and set `atts["I_PARENT_START"] = np.int32(new_ips)`
  and `atts["J_PARENT_START"] = np.int32(new_jps)`. Regenerated `eaton_small` (`dev_case.sh make`) and `eaton_mid`
  (`make_dev_case.py --n 523`). Updated `cases/eaton_small/manifest.md5` (wrfinput_d02 `f6e205a52aba9673981b6b31c1516034`)
  and `cases/eaton_mid/manifest.md5` (wrfinput_d02 `ecdbd81a88c8adfcd2fbba13e2cda4b8`).
- **Effect on numbers:** None. All variable arrays, coordinates and grid dimensions in `wrfinput_d02` are 100% bit-for-bit
  identical (verified across every variable in both cases); only the two global scalar metadata attributes were modified.
- **Evidence:** Variable-by-variable comparison of `wrfinput_d02` against the previous cut confirmed 0 variable differences
  and exactly 2 attribute differences (`I_PARENT_START`, `J_PARENT_START`). WRF nest initialization in `W-T0` passes with `RESULT: IDENTICAL`.
- **If numbers do not match:** check `ncdump -h wrfinput_d02 | grep PARENT_START` against `namelist.input`.

## F-10 2026-10-17 WRF builds ran at make -j 2: build.sh now passes -j 20

- **What failed:** every WRF build since 2026-10-10 took about 40 min: `compile.log` line ~22 says
  `badly formed -j option for parallel make: -j 56` / `setting parallel make -j 2`.
- **Root cause:** WRF's `compile` (csh, `WRF/compile` lines 437–448) accepts `J="-j N"` only for 2 ≤ N ≤ 20 (or 1)
  and otherwise falls back to `-j 2`; `build.sh` passed `-j $BUILD_JOBS` = 56 (the host's cores).
- **Exact change:** `port/h100/build.sh`: `make_jobs=$(( BUILD_JOBS > 20 ? 20 : BUILD_JOBS ))`, `J='-j $make_jobs'`
  for `./compile em_real` and `em_fire`; `BUILD_INFO` line `build jobs: <make -j> (make -j; BUILD_JOBS <n>, ...)`.
- **Effect on numbers:** none expected: parallelism changes the order of compiles, not their commands. Risk: a
  missing dependency in WRF's makefiles could let a file read a `.mod` before it is written (a crash or a
  missing object, not a silent change); the missing-object check of every build catches that.
- **Evidence:** the 26.1 CPU-REF builds of commit `0a55046` at `-j 2` (`$WORK/builds/cpu-ref/0a55046de6f0`, the
  agent's step 1c build) and at `-j 20` (`$WORK/builds/cpu-ref/0a55046de6f0-j20`): see the result line below.
- **If numbers do not match:** compare the two builds' objects with `objdump -d` (skip the 3 header lines, which
  name the file); a difference in one object points at a make-order dependency of that file.
