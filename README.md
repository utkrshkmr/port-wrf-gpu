# port-wrf-gpu: WRF 4.6.0 and WRF-Fire on GPUs, bit for bit

A port of the Weather Research and Forecasting model (WRF) v4.6.0 with WRF-Fire to NVIDIA A100 and H100 GPUs. It
is written as Fortran with OpenACC directives (CUDA Fortran for measured hotspots, ADR-001 rev 2), and it must give
results bit-for-bit identical to a CPU reference build. The repository also holds the verification tools, the plans,
the long-term roadmap, a profiler and a textbook.

**Now:** WRF 4.6.0 + WRF-Fire on one NVIDIA GPU, the plan below. WRF 4.8.0 and NCAR's new fire model CFBM come after
it passes its acceptance gate G5 ([roadmap/](roadmap/README.md), ADR-002).

## The plan, stage by stage

The work is divided into **9 stages and 139 phases** ([roadmap/plan-4.6/](roadmap/plan-4.6/README.md)), each phase
with its tasks of at most half a day, the machine they run on, and a gate someone else can repeat. Two companion plans
run alongside: the [profiler](roadmap/plan-profiler.md) (built layer by layer with the port) and the
[textbook](roadmap/plan-book.md). The design behind every kernel, test and gate is [plan.md](plan.md).

### Machines

| ID | Machine | Used for |
|---|---|---|
| CLOUD | cloud coding environment: gfortran 13 (`-fopenacc` runs OpenACC regions on the host), Python, no GPU, no case data | writing code, `static.sh`, both gfortran views, the smoke case S-3M, the harness on random inputs, reviews, plans, the book |
| WS-A100 | the owner's workstation: 2x A100 40 GB, NVHPC, the dev case `eaton_small` | NVHPC builds, device tests, T-AB and T-TRACE on dev-case windows, fire windows, nsys/ncu on A100; two runs at once (one per GPU) |
| GPU80 | one 80 GB GPU (H100 preferred, or A100 80 GB) | the full Eaton case: memory gates, the 17 h acceptance run, H100 profiles |
| CCR | CPU cluster | CPU-REF reference runs (dev and full case), T-DEC, T-DRIFT, T-RST |
| CI | GitHub Actions | the book PDF |

### How every routine is ported (the ladder)

Rungs L1-L3 on CLOUD (write the GPU view under `#ifdef WRF_GPU`; compile both gfortran views; GPU view = CPU view bit
for bit on the host), L4-L8 on WS-A100 (nvfortran compile with every kernel offloaded; harness host vs device vs CPU
view; T-AB of the routine on real data; T-TRACE against CPU-REF; row in the kernel database). Each routine has a `.c`
task (L1-L3) and a `.g` task (L4-L8). Rules: never change arithmetic, never change the CPU view, one routine per
commit, `static.sh` before every commit ([AGENTS.md](AGENTS.md)).

### Status (2026-10-08)

| Done | Where it stands |
|---|---|
| Phase 0 infrastructure, checked locally: reproducible math (correctly rounded on all 2^32 single-precision inputs), 646 intrinsic calls and 265 powers substituted and certified bitwise on two smoke cases, tracer, routes, pool, comparison tools, gates, agent guides | [port/RESULTS.md](port/RESULTS.md) |
| Code-only run 1: L1 written for 19 of 44 work packages (234 kernels pass `kernel_lint`); reviewed; its CPU verification fails on the P1-WORK stub and 192 GPU-view compile errors, all listed for Stage 0 | S0-01 ... S0-03 below |
| Plans: 4.6 port (139 phases), profiler, book | `roadmap/` |
| The textbook: all 40 chapters and 6 appendices written; CI builds the PDF (artifact `wrf-gpu-book`) | [book/](book/README.md) |
| **Next:** S0-01 ... S0-03 on CLOUD (land run 1), S0-04 ... S0-06 on WS-A100 (toolchain, probes, arithmetic tests) | |

### Stage 0 - Ground truth (12 phases)

