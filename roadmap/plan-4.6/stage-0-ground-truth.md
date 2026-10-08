# Stage 0 — Ground truth

Goal: a trusted starting point before any further GPU work.
- The CPU check works.
- The code of run 1 is landed.
- The toolchain on the A100 workstation is known.
- The CPU reference is reproducible and archived, **on the workstation's own host cores**
  ([ADR-006](../decisions/ADR-006-machines.md): nothing runs on CCR; CPU-REF and GPU-REPRO are compared on one
  machine).
- The dev case `eaton_small` and the acceptance case `eaton_mid` exist with their references.
- Every shared refactor is certified bitwise.

Ladder, gates and machines: [README.md](README.md). Task sizes: S ≤ ¼ day, M ≤ ½ day.

---

## S0-01 · Make the CPU check trustworthy

| | |
|---|---|
| Changes | `port/gates/cpu_verify.sh`, `port/h100/build.sh`, `port/tools/check_deps.py` (locked tools: owner/reviewer only, logged) |
| Machine | CLOUD |
| Depends | — |

| Task | What | Size | Done when |
|---|---|---|---|
| S0-01.1 | `build.sh --worktree`: rebuild the users of an include file when it changed (touch `module_gpu_work.F` when any `inc/gpu_work_*.inc` is newer than its object; same for island includes), or make `cpu_verify.sh` pass `--clean` | S | a changed `gpu_work_<id>.inc` is compiled on the next `--worktree` build |
| S0-01.2 | `check_deps.py`: resolve `physics_mmm/<x>.o` as written in `phys/` entries (false D1 on `mp_wsm6`, `sf_sfclayrev`) | S | `check_deps` on run-1 code reports only real gaps; self-test case added |
| S0-01.3 | `cpu_verify.sh`: report each build's first compile errors in its result line, and keep the `gnu-gpu` S-3M run separate per route when it stops on an unported option | S | the result file names the failing file and line |
| S0-01.4 | Regenerate `protected.md5`; `test_agent_tools.py` PASS; log the three fixes in `TOOL_FIXES.md` | S | `static.sh` PASS on the handoff branch |

**Gate S0-01:** `cpu_verify.sh` on the unchanged handoff gives: builds PASS, `cpu-view` PASS, `gpu-view` PASS
(S-3M), `ref_tests` PASS.

## S0-02 · Land the code of run 1

| | |
|---|---|
| Changes | merges of `agent/wp/<id>` (19 branches) into `agent/code`; `WRF/main/depend.common` |
| Machine | CLOUD |
| Depends | S0-01 |

| Task | What | Size | Done when |
|---|---|---|---|
| S0-02.1 | Scope check of each branch against `f34c479` (done once at review: 19 × PASS); repeat after every fix | S | 19 × PASS |
| S0-02.2 | Dependencies requested by the packages: `module_gpu_tables.o` ← `module_ra_rrtmg_lw.o`; fire driver/model ← `module_wrf_error.o`; `module_fr_fire_driver_wrf.o` ← `module_fr_fire_phys.o`, `module_gpu_route.o`; `mediation_force_domain.o` ← `module_gpu_map.o` | S | `check_deps` PASS |
| S0-02.3 | Scope request P4-MODEL: `set_flags` public in `module_fr_fire_driver.F` (hoist into `fire_driver_em_init`) | S | decided and applied by the reviewer |
| S0-02.4 | Scope request P3-RADDRV: INTEGER work arrays (`gpu_work_alloc_i`, `gpu_work_check_i`) in P1-WORK; move the inline ALLOCATE of `cldfra1_flag`, `mask_loc`, `kupper` | S | interface I-3 extended; P3-RADDRV include uses it |
| S0-02.5 | Open boundaries in `advect_u`, `advect_scalar`, `advect_scalar_pd`: port the open-boundary branches as P2-B2/P2-B3 did (the smoke case S-3M uses open boundaries), instead of `wrf_error_fatal` | M | S-3M runs in the `gnu-gpu` build |
| S0-02.6 | Tool questions of P5-FORCE: `check_generated.py` C4b (the `imask_*` exclusion) and C6 (section form of `gpu_map` calls) against PHASE5 P5.2; fix the checker or the card | S | decision in TOOL_FIXES.md or BLOCKERS.md |
| S0-02.7 | Read every "Questions and blockers" entry of the 19 status files; answer each in the status file or turn it into a task of its phase below | M | no unanswered question |
| S0-02.8 | Merge order: Phase 1 packages, then 2, 3, 4, 5; `cpu_verify.sh` after each group | M | `agent/code` = handoff + 19 packages; cpu_verify PASS except items listed in BLOCKERS.md |

