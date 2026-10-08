# Stage 3 — The physics of the case

Goal: WSM6, sfclayrev, Noah, YSU, Dudhia SW, RRTMG LW, the radiation driver and the physics glue run on the device.
The `solve_em` bracket then encloses only the fire. Spec: plan.md §8 (CP-1 … CP-5, 8.1–8.5), PHASE3.md.

Column physics is checked one column at a time before it meets real data:
1. S3-03 builds a **column harness**: columns extracted from the CPU-REF state, run through the CPU view, the GPU
   view on the host, and the device.
2. Every scheme passes its harness (T-WSM6-COL, T-NOAH-PT, T-YSU-COL, T-RRTMG-COL) before its T-AB.

Task naming as in Stage 2: `.Nc` = L1–L3 on CLOUD, `.Ng` = L4–L8 on WS-A100.

---

## S3-01 · Physics glue of the big-step utilities

Work package P3-GLUE1 · plan.md §8.1 · Depends G2

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S3-01.1c / .1g | `phy_prep` (the `p_hyd_w` column recurrence) | K-PPR-1…7 | M / S |
| S3-01.2c / .2g | `phy_prep_part2` | K-PP2-1, -2 | S / S |
| S3-01.3c / .3g | `moist_physics_prep_em` | K-MPP-1…5 | S / S |
| S3-01.4c / .4g | `moist_physics_finish_em` (unused argmax removed: shared refactor, certify) | K-MPF | M / S |

## S3-02 · Physics tendencies (sub-gate G3.A)

Work package P3-GLUE2 · Depends S3-01

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S3-02.1c / .1g | `init_zero_tendency` (callers of K-ZT-1) | — | S / S |
| S3-02.2c / .2g | `calculate_phy_tend` | K-CPT-1, -2 | S / S |
| S3-02.3c / .3g | `add_a2a`, `add_a2c_u`, `add_a2c_v` (`kte` quirk); `update_phy_ten` caller | K-A2A, K-A2CU, K-A2CV | S / S |
| S3-02.4 | **G3.A**: `T-TRACE-100` | — | WS-A100, S |

