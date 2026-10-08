# Stage 1 — GPU infrastructure (all compute still on the host)

Goal: the GPU build runs the whole model with the state resident on the device, the step bracketed by host updates
(plan.md P1.9), and results bitwise equal to CPU-REF. No dynamics or physics kernel is active yet. The kernels of
run 1 exist in the code, but their routes are off.

Plan.md §6, PHASE1.md and INTERFACES.md I-1 … I-8 hold the specification. Each phase below is one of those items.
Ladder, gates and machines: [README.md](README.md).

**All routes off.** Every phase of this stage runs GPU-REPRO with every route off: `WRF_GPU_OFF=all` (task S1-01.3
adds that keyword to `module_gpu_route.F` if it is missing). Routes are turned on one by one from Stage 2.

---

## S1-01 · First GPU-REPRO build, every route off

| | |
|---|---|
| Machine | WS-A100 |
| Depends | G0 |

| Task | What | Size | Done when |
|---|---|---|---|
| S1-01.1 | `build.sh gpu-repro --commit <handoff>`: full nvfortran build; keep `compile.log` and the `-Minfo=accel` lines per file | M | `wrf.exe` exists |
| S1-01.2 | Fix compile-only issues without changing an executable statement; one commit per issue; every OpenACC rejection becomes a CODING_STANDARD note | M | clean build |
| S1-01.3 | `WRF_GPU_OFF=all` keyword (if missing) in `module_gpu_route.F` | S | the route table prints all off |
| S1-01.4 | Build GPU-DEBUG (`-g -traceback -gpu=lineinfo`) | S | `wrf.exe` exists |
| S1-01.5 | Profiler layer L0: archive `-Minfo=accel` and `-gpu=ptxinfo` per kernel (plan-profiler PR-L0) | S | `perf/db/static/<sha>.csv` |
| S1-01.6 | W-T0 and W-20 with all routes off, GPU-REPRO vs CPU-REF | M | bitwise (the GPU build with nothing on the device equals the CPU build) |

## S1-02 · State on the device (`WRF/tools/gen_allocs.c`) and T-MAP

| | |
|---|---|
| Spec | plan.md P1.2; PHASE1.md P1.2 (the `gpu_map_*` helpers of `module_gpu_map.F`) |
| Machine | CLOUD (generator, gfortran build) → WS-A100 (T-MAP) |
| Depends | S1-01 |

| Task | What | Size | Done when |
|---|---|---|---|
| S1-02.1 | `gen_alloc2`: `gpu_map_enter` after each in-use allocation (guarded by `.NOT. grid%is_intermediate`); boundary arrays; not-in-use dummies | M | generated `allocs.inc` reviewed; `check_generated.py` PASS |
| S1-02.2 | `gen_dealloc2`: `gpu_map_exit` before each DEALLOCATE | S | `check_generated.py` PASS |
| S1-02.3 | gnu-gpu build (host fallback) runs S-3M | S | bitwise vs gnu-ref |
| S1-02.4 | T-MAP (P1-ST code of run 1): `acc_is_present` for every allocated field of both domains | S | PASS on WS-A100 |
| S1-02.5 | W-20 all routes off | S | bitwise |

## S1-03 · Generated update lists and T-UPD

| | |
|---|---|
| Spec | plan.md P1.3; `WRF/tools/gen_gpu.c` |
| Machine | CLOUD → WS-A100 |
| Depends | S1-02 |

| Task | What | Size | Done when |
|---|---|---|---|
| S1-03.1 | `gpu_upd_dev_all.inc`, `gpu_upd_host_all.inc` (every allocated field, `in_use_for_config` guards) | M | `check_generated.py` C4 PASS |
| S1-03.2 | `gpu_upd_dev_bdy.inc` (BOUNDARY_STREAM arrays) | S | C-checks PASS |
| S1-03.3 | `gpu_upd_host_stream(grid, stream)` over `head_statevars` (history, restart) | M | unit test on S-3M: every stream field updated |
| S1-03.4 | T-UPD: debug switch runs host-all then dev-all every step | S | W-20 bitwise |

## S1-04 · Work arrays on the device and T-WORK

| | |
|---|---|
| Spec | INTERFACES.md I-3 (host part done in S0-03) |
| Machine | CLOUD → WS-A100 |
| Depends | S1-02 |

| Task | What | Size | Done when |
|---|---|---|---|
| S1-04.1 | Device part of `gpu_work_alloc_r/_i`: `!$acc enter data create`, device zero fill, re-create when a larger domain appears | S | T-WORK device part PASS |
| S1-04.2 | `gpu_selftest_work`: every work array present, zero after allocation, size ≥ the largest domain's | S | PASS on both A100s |
| S1-04.3 | Device memory of the work arrays for the dev case and (estimate) the full case | S | numbers in RESULTS.md and plan-profiler memory DB |

## S1-05 · Scratch pool and T-POOL

| | |
|---|---|
| Spec | plan.md P1.6; `WRF/frame/module_gpu_scratch.F`; `gen_defs.c` `gen_i1_decls` |
| Machine | CLOUD → WS-A100 |
| Depends | S1-02 |

| Task | What | Size | Done when |
|---|---|---|---|
| S1-05.1 | Pool allocation, offsets, 64-byte alignment; `i1_assoc.inc` generation | M | gnu builds and S-3M bitwise |
| S1-05.2 | Device side: `enter data create(gpu_pool)` + zero-fill kernel | S | T-POOL PASS |
| S1-05.3 | `acc_is_present` of 10 sampled `i1` arrays inside `solve_em` (probe F-PRESENT must have passed) | S | PASS |

