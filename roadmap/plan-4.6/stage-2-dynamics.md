# Stage 2 — The dynamical core

Goal: every dynamics routine of `solve_em` runs on the device, bitwise equal to CPU-REF. The `solve_em` bracket then
encloses only physics and fire calls.

Spec: plan.md §7 (kernel tables 7.1–7.7), PHASE2.md, KERNEL_REFS.md (`python3 port/tools/ref.py <kernel>`).

**Task naming.** Each routine has two tasks ([README.md](README.md), the ladder):
- `.Nc` covers rungs L1–L3 on CLOUD. For run-1 code, rung L1 is a review against `ref.py`, the template and the
  verbatim rule.
- `.Ng` covers rungs L4–L8 on WS-A100.

Every phase ends with its phase gate: all routines at L7 on GPU 0 and GPU 1, `T-REG-20`, `static.sh`, `cpu_verify.sh`.

---

## S2-01 · Physical boundary conditions

Work package P2-A2 · plan.md §7.1 · Depends G1

| Task | Routine | Kernels | Machine | Size |
|---|---|---|---|---|
| S2-01.1c / .1g | `set_physical_bc3d` | K-BC-3D-x, K-BC-3D-y (Template G, x before y) | CLOUD / WS-A100 | M / S |
| S2-01.2c / .2g | `set_physical_bc2d` | K-BC-2D-x, K-BC-2D-y | CLOUD / WS-A100 | S / S |
| S2-01.3 | `rk_phys_bc_dry_1`, `set_phys_bc_dry_2` call sites: islands collapse once all their callees are ported | — | CLOUD | S |

Notes: the open, periodic and symmetric branches are reached by S-3M (open). Port the open branch, or keep a stop
before the island for the others (`gpu_check_config` rejects them for the Eaton family).

## S2-02 · RK preparation, pointwise

Work package P2-A1 · plan.md §7.1 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-02.1c / .1g | `initialize_moist_old` | K-PREP-1 | S / S |
| S2-02.2c / .2g | `calculate_full` | K-PREP-2 | S / S |
| S2-02.3c / .3g | `calc_mu_uv`, `calc_mu_uv_1` | K-PREP-3a…f (interior and edges, in order) | M / S |
| S2-02.4c / .4g | `couple_momentum` | K-PREP-4a…c | S / S |
| S2-02.5c / .5g | `calc_alt` | K-PREP-7 | S / S |
| S2-02.6c / .6g | `calc_php` | K-PREP-8 | S / S |

## S2-03 · RK preparation, columns (sub-gate G2.A)

Work package P2-A1 · Depends S2-01, S2-02

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-03.1c / .1g | `calc_ww_cp` | K-PREP-5a, K-PREP-5b (Template C; range guard `its..ite` vs `its..itf`) | M / S |
| S2-03.2c / .2g | `calc_cq` | K-PREP-6 (species sum in order) | S / S |
| S2-03.3 | **G2.A**: `T-TRACE-100` (W-100) with every route of S2-01 … S2-03 on | — | WS-A100, S |

## S2-04 · Tendency zeroing, WW_SPLIT, rhs_ph

Work package P2-B5 · plan.md §7.2 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-04.1c / .1g | `zero_tend`, `zero_tend2d` | K-ZT-1 (12 call sites) | S / S |
| S2-04.2c / .2g | `WW_SPLIT` (non-IEVA branch) | K-WWS-1 | S / S |
| S2-04.3c / .3g | `rhs_ph` vertical and gw terms | K-RHSPH-1, K-RHSPH-2 | M / S |
| S2-04.4c / .4g | `rhs_ph` horizontal advection (6 nests, the ids+2 / ide-3 quirk) | K-RHSPH-3…8 | M / S |

## S2-05 · advect_u (run 1)

Work package P2-B1 · plan.md §7.2 · Depends G1

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S2-05.1c / .1g | `advect_u`: review run-1 code; flux functions as module routines (F-STMTFN result of S0-05.5 decides whether they stay) | K-ADVU-Y1, -Y2, -X, -Z | M / M |
| S2-05.2 | Open-boundary branches (from S0-02.5) reach S-3M | — | CLOUD, S |
| S2-05.3 | T-TMPL-B on the device with the real flux expressions | — | WS-A100, S |

## S2-06 · advect_v (run 1)

Work package P2-B2 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-06.1c / .1g | `advect_v`: review; the xs edge loop with `i` outside `k`; open boundaries ported | K-ADVV-Y1, -Y2, -X, -Z + open-boundary kernels | M / M |

## S2-07 · advect_w (run 1)

Work package P2-B3 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-07.1c / .1g | `advect_w`: review; the `k=ktf+1` lid loops; open boundaries ported | K-ADVW-Y1, -Y2, -X, -Z | M / M |

## S2-08 · advect_scalar (run 1)

Work package P2-B4 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-08.1c / .1g | `advect_scalar` (θ every stage; moist and TKE in stages 1–2) | K-ADVS-Y1, -Y2, -X, -Z | M / M |
| S2-08.2 | Open boundaries (S0-02.5) | — | CLOUD, S |

