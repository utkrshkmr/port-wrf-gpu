# The WRF 4.6.0 GPU port, phase by phase

This is the working plan of Stage 1 of the [roadmap](../README.md): WRF 4.6.0 + WRF-Fire on NVIDIA A100 and H100
GPUs, bit for bit equal to the CPU reference. It replaces the phase cards' order of work with **9 stages and 139 small
phases**. Each phase:
- is contained: it names the routines and files it changes, and nothing else changes;
- states the machine of every task;
- ends with a gate that someone else can repeat.

The design behind the port is unchanged:
- [plan.md](../../plan.md) for the kernels, tests and gates;
- [ADR-001 rev 2](../decisions/ADR-001-gpu-programming-model.md): OpenACC, with CUDA Fortran for measured hotspots;
- [CODING_STANDARD.md](../../port/agent/CODING_STANDARD.md) for how a kernel is written.

This plan says **in which order, where, and how small**. Two companion plans run alongside it:
- [plan-profiler.md](../plan-profiler.md): the profiler, built together with the port;
- [plan-book.md](../plan-book.md): the textbook, which documents each stage as it closes.

Nothing in this directory is code. Every task below is still to be done, except where a phase says that the code-only
run 1 (2026-10-07) already wrote it. That code is unverified.

## Files

| File | Stage | Phases |
|---|---|---|
| [stage-0-ground-truth.md](stage-0-ground-truth.md) | 0 Ground truth: land run 1, toolchain, probes, references, shared refactors | S0-01 … S0-12 |
| [stage-1-infrastructure.md](stage-1-infrastructure.md) | 1 GPU infrastructure, all compute still on the host | S1-01 … S1-12 |
| [stage-2-dynamics.md](stage-2-dynamics.md) | 2 The dynamical core | S2-01 … S2-23 |
| [stage-3-physics.md](stage-3-physics.md) | 3 The physics of the case | S3-01 … S3-25 |
| [stage-4-fire.md](stage-4-fire.md) | 4 WRF-Fire | S4-01 … S4-13 |
| [stage-5-forcing-acceptance.md](stage-5-forcing-acceptance.md) | 5 Nest forcing, island removal, full-run acceptance | S5-01 … S5-10 |
| [stage-6-performance.md](stage-6-performance.md) | 6 Bit-neutral performance work (with plan-profiler.md) | S6-01 … S6-16 |
| [stage-7-cases-release.md](stage-7-cases-release.md) | 7 Other fires, regression, release v0.1 | S7-01 … S7-08 |
| [stage-8-coverage.md](stage-8-coverage.md) | 8 The rest of WRF 4.6.0: more GPUs, more options | S8-01 … S8-20 |

## Scope

"The whole 4.6 version" is ported in two layers:
1. **Stages 0–7: everything `wrf.exe` executes for the Eaton case family**, the configuration of plan.md §2.2, bit for
   bit on one GPU. This is the contract of v0.1 (milestone M3).
2. **Stage 8: the rest of WRF 4.6.0**, one option family per phase, each with its own small case contract and
   reference. The order follows what wildfire studies use most:
   - multi-GPU, which also brings the full case to two A100 40 GB;
   - restart starts and two-way nesting;
   - Thompson and Morrison microphysics, MYNN, RRTMG SW, Noah-MP, cumulus;
   - the other fire options.

   Options nobody needs stay on the CPU, and `gpu_check_config` rejects them with a clear message.

What stays on the CPU in every stage:
- WPS, `real.exe`, `ideal.exe`;
- initialization;
- I/O formatting;
- the host part of nest interpolation (plan.md §1).

## Machines