**Gate S0-02:**
- `agent/code` builds both gfortran views;
- S-3M is bitwise in both comparisons (`cpu-view`, `gpu-view`);
- the run-1 kernels on the smoke path pass `harness.sh` (CPU vs DEVICE on CLOUD);
- the reviewer merges `agent/code` into the handoff branch.

## S0-03 · Work arrays and the step bracket first

The CPU view of every shared refactor of run 1 reads pointers into `module_gpu_work` arrays. Those arrays exist only
after P1-WORK and the `gpu_work_ensure` call of P1-SYNC (I-3). This phase is therefore a prerequisite of S0-12.

| | |
|---|---|
| Changes | `WRF/frame/module_gpu_work.F` (P1-WORK); the `gpu_work_ensure` call in `solve_em.F` (P1-SYNC, allowed CPU-view addition) |
| Machine | CLOUD |
| Depends | S0-02 |

| Task | What | Size | Done when |
|---|---|---|---|
| S0-03.1 | `gpu_work_ensure`, `gpu_work_alloc_r`, `gpu_work_alloc_i`, `gpu_work_check_r/_i`: host part (allocate, zero-fill); device part under `WRF_GPU` (`!$acc enter data create` + device zero fill) | M | compiles in both views |
| S0-03.2 | `gpu_selftest_work` (T-WORK, host part) | S | prints PASS on S-3M with `WRF_GPU_SELFTEST=1` |
| S0-03.3 | `CALL gpu_work_ensure(ims,ime,jms,jme,kms,kme)` in `solve_em` before the first routine of the step | S | `arith_guard` PASS (allowed addition) |
| S0-03.4 | S-3M: CPU view with the run-1 refactors vs the base CPU view | S | bitwise (`cpu_verify` `cpu-view`) |

**Gate S0-03:** `cpu_verify.sh` PASS in full.

## S0-04 · Toolchain on WS-A100

| | |
|---|---|
| Changes | `port/ENVIRONMENT.md`; infrastructure fixes logged in `TOOL_FIXES.md` |
| Machine | WS-A100 |
| Depends | — |

| Task | What | Size | Done when |
|---|---|---|---|
| S0-04.1 | NVHPC: container (`port/container`) or module; pin the version; record `nvfortran --version`, CUDA version, driver, `nvidia-smi -q` of both GPUs | S | ENVIRONMENT.md section "WS-A100" |
| S0-04.2 | MPI and netCDF built with nvfortran (`setup_toolchain.sh deps`) | M | `x mpif90 --version`, `nc-config --all` recorded |
| S0-04.3 | gfortran netCDF for the `gnu-*` builds (`setup_toolchain.sh deps-gnu`) | S | gnu builds work on WS-A100 too |
| S0-04.4 | Spell-check every flag of the stanzas against `nvfortran -help -gpu` (`-acc=gpu -cuda -gpu=cc80,cc90,nofma,noflushz`); `check_build_flags.py` | S | PASS |
| S0-04.5 | Device query of both A100s: SMs, clocks, memory, L2, ECC, MIG off; `deviceQuery`-style program (CUDA Fortran) | S | numbers in ENVIRONMENT.md (feeds plan-profiler PR-H1) |

**Gate S0-04:** a hello-world OpenACC kernel and a CUDA Fortran kernel run on GPU 0 and GPU 1, with
`ACC_DEVICE_TYPE=nvidia`.

