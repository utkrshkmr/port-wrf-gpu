# The textbook: WRF and WRF-Fire, their algorithms, and their GPU port

A plan only: no chapter is written by this plan. The book (`book/`, area `book`, track B of the backlog) grows from
its current 21-chapter skeleton into a full textbook in LaTeX, built as a PDF by CI. It covers:
- the whole WRF ecosystem (from WPS to `wrf.exe`), with the algorithms in detail;
- WRF-Fire and CFBM;
- the GPU port: method, reproducibility, profiler and optimizations.

**The GPU part is written as concepts plus implementations:**
- each optimization concept (fusion, caching, tiling, warp-level work, launch reduction) is explained in general;
- then shown on a kernel of this port, with measured A100 and H100 numbers from the profiler
  ([plan-profiler.md](plan-profiler.md)).

## 1. Readers and promises

- **Readers:** atmospheric scientists who want to know what WRF computes and how; HPC engineers who want to know how a
  large Fortran model is ported to GPUs bit for bit; fire modelers.
- **Promises:**
  - every equation names the routine that implements it (`\src{file}{routine}`);
  - every number about the port comes from a file of the repository and names the command that produced it;
  - every citation is checked against the publisher.

## 2. Where it stands

| Part | Chapters now | State |
|---|---|---|
| Front | preface, introduction, the case | draft |
| Model, physics, fire, architecture | 03–14 | outline boxes (cards B-03 … B-14) |
| Reproducibility | 15 | draft |
| GPUs, port, performance, multi-GPU, versions | 16–20 | outline; chapter 16 still describes OpenMP (to be rewritten for OpenACC + CUDA Fortran, ADR-001 rev 2) |
| Appendices | kernels, namelist | outline |

The cloud environment cannot build the book (no TeX); CI does on every push to `book/`. The artifact is
`wrf-gpu-book`.

## 3. Structure (new): 8 parts, 40 chapters, 6 appendices

Each chapter lists its sections, its algorithm boxes (`Algorithm n.m`), its figures, and its main sources. Sources
marked † must still be entered in `refs.bib` and checked (task B-00.6). Page estimates are for planning only.

### Part I — The WRF ecosystem

**1 Introduction** (exists, revise; 10 pp): what WRF is; ARW vs NMM history; the community; why GPUs; what "bit for
bit" means and why the fire needs it; how to read the book.

**2 The WRF system end to end** (new; 18 pp)
- WPS: `geogrid` (static fields, map projections), `ungrib` (GRIB decoding, Vtables), `metgrid` (horizontal
  interpolation, masks);
- `real.exe` (vertical interpolation to the hybrid coordinate, base state, soil initialization, lateral boundary
  file);
- `ideal.exe`;
- `wrf.exe`;
- `ndown`;
- post-processing (UPP, wrf-python);
- the relatives: WRFDA, WRF-Chem, WRF-Hydro.
- Figure: the data-flow diagram of the whole system.
- Sources: Skamarock et al. 2019 (ARW Tech Note v4)†; WPS user guide†.

**3 The Eaton case** (exists, revise; 12 pp): domains, nesting, namelist, inputs and their md5s, the fire; the
reference runs; what the GPU run must reproduce.

**4 From analysis to initial and boundary conditions** (new; 14 pp)
- Vertical interpolation in `real.exe`.
- Hydrostatic balance of the initial state.
- Boundary tendencies.
- Algorithm 4.1: building the dry hydrostatic column.

### Part II — The ARW dynamical core

**5 Governing equations** (outline → full; 20 pp)
- Flux-form compressible non-hydrostatic equations.
- The hybrid sigma-pressure coordinate (`hybrid_opt = 2`).
- Map factors.
- Moist potential temperature θm (`use_theta_m`).
- Perturbation forms.
- Figure: the coordinate surfaces over terrain.
- `\src` throughout `dyn_em/`.
- Sources: Skamarock et al. 2019†; Klemp 2011 (hybrid coordinate)†.