## S2-09 · Pressure gradient, buoyancy, w damping

Work package P2-B6 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-09.1c / .1g | `horizontal_pressure_gradient` | K-HPG-Y, K-HPG-X (Template C, `dpn_col`) | M / S |
| S2-09.2c / .2g | `pg_buoy_w` | K-PGB-1 then K-PGB-2 | S / S |
| S2-09.3c / .3g | `w_damp` (reductions; host message pass when `some1 > 0`) | K-WDAMP | M / S |

## S2-10 · Coriolis and curvature (sub-gate G2.B)

Work package P2-B6 · Depends S2-04 … S2-09

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-10.1c / .1g | `coriolis` | K-COR-U, -V, -W | S / S |
| S2-10.2c / .2g | `curvature` | K-CURV-1…6 in order | M / S |
| S2-10.3 | `rk_tendency`: unused IEVA automatics removed (shared refactor; certify like S0-12) | — | CLOUD + WS-A100, S |
| S2-10.4 | **G2.B**: `T-TRACE-100` with every route of S2-04 … S2-10 on | — | WS-A100, S |

## S2-11 · Tendency combination and lateral boundaries (sub-gate G2.C)

Work package P2-C · plan.md §7.3 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-11.1c / .1g | `mass_weight` | K-MW | S / S |
| S2-11.2c / .2g | `relax_bdytend_core` | K-RLX-YS/YE/XS/XE | M / S |
| S2-11.3c / .3g | `relax_bdy_scalar` (`rscalar` work array) | K-RLXS | S / S |
| S2-11.4c / .4g | `rk_addtend_dry` | K-ADT-U/V/W/PH/T/MU | S / S |
| S2-11.5c / .5g | `spec_bdytend` | K-SPT-YS/YE/XS/XE | S / S |
| S2-11.6c / .6g | `spec_bdy_scalar` | K-SPS | S / S |
| S2-11.7 | **G2.C**: `T-TRACE-100` | — | WS-A100, S |

## S2-12 · Acoustic loop: prep, finish, p/rho, coefficients, sums

Work package P2-D1 · plan.md §7.4 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-12.1c / .1g | `small_step_prep` | K-SSP-1…4 | M / S |
| S2-12.2c / .2g | `calc_p_rho` | K-CPR-1, K-CPR-2 | S / S |
| S2-12.3c / .3g | `calc_coef_w` (the template C reference test exists) | K-CCW | S / S |
| S2-12.4c / .4g | `sumflux` | K-SFX-1…3 | S / S |
| S2-12.5c / .5g | `small_step_finish` | K-SSF-1…5 | S / S |

## S2-13 · advance_uv, advance_mu_t

Work package P2-D2 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-13.1c / .1g | `advance_uv` (range guards `i_start_u_tend` vs `i_start_up`) | K-AUV-U, K-AUV-V | M / M |
| S2-13.2c / .2g | `advance_mu_t` | K-AMT-1, -2, -3 | M / S |

## S2-14 · advance_w

Work package P2-D2 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-14.1c | `advance_w` part 1: `rhs`, `wdwn`, surface and top `w`, sweeps | K-AW | M |
| S2-14.2c | `advance_w` part 2: damp_opt=3 block (`dampwt`, `rp_sin`), `ph` update descending, host `pi` | K-AW | M |
| S2-14.1g | L4–L8 (largest column kernel of the acoustic loop; ptxinfo spills checked) | K-AW | M |

## S2-15 · Acoustic boundary updates (sub-gate G2.D)

Work package P2-D3 · Depends S2-12 … S2-14

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-15.1c / .1g | `spec_bdyupdate` (u, v, t, mu_2, muts, w) | K-SBU-YS/YE/XS/XE | S / S |
| S2-15.2c / .2g | `spec_bdyupdate_ph` (`mu_old` private scalar) | K-SBUPH-* | S / S |
| S2-15.3c / .3g | `zero_grad_bdy` (d01 `w`) | K-ZGB-* | S / S |
| S2-15.4 | **G2.D**: `T-TRACE-100`; launch count per d02 step recorded (plan-profiler PR-L1.4) | — | WS-A100, S |

## S2-16 · advect_scalar_pd (run 1)

Work package P2-E1 · plan.md §7.5 · Depends G1

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S2-16.1c | Review fluxes (y, x, z, z0) | K-PD-Y, K-PD-X, K-PD-Z0, K-PD-Z | M |
| S2-16.2c | Review the limiter split against T-PDLIM | K-PD-L1, -L2, -L3a, -L3b | M |
| S2-16.3c | Review the divergence | K-PD-D | S |
| S2-16.1g | L4–L8 | all K-PD-* | M |

## S2-17 · Scalar updates and flow-dependent boundaries (sub-gate G2.E)

Work package P2-E2 · Depends S2-16

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-17.1c / .1g | `rk_update_scalar_pd` | K-UPD-PD | S / S |
| S2-17.2c / .2g | `rk_update_scalar` | K-UPD-1…3 | S / S |
| S2-17.3c / .3g | `flow_dep_bdy` | K-FDB-YS/YE/XS/XE | S / S |
| S2-17.4c / .4g | `bound_tke` | K-BTKE | S / S |
| S2-17.5 | **G2.E**: `T-TRACE-100` (contains RK stage 3 of both domains) | — | WS-A100, S |