## S0-05 · OpenACC feature probes (`port/tests/acc_features`)

These replace the OpenMP probes `omp_features` (plan.md P0.5b) for the OpenACC dialect. Each probe is a small
program with a PASS/FAIL line. The results decide coding choices before more kernels are written.

| | |
|---|---|
| Changes | `port/tests/acc_features/` (new; locked after review), `port/ENVIRONMENT.md` |
| Machine | CLOUD (write; gfortran compiles them) → WS-A100 (run) |
| Depends | S0-04 |

| Task | Probe | Decides |
|---|---|---|
| S0-05.1 | F-IF: `if(.false.)` on `parallel loop` runs on the host with host data | T-AB method (kernel_off) |
| S0-05.2 | F-ROUTINE: `!$acc routine seq` callee reading module PARAMETER, module `declare create` scalars and arrays | B4 form; tables |
| S0-05.3 | F-DECLARE: `declare create` of allocatable module arrays + `update device` | P1.4 tables |
| S0-05.4 | F-PRESENT: pointer bounds-remapped onto a work/pool array, passed to an explicit-shape dummy, found `present` | P1.6/P1.7 |
| S0-05.5 | F-STMTFN, F-INTPROC, F-OPT, F-CHAR: statement functions, internal procedures, OPTIONAL, CHARACTER in device code | run-1 used module-function copies (F-STMTFN unknown) |
| S0-05.6 | F-RED: `reduction(+:)` and `reduction(ieor:)` on INTEGER(8); `reduction(max:)` on REAL | tracer, NaN counts |
| S0-05.7 | F-NAN: `x /= x` in device code under `-Kieee` | NaN checks |
| S0-05.8 | F-STACK: `NV_ACC_CUDA_STACKSIZE` applies; read back with `cudaDeviceGetLimit` | CP-5 |
| S0-05.9 | F-ATTACH: `enter data copyin` of a derived type and `attach` of pointer components (`fp` of WRF-Fire) | I-12 |
| S0-05.10 | F-HOSTDATA: `!$acc host_data use_device` into a CUDA Fortran kernel | CUDA Fortran escape hatch |
| S0-05.11 | F-CACHE, F-ASYNC: `!$acc cache` and `async`/`wait` accepted and bit-neutral | Stage 6 |
| S0-05.12 | F-AUTO, F-PRIVARR: automatic and runtime-sized private arrays in kernels and routines | CP-3 |

**Gate S0-05:** every probe has a recorded result on A100 and a chosen fallback where it fails (CODING_STANDARD.md
and CODE_ONLY.md updated by the reviewer).

## S0-06 · Arithmetic and unit tests on the A100

| | |
|---|---|
| Machine | WS-A100 |
| Depends | S0-04 |

| Task | What | Size | Done when |
|---|---|---|---|
| S0-06.1 | T-FMA (gates everything else): device and host `a*b+c`, the binary32 tie and 10⁶ cases | S | unfused, identical |
| S0-06.2 | T-SIGNZERO, T-MINMAX, T-SUBNORM | S | identical, not flushed |
| S0-06.3 | T-RM-EXH (2³² patterns per function, REAL(4)) | M | 0 mismatches |
| S0-06.4 | T-RM-POW, T-RM-D | M | 0 mismatches |
| S0-06.5 | T-IPOW, T-KISS, T-PDLIM, T-OZN, templates B/C/G/CP, T-CALLCHECK on the device (`run_ref_tests.sh nvhpc`) | M | all PASS |
| S0-06.6 | Repeat .1–.5 on GPU 1 | S | identical results |

**Gate S0-06:** RESULTS.md lists every test with PASS on both A100s.

## S0-07 · CPU-REF build and the symbol audit

| | |
|---|---|
| Machine | WS-A100 (host CPUs, the same container image as the GPU builds) |
| Depends | S0-04 |

