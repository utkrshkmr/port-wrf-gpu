# Stage 0 — Ground truth

Goal: a trusted starting point before any further GPU work.
- The CPU check works.
- The code of run 1 is landed.
- The toolchain on the A100 workstation is known.
- The CPU reference is reproducible and archived.
- The dev case exists.
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
| Machine | WS-A100 (host CPUs) and CCR (the same container image) |
| Depends | S0-04 |

| Task | What | Size | Done when |
|---|---|---|---|
| S0-07.1 | Build CPU-REF from the handoff (`build.sh cpu-ref --commit`); keep `wrf.exe` md5 | S | md5 in RESULTS.md |
| S0-07.2 | T-SYM: `nm` over every in-scope object; no math-library symbols outside the allow-list | S | PASS |
| S0-07.3 | Same build on CCR inside the same image; compare md5 | S | identical binary |
| S0-07.4 | T-BUILD-REF: the port's own files compile without `-w` | S | no warnings |

## S0-08 · CPU-REF reproducibility

| | |
|---|---|
| Machine | CCR (+ WS-A100 host for T-XM) |
| Depends | S0-07 |

| Task | Test | Size | Done when |
|---|---|---|---|
| S0-08.1 | T-DET: same binary, same ranks, twice, 1 h | M | bitwise |
| S0-08.2 | T-DEC-A: 1 vs 64 ranks, 3 d01 steps, level-2 trace | M | bitwise; else bisect (plan.md P0.10) |
| S0-08.3 | T-DEC-B: 64 vs 128 vs 144 ranks, 30 min | M | bitwise |
| S0-08.4 | T-XM: CCR node vs WS-A100 host, 3 d01 steps from t=0 and from 02:00 | S | bitwise |
| S0-08.5 | T-RST: continuous vs restart at 02:00, compared at 03:00 | M | bitwise, or documented |

## S0-09 · Dev case `eaton_small` and its references

| | |
|---|---|
| Machine | CCR (WPS, real.exe, references); WS-A100 receives the files |
| Depends | S0-07 |

| Task | What | Size | Done when |
|---|---|---|---|
| S0-09.1 | Make the dev case (`port/make_dev_case.py`): d02 181×181×60 centered on the ignition | M | `cases/eaton_small/` namelist + manifest |
| S0-09.2 | CPU-REF reference: 1 h continuous from 02:00, restarts at 02:00 and 02:20 | M | archived with md5 |
| S0-09.3 | CPU-REF 17 h dev run (for T-DRIFT) | M | archived |
| S0-09.4 | Copy to WS-A100; `manifest.py check`; run every window of `windows.txt` once with CPU-REF on WS-A100 | M | each window has a reference trace |

## S0-10 · Full-case reference (17 h)

Runs beside Stages 1–4.

| Task | What | Machine | Size |
|---|---|---|---|
| S0-10.1 | 17 h CPU-REF run, level-1 trace, hourly restarts (plan.md P0.11) | CCR | M (mostly waiting) |
| S0-10.2 | 02:00 restart run with `restart_interval = 20` (the 02:20 restart) | CCR | S |
| S0-10.3 | Archive with md5 list; E0 (vs the original CCR run) and E1 (1-ulp perturbation) recorded | CCR | M |
| S0-10.4 | Prof-CPU table (`port/prof_cpu.py`) | CCR | S |

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

**Stage gate G0** (plan.md §14), on these machines:
- WS-A100: S0-04 … S0-06, S0-11;
- CCR: S0-07 … S0-09 (S0-10 may still be running);
- CLOUD: S0-01 … S0-03;
- every family of S0-12 certified, so `cpu_view_base` points at a commit containing all of run 1's refactors.