## S2-18 · End of step (sub-gate G2.F)

Work package P2-F · plan.md §7.6 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-18.1c / .1g | `calc_p_rho_phi` (`VPOW` inlined as `rp_pow`) | K-CPRP-1, K-CPRP-2 | M / S |
| S2-18.2c / .2g | `spec_bdy_final` | K-SBF-* | S / S |
| S2-18.3c / .3g | `set_w_surface` | K-SWS | S / S |
| S2-18.4c / .4g | `update_phys_fields` (no `grid%` in the kernel) | K-UPF | S / S |
| S2-18.5 | **G2.F**: `T-TRACE-100` | — | WS-A100, S |

## S2-19 · Diffusion metrics and deformation (run 1)

Work package P2-G1 · plan.md §7.7 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-19.1c / .1g | `compute_diff_metrics` (`z_at_w` as a private column, per the run-1 note; reviewed) | K-CDM-1…6 | M / S |
| S2-19.2c | `cal_deform_and_div` part 1 (kernels 01–30) | K-DEF-01…30 | M |
| S2-19.3c | `cal_deform_and_div` part 2 (kernels 31–59; run 1 has 59 launches vs the plan's ~40) | K-DEF-31…59 | M |
| S2-19.2g | L4–L8 of `cal_deform_and_div` | | M |

## S2-20 · N2, eddy viscosities, TKE (run 1, partial)

Work package P2-G2 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-20.1c / .1g | `calculate_N2` | K-N2-1…6 (10 launches in run 1) | M / S |
| S2-20.2c / .2g | `smag2d_km` (d01; `diff_opt` as a local) | K-SMAG | S / S |
| S2-20.3c / .3g | `tke_km` (d02, anisotropic branch only) | K-TKEKM-1…4 | M / S |
| S2-20.4c / .4g | `calc_l_scale` | K-LSC | S / S |
| S2-20.5c / .5g | `tke_shear` | K-TKES-1…9 | M / S |
| S2-20.6c / .6g | `tke_buoyancy` | K-TKEB-1, -2 | S / S |
| S2-20.7c / .7g | `tke_dissip` | K-TKED | S / S |
| S2-20.8c / .8g | `tke_rhs` floor | K-TKER | S / S |
| S2-20.9c / .9g | `conv_t_tendf_to_moist` | K-CTM | S / S |

## S2-21 · Vertical diffusion and the stress tensor (run 1, partial)

Work package P2-G3 · Depends G1

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-21.1c / .1g | `cal_titau_11_22_33`, `cal_titau_12_21` | K-TT-11, K-TT-12 | S / S |
| S2-21.2c / .2g | `cal_titau_13_31`, `cal_titau_23_32` | K-TT-13, K-TT-23 | S / S |
| S2-21.3c / .3g | `vertical_diffusion_2` (surface fluxes, `var_mix`, moisture loop) | K-VD2-* | M / S |
| S2-21.4c / .4g | `vertical_diffusion_u_2`, `_v_2`, `_w_2` | K-VDU, K-VDV, K-VDW | M / S |
| S2-21.5c / .5g | `vertical_diffusion_s` | K-VDS-1…3 | S / S |

## S2-22 · Horizontal diffusion (sub-gate G2.G)

Work package P2-G3 · Depends S2-19 … S2-21

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S2-22.1c / .1g | `horizontal_diffusion_2` (caller) | — | S / S |
| S2-22.2c / .2g | `horizontal_diffusion_u_2`, `_v_2`, `_w_2` | K-HDU-1…3, K-HDV-1…3, K-HDW-1…3 | M / S |
| S2-22.3c / .3g | `horizontal_diffusion_s` | K-HDS-1…11 | M / S |
| S2-22.4 | **G2.G**: `T-TRACE-100` and `T-TRACE-TKE` (W-TKE, 1,000 d02 steps incl. `nba_mij`) | — | WS-A100, M |

## S2-23 · Stage closure (G2)

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S2-23.1 | All Stage 2 routes on: W-20 and W-100 on GPU 0 and GPU 1 | WS-A100 | S | bitwise |
| S2-23.2 | T-NSYS on W-20: only physics/fire bracket copies and sync points remain | WS-A100 | S | `t_nsys.sh` PASS |
| S2-23.3 | T-DRIFT: CPU-REF at this commit vs the dev reference, 1 h, on CCR | CCR | S | bitwise |
| S2-23.4 | First dynamics profile on A100: kernel table, launches per step, bandwidth per kernel (plan-profiler PR-R1) | WS-A100 | M | `perf/reports/S2-dynamics-a100.md` |
| S2-23.5 | Book: dynamics chapters get their "port" sections ([plan-book.md](../plan-book.md)) | CLOUD | M | CI builds the PDF |

**Stage gate G2:** `bash port/gates/g2.sh` PASS, plus S2-23.
