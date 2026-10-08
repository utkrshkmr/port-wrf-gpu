# Stage 4 — WRF-Fire

Goal: the fire model of d02 runs on the device. The solve_em bracket is then empty, and the fire spreads cell by cell
exactly as in CPU-REF through ignition and free spread. Spec: plan.md §9 (9.0 preparation, 9.1 kernels), PHASE4.md,
INTERFACES.md I-12 (fire data on the device).

Fire kernels work on the 724² fire grid of the dev case (3284² in the full case). The ghost rows and columns 0 and
`n+1` must hold the values CPU-REF has: T-FIRE-GHOST.

Task naming as in Stage 2: `.Nc` = L1–L3 on CLOUD, `.Ng` = L4–L8 on WS-A100. Every fire T-AB uses W-IGN or W-FIRE,
because W-20 starts after ignition but contains no ignition.

---

## S4-01 · Fire data on the device: flags, constants, fp, ghosts (run 1)

Work package P4-MODEL (tasks 1–6 of its card) · Depends G3

| Task | What | Machine | Size |
|---|---|---|---|
| S4-01.1 | Review the `set_flags` hoist (`fire_ifun_start.eq.1`); scope request S0-02.3 applied | CLOUD | S |
| S4-01.2 | Flags and constants of `module_fr_fire_util` and `module_fr_fire_phys`: `!$acc declare create` + `update device` once per domain after init | CLOUD → WS-A100 | S |
| S4-01.3 | `fp` (domain fire pointers): `enter data copyin` + `attach` of the pointer components (probe F-ATTACH); `fp%fuel_time` not attached (never associated) | CLOUD → WS-A100 | M |
| S4-01.4 | T-FIRE-GHOST: ghosts of `lfn`, `tign_g` on the device equal the host after init (0 and 725 on the dev case) | WS-A100 | S |
| S4-01.5 | Fire work arrays (`lfn_out`, `tend`, `ua`, `va`, …) present (T-WORK covers them) | WS-A100 | S |

## S4-02 · Fire statistics: integer NaN counts (run 1)

Work package P4-MODEL · Depends S4-01

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S4-02.1c / .1g | `print_2d_stats`, `print_3d_stats` (integer any-NaN counts; crash on the host as before) | K-NAN | S / S |

## S4-03 · Atmosphere-to-fire interpolation

Work package P4-A2F · Depends S4-01

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S4-03.1c / .1g | `interpolate_atm2fire` part 1: NaN init, `altw`, `altub/hgtu`, `altvb/hgtv` | K-A2F-1…4 | M / S |
| S4-03.2c / .2g | `interpolate_atm2fire` part 2: log-wind interpolation with the k search (early exit = `EXIT`, no loop directive), edge copies, `uah/vah` stores, z-coupling | K-A2F-5…9, -12, -15 | M / S |
| S4-03.3c / .3g | `continue_at_boundary`: j-strips, i-strips, corners in order; internal `EX` → routine seq | K-CAB-J, -I, -C | M / S |
| S4-03.4c / .4g | `interpolate_2d` (4×4 fine nodes per coarse cell, no overlap for even `sr`) | K-I2D | S / S |

## S4-04 · Level-set tendency and rate of spread (run 1)

Work package P4-LS · Depends S4-01

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S4-04.1c | `fire_ros` routine seq (the `ros_max` capping quirk; unused internal `nrm2` compiled only on the CPU) | K-ROS | S |
| S4-04.2c | `tend_ls`: review the verbatim device copies of `select_eno`, `select_4th`, `select_weno5` (owned by nobody; check_verbatim) | K-TLS | M |
| S4-04.3c | `tend_ls`: ENO1 near the edge, WENO5 in the band, ENO outside; normals; viscosity; `reduction(max:tb)` | K-TLS | M |
| S4-04.1g | L4–L8; per-kernel divergence measured (plan-profiler PR-L3) | — | M |

## S4-05 · Level-set time stepping, ignition time, flame length (run 1)