| Phase | Tasks | Machine | Gate |
|---|---|---|---|
| S0-01 Make the CPU check trustworthy | .1 rebuild users of changed include files in `build.sh --worktree`; .2 `check_deps.py` resolves `physics_mmm/` paths; .3 `cpu_verify.sh` names the failing file and line; .4 regenerate checksums, log the tool fixes | CLOUD | `cpu_verify.sh` PASS on the unchanged handoff |
| S0-02 Land the code of run 1 | .1 scope check of the 19 branches; .2 the 5 dependency requests in `depend.common`; .3 `set_flags` public (P4-MODEL); .4 INTEGER work arrays (P3-RADDRV); .5 open-boundary branches of `advect_u/scalar/scalar_pd`; .6 P5-FORCE checker questions; .7 answer every status-file question; .8 merge by phase with `cpu_verify.sh` after each group | CLOUD | both gfortran views build; S-3M bitwise; run-1 kernels pass the harness |
| S0-03 Work arrays and the step bracket | .1 `gpu_work_ensure/alloc/check` host and device parts; .2 `gpu_selftest_work`; .3 the `gpu_work_ensure` call in `solve_em`; .4 S-3M CPU view with run-1 refactors vs base | CLOUD | `cpu_verify.sh` PASS in full |
| S0-04 Toolchain on WS-A100 | .1 NVHPC pinned, versions recorded; .2 MPI and netCDF with nvfortran; .3 gfortran netCDF; .4 flags spell-checked; .5 device query of both A100s | WS-A100 | an OpenACC and a CUDA Fortran kernel run on GPU 0 and 1 |
| S0-05 OpenACC feature probes | .1 F-IF host fallback; .2 F-ROUTINE; .3 F-DECLARE; .4 F-PRESENT (pool pointers); .5 F-STMTFN/INTPROC/OPT/CHAR; .6 F-RED; .7 F-NAN; .8 F-STACK; .9 F-ATTACH (fire `fp`); .10 F-HOSTDATA; .11 F-CACHE/ASYNC; .12 F-AUTO/PRIVARR | CLOUD -> WS-A100 | every probe recorded with a fallback where it fails |
| S0-06 Arithmetic and unit tests on the A100 | .1 T-FMA; .2 T-SIGNZERO, T-MINMAX, T-SUBNORM; .3 T-RM-EXH; .4 T-RM-POW, T-RM-D; .5 T-IPOW, T-KISS, T-PDLIM, T-OZN, templates, call check on the device; .6 repeat on GPU 1 | WS-A100 | all PASS on both A100s |
| S0-07 CPU-REF build and symbol audit | .1 CPU-REF build, md5 kept; .2 T-SYM; .3 same build on CCR, identical binary; .4 T-BUILD-REF | WS-A100, CCR | |
| S0-08 CPU-REF reproducibility | .1 T-DET; .2 T-DEC-A (1 vs 64 ranks); .3 T-DEC-B; .4 T-XM (CCR node vs workstation host); .5 T-RST | CCR | bitwise (T-RST or documented) |
| S0-09 Dev case `eaton_small` | .1 make the case (d02 181x181x60 on the ignition); .2 CPU-REF 1 h with restarts at 02:00 and 02:20; .3 17 h dev run for T-DRIFT; .4 copy to WS-A100, every window run once with CPU-REF | CCR -> WS-A100 | each window has a reference trace |
| S0-10 Full-case reference (17 h) | .1 the 17 h CPU-REF run with hourly restarts; .2 the 02:20 restart; .3 archive, E0 and E1 experiments; .4 Prof-CPU table | CCR | runs beside Stages 1-4 |
| S0-11 T-UNINIT | NaN-fill vs zero-fill builds on W-T0 | WS-A100 | identical |
| S0-12 Certify the shared refactors of run 1 | one family per task, each CPU-REF vs base bitwise, then the base moves: .1 advect_scalar_pd work arrays; .2 `var_mix`; .3 fire hoists and work arrays (W-IGN); .4 microphysics driver; .5 PBL driver; .6 radiation driver (W-RAD); .7 RRTMG EQUIVALENCE flattening and init hoist (W-RAD); .8 Noah `iloc/jloc`, type codes; .9 surface driver | WS-A100, CCR | **G0** |

### Stage 1 - GPU infrastructure, all compute still on the host (12 phases)

