# Stage 5 — Nest forcing, island removal, full-run acceptance

Goal: nest forcing moves only what the host interpolation reads and writes; no copy is left that is not forcing, I/O
or a reduction result; and the 17 h run of the acceptance case `eaton_mid` on one A100 40 GB is bitwise equal to
CPU-REF run on the same workstation's host cores ([ADR-006](../decisions/ADR-006-machines.md)). Passing G5 makes the
v0.1 candidate. The full Eaton case (d02 811×811) does not fit one 40 GB GPU; it follows with multi-GPU
(S8-01 … S8-05), the first work after G5.

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
| S5-03.2 | T-FORCE: level-2 trace after steps 2, 6, 7 over 20 d01 steps (W-FORCE) | WS-A100 | M | bitwise |
| S5-03.3 | T-SLAB (GPU-DEBUG): host copies outside the slab and strips filled with signaling NaN | WS-A100 | M | nest `_b`, `_bt`, `o3rad` bitwise |
| S5-03.4 | T-O3: device `o3rad` checksum after every forcing | WS-A100 | S | equal |
| S5-03.5 | Bytes per d01 step of steps 3, 4, 6 into `port/PERF.md` (plan-profiler transfer model) | WS-A100 | S | recorded |

## S5-04 · Device bit tracer

Work package P5-TRACE · Depends G4

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-04.1 | `bt_field*` hashes computed on the device (integer sum and XOR reductions, probe F-RED) instead of `update self` + host hash | CLOUD → WS-A100 | M | identical trace lines with the host tracer on W-20 |
| S5-04.2 | Level-2 traces no longer move fields to the host (T-NSYS shows only the hash results) | WS-A100 | S | PASS |

## S5-05 · Remove the solve_em bracket; T-NSYS-CLEAN

Depends S5-03

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-05.1 | Delete the P1.9 bracket (bracket calls become no-ops, then are removed) | CLOUD | S | static PASS |
| S5-05.2 | T-NSYS-CLEAN on 200 d02 steps of the dev case: every copy is forcing, a boundary read, history/restart, or a reduction result (listed) | WS-A100 | M | PASS |
| S5-05.3 | No `cudaMalloc`/`cudaFree` in the time loop | WS-A100 | S | nsys API table |

## S5-06 · Output and input sync

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-06.1 | T-OUT: history frames 02:15 … 03:00 and restarts of the dev case | WS-A100 | M | bitwise files |
| S5-06.2 | T-BDY: window across 03:00 (a `wrfbdy` read) | WS-A100 | M | bitwise |

## S5-07 · One-hour dev windows on both A100s

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-07.1 | W-1H on GPU 0 | WS-A100 | M | bitwise traces and files |
| S5-07.2 | W-1H on GPU 1, at the same time | WS-A100 | M | bitwise, and identical to GPU 0 |
| S5-07.3 | First speed numbers on A100 (dev case): wall seconds per simulated hour, per domain | WS-A100 | S | RESULTS.md |

## S5-08 · Acceptance case: memory and first hour

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-08.1 | `eaton_mid`, init + 1 d01 step: memory log | WS-A100 (GPU 0) | S | peak ≤ 34 GB (G-MEM-3 preliminary) |
| S5-08.2 | `eaton_mid`, 02:20 restart, 100 d02 steps, level 2 vs CPU-REF from the same restart (S0-09.7) | WS-A100 | M | bitwise |
| S5-08.3 | `eaton_mid`, 1 h window, level 1 | WS-A100 | M | bitwise |

## S5-09 · 17 h acceptance on `eaton_mid`

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S5-09.1 | The 17 h GPU-REPRO run on GPU 0 (level-1 trace, all history and restarts) | WS-A100 | M (mostly waiting) | completes |
| S5-09.2 | `compare_fields.py --bitwise` over the 69 frames and 34 restarts; `compare_fire.py` 0 cells; traces identical to the S0-10 reference | WS-A100 | S | PASS |
| S5-09.3 | T-DRIFT-FULL: CPU-REF of the final commit, 17 h on the host cores, equals the S0-10 archive | WS-A100 host | M | bitwise |
| S5-09.4 | The same 17 h run on GPU 1, identical to GPU 0 (and to CPU-REF) | WS-A100 | M | bitwise |
| S5-09.5 | If an H100 or an A100 80 GB becomes available: the same run there, identical | optional | M | bitwise |

## S5-10 · Stage closure (G5)

| Task | What | Machine | Size |
|---|---|---|---|
| S5-10.1 | `bash port/gates/g5.sh` PASS; G-MEM-3 ≤ 34 GB over the 17 h run | WS-A100 | S |
| S5-10.2 | RESULTS.md: binary md5s, image digest, input manifest, both GPUs | WS-A100 | S |
| S5-10.3 | Tag `v0.1-rc1`; backlog card A-29 done (opens Stage 2 of the roadmap: WRF 4.8.0) | CLOUD | S |
| S5-10.4 | Book: "The port" chapter's acceptance section | CLOUD | M |

**Stage gate G5:** plan.md §10 G5, items 1–9, as amended in plan.md §18 (acceptance case `eaton_mid`, both A100s
instead of two GPU types, no T-XM).
