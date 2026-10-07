# P1-ST status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p1_st
- Last commit:

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| task 1: T-FIRE-GHOST gpu_selftest_fire_ghost(grid) | coded | | device lfn/tign_g ghosts are 0.0; called from gpu_selftests when ifire > 0 |
| task 2: gpu_selftests(grid) WRF_GPU_SELFTEST=1 dispatcher | todo | | |
| task 3: gpu_selftest_map(grid) T-MAP | todo | | |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- Ghost columns are `ifds-1` and `(ifde - sr_x) + 1`, ghost rows `jfds-1` and `(jfde - sr_y) + 1`, from `get_ijk_from_subgrid` (the same ends `fire_driver_em` passes in as `ifde-ir`). That is 0 and 725 on the dev mesh and 0 and 3241 when the fire tile is 1..3240. An index outside the allocated array counts as not 0.0.
- The host copies of `lfn` and `tign_g` are refreshed with `!$acc update self` before the count (no compute kernel, so no route). After the S1/S2 upload the two copies already match when the halo is the allocation zero.

## Log

- T-FIRE-GHOST: `gpu_selftest_fire_ghost` plus `work_p1_st_fire_count` / `work_p1_st_ghost_pair`. `gpu_selftests` calls it under `WRF_GPU` when `grid%ifire > 0`. The env-var gate is the next item.
