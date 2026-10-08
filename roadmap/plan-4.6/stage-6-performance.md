# Stage 6 — Performance, bit-neutral

Goal: make the bit-for-bit GPU build fast on A100 and H100 without changing a single bit of the results. Every
optimization is measured first, kept only if it pays, and passes the same bitwise tests as the port.

The profiler that finds and measures the opportunities is built during Stages 1–5 ([plan-profiler.md](../plan-profiler.md),
layers L0–L6). This stage uses it. The concepts (fusion, caching, tiling, warp-level work) and their
implementations become Part VII of the book ([plan-book.md](../plan-book.md)).

**Machines ([ADR-006](../decisions/ADR-006-machines.md)):**
- WS-A100 for every measurement and every correctness test: the dev case for development, the acceptance case
  `eaton_mid` for the numbers that count, the full case on both GPUs once S8-01 … S8-04 exist;
- an H100 only if one becomes available; every "H100" item below is optional and no gate depends on it.

Per-GPU settings stay in `port/ENVIRONMENT.md`.

## The optimization ladder (every phase S6-03 … S6-15)

| Step | What | Machine |
|---|---|---|
| O-1 evidence | the analyzer report names the kernels and the expected gain (bytes, launches, divergence) | WS-A100 |
| O-2 legality | the change keeps every IEEE operation, its operands and its order for every output value (CODING_STANDARD.md rule 1; plan-profiler §4 classification) | CLOUD (review) |
| O-3 code | under `#ifdef WRF_GPU`; a CUDA Fortran version under `#ifdef WRF_CUF_<KERNEL>` beside the OpenACC one (CODING_STANDARD.md §11) | CLOUD |
| O-4 bitwise | T-AB of the touched routes; T-TRACE-100; T-TRACE-RAD; T-REG-20; for CUDA Fortran also OpenACC vs CUDA Fortran on W-20 | WS-A100 |
| O-5 measure | kernel DB before/after on A100 (dev and acceptance case; H100 optional); keep only if the step gets ≥ 3 % faster or the kernel ≥ 10 % (and no other kernel loses) | WS-A100 (H100 optional) |
| O-6 record | PERF.md row; book example if instructive | CLOUD |

A rejected optimization is recorded with its numbers, so it is not tried again.

---