| Phase | Tasks | Machine | Gate |
|---|---|---|---|
| S1-01 First GPU-REPRO build, every route off | .1 full nvfortran build with `-Minfo=accel`; .2 compile-only fixes, one commit each; .3 `WRF_GPU_OFF=all`; .4 GPU-DEBUG build; .5 profiler L0 (ptxinfo per kernel); .6 W-T0 and W-20 bitwise with everything off | WS-A100 | |
| S1-02 State on the device (`gen_allocs.c`), T-MAP | .1 `gpu_map_enter` after each allocation; .2 `gpu_map_exit` before each deallocation; .3 gnu-gpu S-3M; .4 T-MAP; .5 W-20 | CLOUD -> WS-A100 | |
| S1-03 Generated update lists, T-UPD | .1 all-fields lists; .2 boundary-array list; .3 `gpu_upd_host_stream` over the state-variable list; .4 T-UPD | CLOUD -> WS-A100 | |
| S1-04 Work arrays on the device, T-WORK | .1 device part of the work allocators; .2 self test; .3 memory numbers | CLOUD -> WS-A100 | |
| S1-05 Scratch pool, T-POOL | .1 pool offsets and `i1_assoc.inc`; .2 device create and zero fill; .3 presence of sampled `i1` arrays | CLOUD -> WS-A100 | |
| S1-06 Module tables, T-TAB | .1 review run-1 `gpu_update_tables`; .2 `P_*` species indices on the device; .3 T-TAB for existing tables | WS-A100 | |
| S1-07 Sync points S1-S5 and the `solve_em` bracket | .1 S1 (initial state), S2 (nest open); .2 S3 history, S4 restart; .3 S5 boundary read; .4 the bracket and `gpu_work_ensure` | CLOUD -> WS-A100 | files identical to CPU-REF |
| S1-08 Nest-forcing bridge S6 | .1 host-all before and dev-all after `med_nest_force`; .2 W-T0 | CLOUD -> WS-A100 | bitwise |
| S1-09 Startup gate `gpu_check_config`, T-GATE | .1 the allowed-option table; .2 size, ratio, rank, fuel checks; .3 T-GATE | CLOUD -> WS-A100 | a disallowed namelist is rejected |
| S1-10 Self tests and the dispatcher | `WRF_GPU_SELFTEST=1` runs T-MAP, T-TAB, T-POOL, T-WORK | WS-A100 | PASS on both GPUs |
| S1-11 Profiler layer 1 | .1 NVTX/CUDA shim; .2 ranges per `solve_em` section and route; .3 `WRF_GPU_TIMING`; .4 memory log; .5 logging changes no bit | CLOUD -> WS-A100 | |
| S1-12 G1 windows, G-MEM-1 | .1-.2 W-20 on GPU 0 and 1; .3 W-T0 with history and restart writes; .4 T-NSYS; .5 full-case memory after init and first steps (<= 55 GB); .6 book facts | WS-A100, GPU80 | **G1** |

### Stage 2 - The dynamical core (23 phases)

Each routine: `.Nc` (L1-L3, CLOUD) and `.Ng` (L4-L8, WS-A100). Run-1 code starts at a review of L1.

| Phase | Routines (kernels) | Sub-gate |
|---|---|---|
| S2-01 Physical boundary conditions | `set_physical_bc3d`, `set_physical_bc2d` (Template G, x before y); caller islands | |
| S2-02 RK preparation, pointwise | `initialize_moist_old`, `calculate_full`, `calc_mu_uv(_1)`, `couple_momentum`, `calc_alt`, `calc_php` | |
| S2-03 RK preparation, columns | `calc_ww_cp` (Template C, range guards), `calc_cq` (species sum in order) | **G2.A** T-TRACE-100 |
| S2-04 Tendency zeroing, WW_SPLIT, rhs_ph | `zero_tend(2d)`, `WW_SPLIT`, `rhs_ph` vertical, gw and 6 horizontal nests (the `ids+2`/`ide-3` quirk kept) | |
| S2-05 advect_u (run 1) | review; flux functions; open-boundary branches; T-TMPL-B on the device | |
| S2-06 advect_v (run 1) | review; the xs edge loop; open boundaries | |
| S2-07 advect_w (run 1) | review; the `k=ktf+1` lid loops; open boundaries | |
| S2-08 advect_scalar (run 1) | review; open boundaries | |
| S2-09 Pressure gradient, buoyancy, w damping | `horizontal_pressure_gradient` (C), `pg_buoy_w` (two kernels in order), `w_damp` (exact max reductions) | |
| S2-10 Coriolis and curvature | `coriolis`, `curvature` (6 kernels in order); unused IEVA automatics removed and certified | **G2.B** |
| S2-11 Tendency combination, lateral boundaries | `mass_weight`, `relax_bdytend_core`, `relax_bdy_scalar`, `rk_addtend_dry`, `spec_bdytend`, `spec_bdy_scalar` | **G2.C** |
| S2-12 Acoustic loop: prep, finish, p/rho, coefficients, sums | `small_step_prep`, `calc_p_rho`, `calc_coef_w`, `sumflux`, `small_step_finish` | |
| S2-13 advance_uv, advance_mu_t | `advance_uv` (range guards), `advance_mu_t` (3 kernels) | |
| S2-14 advance_w | the whole implicit solve as one column kernel: rhs, sweeps, Rayleigh damping (`rp_sin` twice), `ph` update; spills checked | |
| S2-15 Acoustic boundary updates | `spec_bdyupdate`, `spec_bdyupdate_ph`, `zero_grad_bdy`; launches per d02 step recorded | **G2.D** |
| S2-16 advect_scalar_pd (run 1) | fluxes; the limiter split (Template L) against T-PDLIM; divergence | |
| S2-17 Scalar updates, flow-dependent boundaries | `rk_update_scalar(_pd)`, `flow_dep_bdy`, `bound_tke` | **G2.E** |
| S2-18 End of step | `calc_p_rho_phi` (`VPOW` as `rp_pow`), `spec_bdy_final`, `set_w_surface`, `update_phys_fields` | **G2.F** |
| S2-19 Diffusion metrics and deformation (run 1) | `compute_diff_metrics`; `cal_deform_and_div` (59 kernels, two review tasks) | |
| S2-20 N2, eddy viscosities, TKE (run 1, partial) | `calculate_N2`, `smag2d_km`, `tke_km`, `calc_l_scale`, `tke_shear`, `tke_buoyancy`, `tke_dissip`, `tke_rhs`, `conv_t_tendf_to_moist` | |
| S2-21 Vertical diffusion and the stress tensor (run 1, partial) | `cal_titau_*` (4), `vertical_diffusion_2`, `_u_2/_v_2/_w_2`, `vertical_diffusion_s` | |
| S2-22 Horizontal diffusion | `horizontal_diffusion_2`, `_u_2/_v_2/_w_2`, `horizontal_diffusion_s` (11 kernels) | **G2.G** T-TRACE-100, T-TRACE-TKE |
| S2-23 Stage closure | .1 all routes on, W-20 and W-100 on both GPUs; .2 T-NSYS; .3 T-DRIFT on CCR; .4 first dynamics profile on A100; .5 book sections | **G2** |