## S3-03 · Column test harness framework

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S3-03.1 | Column extractor: from a CPU-REF level-2 run at a checkpoint, write the inputs of N sampled columns (all arguments of the scheme's core routine) to a binary file | CLOUD (write) → WS-A100 (run) | M | file format documented |
| S3-03.2 | Runner template: one column per thread through the core routine, in three builds (CPU view, GPU view on host, device); outputs bit-compared (`harness_diff.py`) | CLOUD | M | the CP template test (`t_tmpl_cp`) extended to file input |
| S3-03.3 | Sampling rule: 10⁵ columns per scheme from 02:30 and 12:00 of the dev case, plus the extreme columns (max cloud, max precipitation, snow, night/day) | CLOUD | S | rule in PHASE3.md |
| S3-03.4 | Device run of the template on the A100; stack size read back (CP-5) | WS-A100 | S | PASS |

## S3-04 · WSM6 device tree (run 1, partial)

Work package P3-WSM6 · plan.md §8.2 · Depends S3-03

| Task | Routine / item | Size (c/g) |
|---|---|---|
| S3-04.1c | `mp_wsm6_run`: `!$acc routine seq` (kernel_lint W2 open from run 1); CP-3 fixed-size locals (≈78 arrays); whole-array syntax rewritten to explicit sections, each hit listed | M |
| S3-04.2c | Callees `slope_wsm6`, `slope_rain`, `slope_snow`, `slope_graup` | S |
| S3-04.3c | `nislfv_rain_plm`, `nislfv_rain_plm6` (≈27 k-vectors) | M |
| S3-04.4c | Statement functions `cpmcal` … `conden`, `lamdar/s/g` (F-STMTFN decides); `vrec`, `vsqrt` routine seq | S |
| S3-04.5c | SAVE scalars → `!$acc declare create` + upload in P1.4; T-TAB entry | S |
| S3-04.1g | T-WSM6-COL on the device (S3-03 framework) | M |

## S3-05 · WSM6 kernel and microphysics driver (sub-gate G3.B)

Depends S3-04

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S3-05.1c / .1g | `wsm6` wrapper (CP-1 gather/scatter, surface accumulators) | K-WSM6 | M / M |
| S3-05.2c / .2g | `microphysics_driver` (work arrays of run 1; effective radius skipped when `has_req*=0`) | — | M / S |
| S3-05.3 | CP-5: per-thread frame from ptxinfo, stack limit set and read back; local-memory reservation added to G-MEM | — | WS-A100, S |
| S3-05.4 | **G3.B**: `T-AB-wsm6` and `T-TRACE-100` | — | WS-A100, S |

## S3-06 · Surface layer sfclayrev and T-ZOLRI

Work package P3-SFCLAY · plan.md §8.3 · Depends S3-03

| Task | Routine / item | Size (c/g) |
|---|---|---|
| S3-06.1c | `sf_sfclayrev_run` routine seq, CP-3; `zolri`, `zolri2`, `psim/psih` lookups and `*_full` fallbacks routine seq | M |
| S3-06.2c | ψ tables `declare create` + upload; T-TAB | S |
| S3-06.3c | `SFCLAYREV` wrapper and `sf_sfclayrev_pre_run`: K-SFCLAY per point | M |
| S3-06.4 | T-ZOLRI: occurrences of the undefined path in the reference = 0 (instrumented CPU-REF once) | WS-A100, S |
| S3-06.1g | Column harness, then L4–L8 | M |

## S3-07 · Noah: certified refactors and tables (run 1)

Work package P3-NOAH · Depends S3-03

| Task | What | Machine | Size |
|---|---|---|---|
| S3-07.1 | Review the run-1 `iloc/jloc` and `LUTYPE/SLTYPE` refactors (certified in S0-12.8) | CLOUD | S |
| S3-07.2 | Review the 49 table uploads, `noahlsm_gpu_upload`, `noahlsm_gpu_tabcheck`; T-TAB | WS-A100 | S |

## S3-08 · Noah leaves I: soil heat and snow

Depends S3-07. Every routine gets `!$acc routine seq` and fixed NSOIL-sized locals (`WRF_NSOILMAX=4`); FATAL
branches become error codes.

| Task | Routines | Size (c) |
|---|---|---|
| S3-08.1c | `TDFCND`, `TBND`, `TMPAVG`, `SNKSRC` | S |
| S3-08.2c | `FRH2O`, `HRT` | M |
| S3-08.3c | `HSTEP`, `ROSR12`, `SHFLX` | S |
| S3-08.4c | `CSNOW`, `SNOW_NEW`, `SNFRAC` (`SNUPGRD` PARAMETER), `ALCALC`, `SNOWZ0` | M |
| S3-08.1g | Point harness of the leaves (inputs from S3-03), on the device | M |

## S3-09 · Noah leaves II: water and evaporation

Depends S3-07

| Task | Routines | Size (c) |
|---|---|---|
| S3-09.1c | `PENMAN`, `CANRES` | S |
| S3-09.2c | `DEVAP`, `TRANSP`, `EVAPO` | M |
| S3-09.3c | `WDFCND`, `SRT`, `SSTEP` | M |
| S3-09.4c | `SMFLX`, `FAC2MIT` | S |
| S3-09.1g | Point harness of the leaves on the device | M |

## S3-10 · Noah composites up to SFLX

Depends S3-08, S3-09

| Task | Routines | Size (c) |
|---|---|---|
| S3-10.1c | `NOPAC` | M |
| S3-10.2c | `SNOPAC`, `SNOWPACK` | M |
| S3-10.3c | `REDPRM` (integer codes) | S |
| S3-10.4c | `SFLX` part 1 (setup, energy) | M |
| S3-10.5c | `SFLX` part 2 (water, snow, outputs; `DO K=1,4` kept) | M |
| S3-10.1g | T-NOAH-PT for `SFLX` on the device (10⁵ points) | M |

## S3-11 · Noah kernel, glacial, T-NOAH-PT

Depends S3-10

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S3-11.1c / .1g | `lsm` wrapper: per point, `itimestep==1` block; error codes reported on the host | K-LSM | M / M |
| S3-11.2c / .2g | `SFLX_GLACIAL` | K-LSM | M / S |
| S3-11.3 | T-NOAH-PT end to end; T-AB-lsm | — | WS-A100, S |

## S3-12 · Sea ice and surface diagnostics

Work package P3-NOAH · Depends S3-03

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S3-12.1c / .1g | `seaice_noah` (+ driver) | K-SEAICE | M / S |
| S3-12.2c / .2g | `SFCDIAGS` | K-SFCDIAG | S / S |

## S3-13 · surface_driver kernels (run 1) (sub-gate G3.C)

Work package P3-SFCDRV · Depends S3-06, S3-11, S3-12

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S3-13.1c | Review the run-1 code; the island is ~3,000 generated lines: `WRF_CHEM` and `CN` guards, optional arguments that must be present | K-SD-1…8 | M |
| S3-13.2c | Calls into SFCLAYREV, lsm, seaice, SFCDIAGS become device calls (their islands collapse) | — | M |
| S3-13.1g | L4–L8, `T-AB-surface_driver` | — | M |
| S3-13.3 | **G3.C**: `T-TRACE-100` | — | WS-A100, S |

## S3-14 · YSU device tree

Work package P3-PBL · plan.md §8.4 · Depends S3-03

| Task | Routine / item | Size (c) |
|---|---|---|
| S3-14.1c | `bl_ysu_run` part 1: routine seq, CP-3 for ≈50 2D arrays and ≈40 vectors | M |
| S3-14.2c | `bl_ysu_run` part 2: the remaining body; `zq(its:ite,kme)` | M |
| S3-14.3c | `tridin_ysu`, `tridi2n`, `get_pblh` (the `DO WHILE` kept) | S |
| S3-14.4 | BEP out-of-bounds guard: certify (shared refactor of Phase 0) | WS-A100, S |
| S3-14.1g | T-YSU-COL on the device | M |

## S3-15 · PBL driver and YSU kernel (sub-gate G3.D)

Depends S3-14

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S3-15.1c / .1g | `pbl_driver` saves and zeroing (run 1); island `WRF_CHEM` guards reviewed | K-PBLD-1 | S / S |
| S3-15.2c / .2g | `ysu` wrapper (CP-1) | K-YSU | M / M |
| S3-15.3 | **G3.D**: `T-AB-ysu`, `T-TRACE-100` (d01 steps) | — | WS-A100, S |

## S3-16 · Radiation driver: every-step kernels (run 1)

Work package P3-RADDRV · plan.md §8.5 · Depends G2

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S3-16.1c / .1g | LW flux accumulations | K-RAD-ACC | S / S |
| S3-16.2c / .2g | Cloud product in k order | K-RAD-CLDT | S / S |

## S3-17 · Radiation driver: radiation-step kernels (run 1)

Depends S3-16

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S3-17.1c / .1g | `solar_eclipse` zero; `calc_coszen` | K-RAD-ECL, K-RAD-COSZ | S / S |
| S3-17.2c / .2g | `CLDFRA` zero, `cal_cldfra1` | K-RAD-CF0, K-RAD-CF1 | S / S |
| S3-17.3c / .3g | Zeroing of fluxes and heating rates, GLAT/GLON | K-RAD-Z | S / S |
| S3-17.4c / .4g | LW and SW post-processing | K-RAD-LWPOST, K-RAD-SWPOST | M / S |
| S3-17.5 | Work-array sizes of run 1 (`ozmixt` n2d·59, `aerodt` n2d·72) guarded by `gpu_check_config` | — | CLOUD, S |

## S3-18 · Ozone interpolation and T-OZN

Depends S3-16

| Task | Routine | Kernels | Size (c/g) |
|---|---|---|---|
| S3-18.1c / .1g | `ozn_time_int` (d01) | K-OZT | S / S |
| S3-18.2c / .2g | `ozn_p_int` per column (the T-OZN reference test exists) | K-OZP | M / S |

## S3-19 · Dudhia shortwave

Work package P3-SW · Depends S3-03

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S3-19.1c | `SWPARA` routine seq; DATA tables → PARAMETER; night early exit; `SDOWN` recurrence | K-SW | M |
| S3-19.2c | `SWRAD` wrapper (CP-1, column reversal) | K-SW | M |
| S3-19.1g | Column harness, then L4–L8 | | M |

## S3-20 · RRTMG tables (run 1, partial)

Work package P3-RRTMG · Depends S3-03

| Task | What | Machine | Size |
|---|---|---|---|
| S3-20.1 | Review the EQUIVALENCE flattening (`ka_s(ind + (ig-1)*nka)`) in all 16 `rrlw_kgNN` modules; certified in S0-12.7 | CLOUD | M |
| S3-20.2 | `rrtmg_lw_ini` hoisted to init (certified S0-12.7); `NLAYERS` constant | CLOUD | S |
| S3-20.3 | Upload and tabcheck (≈0.75 MB of tables); T-TAB | WS-A100 | S |

## S3-21 · RRTMG column setup routines

Depends S3-20. All routines get `!$acc routine seq`; per-column automatics become slices of batch work arrays
(plan.md §8.5 "Batching").

| Task | Routines | Size (c) |
|---|---|---|
| S3-21.1c | `inatm` | M |
| S3-21.2c | `cldprmc` | S |
| S3-21.3c | `setcoef` | M |
| S3-21.4c | `relcalc`, `reicalc`, `INIRAD`, `O3DATA`, buffer layers against `PPROF`/`TPROF` | M |
| S3-21.1g | Column harness of the setup on the device | M |

## S3-22 · RRTMG taumol (taugb1–16)

Depends S3-20

| Task | Routines | Size (c) |
|---|---|---|
| S3-22.1c | `taugb1` … `taugb4` (`rp_mod` for `mod(x,1.0)`) | M |
| S3-22.2c | `taugb5` … `taugb8` | M |
| S3-22.3c | `taugb9` … `taugb12` | M |
| S3-22.4c | `taugb13` … `taugb16`, `taumol` (internal procedures → module procedures if F-INTPROC fails) | M |
| S3-22.1g | Column harness of `taumol` on the device | M |

## S3-23 · RRTMG radiative transfer and McICA (T-KISS)

Depends S3-20

| Task | Routines | Size (c) |
|---|---|---|
| S3-23.1c | `rtrnmc` part 1 (`abscld`, `efclfrac`, `odcld` as batch slices) | M |
| S3-23.2c | `rtrnmc` part 2 (fluxes, heating rates) | M |
| S3-23.3c | `mcica_subcol_lw`, `generate_stochastic_clouds` (unused Mersenne state removed: certify), `kissvec` | M |
| S3-23.4 | T-KISS on the device with the real `kissvec` | WS-A100, S |
| S3-23.1g | Column harness of `rtrnmc` and McICA on the device | M |

## S3-24 · RRTMG batching and kernel (sub-gate G3.E)

Depends S3-17 … S3-23

| Task | Routine / item | Kernels | Size (c/g) |
|---|---|---|---|
| S3-24.1c | Batch work arrays (`WRF_RRTMG_BATCH`, default 4096; ≈1.1 MB per column) and the host batch loop | — | M |
| S3-24.2c | `RRTMG_LWRAD`: one thread per column of the batch; error codes instead of STOP / `wrf_error_fatal` | K-RRTMG-COL | M |
| S3-24.1g | T-RRTMG-COL (10⁵ columns from 02:00 and 12:00), host vs device | — | M |
| S3-24.2g | L6–L8 on W-RAD; batch size vs memory on A100 40 GB (2048 if needed) | — | M |
| S3-24.3 | **G3.E**: `T-AB-radiation_driver` and `T-TRACE-RAD` (W-RAD, 4 radiation calls per domain) | — | WS-A100, M |

## S3-25 · Stage closure (G3)

| Task | What | Machine | Size | Done when |
|---|---|---|---|---|
| S3-25.1 | All Stage 2–3 routes on: W-20, W-100, W-RAD on GPU 0 and GPU 1 | WS-A100 | M | bitwise |
| S3-25.2 | T-NSYS on W-20: only the fire bracket and sync points | WS-A100 | S | PASS |
| S3-25.3 | T-DRIFT (host cores) | WS-A100 | S | bitwise |
| S3-25.4 | G-MEM-2: acceptance case `eaton_mid`, first d01 step with radiation on both domains; peak ≤ 34 GB; the full case from the estimator | WS-A100 | S | logged |
| S3-25.5 | Physics profile on A100 (column kernels: occupancy, local memory, registers) | WS-A100 | M | `perf/reports/S3-physics-a100.md` |
| S3-25.6 | Book: physics chapters' "port" sections | CLOUD | M | CI PDF |

**Stage gate G3:** `bash port/gates/g3.sh` PASS, plus S3-25.
