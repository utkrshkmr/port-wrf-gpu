# Stage 5 — Nest forcing, island removal, full-run acceptance

Goal: nest forcing moves only what the host interpolation reads and writes; no copy is left that is not forcing, I/O
or a reduction result; and the 17 h run of the acceptance case `eaton_mid` on one GPU is bitwise equal to CPU-REF
run on the same machine's host cores ([ADR-006 rev 2](../decisions/ADR-006-machines.md)). On a profile whose GPUs
hold the full case (80 GB), the full 17 h Eaton run is part of G5 as well (S5-09.6). On `a100-40x2` the full case
follows with multi-GPU (S8-01 … S8-05), the first work after G5. Passing G5 makes the v0.1 candidate; the release
lists the profiles on which it passed.

Spec: plan.md §10 (P5.1–P5.4, G5), PHASE5.md, INTERFACES.md I-11.

---

## S5-01 · couple_or_uncouple_em on the device

Work package P5-CPL · plan.md P5.1 · Depends G4

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S5-01.1c | mu work arrays (`mutf_2` … `muvt_2`) as work arrays (shared refactor: certify as in S0-12) | — | S |
| S5-01.2c | Couple: K-CPL-MU-1…4b, K-CPL-F, K-CPL-V (patch clipped to the domain) | K-CPL-* | M |
| S5-01.3c | Uncouple: the same kernels with the stored reciprocals, as written | K-CPL-* | M |
| S5-01.1g | L4–L8 with the S6 bridge still on (route on, bridge off for this route only: I-11) | — | M |

## S5-02 · Generated forcing lists (run 1, partial)

Work package P5-FORCE · Depends G4

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-02.1 | `gpu_upd_host_force_slab.inc`: every INTERP_DOWN field, j-slab from `js` to `je` (the pack-loop rows) | CLOUD | M | `check_generated.py` (as decided in S0-02.6) PASS |
| S5-02.2 | `gpu_pack_force_strips.inc`: device pack of the FORCE_DOWN spec-zone strips (`sz + 1 = 6` wide) and the host unpack | CLOUD | M | generated code reviewed |
| S5-02.3 | `gpu_upd_dev_force_full.inc` (`o3rad`) | CLOUD | S | generated |
| S5-02.4 | gnu-gpu S-3M bitwise (host fallback of the pack) | CLOUD | S | PASS |

## S5-03 · `med_force_domain` rewired

Work package P5-FORCE · plan.md P5.2 · Depends S5-01, S5-02

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-03.1 | Steps 1–8 of P5.2 under `gpu_on(R_COUPLE_OR_UNCOUPLE_EM)`; the S6 bridge stays for the route-off case (I-11) | CLOUD | M | static PASS |
| S5-03.2 | T-FORCE: level-2 trace after steps 2, 6, 7 over 20 d01 steps (W-FORCE) | GPU-M | M | bitwise |
| S5-03.3 | T-SLAB (GPU-DEBUG): host copies outside the slab and strips filled with signaling NaN | GPU-M | M | nest `_b`, `_bt`, `o3rad` bitwise |
| S5-03.4 | T-O3: device `o3rad` checksum after every forcing | GPU-M | S | equal |
| S5-03.5 | Bytes per d01 step of steps 3, 4, 6 into `port/PERF.md` (plan-profiler transfer model) | GPU-M | S | recorded |

## S5-04 · Device bit tracer

Work package P5-TRACE · Depends G4

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-04.1 | `bt_field*` hashes computed on the device (integer sum and XOR reductions, probe F-RED) instead of `update self` + host hash | CLOUD → GPU-M | M | identical trace lines with the host tracer on W-20 |
| S5-04.2 | Level-2 traces no longer move fields to the host (T-NSYS shows only the hash results) | GPU-M | S | PASS |

## S5-05 · Remove the solve_em bracket; T-NSYS-CLEAN

Depends S5-03

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-05.1 | Delete the P1.9 bracket (bracket calls become no-ops, then are removed) | CLOUD | S | static PASS |
| S5-05.2 | T-NSYS-CLEAN on 200 d02 steps of the dev case: every copy is forcing, a boundary read, history/restart, or a reduction result (listed) | GPU-M | M | PASS |
| S5-05.3 | No `cudaMalloc`/`cudaFree` in the time loop | GPU-M | S | nsys API table |