### Stage 3 - The physics of the case (25 phases)

Column physics passes a column harness (columns from the CPU-REF state through CPU view, GPU view on the host, and
the device) before it meets real data.

| Phase | Routines / items | Sub-gate |
|---|---|---|
| S3-01 Physics glue | `phy_prep` (the `p_hyd_w` recurrence), `phy_prep_part2`, `moist_physics_prep_em`, `moist_physics_finish_em` | |
| S3-02 Physics tendencies | `init_zero_tendency`, `calculate_phy_tend`, `add_a2a/_a2c_u/_a2c_v` (the `kte` quirk), `update_phy_ten` | **G3.A** |
| S3-03 Column test harness | .1 column extractor from a CPU-REF checkpoint; .2 runner in three builds; .3 sampling rule (10^5 columns, extremes); .4 device run, stack size read back | |
| S3-04 WSM6 device tree (run 1, partial) | `mp_wsm6_run` routine seq, ~78 fixed-size locals, whole-array syntax rewritten; `slope_*`; `nislfv_rain_plm(6)`; statement functions; SAVE scalars on the device; T-WSM6-COL | |
| S3-05 WSM6 kernel and microphysics driver | `wsm6` wrapper (CP-1), `microphysics_driver` (effective radius skipped), CP-5 stack limit | **G3.B** T-AB-wsm6 |
| S3-06 Surface layer sfclayrev, T-ZOLRI | `sf_sfclayrev_run`, `zolri`, psi tables; wrapper per point; T-ZOLRI = 0 occurrences | |
| S3-07 Noah: certified refactors and tables (run 1) | `iloc/jloc`, type codes reviewed; 49 table uploads, T-TAB | |
| S3-08 Noah leaves I: soil heat and snow | `TDFCND`, `TBND`, `TMPAVG`, `SNKSRC`, `FRH2O`, `HRT`, `HSTEP`, `ROSR12`, `SHFLX`, `CSNOW`, `SNOW_NEW`, `SNFRAC`, `ALCALC`, `SNOWZ0`; point harness | |
| S3-09 Noah leaves II: water and evaporation | `PENMAN`, `CANRES`, `DEVAP`, `TRANSP`, `EVAPO`, `WDFCND`, `SRT`, `SSTEP`, `SMFLX`, `FAC2MIT`; point harness | |
| S3-10 Noah composites up to SFLX | `NOPAC`, `SNOPAC`, `SNOWPACK`, `REDPRM`, `SFLX` (two tasks); T-NOAH-PT | |
| S3-11 Noah kernel, glacial | `lsm` wrapper per point, `SFLX_GLACIAL`; T-NOAH-PT end to end, T-AB-lsm | |
| S3-12 Sea ice and surface diagnostics | `seaice_noah`, `SFCDIAGS` | |
| S3-13 surface_driver kernels (run 1) | review the ~3000-line island; callee islands collapse; T-AB-surface_driver | **G3.C** |
| S3-14 YSU device tree | `bl_ysu_run` (two tasks, ~90 fixed arrays), `tridin_ysu`, `tridi2n`, `get_pblh`; BEP guard certified; T-YSU-COL | |
| S3-15 PBL driver and YSU kernel | `pbl_driver`, `ysu` wrapper (CP-1) | **G3.D** T-AB-ysu |
| S3-16 Radiation driver: every-step kernels (run 1) | LW accumulations, cloud product in k order | |
| S3-17 Radiation driver: radiation-step kernels (run 1) | `solar_eclipse`, `calc_coszen`, `cal_cldfra1`, zeroing, LW and SW post-processing; work-array sizes guarded | |
| S3-18 Ozone interpolation, T-OZN | `ozn_time_int`, `ozn_p_int` per column (Template R) | |
| S3-19 Dudhia shortwave | `SWPARA` routine seq (night exit, `SDOWN` recurrence), `SWRAD` wrapper; column harness | |
| S3-20 RRTMG tables (run 1, partial) | EQUIVALENCE flattening in 16 modules reviewed; `rrtmg_lw_ini` hoisted; upload and T-TAB | |
| S3-21 RRTMG column setup | `inatm`, `cldprmc`, `setcoef`, `relcalc`, `reicalc`, `INIRAD`, `O3DATA`, buffer layers; harness | |
| S3-22 RRTMG taumol | `taugb1` ... `taugb16` in four tasks (`rp_mod`), `taumol`; harness | |
| S3-23 RRTMG radiative transfer and McICA | `rtrnmc` (two tasks), `mcica_subcol_lw`, `generate_stochastic_clouds`, `kissvec`; T-KISS on the device; harness | |
| S3-24 RRTMG batching and kernel | batch work arrays (`WRF_RRTMG_BATCH`), one thread per column, error codes; T-RRTMG-COL; W-RAD | **G3.E** T-AB-radiation_driver, T-TRACE-RAD |
| S3-25 Stage closure | .1 all routes on, W-20/W-100/W-RAD on both GPUs; .2 T-NSYS; .3 T-DRIFT; .4 G-MEM-2 (<= 70 GB, GPU80); .5 physics profile; .6 book | **G3** |