**6 Time integration** (outline → full; 22 pp)
- RK3 (Wicker–Skamarock).
- Split-explicit acoustic steps.
- Divergence damping and off-centering (`epssm`).
- The vertically implicit w–φ solve (tridiagonal).
- Algorithm 6.1: one RK3 step of `solve_em`.
- Algorithm 6.2: one acoustic sub-step (`advance_uv`, `advance_mu_t`, `advance_w`).
- Algorithm 6.3: the tridiagonal solve of `advance_w`.
- Figure: the step timeline (RK stages × acoustic sub-steps).
- Sources: Wicker & Skamarock 2002†; Klemp, Skamarock & Dudhia 2007†.

**7 Spatial discretization and advection** (outline → full; 24 pp)
- Arakawa C grid.
- Flux-form advection of orders 2–6; odd orders as upwind.
- The positive-definite limiter (`advect_scalar_pd`) and the monotonic option.
- WENO options.
- Algorithm 7.1: 5th/3rd-order flux of `advect_u`.
- Algorithm 7.2: the PD limiter, including the split form used on the GPU and why it is identical.
- Figures: staggering; the flux stencil.
- Sources: Wicker & Skamarock 2002†; Skamarock & Weisman 2009†.

**8 Boundaries and nesting** (outline → full; 20 pp)
- Specified and relaxation zones.
- Open, periodic and symmetric boundaries.
- Nest interpolation (`interp_fcn`); one- and two-way nesting; feedback and smoothing.
- `med_force_domain` coupling and uncoupling.
- Algorithm 8.1: the relaxation-zone tendency.
- Algorithm 8.2: forcing one nest step.
- Figure: the zones; the nest footprint.

**9 Diffusion, turbulence and damping** (outline → full; 22 pp)
- `diff_opt`, `km_opt`: 2D Smagorinsky and 1.5-order TKE.
- Deformation and stress tensor.
- `w_damping`; Rayleigh damping (`damp_opt = 3`); the 6th-order filter.
- Algorithm 9.1: the TKE equation terms in WRF order.
- Sources: Deardorff 1980†; Skamarock et al. 2019†.

**10 Coriolis, curvature, map projections** (new; 8 pp).

### Part III — Physics

**11 The physics interface** (new; 12 pp)
- Tendencies, coupling with μ, physics call order and time steps (`radt`, `bldt`, …).
- `phy_prep`, `update_phy_ten`.
- Algorithm 11.1: physics inside RK stage 1.

**12 Microphysics** (outline → full; 26 pp)
- WSM6 in depth: species, processes, sedimentation (semi-Lagrangian `nislfv_rain_plm`), saturation adjustment.
- Overview of Thompson, Morrison, P3, NSSL.
- Algorithm 12.1: one WSM6 column.
- Sources: Hong & Lim 2006†; Hong, Dudhia & Chen 2004†.

**13 Radiation** (outline → full; 28 pp)
- RRTMG LW in depth: correlated-k, 16 bands, g-points, `taumol`, cloud overlap and McICA (KISS generator),
  `rtrnmc`.
- Dudhia SW.
- Ozone climatology and interpolation; CAM greenhouse gases.
- Overview of RRTMG SW and Goddard.
- Algorithms 13.1 (one RRTMG column) and 13.2 (McICA sub-columns).
- Sources: Mlawer et al. 1997†; Iacono et al. 2008†; Pincus et al. 2003†; Dudhia 1989†.

**14 Surface layer** (outline → full; 14 pp)
- Monin–Obukhov similarity; the revised MM5 scheme (`sfclayrev`); stability functions and tables.
- `zolri` and its defined-result fix.
- Sources: Jiménez et al. 2012†.

**15 Land surface** (outline → full; 24 pp)
- Noah in depth: soil heat and moisture, canopy resistance, Penman, snow, frozen soil (`SFLX` tree); glacial and sea
  ice.
- Overview of Noah-MP, RUC and CLM.
- Algorithm 15.1: one Noah point step.
- Sources: Chen & Dudhia 2001†; Ek et al. 2003†.

**16 Planetary boundary layer and LES** (outline → full; 18 pp)
- YSU in depth: non-local K, entrainment, `get_pblh`.
- When to run LES (d02 here) instead.
- Overview of MYNN and ACM2.
- Sources: Hong, Noh & Dudhia 2006†.

**17 Cumulus and the grey zone** (new; 10 pp, overview): Kain–Fritsch, Grell–Freitas, scale awareness; why the case
needs none.