## S5-06 · Output and input sync

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-06.1 | T-OUT: history frames 02:15 … 03:00 and restarts of the dev case | GPU-M | M | bitwise files |
| S5-06.2 | T-BDY: window across 03:00 (a `wrfbdy` read) | GPU-M | M | bitwise |

## S5-07 · One-hour dev windows on every GPU

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-07.1 | W-1H on GPU 0 | GPU-M | M | bitwise traces and files |
| S5-07.2 | W-1H on a second GPU at the same time (one-GPU profiles: again on the same GPU) | GPU-M | M | bitwise, and identical to the first run |
| S5-07.3 | First speed numbers on A100 (dev case): wall seconds per simulated hour, per domain | GPU-M | S | RESULTS.md |
| S5-07.4 | Whole-step CPU/GPU comparison of W-1H with everything on the device: CPU-REF (best rank count) and CPU-PROD on the host vs GPU-REPRO on one A100, per range (plan-profiler PR-C3) | GPU-M | M | `perf/reports/cpu-vs-gpu-eaton_small-<sha>.md` |
| S5-07.5 | First energy to solution of the same runs (plan-profiler PR-C4; GPU power, host RAPL if readable) | GPU-M | S | joules per simulated hour in the report |

## S5-08 · Acceptance case: memory and first hour

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-08.1 | `eaton_mid`, init + 1 d01 step: memory log | GPU-M (GPU 0) | S | peak ≤ the profile's G-MEM limit (34 GB on 40 GB GPUs) |
| S5-08.2 | `eaton_mid`, 02:20 restart, 100 d02 steps, level 2 vs CPU-REF from the same restart (S0-09.7) | GPU-M | M | bitwise |
| S5-08.3 | `eaton_mid`, 1 h window, level 1 | GPU-M | M | bitwise |

## S5-09 · 17 h acceptance on `eaton_mid`

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-09.1 | The 17 h GPU-REPRO run on GPU 0 (level-1 trace, all history and restarts) | GPU-M | M (mostly waiting) | completes |
| S5-09.2 | `compare_fields.py --bitwise` over the 69 frames and 34 restarts; `compare_fire.py` 0 cells; traces identical to the S0-10 reference | GPU-M | S | PASS |
| S5-09.3 | T-DRIFT-FULL: CPU-REF of the final commit, 17 h on the host cores, equals the S0-10 archive | GPU-M host | M | bitwise |
| S5-09.4 | The same 17 h run on a second GPU (one-GPU profiles: T-XG on W-1H against another profile's archive, if one exists) | GPU-M | M | bitwise |
| S5-09.5 | Each further profile that becomes available repeats S5-09.1–.2 on `eaton_mid`; T-XG shows its GPU traces equal those of the profiles before it | GPU-M (other profile) | M | bitwise |
| S5-09.6 | Profiles whose GPUs hold the full case (80 GB): memory (≤ 68 GB), 100 d02 steps and 1 h from the 02:20 restart, then the full 17 h Eaton run, all bitwise against the full-case CPU-REF reference of S0-10.6 on the same machine | GPU-M (80 GB profiles) | M (mostly waiting) | bitwise; 0 differing fire cells |

## S5-10 · Stage closure (G5)

| Task | What | Machine | Size |
|---|---|---|---|
| S5-10.1 | `bash port/gates/g5.sh` PASS; G-MEM-3 within the profile's limit over the 17 h run(s) | GPU-M | S |
| S5-10.2 | RESULTS.md: binary md5s, image digest, input manifest, machine id and profile of every run | GPU-M | S |
| S5-10.3 | Tag `v0.1-rc1`; backlog card A-29 done (opens Stage 2 of the roadmap: WRF 4.8.0) | CLOUD | S |
| S5-10.4 | Book: "The port" chapter's acceptance section | CLOUD | M |

**Stage gate G5:** plan.md §10 G5, items 1–9, as amended in plan.md §18 (acceptance case `eaton_mid` on
every profile, the full case where it fits, machine-change protocol instead of a fixed T-XM).