| Phase | Title | Tasks (each S/M) | Machine |
|---|---|---|---|
| **S6-01** | Baseline profiles | .1 dev case on A100: nsys of W-100 and W-RAD, ncu of the top-30 kernels; .2 acceptance case `eaton_mid` on A100: 1 h nsys, ncu top-30 (an H100, if available, repeats both); .3 bandwidth floor and roofline per kernel (PR-M1, PR-M2); .4 time per NVTX range vs Prof-CPU; .5 report `perf/reports/S6-01-baseline.md` | WS-A100 (H100 optional) |
| **S6-02** | Opportunity reports | .1 fusion finder (PR-A1); .2 cache and reuse report (PR-A2); .3 tiling candidates (PR-A3); .4 warp report: divergence, coalescing, occupancy, spills (PR-A4); .5 launch and gap report (PR-A5); .6 ranked list with expected gains, one row per later phase | WS-A100 |
| **S6-03** | O1: fire NaN-check kernels out of production builds (they touch no state; kept in GPU-DEBUG) | .1 code; .2 bitwise; .3 measure | WS-A100 |
| **S6-04** | O2: merge boundary-strip kernels (4 strips → 1 with an index map) and zero/copy kernels | .1 BC family; .2 spec/relax family; .3 acoustic-loop BC updates; .4 bitwise; .5 measure | WS-A100 |
| **S6-05** | O3: asynchronous queues for independent kernels (species loops, independent BC calls); `wait` before dependents | .1 dependency map of the step (PR-A1 data); .2 queues in dynamics; .3 physics; .4 bitwise; .5 measure | WS-A100 |
| **S6-06** | O7 fusion I: pointwise sequences inside one routine (same iteration space, producer before consumer at the same index) | .1 `small_step_prep`; .2 `rk_addtend_dry`, `zero_tend` groups; .3 `calc_p_rho`/`small_step_finish`; .4 physics glue; .5 bitwise, measure | WS-A100 |
| **S6-07** | Fusion II: chains across routines in the acoustic sub-step (pointwise only; a stencil consumer is fused only by recomputing its producer with the same operations) | .1 legality table per chain; .2 `advance_uv` + `spec_bdyupdate`; .3 `advance_mu_t` + `advance_w` inputs; .4 bitwise, measure | WS-A100 |
| **S6-08** | Launch overhead: CUDA Graph of one acoustic sub-step through CUDA Fortran stream capture on the OpenACC queue (experiment) | .1 probe; .2 capture and replay; .3 bitwise; .4 measure; .5 decision | WS-A100 (H100 optional) |
| **S6-09** | Caching: `!$acc cache` for stencil reuse; read-only paths; L2 persistence windows (`cudaAccessPolicyWindow`) for hot arrays (fire grid, tables); small tables in constant memory | .1 candidates from PR-A2; .2 advection; .3 fire WENO; .4 L2 window experiment on A100 (vs H100 if available: 40 vs 50 MB L2); .5 bitwise, measure | WS-A100 (H100 optional) |
| **S6-10** | Coalescing and loop order: kernels whose `sectors/request` is high; inner index `i` across the vector dimension; column kernels' access pattern | .1 list from PR-A4; .2 fixes, one kernel per commit; .3 bitwise, measure | WS-A100 |
| **S6-11** | Tiling: shared-memory tiles for wide stencils (5th/6th-order advection, diffusion, fire WENO) in CUDA Fortran; 2.5D blocking along j or k; H100 TMA and thread-block clusters as a second step | .1 advection y-flux (Template B) tile; .2 x-flux; .3 diffusion; .4 fire `tend_ls`; .5 H100 TMA variant (optional); .6 bitwise (OpenACC vs CUDA Fortran), measure | WS-A100 (H100 optional) |
| **S6-12** | Warp-level: divergence and occupancy. Band and non-band points of the fire level set in separate passes; boundary specials in separate kernels; `maxregcount`/launch bounds per file; spills of column physics | .1 fire divergence; .2 advection edge branches; .3 register caps per kernel and GPU; .4 local-memory spills (split kernels); .5 bitwise, measure | WS-A100 (H100 optional) |
| **S6-13** | Column physics: RRTMG performance version (O6: (b, layer) and (b, g) parallelism; g-point sums kept in the original order); WSM6 and Noah occupancy | .1 K-RRTMG-TAU; .2 K-RRTMG-RT1; .3 K-RRTMG-RT2 (ordered sums); .4 WSM6 batch shape; .5 bitwise (T-RRTMG-COL, T-TRACE-RAD), measure | WS-A100 (H100 optional) |
| **S6-14** | I/O and transfers: pinned buffers and asynchronous history D2H (O8); lazy `o3rad` (O10); parent-side forcing pack (O11); quilting | .1 O8; .2 O10 with the restart rule; .3 O11; .4 T-OUT, T-O3 bitwise, measure | WS-A100 (H100 optional) |
| **S6-15** | Per-GPU tuning (O4/O5): `vector_length`, `num_gangs`, register caps per kernel for A100 and for H100; settings files | .1 A100 sweep (dev case); .2 sweep on the acceptance case (H100 sweep optional); .3 settings in ENVIRONMENT.md | WS-A100 (H100 optional) |
| **S6-16** | Stage closure (G6) | .1 the tuned binary repeats G5 bitwise on WS-A100; .2 PERF.md complete for A100 (speedups vs CPU-REF on the 56 host cores and, statistically, vs the original CCR run; H100 if available); .3 book Part VII results chapter | WS-A100, CLOUD |

## Beyond bit-neutral

Changes that alter bits are outside this stage: FMA, fast intrinsics, reordered or tree reductions, mixed precision.
They belong to the FAST build mode ([ADR-003](../decisions/ADR-003-repro-and-fast-modes.md), backlog cards P-12 …
P-14), which is validated statistically against an ensemble. They are never part of REPRO.