**18 Other physics** (new; 8 pp, overview): urban, lake, slope radiation, FDDA nudging, chemistry hooks.

### Part IV — Fire

**19 Fire behavior basics** (new; 16 pp)
- Rothermel's rate of spread.
- Fuel models: Anderson 13, Scott–Burgan 40.
- Fuel moisture, wind and slope factors.
- Sources: Rothermel 1972†; Anderson 1982†; Scott & Burgan 2005†.

**20 WRF-Fire numerics** (outline → full; 30 pp)
- The refined fire grid (`sr_x`, `sr_y`); atmosphere-to-fire interpolation (log profile).
- The level-set equation; RK3 in `prop_ls_rk3`; ENO/WENO5 in `tend_ls`; reinitialization.
- Ignition; fuel consumption over subcells; heat and moisture fluxes; feedback into the atmosphere.
- Algorithms 20.1 (one fire step), 20.2 (`tend_ls` per point), 20.3 (`fuel_left` per cell).
- Figure: fire perimeter evolution of the Eaton run (from the traces of S4-12).
- Sources: Clark et al. 2004†; Mandel, Beezley & Kochanski 2011†; Coen et al. 2013†; Muñoz-Esparza et al. 2018†.

**21 CFBM** (outline; 12 pp): NCAR's new fire behavior model and how it differs (analysis/cfbm.md); filled in Stage 3
of the roadmap.

### Part V — Software

**22 Architecture** (outline → full; 20 pp)
- Driver, mediation and model layers.
- The domain type; tiles, patches and memory dimensions.
- The Registry and generated code (`gen_allocs`, `nest_interpdown`).
- Figures: the call tree of one step; the layers.

**23 Parallelism on CPUs** (new; 14 pp): RSL_LITE halos, MPI decomposition, OpenMP tiles, I/O quilting.

**24 I/O and the build** (new; 12 pp): the I/O API and netCDF; history and restart streams; `configure`, stanzas,
`compile`; the Registry at build time.

### Part VI — GPUs and the port

**25 GPU architecture for this book** (rewrite of 16; 20 pp)
- SMs, warps, schedulers.
- Registers, local memory, shared memory, L1, L2, HBM; bandwidth and latency; occupancy.
- A100 and H100 compared: SMs, L2 40 vs 50 MB, shared memory 164 vs 228 KB per SM, HBM2e vs HBM3, TMA, clusters.
- Figure: the memory hierarchy with measured A100/H100 numbers (plan-profiler PR-H).
- Sources: NVIDIA A100 whitepaper 2020†; NVIDIA H100 whitepaper 2022†.

**26 Programming models** (new; 22 pp)
- OpenACC: `parallel loop`, `loop seq`, `routine seq`, data regions, `present`, `update`, `declare create`, `async`.
- CUDA Fortran: kernels, shared memory, warp intrinsics, streams; interop with `host_data use_device`.
- Why this pair (ADR-001 rev 2); what would change for AMD.
- Listings: one kernel in OpenACC and in CUDA Fortran.
- Sources: OpenACC 3.3 specification†; NVIDIA CUDA Fortran guide†.

**27 Floating-point reproducibility** (exists as 15, complete; 22 pp)
- IEEE 754; FMA contraction; flush-to-zero; correctly rounded functions; the `rp_*` library; order of operations;
  compiler flags.
- Proving bit equality: the bit-hash tracer, T-AB, T-TRACE.
- Algorithm 27.1: argument reduction of `rp_sin`.
- Sources: Goldberg 1991†; IEEE 754-2019†; Muller et al. Handbook of FP arithmetic†.

**28 The porting method** (from 17; 22 pp)
- Residency.
- Islands and routes.
- The call check.
- Templates A–G and CP, with one worked example each.
- Work arrays and the pool.
- Shared refactors and certification.
- The routine ladder (plan-4.6).

**29 The port, subsystem by subsystem** (from 17; 30 pp)
- Dynamics, physics, fire, forcing.
- For each: the hard cases (rolling buffers, recurrences, column physics, the PD limiter split, RRTMG batching) and
  how bit equality was kept.
- Numbers from RESULTS.md.

### Part VII — Performance on A100 and H100

