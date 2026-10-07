# Stage 8 — The rest of WRF 4.6.0

Goal: grow from the Eaton configuration to the WRF 4.6.0 options that wildfire and mesoscale studies use, one
option family per phase. Each phase is independent and has its own case contract and reference, so a group can run
just the phases it needs. Options nobody needs stay on the CPU, and `gpu_check_config` rejects them with a message
naming the option.

## How every Stage 8 phase runs

| Step | What | Machine |
|---|---|---|
| 8-a case | a variant of the dev case (or an ideal case) that turns the option on; namelist and manifest in `cases/<variant>/` | CLOUD (namelist), CCR (real.exe) |
| 8-b reference | CPU-REF references of the variant: restarts and the windows it needs | CCR |
| 8-c kernel table | the plan.md-style kernel table of the new routines (file:line, template, kernel IDs) appended to plan.md as §8.x/§9.x; routes added; `gen_kernels_csv.py` | CLOUD |
| 8-d packages | the routines split into work packages (`wp_def.py`) so code-only runs can write L1 in parallel | CLOUD |
| 8-e routines | the routine ladder L1–L8 for each routine (Stage 2 task naming) | CLOUD → WS-A100 |
| 8-f harness | column/point harness for column physics (S3-03 framework) | WS-A100 |
| 8-g gate | T-AB of every new route, T-TRACE-100 on the variant, the Eaton regression unchanged (T-REG-20), `gpu_check_config` accepts the option | WS-A100 |
| 8-h book | the scheme's book section moves from "overview" to "in depth" ([plan-book.md](../plan-book.md)) | CLOUD |

## Phases

| Phase | Option family | Why | Size (phases' tasks) | Machine | Depends |
|---|---|---|---|---|---|
| **S8-01** | Multi-GPU design (ADR-005): device-resident halos, GPU-aware MPI, RSL_LITE pack/unpack on the device | full case on 2× A100 40 GB; larger fires | design note + probe (M ×3) | CLOUD, WS-A100 | G5 |
| **S8-02** | Device halo pack/unpack (`external/RSL_LITE/f_pack.F90` kernels), halo includes on the device | the core of multi-GPU | ≈10 M tasks | CLOUD → WS-A100 | S8-01 |
| **S8-03** | Decomposition independence on GPUs: 1 vs 2 GPUs bitwise on the dev case (T-DEC-GPU) | multi-GPU correctness | 4 M | WS-A100 (both A100s) | S8-02 |
| **S8-04** | The full Eaton case on 2× A100 40 GB: memory per rank, G5 items 1–4 | makes WS-A100 an acceptance machine | 4 M | WS-A100 | S8-03 |
| **S8-05** | Multi-GPU performance: halo time, overlap of halos with interior kernels (bit-neutral), scaling 1 → 2 GPUs | Track M | 5 M | WS-A100, GPU80 node | S8-04 |
| **S8-06** | Restart starts on the GPU (`restart = .true.`): read, upload, T-RST-GPU | long runs in pieces | 3 S | WS-A100 | G5 |
| **S8-07** | Two-way nesting (`feedback = 1`, `smooth_option`): feedback interpolation (host bridge first, then device) | common in nested fire runs | 6 M | WS-A100 | G5 |
| **S8-08** | More than two domains; other nest ratios; nests opening later | multi-scale fire setups | 4 M | WS-A100, GPU80 | S8-07 |
| **S8-09** | Adaptive time step (`use_adaptive_time_step`): CFL maxima (exact max reductions) | operational setups | 3 M | WS-A100 | G5 |
| **S8-10** | Advection options: other orders, monotonic limiter (`moist_adv_opt = 2`), WENO (`adv_opt = 3/4`) | robustness near fire plumes | 8 M | WS-A100 | G5 |
| **S8-11** | Turbulence options: `km_opt = 3` (3D Smagorinsky), `diff_6th_opt`, `mix_isotropic`, NBA `sfs_opt` | LES of fire plumes | 8 M | WS-A100 | G5 |
| **S8-12** | Slope-dependent radiation (`slope_rad`, `topo_shading`) | steep fire terrain | 4 M | WS-A100 | G5 |
| **S8-13** | Microphysics: Thompson (`mp = 8`), with its lookup tables on the device | widely used | 12 M | WS-A100 | G5 |
| **S8-14** | Microphysics: Morrison two-moment (`mp = 10`) | pyroconvection studies | 10 M | WS-A100 | G5 |
| **S8-15** | PBL and surface layer: MYNN (`bl_pbl = 5`, `sf_sfclay = 5`, EDMF) | widely used in fire weather | 12 M | WS-A100 | G5 |
| **S8-16** | Radiation: RRTMG SW (`ra_sw = 4`), sharing the batching of RRTMG LW | pairs with RRTMG LW | 10 M | WS-A100 | G5 |
| **S8-17** | Land surface: Noah-MP (`sf_surface = 4`) | modern LSM default | 16 M | WS-A100 | G5 |
| **S8-18** | Cumulus for coarse outer domains: Kain–Fritsch (`cu = 1`), Grell–Freitas (`cu = 3`) | outer domains above 5 km | 10 M | WS-A100 | G5 |
| **S8-19** | Other fire options: fuel moisture model (`fmoist_run`), fire tracers, other `fire_upwinding` and `fire_fuel_left_method`, line and multiple ignitions, `fire_sfc_flx` | other fires, other studies | 10 M | WS-A100 | G5 |
| **S8-20** | Diagnostics and bookkeeping: `do_radar_ref`, `prec_acc_dt`, buckets, `nwp_diagnostics`, `output_diagnostics` | users' outputs | 6 M | WS-A100 | G5 |

The order of S8-06 … S8-20 is the owner's choice. The table lists them by expected demand from fire studies.
Multi-GPU (S8-01 … S8-05) comes first because it lets the two A100s run the full case.