### Stage 4 - WRF-Fire (13 phases)

Fire T-AB runs on W-IGN or W-FIRE (W-20 contains no ignition).

| Phase | Routines / items | Gate |
|---|---|---|
| S4-01 Fire data on the device (run 1) | `set_flags` hoist reviewed; flags and constants `declare create`; `fp` attached (F-ATTACH); T-FIRE-GHOST; fire work arrays present | |
| S4-02 Fire statistics (run 1) | `print_2d_stats`, `print_3d_stats` with integer NaN counts | |
| S4-03 Atmosphere-to-fire interpolation | `interpolate_atm2fire` (two tasks: heights, log-wind search with early exit, z-coupling), `continue_at_boundary` (strips in order), `interpolate_2d` | |
| S4-04 Level-set tendency and rate of spread (run 1) | `fire_ros` routine seq (capping quirk kept), `tend_ls` (WENO5/ENO1 by node, viscosity, max reduction); divergence measured | |
| S4-05 Time stepping, ignition time, flame length (run 1) | `prop_ls_rk3`, `tign_update` and boundary guard, `calc_flame_length` | |
| S4-06 Reinitialization (run 1) | `reinit_ls_rk3`, `advance_ls_reinit` x3 with boundary continuation between stages | |
| S4-07 Ignition | `nearest`, `ignite_fire` (host window test, per-point kernel, counts) | |
| S4-08 Fuel consumption | `fuel_left_cell_1`, `fuel_left` (4 sub-cells in order, reads ghosts), normalization and checks | |
| S4-09 Heat fluxes and sums | `heat_fluxes`, `sum_2d_cells` x3 (inner loops sequential) | |
| S4-10 fire_model and the drivers (run 1, partial) | `fire_model`, `fire_driver_phys`, `fire_driver_em`, init and step call sites | |
| S4-11 Fire tendency into the atmosphere | `fire_tendency` (zero, fluxes with `rp_exp`, divergence) | |
| S4-12 Fire windows | .1 T-AB of every fire route on W-IGN; .2 T-FIRE-IGN (02:00-02:35); .3 T-FIRE-WIN (02:20-03:00) on both GPUs; .4 `compare_fire.py`: 0 differing cells | |
| S4-13 Stage closure | .1 no island left in `solve_em`; .2 T-DRIFT; .3 fire profile on A100; .4 book | **G4** |

