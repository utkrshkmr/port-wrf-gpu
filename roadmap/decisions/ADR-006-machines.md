# ADR-006: Development and verification only on the cloud environment and the A100 workstation

- Status: **decided** (2026-10-08, project owner)
- Supersedes the machine assignments of plan.md (CCR for the reference runs, an 80 GB GPU for the full case) and of
  [plan-4.6/README.md](../plan-4.6/README.md) as first written on 2026-10-07.

## Decision

1. **Two machines only.** All development, all tests and all bit-for-bit comparisons run on
   - **CLOUD**, the cloud coding environment (gfortran, no GPU), and
   - **WS-A100**, the owner's workstation: two A100 40 GB and 56 host cores (Xeon Gold 6330).

   Nothing is developed or tested on CCR, and no 80 GB GPU is assumed.
2. **Apples to apples on one machine.** CPU-REF, the reference every GPU result must equal bit for bit, is built with
   the same `nvfortran` and the same container image as GPU-REPRO and **runs on the host CPUs of WS-A100**. Every
   reference run (dev case, acceptance case, windows, T-DRIFT) is made there. Reproducibility across MPI rank counts
   (T-DEC) is checked on the same host with 1, 28 and 56 ranks. The cross-machine test T-XM is dropped from the gates.
3. **CCR is data and context, not a test machine.** The input files of the Eaton case and the original CCR run come
   from CCR as files. The original run is compared with CPU-REF **statistically** (experiment E0: fields, fire
   perimeter, timing), never bit for bit; the CCR runs are "roughly matched", as the owner put it.
4. **The acceptance case fits one A100 40 GB.** The full Eaton case needs about 57 GB of device memory and cannot run
   on one 40 GB GPU. The acceptance gate G5 therefore runs on a new case, **`eaton_mid`**: the same dates, physics,
   fire options and ignition as the full case, d01 unchanged, and the largest d02 that fits one A100 40 GB with at
   least 15 % headroom by the memory estimator (expected about 400 x 400 x 60, fire grid about 1600^2, about 30 GB;
   task S0-09.5 decides). Its 17 h CPU-REF reference is run on the workstation's 56 cores. The dev case
   `eaton_small` (d02 181 x 181) stays the development case for all windows.
5. **The full Eaton case runs on the two A100s together.** Multi-GPU (phases S8-01 ... S8-05: device-resident halos,
   GPU-aware MPI, decomposition independence) is the only route to the full case and is the first work after G5. Its
   CPU-REF reference (17 h, 811 x 811 d02) is run on the workstation's host CPUs once that path exists, so the
   full-case comparison is also apples to apples on one machine.
6. **H100 is optional.** Every H100 measurement of the plans (performance stage, profiler, book Part VII) is kept as
   "if an H100 becomes available". No gate depends on it. Per-GPU tuning targets the A100 first.
7. **Memory limits follow.** The G-MEM gates become: dev case <= 25 GB (G1), acceptance case <= 34 GB at G3 and G5,
   with the full-case estimate reported from `gpu_mem_estimate.py` only.

## Why

- The owner's environment: no development or testing is allowed on CCR; the GPUs at hand are two A100 40 GB.
- A bit-for-bit comparison is only meaningful between two builds of one source by one compiler on one machine. A
  reference made elsewhere would add the machine to the list of things that can differ, and the port could not tell a
  real difference from a cross-machine one.
- The owner's requirement that the comparison be "apples to apples only on the A100 machine" is exactly the
  REPRO/GPU-REPRO pairing: same source, same compiler, same flags, same container, same node.

## Consequences

- plan.md keeps its design (kernels, tests, gates) but its machine columns and the full-case acceptance are amended
  (plan.md section 18). [plan-4.6/](../plan-4.6/README.md) and the root README carry the new assignments.
- `port/ccr/` (the CCR run scripts) is kept for reference but is not part of any gate.
- WPS and `real.exe` for the dev and acceptance cases are built and run on the workstation host.
- The CPU-REF runs take longer on 56 cores than on a cluster. The costs are measured first (S0-09.1) and the
  acceptance run length is 17 h as the goal, shortened only if the owner decides so after seeing the cost.
- The book's results tables report A100 numbers; H100 columns stay marked "(to be reported)" until an H100 is used.