**30 Profiling methodology** (new; 16 pp): NVTX, the OpenACC profiling interface, nsys, ncu; sampling; repeatability;
the kernel database (plan-profiler §3).

**31 Performance models** (from 18; 16 pp)
- Roofline with measured ceilings.
- Bandwidth floor of a step.
- Launch-overhead, transfer and memory models.
- Figures: the roofline of the port's kernels on A100 and H100.
- Sources: Williams, Waterman & Patterson 2009†.

**32 Optimization I: fewer launches and kernel fusion** (new; 18 pp)
- Launch costs.
- Fusion legality (pointwise vs stencil; recomputation), in bitwise terms.
- Asynchronous queues; CUDA Graphs.
- Worked example: the acoustic sub-step (S6-06, S6-07, S6-08) with before/after numbers.

**33 Optimization II: memory, caching and data layout** (new; 18 pp)
- Coalescing.
- The read-only path and constant memory.
- L2 residency control (A100 vs H100).
- `!$acc cache`.
- Layout of WRF arrays (i fastest) and its consequences for column kernels.
- Worked examples from S6-09, S6-10.

**34 Optimization III: tiling and shared memory** (new; 20 pp)
- Stencil reuse; 2.5D blocking; tile and halo sizes vs shared memory.
- H100 TMA and thread-block clusters.
- Worked example: the advection y-flux (Template B) in CUDA Fortran (S6-11).
- Algorithm 34.1: tiled 5th-order flux.

**35 Optimization IV: warp-level work** (new; 18 pp)
- Divergence and how to remove it without changing bits (splitting by branch, warp-uniform conditions).
- Occupancy and registers; spills and local memory.
- Reductions, and why float tree reductions are FAST-only.
- Worked examples: fire WENO band split, column physics (S6-12).

**36 Column physics on GPUs** (new; 16 pp): thread per column; fixed-size locals; stack; batching RRTMG; ordered
parallel sums (R2); worked example S6-13.

**37 Results** (from 18; 14 pp)
- Speedups on A100 and H100 against CPU-REF and the original CCR run.
- Time per range; energy to solution (P-15).
- All from PERF.md.

**38 Multi-GPU** (from 19; 14 pp): device halos, GPU-aware MPI, decomposition independence, 2× A100 40 GB (Stage 8).

### Part VIII — Evolution

**39 WRF versions** (from 20; 12 pp): 4.6.0 → 4.8.0 and the forward port (ADR-002).

**40 Outlook** (new; 6 pp): CFBM, AMD, FAST mode, upstreaming.

### Appendices

- **A Kernel catalogue** (generated from `kernels.csv`: ID, routine, template, file:line, route, A100/H100 time).
- **B Namelist of the case.**
- **C Notation.**
- **D Test catalogue** (generated from plan.md §13 and the gates).
- **E Build and run guide.**
- **F Glossary.**

## 4. Conventions

- **Algorithms:** `algorithmicx` (`algpseudocode`) boxes, each with the routine it describes and the loop order of the
  source.
- **Equations:** numbered, each followed by `\src{file}{routine}`. Symbols in Appendix C.
- **Code:**
  - `listings` with a Fortran style (no shell escape, so CI stays simple);
  - excerpts no longer than 30 lines;
  - file and line range named.
- **Figures:**
  - TikZ for diagrams;
  - `pgfplots` for data, reading CSV files exported by `perf/tools` (plan-profiler PR-L5.3) and by the comparison
    tools.
  - No figure is drawn from numbers typed by hand.
- **Boxes:** `portnote` (how the port handles it), `keypoint` (the one thing to remember), `outline` (until written).

## 5. Build pipeline

| Item | What |
|---|---|
| CI | `.github/workflows/book.yml` builds the PDF on every push to `book/`; artifact `wrf-gpu-book`; fails on errors, undefined references and citations |
| Packages | add `algpseudocode`, `listings`, `pgfplots`, `siunitx`, `cleveref` to `preamble.tex` (one task, CI proves they exist in TeX Live) |
| Generated content | `book/gen/`: the kernel catalogue from `kernels.csv`, the test catalogue, the namelist table, figure CSVs from `perf/db`. A script regenerates them, and CI checks they are current. |
| `\src` check | a script verifies that every `\src{file}{routine}` names an existing routine in `WRF/` at the CPU-view base |
| Bibliography check | every `refs.bib` entry has a DOI or publisher URL and a "checked" note (B-02) |
| Editions | a tagged PDF at each milestone (M1 … M3, then per stage): `book-v0.1.pdf` with v0.1 of the port |
| Local build | `cd book && make` on any machine with TeX Live (not the cloud environment) |