| ID | Machine | Has | Runs | Cannot |
|---|---|---|---|---|
| **CLOUD** | the cloud coding environment (claude.ai/code) | Linux, 4 cores, gfortran 13 (`-fopenacc` runs OpenACC regions on the host), Python 3, git, GitHub; no NVHPC, no GPU, no TeX, no case data | writing code; `static.sh`; gfortran builds of both views (`gnu-ref`, `gnu-gpu`); the smoke case S-3M; `harness.sh` on random inputs; the reference unit tests; review; planning; book text | nvfortran, any device run, real data |
| **WS-A100** | the owner's workstation | 2× A100 40 GB (cc80), Xeon Gold 6330 (2×28 = 56 cores), NVHPC (container or module), the dev case `eaton_small` and the acceptance case `eaton_mid` | **everything that runs**: NVHPC builds (CPU-REF and GPU-REPRO); **all CPU-REF reference runs on the host cores** (dev and acceptance case, windows, T-DET, T-DEC with 1/28/56 ranks, T-RST, T-DRIFT); WPS and `real.exe` for the cases; device unit tests and probes; harness on the device; T-AB and T-TRACE; fire windows; the 17 h acceptance run (G5) on one GPU; nsys and ncu on A100; two independent runs at once (one per GPU); later the full case on both GPUs (S8-01 … S8-05) | the full Eaton case on one GPU (about 57 GB, plan.md §3) |
| **CI** | GitHub Actions of the repository | TeX Live | the book PDF ([plan-book.md](../plan-book.md)) | GPUs, case data |

**Machine policy ([ADR-006](../decisions/ADR-006-machines.md), 2026-10-08).** Nothing is developed or tested on
CCR, and no 80 GB GPU is assumed. CCR supplies the input files and the original run, which is compared with CPU-REF
statistically (E0), never bit for bit. Every bit-for-bit comparison is CPU-REF on the workstation's host CPUs against
GPU-REPRO on its A100s: same source, same compiler, same container, same machine. An H100 is optional everywhere it
is named (Stage 6, the profiler, the book); no gate depends on it. Older text that names "CCR" or "GPU80" as a
machine of a task is superseded by this policy; `port/ccr/` is kept for reference only.

**Cases.** `eaton_small` (d02 181×181×60) is the development case for every window. `eaton_mid` is the acceptance
case: the same dates, physics, fire options and ignition as the full case, d01 unchanged, and the largest d02 that
fits one A100 40 GB with at least 15 % headroom by `gpu_mem_estimate.py` (expected about 400×400×60, fire grid about
1600², about 30 GB; S0-09.5 decides). The full case (d02 811×811) needs both A100s and comes with multi-GPU
(S8-01 … S8-05), the first work after G5. G-MEM limits: dev case ≤ 25 GB at G1; acceptance case ≤ 34 GB at G3 and G5.

Backlog needs ([TASK_PROTOCOL.md](../TASK_PROTOCOL.md) §2):
- CLOUD = `cpu` (+ `net`);
- WS-A100 = `gpu-nv`, `data` (the `ccr` need is no longer used).

Run times to expect are in [ENV_H100.md](../../port/agent/ENV_H100.md) §5. While a routine is still on the host,
a W-20 window takes 10–20 min, and much less once it is ported. A100 40 GB specifics are in §5a.

## The routine ladder (applies to every routine of Stages 1–5)

A routine is ported in eight rungs. Rungs 1–3 run on CLOUD, 4–8 on WS-A100. A phase lists its routines; each routine
gets **two tasks**: `.c` (rungs 1–3) and `.g` (rungs 4–8). A routine longer than about 300 CPU lines gets one more
`.c` task per 300 lines, so no task is longer than half a day.