### Stage 5 - Nest forcing, island removal, acceptance (10 phases)

| Phase | Tasks | Machine | Gate |
|---|---|---|---|
| S5-01 couple_or_uncouple_em on the device | mu work arrays certified; couple and uncouple kernels (patch clipped to the domain); L4-L8 with the bridge | CLOUD -> WS-A100 | |
| S5-02 Generated forcing lists (run 1, partial) | parent j-slab list; device pack of the nest's spec-zone strips and host unpack; `o3rad` upload; gnu-gpu S-3M | CLOUD | |
| S5-03 `med_force_domain` rewired | steps 1-8 of plan P5.2; T-FORCE; T-SLAB (signaling NaNs outside the slab); T-O3; bytes per step recorded | CLOUD -> WS-A100 | bitwise |
| S5-04 Device bit tracer | hashes computed on the device; level-2 traces move no fields | CLOUD -> WS-A100 | identical trace lines |
| S5-05 Remove the `solve_em` bracket | delete the bracket; T-NSYS-CLEAN on 200 d02 steps; no `cudaMalloc` in the time loop | CLOUD -> WS-A100 | PASS |
| S5-06 Output and input sync | T-OUT (history and restart files), T-BDY (a boundary read) | WS-A100 | bitwise |
| S5-07 One-hour dev windows | W-1H on GPU 0 and GPU 1 at once; first speed numbers | WS-A100 | bitwise, GPUs identical |
| S5-08 Full-case memory and first hour | memory after init (<= 70 GB); 100 d02 steps from 02:20; 1 h window | GPU80 | bitwise |
| S5-09 Full 17 h acceptance | the 17 h run; 69 history frames and 34 restarts bitwise, 0 differing fire cells, traces identical; T-DRIFT-FULL on CCR; T-XM; a second GPU type if available | GPU80, CCR | |
| S5-10 Stage closure | `g5.sh` PASS, G-MEM-3; RESULTS.md with md5s and digests; tag `v0.1-rc1`; book acceptance section | GPU80, CLOUD | **G5** (opens 4.8.0 and CFBM) |

### Stage 6 - Performance without changing a bit (16 phases)

Every optimization climbs the ladder: analyzer evidence -> legality note (classes R0/R1/R2 keep the bits; F is FAST
only) -> code -> bitwise tests (T-AB, T-TRACE-100, T-TRACE-RAD, T-REG-20; OpenACC vs CUDA Fortran) -> measure on
A100 (dev) and H100 (full) -> keep if the step is >= 3 % faster or the kernel >= 10 %.

| Phase | What | Machine |
|---|---|---|
| S6-01 Baseline profiles | nsys and ncu of W-100/W-RAD on A100 and 1 h of the full case on H100; bandwidth floor and roofline per kernel; time per range vs Prof-CPU; report | WS-A100, GPU80 |
| S6-02 Opportunity reports | fusion finder, cache and reuse, tiling candidates, warp report (divergence, coalescing, occupancy, spills), launches and gaps; ranked list | WS-A100 |
| S6-03 O1 | fire NaN-check kernels out of production builds | WS-A100 |
| S6-04 O2 | merge boundary-strip kernels (4 -> 1) and zero/copy kernels | WS-A100 |
| S6-05 O3 | asynchronous queues for independent kernels, `wait` before dependents | WS-A100 |
| S6-06 Fusion I | pointwise sequences inside one routine (`small_step_prep`, `rk_addtend_dry`, `calc_p_rho`, physics glue) | WS-A100 |
| S6-07 Fusion II | chains across routines in the acoustic sub-step, with a legality table per chain | WS-A100 |
| S6-08 CUDA Graph | one acoustic sub-step captured and replayed (experiment) | WS-A100, GPU80 |
| S6-09 Caching | `!$acc cache`, read-only paths, L2 persistence windows (fire grid, tables) on A100 vs H100, constant memory | WS-A100, GPU80 |
| S6-10 Coalescing and loop order | kernels with high sectors/request, one per commit | WS-A100 |
| S6-11 Tiling | shared-memory tiles in CUDA Fortran for advection y- and x-fluxes, diffusion, fire `tend_ls`; H100 TMA and clusters | WS-A100, GPU80 |
| S6-12 Warp level | fire band split, advection edge branches, register caps per kernel and GPU, spills of column physics | WS-A100, GPU80 |
| S6-13 Column physics | RRTMG performance version (per layer, per g-point, ordered sums); WSM6 and Noah batch shape | WS-A100, GPU80 |
| S6-14 I/O and transfers | pinned asynchronous history output (O8), lazy `o3rad` (O10), parent-side pack (O11), quilting | WS-A100, GPU80 |
| S6-15 Per-GPU tuning | `vector_length`, `num_gangs`, register caps per kernel for A100 and H100; settings files | WS-A100, GPU80 |
| S6-16 Stage closure | tuned binary repeats G5 bitwise; PERF.md complete for both GPUs (speedups vs CPU-REF and the original run); book results chapter | GPU80, CCR, CLOUD (**G6**) |