Depends S4-04

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S4-05.1c / .1g | `prop_ls_rk3` (the three stages with `dt/3`, `dt/2`, `dt`) | K-PLS-0…3 | S / S |
| S4-05.2c / .2g | `tign_update` and the boundary guard (host rescan with the original message) | K-TIGN-1, K-TIGN-G | S / S |
| S4-05.3c / .3g | `calc_flame_length` | K-FLAME | S / S |

## S4-06 · Reinitialization (run 1)

Depends S4-04

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S4-06.1c / .1g | `reinit_ls_rk3` (`tend_1..3` removed: certified S0-12.3) | K-RI-0, K-RI-F | S / S |
| S4-06.2c / .2g | `advance_ls_reinit` ×3 with `continue_at_boundary` between stages (s3, s1, s2, s3) | K-ALR | M / S |

## S4-07 · Ignition

Work package P4-FUEL · Depends S4-01

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S4-07.1c / .1g | `nearest` routine seq | — | S / S |
| S4-07.2c / .2g | `ignite_fire`: host window test, per-point kernel, integer `ignited` count, WARNING counter | K-IGN | M / S |

## S4-08 · Fuel consumption

Work package P4-FUEL · Depends S4-01

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S4-08.1c / .1g | `fuel_left_cell_1` routine seq (`rp_exp`) | — | S / S |
| S4-08.2c / .2g | `fuel_left`: cells × 4 subcells in source order; reads ghosts 0/n+1; crash flags | K-FL-1 | M / S |
| S4-08.3c / .3g | Normalization and check loop | K-FL-2, K-FL-3 | S / S |

## S4-09 · Heat fluxes and sums over fire cells

Work package P4-FUEL · Depends S4-08

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S4-09.1c / .1g | `heat_fluxes` (`cmbcnst` on the device) | K-HF | S / S |
| S4-09.2c / .2g | `sum_2d_cells` ×3 (inner `joff`/`ioff` loops sequential, source order) | K-S2D | S / S |

## S4-10 · fire_model and the fire drivers (run 1, partial)

Work package P4-MODEL · Depends S4-03 … S4-09

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S4-10.1c / .1g | `fire_model`: ifun 5 copy, ifun 6 update, the order of calls | K-FM5, K-FM6 | M / S |
| S4-10.2c / .2g | `fire_driver_phys` and `fire_driver_em`: scaling, the island inside the tile loop (one tile only) | K-FSC | M / S |
| S4-10.3c / .3g | `fire_driver_em_init`, `fire_driver_em_step` call sites; the ifun-2 gradient max (message only) | — | S / S |

## S4-11 · Fire tendency into the atmosphere

Work package P4-ATM · Depends S4-01

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S4-11.1c / .1g | `fire_tendency`: zero, fluxes per (i,k,j) with `rp_exp`, divergence | K-FT-1, -2, -3 | M / S |

## S4-12 · Fire windows

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S4-12.1 | `T-AB` of every fire route on W-IGN | WS-A100 | M | identical |
| S4-12.2 | T-FIRE-IGN: 02:00 → 02:35 (6,300 d02 steps), level 1 with all fire arrays, level 2 for 100 steps after 8280 s | WS-A100 | M | bitwise |
| S4-12.3 | T-FIRE-WIN: 02:20 → 03:00 (W-FIRE) on GPU 0, and the same on GPU 1 | WS-A100 | M | bitwise |
| S4-12.4 | `compare_fire.py` at 02:30, 02:45, 03:00 | WS-A100 | S | 0 differing cells |

## S4-13 · Stage closure (G4)

| Task | What | Machine | Size |
|---|---|---|---|
| S4-13.1 | The bracket is empty: no island left inside `solve_em` (`t_nsys.sh` W-20) | WS-A100 | S |
| S4-13.2 | T-DRIFT (host cores) | WS-A100 | S |
| S4-13.3 | Fire profile on A100: WENO divergence, fire-grid bandwidth, launches per fire call | WS-A100 | M |
| S4-13.4 | Book: fire chapter "port" section; first fire animation from the trace of S4-12 | CLOUD | M |

**Stage gate G4:** `bash port/gates/g4.sh` PASS, plus S4-13.