| Rung | What | Machine | How | Passes when |
|---|---|---|---|---|
| L1 write | GPU view under `#ifdef WRF_GPU`: kernels by template, island, call check, route | CLOUD | `python3 port/tools/ref.py <kernel>`; CODING_STANDARD.md | `bash port/gates/static.sh` PASS (arith_guard, kernel_lint, scope) |
| L2 CPU compile | both gfortran views compile the file | CLOUD | `compile_one.sh gnu-gpu <file>`, `compile_one.sh gnu-ref <file>` | no errors; `default(none)` complete |
| L3 CPU equality | GPU view = CPU view on the host | CLOUD | `harness.sh <file> <routine> --builds <gnu-ref>,<gnu-gpu>`; S-3M through `cpu_verify.sh` when the routine is on the smoke path | identical bits |
| L4 device compile | nvfortran GPU-REPRO compile | WS-A100 | `compile_one.sh gpu-repro <file> --minfo` | every kernel generates GPU code; no implicit data movement; inner loops `seq`; registers and spills recorded (profiler layer L0) |
| L5 device harness | host, device and CPU view on random inputs | WS-A100 | `harness.sh <file> <routine>` | three-way identical |
| L6 T-AB | device vs host execution of the routine on real data | WS-A100 | `bash port/gates/t_ab.sh <route> W-20` | identical traces |
| L7 T-TRACE | GPU-REPRO vs CPU-REF | WS-A100 | `bash port/gates/t_trace.sh W-20` | bitwise |
| L8 record | the routine's kernels in the kernel database | WS-A100 | [plan-profiler.md](../plan-profiler.md) PR-L2/L3 | rows present |

A routine is **done** at L7, plus L8 once that profiler layer exists (from S2-01). Its `kernels.csv` row is then set
with the commit and the passing tests: `workbook.py set <kernel> done --commit <sha> --tests "..."`.

**Code written ahead.** A code-only run may write L1 for any routine of a later phase. That phase then starts at L2,
and its `.c` task becomes a review: the code is checked against `ref.py`, the template and the verbatim rule, before
rungs 2–3. Run-1 code is marked "run 1" in the phase tables.

## Gates

| Gate | Where | Contains |
|---|---|---|
| **Phase gate** `G-<phase>` | WS-A100 (+ CLOUD) | every routine of the phase at L7, on GPU 0 and on GPU 1; `T-REG-20` (W-20, everything ported so far) bitwise; `static.sh` and `cpu_verify.sh` PASS; workbook and `kernels.csv` current |
| **Sub-gate** (plan.md G2.A … G3.E, G4) | WS-A100 | the phase gates of its phases, plus `T-TRACE-100` (W-100) or the window plan.md names (W-RAD, W-TKE, W-IGN, W-FIRE) |
| **Stage gate** G0 … G6 | as listed per stage | plan.md §14 |

A failing gate never moves forward:
1. The failure is diagnosed with [DEBUGGING.md](../../port/agent/DEBUGGING.md).
2. After three honest attempts, it is recorded in BLOCKERS.md and the phase stays open.
3. Independent phases continue meanwhile.

## Order and independence

- Stages run in order: a stage starts when the previous stage gate has passed. Exceptions:
  - S0-10 (the long CPU-REF references on the host cores) and S0-12 can run beside Stages 1–4;
  - Stage 6's profiler layers are built from Stage 1 on;
  - book tasks run any time.
- **Inside a stage, phases are independent** unless their "Depends" line says otherwise. Islands make every routine
  portable alone, so they run in any order and in parallel, for example two agents or one per GPU.
- Each phase is a branch `agent/<phase-id>` (lowercase) from the handoff branch. The reviewer merges it after its
  gate.

## Phase index

