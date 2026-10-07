# CFBM — NCAR's Community Fire Behavior Model

Surveyed on 2026-10-06 at commit `eb77580` (2026-04-15): the commit WRF 4.8.0 pins as its `phys/fire_behavior`
submodule. Upstream: https://github.com/NCAR/fire_behavior, Apache License 2.0. Documentation:
https://ral.ucar.edu/model/community-fire-behavior-model.

## What it is

CFBM is a modular, standalone rewrite of WRF-Fire's SFIRE fire-spread model, in modern Fortran (`.F90`), about
12,900 lines in 33 files:

| Directory | Files | Lines | Content |
|---|---|---|---|
| `physics/` | 7 | 3,669 | `level_set_mod` (2,278 lines: the level-set front propagation), `ros_wrffire_mod` (Rothermel rate of spread, from WRF-Fire), `fmc_wrffire_mod` (fuel moisture), `fuel_anderson_mod` (Anderson fuel models), `fire_model_mod`, `fire_physics_mod`, `fire_driver_mod` |
| `state/` | 3 | 1,544 | the fire state type, tiles, ignition lines |
| `io/` | 7 | 3,000 | standalone I/O, and `wrf_mod` / `wrfdata_mod`: coupling to WRF (`Interp_wrfwinds_to_cfbm`, `Provide_atm_feedback`) |
| `share/` | 9 | 1,813 | constants, utilities |
| `nuopc/` | 4 | 2,567 | NUOPC/ESMF cap: coupling inside the UFS (e.g. the Short-Range Weather application) |
| `driver/` | 3 | 327 | standalone driver |

**In WRF 4.8.0:**
- selected by `ifire = 1` (`ifire = 2` is the old WRF-Fire/SFIRE, still present and unchanged);
- the fire state is `grid%fire_state` (a derived type inside `domain`);
- initialized by `Init_fire_state_within_wrf` (`start_em.F`);
- advanced by `Advance_state` in `first_rk_step_part1`, between `Interp_wrfwinds_to_cfbm` and
  `Provide_atm_feedback`;
- built only by WRF's CMake build.

## What it means for the port

- **Same algorithms as Phase 4.** Level set and Rothermel spread rate are what Phase 4 ports in WRF-Fire. The
  kernels (level-set advance, normal and gradient stencils, spread rate per cell, fuel-fraction update) map one to
  one. They are written differently: CFBM uses derived types and module procedures where SFIRE uses long argument
  lists.
- **A cleaner GPU target.** Its own state type means one deep data structure to map: map the components by address
  as P1.2 does for `grid`, never with `map(grid%x)`. Its standalone driver means it can be ported and tested **without
  WRF**, on a small grid, which is fast to iterate on.
- **Bit-for-bit method as everywhere:** CPU build vs GPU build of the same CFBM source, standalone first, then inside
  WRF 4.8.0 with `ifire = 1`.
- **NUOPC coupling** (UFS) is out of scope of the GPU work at first. The standalone and WRF-coupled paths come first.
- **Upstream:** CFBM is under active development. Our GPU changes should be offered upstream as pull requests to
  NCAR/fire_behavior (Apache-2.0), so that future CFBM versions keep them, instead of living only in a fork.

Track C of the backlog: C-01 build and run standalone on CPU, C-02 kernel inventory and mapping to Phase 4, C-03 to
C-08 standalone GPU port with bit-for-bit tests, C-09/C-10 integration in WRF 4.8.0, C-11 upstream contribution.
