# ADR-006: Machines — no CCR; detect the GPU machine, then build and test for it

- Status: **decided, revision 2** (2026-10-11, project owner). Revision 1 (2026-10-08) is kept below for the record.

## Revision 2: the GPU machine varies

The owner: the test machine will sometimes have one A100 80 GB, sometimes two A100 40 GB, and sometimes one or more
H100s. Every build and every test must first detect which machine it is on, and then use only what is valid there.

### Decision

1. **Two kinds of machine, as in revision 1.** CLOUD (no GPU) and **GPU-M**, "the GPU machine at hand". Nothing is
   developed or tested on CCR; CCR supplies input files and the original run (compared statistically, E0).
2. **Detect first.** Every session, build and gate on GPU-M starts with `port/h100/machine.sh detect`, which writes
   `$WORK/machine.json`: GPU model, count, memory and compute capability; driver; host CPU model, sockets, cores, RAM;
   whether RAPL energy counters are readable; and a stable machine id (a hash, no host name). Scripts read their
   choices from it and never assume a machine.
3. **Profiles.** Capabilities are derived from the detected numbers, not from a name, so a machine not listed still
   works. The known profiles:

   | Profile | GPUs | Memory per GPU | cc |
   |---|---|---|---|
   | `a100-40x2` | 2 × A100 40 GB | 40 GB | 8.0 |
   | `a100-80x1` | 1 × A100 80 GB | 80 GB | 8.0 |
   | `h100-80xN` | N ≥ 1 × H100 80 GB (PCIe or SXM) | 80 GB | 9.0 |

   A GPU with compute capability below 8.0 stops the scripts: the build targets cc80 and cc90 only.
4. **What each profile can run** (`port/machines/capabilities.md`, generated from the rules below):

   | Item | Rule | a100-40x2 | a100-80x1 | h100-80xN |
   |---|---|---|---|---|
   | Memory gate G-MEM | peak ≤ 85 % of one GPU's memory | 34 GB | 68 GB | 68 GB |
   | Cases on one GPU | the memory estimate fits the gate | dev, `eaton_mid` | dev, `eaton_mid`, full | dev, `eaton_mid`, full |
   | Two runs at once | one per GPU | yes | no | if N ≥ 2 |
   | "GPU 0 equals GPU 1" checks | on two GPUs, else the same GPU twice | two GPUs | twice | two GPUs if N ≥ 2, else twice |
   | Acceptance G5 | `eaton_mid` always; the full case where it fits one GPU | `eaton_mid` | `eaton_mid` + full | `eaton_mid` + full |
   | Full case | one GPU if it fits, else multi-GPU (S8-01 … S8-05) | multi-GPU | one GPU | one GPU (multi-GPU if N ≥ 2) |
   | Multi-GPU phases S8-01 … S8-05 | need ≥ 2 GPUs | yes | no (recorded as not possible here) | if N ≥ 2 |
   | H100-only optimizations (TMA, clusters) | cc 9.0 | no | no | yes |
   | CPU reference ranks | 1, n/4, n/2, n host cores | from detection | from detection | from detection |

   `eaton_mid` (the largest d02 that fits one 40 GB GPU with the gate's headroom) fits every profile, so it is the
   acceptance case that every machine can repeat. The full case is added wherever the machine can run it.
5. **Apples to apples on one machine.** A bit-for-bit comparison is always CPU-REF against GPU-REPRO **with CPU-REF
   run on the host of the same machine**, or with an archived CPU-REF reference that the machine-change protocol has
   proven reproducible on this host (T-XM below). The CPU-REF binary is built for a portable x86 target
   (`-tp=haswell`), so the same binary is expected to give the same bits on every host; T-XM checks it.
6. **Machine-change protocol** (`port/gates/t_machine.sh`, phase S0-00), run whenever the detected machine id differs
   from the last one recorded in `$WORK`:
   1. toolchain check: the same pinned image; driver and CUDA versions recorded;
   2. **new GPU model or driver:** the device arithmetic tests and the OpenACC probes again (T-FMA, T-SIGNZERO,
      T-MINMAX, T-SUBNORM, T-RM-EXH, F-*): they are properties of the hardware, driver and compiler;
   3. **new host:** T-XM, CPU-REF on this host against the archived references on the gating tiers T0 and T1 and on
      W-20. Bitwise: the archive is valid here. Not bitwise: the references this machine needs are regenerated on its
      host before any GPU comparison, and the archive is keyed by host;
   4. **cross-GPU check (T-XG):** GPU-REPRO of the current commit on T0, T1 and W-20 against the archived GPU traces of
      the same commit from any other profile. The same binary must give the same bits on A100 and H100;
   5. the result goes into `port/machines/<id>.json` and the workbook; gates refuse to run until it has passed.
7. **Results carry the machine.** Every gate result, RESULTS.md row, kernel-database row and PERF.md number records
   the machine id and profile. Performance numbers of different profiles are never mixed without that column, and
   tuning settings (S6-15) are kept per GPU model.
8. **The v0.1 claim lists the profiles** on which G5 passed. G5 needs at least one profile; each further profile that
   becomes available repeats `eaton_mid` (and the full case where it fits) and adds itself to the list, with T-XG
   showing the GPU results are the same bits across GPU models.

### Why

- The owner's machines change between sessions. A plan bound to one machine either fails on the others or silently
  runs tests that are not valid there (a case that does not fit, a GPU-0-vs-GPU-1 check on a one-GPU machine).
- Bit-for-bit identity is only meaningful against a reference whose validity on this machine is shown, not assumed.
  T-XM and T-XG make the move between machines a tested event instead of a hope.
- Deriving capabilities from detected numbers keeps the scripts correct on a machine nobody listed.

---

## Revision 1 (2026-10-08, superseded in points 4–7 by revision 2): development and verification only on the cloud environment and the A100 workstation

- Status: superseded by revision 2 where they differ (machine profiles, acceptance cases, memory limits)
- Supersedes the machine assignments of plan.md (CCR for the reference runs, an 80 GB GPU for the full case) and of
  [plan-4.6/README.md](../plan-4.6/README.md) as first written on 2026-10-07.

### Decision

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

### Why

- The owner's environment: no development or testing is allowed on CCR; the GPUs at hand are two A100 40 GB.
- A bit-for-bit comparison is only meaningful between two builds of one source by one compiler on one machine. A
  reference made elsewhere would add the machine to the list of things that can differ, and the port could not tell a
  real difference from a cross-machine one.
- The owner's requirement that the comparison be "apples to apples only on the A100 machine" is exactly the
  REPRO/GPU-REPRO pairing: same source, same compiler, same flags, same container, same node.

### Consequences

- plan.md keeps its design (kernels, tests, gates) but its machine columns and the full-case acceptance are amended
  (plan.md section 18). [plan-4.6/](../plan-4.6/README.md) and the root README carry the new assignments.
- `port/ccr/` (the CCR run scripts) is kept for reference but is not part of any gate.
- WPS and `real.exe` for the dev and acceptance cases are built and run on the workstation host.
- The CPU-REF runs take longer on 56 cores than on a cluster. The costs are measured first (S0-09.1) and the
  acceptance run length is 17 h as the goal, shortened only if the owner decides so after seeing the cost.
- The book's results tables report A100 numbers; H100 columns stay marked "(to be reported)" until an H100 is used.