### Stage 7 - Other fires, regression, release v0.1 (8 phases)

| Phase | What | Machine |
|---|---|---|
| S7-01 Onboarding tools | `manifest.py`, `check_case.py` against the envelope; memory estimator within 5 %; the A100 40 GB fit rule; docs | CLOUD, WS-A100 |
| S7-02 Regression suite | `port/regress.sh` (T-REG-20, T-TRACE-100, T-TRACE-RAD, T-FMA, T-SUBNORM); nightly on WS-A100; result page | WS-A100 |
| S7-03 Second fire case | choose with the owner; WPS/real on CCR; case contract; CPU-REF 1 h around ignition; T-CASE-1H | CCR, WS-A100 |
| S7-04 Envelope edges | `e_vert` at `WRF_KMAX`; another nest ratio; a d02 near the 80 GB limit | CCR, GPU80 |
| S7-05 License and release checks | ADR-004 (owner), headers and NOTICE, no private paths | CLOUD |
| S7-06 User documentation | build and run guide, troubleshooting, limits | CLOUD |
| S7-07 Release v0.1 | tag, CITATION.cff and DOI, the book PDF, announcement | CLOUD |
| S7-08 Upstream contact (optional) | summary for NCAR of the bitwise method and the patches that could go upstream | CLOUD |

Gate G7: the regression suite has run nightly for 2 weeks without a failure; the second fire passes; v0.1 is tagged.

### Stage 8 - The rest of WRF 4.6.0 (20 phases, after G5, order chosen by the owner)

Each phase: a case variant and its CPU reference (CCR), the kernel table and work packages (CLOUD), the routine
ladder (CLOUD -> WS-A100), column harness where needed, and a gate (T-AB of every new route, T-TRACE-100 on the
variant, the Eaton regression unchanged, `gpu_check_config` accepts the option).

| Phase | Option family |
|---|---|
| S8-01 | Multi-GPU design (ADR-005): device-resident halos, GPU-aware MPI, RSL_LITE pack/unpack on the device |
| S8-02 | Device halo pack/unpack kernels and halo includes on the device |
| S8-03 | Decomposition independence on GPUs: 1 vs 2 GPUs bitwise (T-DEC-GPU) |
| S8-04 | The full Eaton case on 2x A100 40 GB |
| S8-05 | Multi-GPU performance: halo time, overlap, scaling 1 -> 2 GPUs |
| S8-06 | Restart starts on the GPU (`restart = .true.`) |
| S8-07 | Two-way nesting (`feedback = 1`) |
| S8-08 | More than two domains, other nest ratios, nests opening later |
| S8-09 | Adaptive time step |
| S8-10 | Advection options: other orders, monotonic limiter, WENO |
| S8-11 | Turbulence options: 3D Smagorinsky, 6th-order diffusion, isotropic mixing, NBA |
| S8-12 | Slope-dependent radiation and topographic shading |
| S8-13 | Thompson microphysics |
| S8-14 | Morrison two-moment microphysics |
| S8-15 | MYNN boundary layer and surface layer |
| S8-16 | RRTMG shortwave |
| S8-17 | Noah-MP |
| S8-18 | Cumulus: Kain-Fritsch, Grell-Freitas |
| S8-19 | Other fire options: fuel moisture model, tracers, other upwinding and fuel-left methods, line ignitions |
| S8-20 | Diagnostics and bookkeeping options |

### The profiler (built with the port)