## S1-06 · Module tables and T-TAB

| | |
|---|---|
| Spec | plan.md P1.4; INTERFACES.md I-4; P1-TAB code of run 1 |
| Machine | WS-A100 |
| Depends | S1-02 |

| Task | What | Size | Done when |
|---|---|---|---|
| S1-06.1 | Review P1-TAB `gpu_update_tables` and the dispatcher calls into P3-WSM6, P3-SFCLAY, P3-NOAH, P3-SW, P3-RRTMG upload routines (stubs where the physics phase has not run yet) | S | compiles; stubs listed |
| S1-06.2 | Generated `module_state_description` `P_*` indices on the device (declare create + update, or firstprivate) | S | decided, documented |
| S1-06.3 | T-TAB for the tables that exist (bit-sum host vs device) | S | PASS; the rest join in Stage 3 |

## S1-07 · Sync points S1–S5 and the `solve_em` bracket

| | |
|---|---|
| Spec | plan.md P1.5, P1.9; PHASE1.md P1.5+P1.9; INTERFACES.md I-8 |
| Machine | CLOUD → WS-A100 |
| Depends | S1-03 |

| Task | What | Size | Done when |
|---|---|---|---|
| S1-07.1 | S1 (after `med_initialdata_input`) and S2/S2' (nest open) | S | gnu-gpu S-3M bitwise |
| S1-07.2 | S3 (first statement of `med_hist_out`), S4 (`med_restart_out`) | S | history/restart files identical to CPU-REF on W-20 |
| S1-07.3 | S5 (boundary read): the "bdy read this step" flag | S | window across a boundary read (W-1H start) bitwise |
| S1-07.4 | The bracket: `gpu_bracket_begin/end` in `solve_em`; `gpu_work_ensure` after begin | S | W-20 bitwise |

## S1-08 · Nest-forcing bridge S6 (Phase 1–4 form)

| Task | What | Machine | Done when |
|---|---|---|---|
| S1-08.1 | Around `med_nest_force`: host-all before, dev-all after, both domains (plan.md P1.5 S6), conditional on `gpu_on(R_COUPLE_OR_UNCOUPLE_EM)` being off (I-11) | CLOUD | static PASS |
| S1-08.2 | W-T0 (nest opens, 3 d01 steps from t=0) | WS-A100 | bitwise |

## S1-09 · Startup gate `gpu_check_config` and T-GATE

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S1-09.1 | The allowed-option table (plan.md §2.2, P1.8) generated by `gen_check_table.py` | CLOUD | M | table reviewed |
| S1-09.2 | Checks: vertical size vs `WRF_KMAX`, `sr_x = sr_y` even, one rank, `numtiles = 1`, fuel categories | CLOUD | S | unit cases |
| S1-09.3 | T-GATE: `cu_physics = 1` is rejected with the violation listed | WS-A100 | S | PASS |

## S1-10 · Self tests and the dispatcher

| Task | What | Machine | Done when |
|---|---|---|---|
| S1-10.1 | `WRF_GPU_SELFTEST=1` runs T-MAP, T-TAB, T-POOL, T-WORK and exits (P1-ST code of run 1, reviewed) | WS-A100 | `t_selftest.sh` PASS on GPU 0 and 1 |

## S1-11 · Profiler layer 1: NVTX, timing and memory logs

| | |
|---|---|
| Spec | plan.md P1.10–P1.12; INTERFACES.md I-7; [plan-profiler.md](../plan-profiler.md) PR-L1 |
| Machine | CLOUD → WS-A100 |
| Depends | S1-01 |

| Task | What | Size | Done when |
|---|---|---|---|
| S1-11.1 | `wrf_gpu_shim.c`: NVTX push/pop, `cudaMemGetInfo`, `cudaDeviceGetLimit/SetLimit` | S | links in GPU builds; no-op in CPU builds |
| S1-11.2 | `BENCH_START/END` → NVTX ranges under `WRF_GPU`; one range per route (`gpu_on` call sites) | M | nsys shows the solve_em structure |
| S1-11.3 | `WRF_GPU_TIMING=1` log per simulated hour and domain | S | log lines on W-20 |
| S1-11.4 | Memory log: free/total at start, after each domain init, first step, hourly; peak | S | log lines on W-20 |
| S1-11.5 | Check: timing and memory logging change no bit | S | W-20 bitwise with and without |

## S1-12 · G1 windows; G-MEM-1

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S1-12.1 | W-20, level-2 trace, all routes off, on GPU 0 | WS-A100 | S | bitwise |
| S1-12.2 | W-20 on GPU 1 | WS-A100 | S | bitwise |
| S1-12.3 | W-T0: the first 3 d01 steps from t=0 (nest open, forcing), with one history and one restart write | WS-A100 | M | files identical |
| S1-12.4 | T-NSYS on W-20: every copy belongs to the bracket, a sync point or the S6 bridge | WS-A100 | S | `t_nsys.sh` PASS |
| S1-12.5 | G-MEM-1: dev case, init + first d01 step + first d02 step, logged peak; the acceptance case's peak from the same log and the full case from the estimator only | WS-A100 | S | dev case ≤ 25 GB; acceptance case ≤ 34 GB |
| S1-12.6 | Book: chapter "Data residency" facts and numbers ([plan-book.md](../plan-book.md) B-28.2) | CLOUD | S | text in book |

**Stage gate G1:** every phase gate of Stage 1, plus `bash port/gates/g1.sh` PASS on WS-A100, with G-MEM-1
recorded.