## 6. Tasks

Machines:
- every writing task runs on CLOUD and is checked by CI (`needs: cpu`);
- tasks that need measured numbers name the port or profiler phase they wait for.

Sizes are S ≤ ¼ day, M ≤ ½ day. A chapter's tasks follow its sections, about 1 task per 4–6 pages.

### 6.1 Infrastructure

| Task | What | Size | Done when |
|---|---|---|---|
| B-00.1 | New part and chapter structure: rename files to the 40-chapter numbering, keep existing text, update `main.tex` | M | CI PDF with all chapter shells |
| B-00.2 | Packages and styles (algorithms, listings, pgfplots, siunitx, cleveref); a sample of each in the preface | S | CI PDF |
| B-00.3 | `\src` checker script and its CI step | S | fails on a wrong routine name |
| B-00.4 | Generated appendices A, B, D and their regeneration check | M | CI PDF |
| B-00.5 | Figure pipeline: CSV → pgfplots template; one figure from `perf/db` | S | CI PDF |
| B-00.6 | Bibliography: enter and check the † sources of §3 (≈40 entries), publisher and DOI per entry | M ×2 | `refs.bib` with notes |
| B-00.7 | Notation appendix C, kept in step with chapters 5–9 | S | CI PDF |
| B-00.8 | Edition script: tag, build, attach the PDF to the release | S | `book-v0.0.pdf` (skeleton edition) |

### 6.2 Chapters

One row per chapter. The tasks are the section groups, in order: `B-<ch>.1`, `B-<ch>.2`, … "Waits for" names
measured content; the rest can be written now from the code and the sources.