| Phase | Title | Main machine | Depends |
|---|---|---|---|
| **Stage 0** | **Ground truth** | | |
| S0-01 | Make the CPU check trustworthy (clean builds, dependency checker) | CLOUD | — |
| S0-02 | Land the code of run 1 (review, merge, scope requests) | CLOUD | S0-01 |
| S0-03 | Work arrays and the step bracket first (P1-WORK, gpu_work_ensure) | CLOUD | S0-02 |
| S0-04 | Toolchain on WS-A100 | WS-A100 | — |
| S0-05 | OpenACC feature probes (acc_features) | CLOUD → WS-A100 | S0-04 |
| S0-06 | Arithmetic and unit tests on the A100 | WS-A100 | S0-04 |
| S0-07 | CPU-REF build and symbol audit (T-SYM) | WS-A100 | S0-04 |
| S0-08 | CPU-REF reproducibility on the host cores (T-DET, T-DEC, T-RST) | WS-A100 | S0-07 |
| S0-09 | Dev case eaton_small, acceptance case eaton_mid, and their references | WS-A100 | S0-07 |
| S0-10 | Long references: eaton_mid 17 h; E0 against the original CCR run | WS-A100 | S0-08, S0-09 |
| S0-11 | T-UNINIT, once | WS-A100 | S0-09 |
| S0-12 | Certify the shared refactors of run 1 (one family per task) | WS-A100 | S0-03, S0-09 |
| **Stage 1** | **GPU infrastructure** | | |
| S1-01 | First GPU-REPRO build, every route off | WS-A100 | G0 |
| S1-02 | State on the device (gen_allocs) and T-MAP | CLOUD → WS-A100 | S1-01 |
| S1-03 | Generated update lists and T-UPD | CLOUD → WS-A100 | S1-02 |
| S1-04 | Work arrays on the device and T-WORK | CLOUD → WS-A100 | S1-02 |
| S1-05 | Scratch pool and T-POOL | CLOUD → WS-A100 | S1-02 |
| S1-06 | Module tables and T-TAB | CLOUD → WS-A100 | S1-02 |
| S1-07 | Sync points S1–S5 and the solve_em bracket | CLOUD → WS-A100 | S1-03 |
| S1-08 | Nest-forcing bridge S6 (Phase 1–4 form) | CLOUD → WS-A100 | S1-07 |
| S1-09 | Startup gate gpu_check_config and T-GATE | CLOUD → WS-A100 | S1-01 |
| S1-10 | Self tests and the dispatcher (WRF_GPU_SELFTEST) | CLOUD → WS-A100 | S1-04 … S1-06 |
| S1-11 | Profiler layer 1: NVTX, timing and memory logs | CLOUD → WS-A100 | S1-01 |
| S1-12 | G1 windows; G-MEM-1 (dev case) | WS-A100 | all of Stage 1 |
| **Stage 2** | **Dynamics** | | |
| S2-01 | Physical boundary conditions | WS-A100 | G1 |
| S2-02 | RK preparation, pointwise | WS-A100 | G1 |
| S2-03 | RK preparation, columns (G2.A) | WS-A100 | S2-01, S2-02 |
| S2-04 | Tendency zeroing, WW_SPLIT, rhs_ph | WS-A100 | G1 |
| S2-05 | advect_u (run 1) | WS-A100 | G1 |
| S2-06 | advect_v (run 1) | WS-A100 | G1 |
| S2-07 | advect_w (run 1) | WS-A100 | G1 |
| S2-08 | advect_scalar (run 1) | WS-A100 | G1 |
| S2-09 | Pressure gradient, buoyancy, w damping | WS-A100 | G1 |
| S2-10 | Coriolis and curvature (G2.B) | WS-A100 | S2-04 … S2-09 |
| S2-11 | Tendency combination and lateral boundaries (G2.C) | WS-A100 | G1 |
| S2-12 | Acoustic loop: prep, finish, p/rho, coefficients, sums | WS-A100 | G1 |
| S2-13 | advance_uv, advance_mu_t | WS-A100 | G1 |
| S2-14 | advance_w | WS-A100 | G1 |
| S2-15 | Acoustic boundary updates (G2.D) | WS-A100 | S2-12 … S2-14 |
| S2-16 | advect_scalar_pd (run 1) | WS-A100 | G1 |
| S2-17 | Scalar updates and flow-dependent boundaries (G2.E) | WS-A100 | S2-16 |
| S2-18 | End of step (G2.F) | WS-A100 | G1 |
| S2-19 | Diffusion metrics and deformation (run 1) | WS-A100 | G1 |
| S2-20 | N2, eddy viscosities, TKE (run 1, partial) | WS-A100 | G1 |
| S2-21 | Vertical diffusion and the stress tensor (run 1, partial) | WS-A100 | G1 |
| S2-22 | Horizontal diffusion (G2.G) | WS-A100 | S2-19 … S2-21 |
| S2-23 | Stage closure: T-NSYS, T-DRIFT, dynamics profile (G2) | WS-A100 | all of Stage 2 |
| **Stage 3** | **Physics** | | |
| S3-01 | Physics glue of the big-step utilities | WS-A100 | G2 |
| S3-02 | Physics tendencies (G3.A) | WS-A100 | S3-01 |
| S3-03 | Column test harness framework | CLOUD → WS-A100 | G2 |
| S3-04 | WSM6 device tree (run 1, partial) | CLOUD → WS-A100 | S3-03 |
| S3-05 | WSM6 kernel and microphysics driver (G3.B) | WS-A100 | S3-04 |
| S3-06 | Surface layer sfclayrev and T-ZOLRI | CLOUD → WS-A100 | S3-03 |
| S3-07 | Noah: certified refactors and tables (run 1) | WS-A100 | S3-03 |
| S3-08 | Noah leaves I: soil heat and snow | CLOUD → WS-A100 | S3-07 |
| S3-09 | Noah leaves II: water and evaporation | CLOUD → WS-A100 | S3-07 |
| S3-10 | Noah composites up to SFLX | CLOUD → WS-A100 | S3-08, S3-09 |
| S3-11 | Noah kernel, glacial, T-NOAH-PT | WS-A100 | S3-10 |
| S3-12 | Sea ice and surface diagnostics | CLOUD → WS-A100 | S3-03 |
| S3-13 | surface_driver kernels (run 1) (G3.C) | WS-A100 | S3-06, S3-11, S3-12 |
| S3-14 | YSU device tree | CLOUD → WS-A100 | S3-03 |
| S3-15 | PBL driver and YSU kernel (G3.D) | WS-A100 | S3-14 |
| S3-16 | Radiation driver: every-step kernels (run 1) | WS-A100 | G2 |
| S3-17 | Radiation driver: radiation-step kernels (run 1) | WS-A100 | S3-16 |
| S3-18 | Ozone interpolation and T-OZN | WS-A100 | S3-16 |
| S3-19 | Dudhia shortwave | CLOUD → WS-A100 | S3-03 |
| S3-20 | RRTMG tables (run 1, partial) | WS-A100 | S3-03 |
| S3-21 | RRTMG column setup routines | CLOUD → WS-A100 | S3-20 |
| S3-22 | RRTMG taumol (taugb1–16) | CLOUD → WS-A100 | S3-20 |
| S3-23 | RRTMG radiative transfer and McICA (T-KISS) | CLOUD → WS-A100 | S3-20 |
| S3-24 | RRTMG batching and kernel; T-RRTMG-COL (G3.E) | WS-A100 | S3-17 … S3-23 |
| S3-25 | Stage closure: T-TRACE-RAD, T-NSYS, T-DRIFT, G-MEM-2 (acceptance case) (G3) | WS-A100 | all of Stage 3 |
| **Stage 4** | **Fire** | | |
| S4-01 | Fire data on the device: flags, constants, fp, ghosts (run 1) | WS-A100 | G3 |
| S4-02 | Fire statistics: integer NaN counts (run 1) | WS-A100 | S4-01 |
| S4-03 | Atmosphere-to-fire interpolation | CLOUD → WS-A100 | S4-01 |
| S4-04 | Level-set tendency and rate of spread (run 1) | WS-A100 | S4-01 |
| S4-05 | Level-set time stepping, ignition time, flame length (run 1) | WS-A100 | S4-04 |
| S4-06 | Reinitialization (run 1) | WS-A100 | S4-04 |
| S4-07 | Ignition | CLOUD → WS-A100 | S4-01 |
| S4-08 | Fuel consumption | CLOUD → WS-A100 | S4-01 |
| S4-09 | Heat fluxes and sums over fire cells | CLOUD → WS-A100 | S4-08 |
| S4-10 | fire_model and the fire drivers (run 1, partial) | WS-A100 | S4-03 … S4-09 |
| S4-11 | Fire tendency into the atmosphere | CLOUD → WS-A100 | S4-01 |
| S4-12 | Fire windows: T-FIRE-IGN, T-FIRE-WIN | WS-A100 | S4-10, S4-11 |
| S4-13 | Stage closure (G4) | WS-A100 | S4-12 |
| **Stage 5** | **Forcing and acceptance** | | |
| S5-01 | couple_or_uncouple_em on the device | CLOUD → WS-A100 | G4 |
| S5-02 | Generated forcing lists (gen_gpu.c) (run 1, partial) | CLOUD → WS-A100 | G4 |
| S5-03 | med_force_domain rewired; T-FORCE, T-SLAB, T-O3 | WS-A100 | S5-01, S5-02 |
| S5-04 | Device bit tracer | CLOUD → WS-A100 | G4 |
| S5-05 | Remove the solve_em bracket; T-NSYS-CLEAN | WS-A100 | S5-03 |
| S5-06 | Output and input sync: T-OUT, T-BDY | WS-A100 | S5-05 |
| S5-07 | One-hour dev windows (W-1H) on both A100s | WS-A100 | S5-06 |
| S5-08 | Acceptance case: memory and first hour | WS-A100 | S5-07 |
| S5-09 | 17 h acceptance on eaton_mid; T-DRIFT-FULL; the same run on GPU 1 | WS-A100 | S5-08, S0-10 |
| S5-10 | Stage closure (G5, v0.1 candidate) | WS-A100 | S5-09 |
| **Stage 6** | **Performance (bit-neutral)** | | |
| S6-01 … S6-16 | profiles, then one optimization family per phase | WS-A100 (H100 optional) | G5 (profiler layers earlier) |
| **Stage 7** | **Other fires and release** | | |
| S7-01 … S7-08 | onboarding, a second fire, regression in CI, release v0.1 | CLOUD, WS-A100 | G5 |
| **Stage 8** | **The rest of WRF 4.6.0** | | |
| S8-01 … S8-20 | multi-GPU and the full Eaton case on the 2× A100 40 GB (first after G5), restarts, two-way nesting, more physics and fire options | CLOUD, WS-A100 | G5 |

## What run 1 left (input to Stage 0)

These are the verified facts. The CPU check's result goes into S0-02 when it is known.
- **19 of 44 work packages have code**, and 91 of 265 card items are coded. 234 kernels pass `kernel_lint`.
  - Coded: P1-ST, P1-TAB, P2-B1, P2-B2, P2-B3, P2-B4, P2-E1, P2-G1, P3-RADDRV, P3-SFCDRV, P4-LS.
  - Partial: P2-G2, P2-G3, P3-NOAH (3/39), P3-PBL, P3-RRTMG, P3-WSM6, P4-MODEL, P5-FORCE.
- All 19 branches pass the scope check and merge without conflicts.
- `arith_guard` reports only CPU-view changes: the shared refactors of run 1, which S0-12 certifies. No new
  arithmetic in GPU code.
- Gaps:
  - P1-WORK was not written, but the CPU view of the run-1 shared refactors needs it (S0-03).
  - `advect_u`, `advect_scalar` and `advect_scalar_pd` stop on open boundaries, which the smoke case uses (S0-02).
  - `check_deps.py` misreads `physics_mmm/` paths (S0-01).
  - Five dependency requests and two scope requests are open (S0-02).
  - The cpu_verify incremental builds use stale objects when include files change (S0-01).