| Task | What | Size | Done when |
|---|---|---|---|
| S0-07.1 | Build CPU-REF from the handoff (`build.sh cpu-ref --commit`); keep `wrf.exe` md5 | S | md5 in RESULTS.md |
| S0-07.2 | T-SYM: `nm` over every in-scope object; no math-library symbols outside the allow-list | S | PASS |
| S0-07.3 | Build WPS and `real.exe` on the host (gfortran or nvfortran; they only make inputs and are not compared) | M | `geogrid`, `metgrid`, `real.exe` run on the Eaton domain |
| S0-07.4 | T-BUILD-REF: the port's own files compile without `-w` | S | no warnings |

## S0-08 · CPU-REF reproducibility

| | |
|---|---|
| Machine | WS-A100 (host CPUs, 56 cores; the dev case) |
| Depends | S0-07, S0-09.1 |

| Task | Test | Size | Done when |
|---|---|---|---|
| S0-08.1 | T-DET: same binary, same ranks, twice, 1 h of the dev case | M | bitwise |
| S0-08.2 | T-DEC-A: 1 vs 56 ranks, 3 d01 steps, level-2 trace | M | bitwise; else bisect (plan.md P0.10) |
| S0-08.3 | T-DEC-B: 14 vs 28 vs 56 ranks, 30 min | M | bitwise |
| S0-08.4 | T-RST: continuous vs restart at 02:00, compared at 03:00 | M | bitwise, or documented |
| S0-08.5 | Cost table: wall time of the dev and acceptance cases on 56 ranks, per simulated hour (sets the plan for S0-10 and S5-09) | S | numbers in ENVIRONMENT.md |

T-XM (the same binary on two machines) is dropped: there is one machine (ADR-006).

## S0-09 · Dev case `eaton_small`, acceptance case `eaton_mid`, and their references

| | |
|---|---|
| Machine | WS-A100 (WPS and `real.exe` on the host; CPU-REF references on the 56 host cores) |
| Depends | S0-07 |

| Task | What | Size | Done when |
|---|---|---|---|
| S0-09.1 | Make the dev case (`port/make_dev_case.py` + WPS/real on the host): d02 181×181×60 centered on the ignition; inputs from the CCR files checked against `manifest.md5` | M | `cases/eaton_small/` namelist + manifest |
| S0-09.2 | CPU-REF dev reference: 1 h continuous from 02:00, restarts at 02:00 and 02:20 | M | archived with md5 |
| S0-09.3 | CPU-REF 17 h dev run (for T-DRIFT) | M (waiting) | archived |
| S0-09.4 | `manifest.py check`; run every window of `windows.txt` once with CPU-REF | M | each window has a reference trace |
| S0-09.5 | Size the acceptance case: `gpu_mem_estimate.py` over d02 sizes; choose the largest d02 that leaves ≥ 15 % of 40 GB free (expected about 400×400×60, fire grid about 1600²); `RRTMG` batch 2048 if that is what makes it fit | S | size recorded in `cases/eaton_mid/README.md` |
| S0-09.6 | Make `eaton_mid` (same dates, physics, fire options and ignition; d01 unchanged; d02 centered on the ignition); namelist and manifest | M | `cases/eaton_mid/` |
| S0-09.7 | CPU-REF `eaton_mid` references: 1 h from 02:00 with restarts at 02:00 and 02:20; windows W-20/W-100/W-RAD of the acceptance case run once | M | archived |

## S0-10 · Long references: `eaton_mid` 17 h, E0, E1, Prof-CPU

Runs on the host cores beside Stages 1–4 (the GPUs stay free for the port). The cost table of S0-08.5 says how long
each run takes; the owner decides the run length if 17 h is too costly (ADR-006).

