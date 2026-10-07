# The profiler: built with the port, used to find acceleration on A100 and H100

A plan only: nothing here is built yet. The profiler grows in layers, each built in the port phase that first needs it
([plan-4.6/](plan-4.6/README.md)), so every kernel is measured from the day it runs on the device. It then:
- feeds Stage 6 (bit-neutral optimization);
- feeds the FAST mode studies (ADR-003);
- supplies the numbers and figures of the book's performance part ([plan-book.md](plan-book.md), Part VII).

- **Area:** `perf` ([AREAS.md](../AREAS.md)). Tools go in `perf/tools/`, measurements in `perf/db/`, reports in
  `perf/reports/`. Nothing of the profiler changes WRF results; the NVTX and timing hooks inside WRF are already part
  of the port (P1-PROF, S1-11).
- **Backlog cards it absorbs:** P-03 (traffic model), P-04 (launch model), P-05 (transfer model), P-06 (profiling
  scripts), P-07, P-08, P-11 (profiles and bottleneck taxonomy), P-21 … P-27 (optimizations O1–O11).

## 1. What the profiler must answer

1. Where does a step spend its time, per domain, per NVTX range (dynamics RK, acoustic, scalar transport, turbulence,
   each physics scheme, fire, forcing, I/O), on A100 and on H100?
2. For each kernel:
   - its share of the step;
   - the DRAM bytes it moves;
   - how close it runs to the GPU's measured bandwidth or compute roof;
   - what limits it: bandwidth, latency, occupancy, divergence, uncoalesced access, spills, or launch overhead.
3. Which changes would make the step faster without changing a bit:
   - fusion, caching, tiling, warp-level fixes, fewer launches, overlap;
   - with an estimate of the gain before anyone writes code.
4. Did a commit make anything slower (performance regression)?

## 2. Hardware (to be measured, not assumed)

Datasheet values below are a starting point only. PR-H1 … PR-H4 measure the real ceilings on the owner's machines,
and the models use the measured numbers.

| | A100 40 GB (PCIe / SXM) | A100 80 GB SXM | H100 PCIe 80 GB | H100 SXM 80 GB |
|---|---|---|---|---|
| Compute capability | 8.0 | 8.0 | 9.0 | 9.0 |
| SMs | 108 | 108 | 114 | 132 |
| HBM bandwidth (datasheet) | 1.56 TB/s | 2.04 TB/s | 2.0 TB/s | 3.35 TB/s |
| L2 cache | 40 MB | 40 MB | 50 MB | 50 MB |
| L1 + shared memory per SM | 192 KB (≤ 164 KB shared) | 192 KB | 256 KB (≤ 228 KB shared) | 256 KB |
| Registers per SM | 64 K × 32 bit | same | same | same |
| Max resident threads per SM | 2048 | 2048 | 2048 | 2048 |
| FP64 / FP32 (non-tensor) | 9.7 / 19.5 TFLOP/s | same | ≈ 26 / 51 | ≈ 34 / 67 |
| Features for this work | async copy to shared memory, L2 residency control | same | + TMA, thread-block clusters, distributed shared memory | same |

What this means for the port:
- **Memory-bound stencil kernels** (most of the dynamics) should speed up with bandwidth, about 2× from A100 40 GB to
  H100 SXM.
- **Launch- and latency-bound parts** gain less:
  - the many short kernels of the acoustic loop;
  - small dev-case domains.

  Fusion and launch reduction therefore matter more on H100.
- **Column physics** (WSM6, Noah, YSU, RRTMG) is limited by registers, local memory and divergence, not bandwidth.
  The larger H100 register and L1 budget changes the best batch shape.
- **The fire grid of the full case** is about 43 MB per field: just over the A100 L2 and just under the H100 L2. The
  dev case's 724² grid (2 MB per field) fits easily, so dev-case measurements of fire kernels must not be
  extrapolated to the full case without a full-case check (GPU80).

## 3. Layers

