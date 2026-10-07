# WRF 4.6.0 → 4.8.0: what changed, and what it means for the port

Measured on 2026-10-06:
- pristine 4.6.0: this repository's import commit `dda741a` (branch `upstream/v4.6.0`);
- 4.8.0: tag `v4.8.0`, commit `06d4240`, released 2026-06-08, with its submodules `physics_mmm` (`550b5b4`) and
  `fire_behavior` (`eb77580`) checked out.

Releases in between: 4.6.1, 4.7.0, 4.7.1. Task V-01 repeats this measurement with the script it adds, and keeps it
reproducible.

## Whole code base

| | Count |
|---|---|
| Source files (`.F`, `.F90`, `.f90`, `.c`, `.h`, `.inc`, Registry) in 4.6.0 / 4.8.0 | 3466 / 3459 |
| Added / removed in 4.8.0 | 25 / 32 |
| Changed (present in both) | 173: phys 47, hydro 34, chem 21, var 15, wrftladj 11, dyn_em 10, external 9, frame 8, share 7, tools 6, Registry 3, main 1 |

### New submodules in 4.8.0

`phys/fire_behavior` (CFBM, the new fire model), `phys/TEMPO`, `phys/MYNN-EDMF`, `phys/MYNN-SFC`, `phys/GFL` (and
`noahmp`, `physics_mmm` as before). The repository will import them as plain files (ADR-002).

## The files and routines the port touches

### By file

21 of the 60 files the port edits (Phases 1–4 and the Registry) changed. Lines added / removed:

| File | + | − | Nature (from the diffs) |
|---|---|---|---|
| `Registry/Registry.EM_COMMON` | 150 | 79 | new and renamed options/fields |
| `dyn_em/solve_em.F` | 206 | 5 | new calls (CFBM, diagnostics) |
| `dyn_em/module_first_rk_step_part1.F` | 199 | 13 | CFBM coupling (`Advance_state`, wind interpolation, feedback) |
| `dyn_em/start_em.F` | 148 | 10 | CFBM initialization |
| `dyn_em/module_em.F` | 147 | 3 | additions |
| `dyn_em/module_first_rk_step_part2.F` | 12 | 0 | |
| `dyn_em/module_big_step_utilities_em.F` | 7 | 7 | small edits (in physics-glue routines, see below) |
| `phys/module_physics_init.F` | 484 | 47 | new schemes' init |
| `phys/module_diagnostics_driver.F` | 464 | 3 | new diagnostics |
| `phys/module_microphysics_driver.F` | 350 | 12 | TEMPO and others |
| `phys/module_surface_driver.F` | 273 | 132 | MYNN-SFC and others |
| `phys/module_physics_addtendc.F` | 168 | 3 | |
| `phys/module_sf_noahdrv.F` | 94 | 1 | |
| `phys/module_pbl_driver.F` | 76 | 32 | MYNN-EDMF |
| `share/mediation_integrate.F` | 119 | 2 | |
| `frame/module_domain.F` | 4 | 96 | |
| `phys/module_bl_ysu.F` | 27 | 20 | |
| `phys/module_mp_wsm6.F` | 18 | 1 | |
| `phys/module_sf_sfclayrev.F` | 7 | 0 | |
| `phys/module_ra_rrtmg_lw.F`, `phys/module_radiation_driver.F` | 2 | 2 | |
| `physics_mmm/sf_sfclayrev.F90` | 36 changed lines | | |
| `physics_mmm/bl_ysu.F90` | 3 changed lines | | |
| `physics_mmm/mp_wsm6_effectRad.F90` | 2 changed lines | | |
| `physics_mmm/mp_wsm6.F90`, `module_libmassv.F90` | unchanged | | |
| **All WRF-Fire (SFIRE) files** (`phys/module_fr_fire_*.F`) | unchanged | | |

### By routine

Routines that a work package of Phases 1–3 owns (`port/agent/wp/ownership.json`) and whose text differs in 4.8.0:

| Work package | Routines | Changed in 4.8.0 (changed lines) |
|---|---|---|
| P1-SYNC (drivers) | 88 | `solve_em` (211), `med_before_solve_io` (18) |
| **All 18 Phase 2 packages** (dynamics) | 74 | **none** |
| P3-GLUE1 | 4 | `phy_prep_part2` (4), `moist_physics_finish_em` (6) |
| P3-GLUE2 | 16 | `calculate_phy_tend` (126), `update_phy_ten` (31), `phy_cu_ten` (2), `phy_fr_ten` (15) |
| P3-WSM6 | 23 | `wsm6` wrapper (17), `mp_wsm6_effectRad_finalize` (2), `microphysics_driver` (362); core `mp_wsm6_run` unchanged |
| P3-SFCLAY | 16 | `sfclayrev` (7), `sf_sfclayrev_run` (35) |
| P3-NOAH | 58 | `lsm` (40), `lsm_mosaic` (55); the Noah core (`SFLX` and callees) unchanged |
| P3-SFCDRV | 13 | `surface_driver` (273), `mynn_seaice_wrapper` (128), `sfclayrev_seaice_wrapper` (6) |
| P3-PBL | 14 | `pbl_driver` (108), `ysu` (47), `bl_ysu_run` (3) |
| P3-RADDRV | 25 | `calc_coszen` (4) |
| P3-RRTMG, P3-SW | 88 | none |

## What it means

1. **The dynamics port carries over unchanged.** Every routine of Phase 2 has identical text in 4.8.0: their kernels,
   islands and tests apply as they are.
2. **The physics port carries over in its cores**: WSM6, Noah's SFLX, RRTMG and Dudhia SW are unchanged, as are YSU
   and sfclayrev apart from small edits. What changed are the **drivers and wrappers**: `surface_driver`,
   `pbl_driver`, `microphysics_driver`, `calculate_phy_tend`, `lsm`. These must be re-ported: about 20 routines, most
   of them glue code.
3. **The infrastructure needs real work for 4.8.0**:
   - the Registry changes (new fields and options) regenerate the P1.2/P1.3 code, which is automatic;
   - `solve_em` and `first_rk_step_part1` gained the CFBM coupling;
   - the case contract must be rechecked against the new options (task V-03).
4. **WRF-Fire (Phase 4) carries over unchanged**, and **CFBM is new work** (track C,
   [cfbm.md](cfbm.md)). It reuses the level-set and spread-rate kernels of Phase 4: CFBM's physics comes from the same
   SFIRE algorithms.
5. **Build:** CFBM is built only by WRF's CMake build in 4.8.0 (`phys/CMakeLists.txt`: `add_subdirectory(fire_behavior)`;
   `phys/Makefile` does not list it). A 4.8.0 port with CFBM needs a CMake mode in the port's build scripts (task V-06).

Estimated forward-port effort (task sizes as in [../TASK_PROTOCOL.md](../TASK_PROTOCOL.md)):
- about 8 tasks to import and re-baseline;
- about 10 to re-port the changed routines;
- about 4 for CMake and the case contract;
- track C on top (CFBM).