| Task | What | Machine | Size |
|---|---|---|---|
| S0-10.1 | `eaton_mid` 17 h CPU-REF run, level-1 trace, hourly restarts (plan.md P0.11 applied to the acceptance case) | WS-A100 host | M (mostly waiting) |
| S0-10.2 | 02:00 restart run with `restart_interval = 20` (the 02:20 restart) | WS-A100 host | S |
| S0-10.3 | Archive with md5 list; E1 (1-ulp perturbation of `eaton_mid`) recorded | WS-A100 host | M |
| S0-10.4 | E0: the original CCR run (its history files, copied as data) vs CPU-REF of the **full** case over the first hours, with `compare_fields.py` and `compare_fire.py`: a statistical comparison that documents how far a different build on a different machine moves the fire. Not a gate. The full-case CPU-REF run is made here on the host for as many hours as the cost table allows | WS-A100 host | M |
| S0-10.5 | Prof-CPU table (`port/prof_cpu.py`) for the dev and acceptance cases on 56 ranks | WS-A100 host | S |

## S0-11 · T-UNINIT, once

| Task | What | Machine | Done when |
|---|---|---|---|
| S0-11.1 | `t_uninit.sh`: gnu builds with NaN and zero fills of uninitialized memory, W-T0 | WS-A100 | identical, or every read of uninitialized scratch named in RESULTS.md |

## S0-12 · Certify the shared refactors of run 1

Each family is one task: `t_cpu_view.sh W-T0 W-20 W-100` (and `W-IGN` for fire) plus `t_drift.sh`, then a base
move (WORKFLOW.md §6). The base moves once per family, in the order below.

| Task | Family (run-1 package) | Files | Extra window |
|---|---|---|---|
| S0-12.1 | advect_scalar_pd work arrays (P2-E1) | module_advect_em.F | — |
| S0-12.2 | `var_mix` work array (P2-G3) | module_diffusion_em.F | W-TKE |
| S0-12.3 | Fire: `tend`, `lfn_out` work arrays; `set_flags` hoist; dead ignition check removed; `tend_1..3` removed (P4-LS, P4-MODEL) | module_fr_fire_core/driver/model/util.F | W-IGN |
| S0-12.4 | Microphysics driver work arrays (P3-WSM6) | module_microphysics_driver.F | — |
| S0-12.5 | PBL driver work arrays (P3-PBL) | module_pbl_driver.F | — |
| S0-12.6 | Radiation driver work arrays (P3-RADDRV) | module_radiation_driver.F | W-RAD |
| S0-12.7 | RRTMG EQUIVALENCE flattening and `rrtmg_lw_ini` hoist (P3-RRTMG) | module_ra_rrtmg_lw.F | W-RAD |
| S0-12.8 | Noah: `iloc/jloc`, `LUTYPE/SLTYPE` codes, sea ice, glacial (P3-NOAH) | module_sf_noah*.F | — |
| S0-12.9 | surface_driver work arrays (P3-SFCDRV) | module_surface_driver.F | — |

Each row: CPU-REF of the base vs CPU-REF of the refactor commit, bitwise on traces and output files. If a family
fails, it is split down to the single statement change that moves bits. That change is then fixed or reverted.

## S0-13 · Sample gating cases (tiny and small), generated

Between the per-routine harness (random inputs) and the dev-case windows (10–20 min each while routines are still on
the host) there is room for cases that run in seconds to a few minutes and still exercise the real model: the
whole time step, both builds, the fire. They are **gating tests**: CPU-REF and GPU-REPRO run the same case from the
same input, and every field must agree bit for bit. They do not replace the dev or acceptance case; they catch most
mistakes before those are spent on.

| | |
|---|---|
| Changes | `port/make_test_cases.py` (new; infrastructure), `cases/tests/<tier>-<name>/` (namelist, manifest, README with the expected wall time), `port/h100/windows.txt` and `port/gates/t_tiers.sh` (locked: reviewer adds the entries), `cpu_verify.sh` (runs tier T0) |
| Machine | CLOUD (generator, T0 on gfortran) → WS-A100 (host runs of `ideal.exe`/`real.exe`, CPU-REF references, device runs) |
| Depends | S0-07 (builds), the owner's small fire input files for T1 |

**Tiers.** Each tier is a set of cases of one size; each case has a CPU-REF reference and is compared on traces
(level 2) and on every history and restart field.