| Layer | What it gives | Built in phase | Machine |
|---|---|---|---|
| **L0 static** | per kernel, from the compiler: parallelization schedule and implicit data movement (`-Minfo=accel`); registers, spills, stack frame, shared memory (`-gpu=ptxinfo`); mapped to kernel IDs through the `! K-...` comment above each directive | S1-01.5 | WS-A100 (compile); parse anywhere |
| **L1 runtime hooks** | NVTX ranges: one per route call site, per `solve_em` section (the `BENCH_*` timers), per domain and RK stage; `WRF_GPU_TIMING` and memory logs; launch counter per step | S1-11 | WS-A100 |
| **L1b OpenACC profiling library** | a small C library on the OpenACC Profiling Interface (`acc_prof_register`, loaded with `ACC_PROFLIB`): per compute region, the source file and line, launches, gang/vector sizes and device time, plus every data event. This is the port's own lightweight profiler, cheap enough for every regression run. | S2-01 (first kernels) | CLOUD (write) → WS-A100 |
| **L2 system profile** | scripted `nsys` captures of a window: kernel table (count, total, mean, min, max), memcpy table (T-NSYS), launch gaps per stream, API overhead, NVTX range summary | S1-12 (copies), S2-23 (kernels) | WS-A100, GPU80 |
| **L3 kernel metrics** | `ncu` on a sampled set of kernels, with fixed section sets and the metrics in §3.1 | S2-23.4 | WS-A100, GPU80 |
| **L4 models** | measured roofline per kernel; bandwidth floor per step; launch-overhead, transfer and memory models; predicted vs measured | S2-23 (first), S6-01 (complete) | anywhere (inputs from L0–L3) |
| **L5 kernel database** | one row per kernel × GPU × case × window × commit (schema §3.2); diff between commits; report generator (Markdown for `perf/reports`, CSV for the book's pgfplots figures) | S2-01 (schema), grows every phase | CLOUD (tools), WS-A100 (data) |
| **L6 analyzers** | the opportunity finders of §5: fusion, caching and reuse, tiling, warp-level, launches and gaps, transfers | S6-02 (complete); A1 and A5 from S2-23 | CLOUD (tools), WS-A100 |
| **H hardware** | measured ceilings of each GPU: bandwidth, L2 effects, launch latency, reductions, host links | S0-04.5 (query), S6-01 (micro-benchmarks) | WS-A100, GPU80 |

### 3.1 Kernel metrics (L3)

| Question | ncu metric (Nsight Compute names) |
|---|---|
| time | `gpu__time_duration.sum` |
| DRAM traffic and throughput | `dram__bytes_read.sum`, `dram__bytes_write.sum`, `dram__throughput.avg.pct_of_peak_sustained_elapsed` |
| cache hit rates | `lts__t_sector_hit_rate.pct` (L2), `l1tex__t_sector_hit_rate.pct` (L1) |
| coalescing | `l1tex__t_sectors_pipe_lsu_mem_global_op_ld.sum` / `l1tex__t_requests_pipe_lsu_mem_global_op_ld.sum` (sectors per request; 4 is ideal for 4-byte loads by a full warp) |
| divergence | branch efficiency from the SourceCounters section; `smsp__thread_inst_executed_per_inst_executed.ratio` |
| occupancy | `sm__warps_active.avg.pct_of_peak_sustained_active`; theoretical occupancy and its limiter (registers, shared memory, block size) |
| stalls | `smsp__pcsamp_warps_issue_stalled_*` (top 3 reasons) |
| spills | `l1tex__t_bytes_pipe_lsu_mem_local_op_ld.sum`, `..._op_st.sum` |
| work | FP32 and FP64 instruction counts (`smsp__sass_thread_inst_executed_op_{f,d}{add,mul,fma}_pred_on.sum`) for the arithmetic intensity |

**Sampling rule:** profile one launch of each kernel per window (`--launch-skip` to reach a typical step), for:
- the top 30 kernels by time;
- one kernel per template (A, B, C, D, G, CP);
- every kernel new in the phase.

ncu serializes and replays kernels, so its timings are never used for the step time; those come from L1b and L2.

### 3.2 Kernel database schema (L5)

`kernel_id, route, routine, file, line, template, stage_phase, gpu, gpu_clock_mode, case, window, build_mode,
commit, launches_per_step, time_per_launch_us, share_of_step, dram_bytes, bw_pct_measured_peak, l2_hit, l1_hit,
sectors_per_request, branch_efficiency, occupancy_achieved, occupancy_theoretical, registers, spill_bytes,
local_bytes, shared_bytes, flops_fp32, flops_fp64, arithmetic_intensity, bound_class, notes`

Rules:
- One CSV per (commit, GPU, window), under `perf/db/`, kept small (no raw profiles in git; raw `.nsys-rep` and
  `.ncu-rep` files stay on the machine with their path recorded).
- `bound_class` is one of: `bandwidth`, `latency`, `launch`, `occupancy`, `divergence`, `uncoalesced`, `spills`,
  `compute`. It is set by the rules of the analyzers.
- Clocks are locked for measurements (`nvidia-smi -lgc` where the owner allows it); otherwise the clock mode is
  recorded.

## 4. Which optimizations keep the bits (classification)

| Class | Meaning | Examples | Tests before merge |
|---|---|---|---|
| **R0** neutral by construction | no arithmetic statement changes: scheduling, data movement, launch shape | async queues; merging boundary strips that run the same statements; `vector_length`/`num_gangs`; register caps; L2 persistence; pinned buffers; removing kernels that write no state | T-AB of the routes, T-REG-20 |
| **R1** neutral by proof | the same statements on the same operands, regrouped | fusion of pointwise producer→consumer; shared-memory tiling that only stages loads; splitting a kernel by branch (fire band/non-band); loop interchange of independent iterations; recomputing a producer value with the same operations | a written legality note per change; T-AB, T-TRACE-100, T-TRACE-RAD; OpenACC vs CUDA Fortran on W-20 |
| **R2** order-preserving parallel accumulation | parallel work whose sums are still added in the original order | RRTMG performance version (g-point contributions computed in parallel, summed sequentially in band/g order) | R1 tests + column harness |
| **F** changes bits | anything that changes an operation, its rounding or its order | FMA, fast math, tree or shuffle reductions of floats, mixed precision, algorithm changes | FAST mode only (ADR-003), statistical validation |

Integer and bitwise reductions (`+`, `ieor`, `max` of exact values) are exact in any order and are R0. A
floating-point `max`/`min` reduction is exact too. A floating-point sum reduction is not.

## 5. Analyzers (L6): how each opportunity is found

| ID | Opportunity | Inputs | Rule | Output |
|---|---|---|---|---|
| **A1** | **Fusion** | kernel order per step (L2); read/write sets and index offsets per kernel from the source (`port/tools/ftn.py` on each kernel body); iteration spaces | consecutive kernels on the same queue, no host work between, same iteration space; the consumer reads the producer's outputs only at the same index (pointwise, R1) or within radius *r* (stencil: only with recomputation or a tile halo) | ranked chains with DRAM bytes saved (the intermediate's write + read) and launches saved |
| **A2** | **Caching and reuse** | per kernel, the set of (array, offset) reads; per step, which kernels read each array; footprints | arrays read at ≥ 3 offsets → `!$acc cache`/shared-memory candidate; small read-only arrays read by many kernels (tables, 2D fields) → constant memory, read-only path, or L2 persistence; working sets near the L2 size flagged per GPU | candidate list with expected L2/L1 hit change |
| **A3** | **Tiling** | stencil radius and shape (A2), iteration space, measured L1/L2 hit rates and DRAM bytes (L3) | bytes moved / minimal bytes > 1.5 for a stencil kernel → shared-memory tile candidate; tile size from the GPU's shared memory (164 KB vs 228 KB per SM); H100 TMA and cluster variants | per kernel: expected DRAM reduction and tile shape |
| **A4** | **Warp-level** | L3 metrics, L0 registers and spills | branch efficiency < 90 % → divergence (split by branch, warp-uniform conditions); sectors/request > 4.5 → coalescing (loop order, index mapping); occupancy limited by registers → register caps or kernel split; spills > 0 → split or fewer live arrays | diagnosis line per kernel with the suggested R0/R1 change |
| **A5** | **Launches and gaps** | L2 kernel table and gaps | kernels < 10 µs; idle time between kernels per step; launches per d02 step | merge, async and graph candidates with the time at stake |
| **A6** | **Transfers** | T-NSYS tables per window | copies not explained by a sync point; pageable vs pinned; bytes per step | list (also a correctness signal) |