Layers, each built in the phase that first needs it ([roadmap/plan-profiler.md](roadmap/plan-profiler.md)):
L0 compiler information (S1-01); L1 NVTX, timing and memory logs (S1-11); L1b an OpenACC profiling-interface library
(S2-01); L2 nsys captures (S1-12, S2-23); L3 ncu kernel metrics (S2-23); L4 models (S2-23, S6-01); L5 the kernel
database and commit-to-commit diff (S2-01 on); L6 the analyzers A1-A6 for fusion, caching, tiling, warp-level work,
launches and transfers (S6-02); H measured hardware ceilings of each GPU (S0-04, S6-01). Tasks PR-H1 ... PR-V2.

### The textbook

[book/](book/README.md): 8 parts, 40 chapters and 6 appendices, all written; CI builds the PDF on every push. What
remains is measured results, printed as "(to be reported)" until the gates pass, and the bibliography check (card
B-02). Appendix A is generated from the kernel table (`python3 book/tools/kernels_tex.py`).

### After 4.6.0 (roadmap stages 2 and 3)

WRF 4.8.0 by a three-way forward port (ADR-002: dynamics and WRF-Fire merge unchanged; about 20 physics drivers are
ported again), then NCAR's Community Fire Behavior Model, standalone first and then inside 4.8.0. Neither starts
before G5.

## Layout

The repository is divided into **areas**, each with its own instructions and the paths it may change
([AREAS.md](AREAS.md)). Agents start there.

| Path | Content | Area |
|---|---|---|
| `WRF/` | WRF v4.6.0 with the GPU port (all GPU code under `#ifdef WRF_GPU`; the CPU view is unchanged) | `port`, `port-wp` |
| `WPS/` | WPS v4.6.0, unchanged (makes the cases; stays on the CPU) | — |
| `port/` | the port's tools, tests, gates, run scripts and agent guides ([port/README.md](port/README.md), [port/agent/](port/agent/README.md)) | `review`, `port` |
| `cases/` | the case contract of the Eaton fire case | `review` |
| [plan.md](plan.md), [explain-wrf.md](explain-wrf.md) | the execution plan and the porting guide | `review` |
| [AGENTS.md](AGENTS.md) | instructions of the port agent | `review` |
| [roadmap/](roadmap/README.md) | decisions, analyses, the backlog of half-day tasks | `roadmap` |
| [book/](book/README.md) | the LaTeX textbook (built by CI) | `book` |
| [perf/](perf/README.md) | performance models, tools and reports | `perf` |
| [docs/](docs/README.md) | user documentation (for the release) | `docs` |

## Provenance

The branch `upstream/v4.6.0` holds WRF, WPS and Noah-MP exactly as released. The table records the upstream commits.

| Directory          | Upstream                                              | Version                       | Commit                                     |
|--------------------|-------------------------------------------------------|-------------------------------|--------------------------------------------|
| `WRF/`             | [wrf-model/WRF](https://github.com/wrf-model/WRF)     | v4.6.0                        | `0a11865f97680fdd6865b278ea29d910e5db3ed7` |
| `WRF/phys/noahmp/` | [NCAR/noahmp](https://github.com/NCAR/noahmp)         | submodule pinned by WRF v4.6.0 | `848f54ad3d28c4303151fe5ad83724e232694422` |
| `WPS/`             | [wrf-model/WPS](https://github.com/wrf-model/WPS)     | v4.6.0                        | `335c76a111f84503e8b963abaf273ea8053645bb` |

To check the import against its release (fetching only reads from the upstream repositories):

```sh
git fetch --depth 1 https://github.com/wrf-model/WRF refs/tags/v4.6.0
git diff --stat FETCH_HEAD upstream/v4.6.0:WRF        # only phys/noahmp (submodule link -> vendored files)
git fetch --depth 1 https://github.com/wrf-model/WPS refs/tags/v4.6.0
git diff --stat FETCH_HEAD upstream/v4.6.0:WPS        # empty
```

`git diff upstream/v4.6.0 -- WRF` shows every change the port made to WRF.

## WRF-Fire

- Fire model code is built into WRF: `WRF/phys/module_fr_fire_*.F`.
- Ideal fire case: `WRF/test/em_fire` (`./compile em_fire`).
- Real-data fire runs use WPS `geogrid/GEOGRID.TBL.FIRE` and `namelist.wps.fire`.

## Build

`WRF/` and `WPS/` are siblings, so WPS finds the WRF build in `../WRF` on its own:

```sh
cd WRF && ./configure && ./compile em_real    # or em_fire
cd ../WPS && ./configure && ./compile
```

Noah-MP is stored as plain files instead of a submodule; the WRF build links them from
`WRF/phys/noahmp` as usual.