| Tier | Cases | Size, model time | Wall time, one A100 (expected) | Input | Used at |
|---|---|---|---|---|---|
| **T0 ideal-tiny** | `t0-fire` (the current smoke case, 103×103×51, open boundaries, one domain); `t0-fire-nest` (two domains, nest ratio 3, `nested` boundaries, fire on the nest: the Eaton boundary options); `t0-phys` (the Eaton physics suite on the ideal case, radiation every 30 s); `t0-cold` (no fire: dynamics and physics only) | 1–3 simulated minutes | seconds to 2 min | none: `ideal.exe` from a generated sounding and fuel map | rung L3 on CLOUD (gfortran views); rung L5–L6 first check on the device; `cpu_verify.sh`; every commit |
| **T1 real-small** | one case per small fire input the owner provides: `t1-<name>`, with the Eaton namelist options, `sr_x = sr_y = 4`, 10–30 simulated minutes through the ignition; restart written before ignition so that windows are restart-vs-restart | a few hundred points per side, 10–30 min | 2–10 min | the owner's small `wrfinput_d0*`/`wrfbdy_d01` files, md5s in the manifest | per-phase gates before W-20; the nightly regression (S7-02) |
| **T2 dev** | `eaton_small` windows W-T0 … W-1H (S0-09) | as `windows.txt` | 10 min to hours | Eaton inputs | sub-gates, stage gates |
| **T3 acceptance** | `eaton_mid` (S0-09.5–.7), 17 h | 17 h | days | Eaton inputs | G5 |

| Task | What | Size | Done when |
|---|---|---|---|
| S0-13.1 | `make_test_cases.py t0`: writes the four T0 namelists, soundings and fuel maps from one template (the smoke-case generator generalized); options chosen so that `gpu_check_config` accepts `t0-fire-nest`, `t0-phys` and `t0-cold` (the Eaton envelope: nested boundaries, even `sr`, `WRF_KMAX`), while `t0-fire` keeps its open boundaries for the CPU-view checks | M | the four cases run with `gnu-ref` in under a minute each on CLOUD |
| S0-13.2 | `make_test_cases.py t1 <inputs>`: from the owner's small input files, writes the namelist (Eaton options, dates and domain sizes read from the files), the manifest, a restart point before ignition, and the README | M | one `cases/tests/t1-<name>/` per input set |
| S0-13.3 | CPU-REF references of T0 and T1 on the host cores (1 rank and 8 ranks, both bitwise: a small T-DEC); archived with md5s under `$WORK/reference/tests/` | S | references exist |
| S0-13.4 | `windows.txt` entries (`T0-*`, `T1-*`) and `t_tiers.sh <build> T0|T1`: runs every case of a tier with GPU-REPRO and compares with `compare.sh`; prints one PASS/FAIL line per case | M | `t_tiers.sh` runs on WS-A100 |
| S0-13.5 | Precision report on failure: `compare_fields.py --report` prints, per differing field, the first differing step, the number of differing points, the largest difference in ulps, and the digits of agreement, so that a failure is localized without a second run; `bittrace_diff.py` names the step, stage, tag and field as before | S | one failing case produces the report |
| S0-13.6 | `cpu_verify.sh` runs T0 (all four cases) instead of S-3M alone; `t_reg20.sh` runs T0 and T1 on the device before W-20 | S | both scripts updated (tool fix, logged) |
| S0-13.7 | Cost table of the tiers (wall time per case on CPU-REF 8 ranks and on one A100) in ENVIRONMENT.md | S | numbers recorded |

**Gate S0-13:** every T0 and T1 case is bitwise, CPU-REF (host) vs GPU-REPRO with every route off (the Stage 1
configuration), on both A100s. From then on every phase gate runs `t_tiers.sh T0 T1` before its W-20.

**Stage gate G0** (plan.md §14), on these machines:
- WS-A100: S0-04 … S0-09, S0-11, S0-13 (S0-10 may still be running);
- CLOUD: S0-01 … S0-03;
- every family of S0-12 certified, so `cpu_view_base` points at a commit containing all of run 1's refactors.