| Ch | Title | Tasks (size) | Waits for |
|---|---|---|---|
| 1 | Introduction | .1 revise (S) | — |
| 2 | The WRF system end to end | .1 WPS (M) .2 real/ideal (M) .3 wrf.exe, ndown, post (S) .4 data-flow figure (S) | — |
| 3 | The Eaton case | .1 revise with references and windows (S) | S0-09, S0-10 |
| 4 | Initial and boundary conditions | .1 vertical interpolation (M) .2 balance, Algorithm 4.1 (M) .3 boundary file (S) | — |
| 5 | Governing equations | .1 flux form (M) .2 hybrid coordinate (M) .3 map factors, θm (M) .4 perturbation form (S) | — |
| 6 | Time integration | .1 RK3 (M) .2 acoustic steps (M) .3 damping, off-centering (S) .4 implicit w–φ, Algorithm 6.3 (M) .5 step timeline figure (S) | — |
| 7 | Advection | .1 C grid, operators (M) .2 odd orders, Algorithm 7.1 (M) .3 PD limiter, Algorithm 7.2 (M) .4 WENO, monotonic (S) | — |
| 8 | Boundaries and nesting | .1 zones (M) .2 open/periodic/symmetric (S) .3 nesting, feedback (M) .4 forcing, Algorithm 8.2 (M) | — |
| 9 | Diffusion and turbulence | .1 Smagorinsky (M) .2 TKE, Algorithm 9.1 (M) .3 damping, filters (S) | — |
| 10 | Coriolis, curvature, projections | .1 (M) | — |
| 11 | Physics interface | .1 coupling, call order, Algorithm 11.1 (M) | — |
| 12 | Microphysics | .1 WSM6 processes (M) .2 sedimentation (M) .3 Algorithm 12.1 (S) .4 other schemes (M) | — |
| 13 | Radiation | .1 correlated-k (M) .2 taumol and bands (M) .3 McICA and KISS (M) .4 rtrnmc (M) .5 Dudhia SW (S) .6 ozone, gases (S) .7 overview (S) | — |
| 14 | Surface layer | .1 MOST and sfclayrev (M) .2 tables, zolri (S) | — |
| 15 | Land surface | .1 Noah energy (M) .2 water, Penman, canopy (M) .3 snow, frozen soil (M) .4 Algorithm 15.1 (S) .5 other LSMs (S) | — |
| 16 | PBL and LES | .1 YSU (M) .2 pblh, entrainment (S) .3 LES and others (S) | — |
| 17 | Cumulus | .1 (M) | — |
| 18 | Other physics | .1 (M) | — |
| 19 | Fire behavior basics | .1 Rothermel (M) .2 fuel models (M) .3 moisture, wind, slope (S) | — |
| 20 | WRF-Fire numerics | .1 grids, interpolation (M) .2 level set, RK3 (M) .3 ENO/WENO, Algorithm 20.2 (M) .4 reinitialization (S) .5 ignition, fuel, Algorithm 20.3 (M) .6 fluxes, feedback (S) .7 Eaton perimeter figure (S) | figure: S4-12 |
| 21 | CFBM | .1 from analysis/cfbm.md (M) | roadmap Stage 3 |
| 22 | Architecture | .1 layers (M) .2 domain type, dims (M) .3 Registry, generated code (M) .4 call-tree figure (S) | — |
| 23 | Parallelism on CPUs | .1 RSL_LITE, halos (M) .2 tiles, quilting (S) | — |
| 24 | I/O and build | .1 I/O API, streams (M) .2 configure, compile (S) | — |
| 25 | GPU architecture | .1 SMs and warps (M) .2 memory hierarchy (M) .3 A100 vs H100 with measured numbers (M) | numbers: PR-H1 … H3 |
| 26 | Programming models | .1 OpenACC (M) .2 CUDA Fortran (M) .3 interop, choice (S) | — |
| 27 | Floating-point reproducibility | .1 IEEE and FMA (M) .2 functions, rp_* (M) .3 flags, order (S) .4 proving equality (M) | T-FMA etc.: S0-06 |
| 28 | The porting method | .1 residency, islands (M) .2 templates (M ×2) .3 work arrays, refactors (M) .4 the ladder (S) | — |
| 29 | The port by subsystem | .1 dynamics (M) .2 physics (M) .3 fire (M) .4 forcing (S) | G2, G3, G4, G5 |
| 30 | Profiling methodology | .1 tools (M) .2 sampling, repeatability (S) .3 kernel DB (S) | PR-L1b, PR-L2, PR-L3 |
| 31 | Performance models | .1 roofline (M) .2 floors and models (M) .3 figures (S) | PR-L4, S6-01 |
| 32 | Fusion and launches | .1 concepts (M) .2 legality (M) .3 worked example (M) | S6-04 … S6-08 |
| 33 | Memory and caching | .1 concepts (M) .2 L2 control A100/H100 (S) .3 examples (M) | S6-09, S6-10 |
| 34 | Tiling | .1 concepts (M) .2 2.5D blocking, Algorithm 34.1 (M) .3 TMA, clusters (S) .4 example (M) | S6-11 |
| 35 | Warp-level work | .1 divergence (M) .2 occupancy, spills (M) .3 reductions (S) .4 examples (M) | S6-12 |
| 36 | Column physics on GPUs | .1 thread per column (M) .2 RRTMG batching, ordered sums (M) | S3-24, S6-13 |
| 37 | Results | .1 tables and figures (M) | S6-16 |
| 38 | Multi-GPU | .1 design (M) .2 results (S) | S8-01 … S8-05 |
| 39 | WRF versions | .1 from the analysis (M) | roadmap Stage 2 |
| 40 | Outlook | .1 (S) | — |

## 7. Gates

| Gate | Condition |
|---|---|
| Chapter done | its outline box replaced; CI builds with no errors or undefined references; every equation has `\src` and the checker passes; every number names its source; the reviewer's checklist (book/AGENTS.md) signed in the log |
| Part done | all chapters done; the part read end to end once for consistency of notation |
| Edition | at each port milestone: the parts that can be written are done, the rest keep their outline boxes; tagged PDF |

Order of writing:
1. Parts I–V can start now, in any order.
2. Part VI follows the port's stages.
3. Part VII follows Stage 6.

Book cards B-03 … B-21 of the backlog map onto the chapters above. Task B-00.1 renumbers them, and the backlog is
updated in the same commit.