## 6. Tasks

Size S ≤ ¼ day, M ≤ ½ day. "Built in" refers to the phase of [plan-4.6](plan-4.6/README.md) that creates the need.

| Task | What | Machine | Size | Built in | Done when |
|---|---|---|---|---|---|
| PR-H1 | Device query of every GPU (SMs, clocks, L2, memory, persisting-L2 limit, ECC) | WS-A100, GPU80 | S | S0-04.5 | ENVIRONMENT.md table |
| PR-H2 | Bandwidth micro-benchmarks in OpenACC and CUDA Fortran: copy, scale, add, triad; strided; working-set sweep across L2 | WS-A100, GPU80 | M | S6-01 | measured ceilings in `perf/db/hw.csv` |
| PR-H3 | Launch latency (empty kernel, OpenACC and CUDA Fortran, sync and async), reduction throughput, host-link bandwidth (pinned/pageable) | WS-A100, GPU80 | M | S6-01 | `perf/db/hw.csv` |
| PR-H4 | Roofline ceilings (FP32, FP64, DRAM, L2) from H2/H3 | anywhere | S | S6-01 | ceilings file |
| PR-L0.1 | `minfo_parse.py`: `-Minfo=accel` → per kernel schedule, `seq` loops, implicit copies | CLOUD | M | S1-01.5 | parses a full build log |
| PR-L0.2 | `ptxinfo_parse.py`: registers, spills, stack, shared memory per kernel | CLOUD | S | S1-01.5 | CSV |
| PR-L0.3 | Kernel-ID map: compiler kernel name (`<routine>_<line>_gpu`) ↔ `! K-...` comment ↔ `kernels.csv` | CLOUD | S | S1-01.5 | every kernel mapped |
| PR-L1.1 | NVTX design: names, nesting, colors per category; payload with domain and RK stage | CLOUD | S | S1-11 | spec in this file's appendix |
| PR-L1.2 | Per-route NVTX ranges generated with the islands (no hand edits) | CLOUD | S | S1-11 | ranges in nsys |
| PR-L1.3 | Overhead check: NVTX and timing on/off, W-20 time difference < 1 % | WS-A100 | S | S1-11 | measured |
| PR-L1.4 | Launch counter per d02 step (from L1b) | WS-A100 | S | S2-15 | number in PERF.md |
| PR-L1b.1 | `acc_prof` library: kernel-launch and data events with file:line, device time via CUDA events, CSV at exit | CLOUD → WS-A100 | M | S2-01 | CSV for W-20 |
| PR-L1b.2 | Aggregation per kernel ID and per step; integration into `window.sh` (`WRF_ACC_PROF=1`) | CLOUD | S | S2-01 | one command |
| PR-L2.1 | `nsys_capture.sh <build> <window>`: capture with NVTX, CUDA, OpenACC traces; export SQLite | WS-A100 | S | S2-23 | report file |
| PR-L2.2 | `nsys_kernels.py`: kernel table, gaps, API overhead, NVTX summary from SQLite | CLOUD | M | S2-23 | CSV + Markdown |
| PR-L3.1 | `ncu_sample.sh`: the sampling rule of §3.1, section sets, metric list | WS-A100 | M | S2-23.4 | one report per window |
| PR-L3.2 | `ncu_parse.py` → kernel DB columns | CLOUD | S | S2-23.4 | CSV |
| PR-L4.1 | Roofline per kernel (measured ceilings, AI from L3) and plot data | CLOUD | M | S2-23.4 | CSV + figure data |
| PR-L4.2 | Bandwidth floor per step and efficiency (time / floor) | CLOUD | S | S2-23.4 | number per window |
| PR-L4.3 | Launch-overhead model (launches × measured latency) vs measured gaps | CLOUD | S | S2-23.4 | table |
| PR-L4.4 | Transfer model per phase of the port (from the islands and sync points) vs T-NSYS bytes | CLOUD | M | S1-12 | table |
| PR-L4.5 | Memory model: `gpu_mem_estimate.py` vs the memory log; per-GPU fit rule (40 vs 80 GB) | CLOUD | S | S1-12, S3-25 | ≤ 5 % error |
| PR-L5.1 | DB schema, CSV writer, validation | CLOUD | S | S2-01 | schema checked in |
| PR-L5.2 | `perfdiff.py`: commit vs commit, regressions > 5 % flagged | CLOUD | S | S2-23 | report |
| PR-L5.3 | Report generator (Markdown) and book export (pgfplots CSV) | CLOUD | M | S2-23 | report and figure from the same data |
| PR-L5.4 | Regression hook: L1b numbers of the nightly regression (S7-02) into the DB | WS-A100 | S | S7-02 | nightly rows |
| PR-A1 | Fusion finder (§5 A1) | CLOUD | M ×2 | S2-23 (first), S6-02 | ranked chains for the acoustic loop |
| PR-A2 | Reuse and caching report | CLOUD | M | S6-02 | candidate list |
| PR-A3 | Tiling candidates | CLOUD | M | S6-02 | per-kernel estimate |
| PR-A4 | Warp-level diagnosis | CLOUD | M | S3-25 (first), S6-02 | diagnosis per kernel |
| PR-A5 | Launch and gap report | CLOUD | S | S2-23 | report |
| PR-A6 | Transfer report (T-NSYS extended) | CLOUD | S | S1-12 | report |
| PR-R1 | Dynamics profile on A100 | WS-A100 | M | S2-23.4 | `perf/reports/S2-dynamics-a100.md` |
| PR-R2 | Physics profile on A100 | WS-A100 | M | S3-25.5 | report |
| PR-R3 | Fire profile on A100 | WS-A100 | M | S4-13.3 | report |
| PR-R4 | Baseline full case on H100 and dev case on A100 | GPU80, WS-A100 | M | S6-01 | report |
| PR-R5 | Final tuned report, both GPUs | GPU80, WS-A100 | M | S6-16 | PERF.md |
| PR-V1 | Repeatability: 5 runs, coefficient of variation < 2 % per range | WS-A100 | S | S2-23 | measured |
| PR-V2 | Model sanity: L3 DRAM bytes vs the static traffic model per kernel (P-03) within 20 % | CLOUD | S | S6-01 | table |

## 7. How a finding becomes an optimization

1. An analyzer row (A1 … A6) names a kernel or chain, its class (R0/R1/R2) and the expected gain.
2. Stage 6 takes the top rows into the optimization ladder ([stage-6-performance.md](plan-4.6/stage-6-performance.md)).
   The ladder is: legality note → code → bitwise tests → measurement on A100 and H100 → keep or reject.
3. The kernel database keeps the before/after rows. The report and the book figure are generated from them.

## 8. In the book

The profiler's method, the hardware facts it measures, and each optimization family with a worked example from this
port make up Part VII of the book ([plan-book.md](plan-book.md), chapters 30–37). Every number and figure there comes
from `perf/db` and names the command that produced it.
