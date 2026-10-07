# P1-ST status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: coded
- Branch: agent/wp/p1_st
- Last commit: 3be67bd

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| task 1: T-FIRE-GHOST gpu_selftest_fire_ghost(grid) | coded | 9a92bdd | device lfn/tign_g ghosts are 0.0; called from gpu_selftests when ifire > 0 |
| task 2: gpu_selftests(grid) WRF_GPU_SELFTEST=1 dispatcher | coded | 3be67bd | calls map, tab, work, and fire ghost when ifire > 0; env read once |
| task 3: gpu_selftest_map(grid) T-MAP | coded | | acc_is_present via head_statevars; empty list is FAIL |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- Ghost columns are `ifds-1` and `(ifde - sr_x) + 1`, ghost rows `jfds-1` and `(jfde - sr_y) + 1`, from `get_ijk_from_subgrid` (the same ends `fire_driver_em` passes in as `ifde-ir`). That is 0 and 725 on the dev mesh and 0 and 3241 when the fire tile is 1..3240. An index outside the allocated array counts as not 0.0.
- The host copies of `lfn` and `tign_g` are refreshed with `!$acc update self` before the count (no compute kernel, so no route). After the S1/S2 upload the two copies already match when the halo is the allocation zero.
- T-MAP counts `head_statevars` nodes with `Ndim >= 1` and type `r`, `d`, `i`, or `l` (the sentinel head is skipped; scalars are on the list but are not device-mapped). An empty list prints FAIL (`0 of 0`). Boundary arrays are mapped in `gen_allocs` but are not nodes of this list, so this walk does not check them. At most eight missing names are printed.

## Log

- T-FIRE-GHOST (9a92bdd): `gpu_selftest_fire_ghost` plus `work_p1_st_fire_count` / `work_p1_st_ghost_pair`.
- Dispatcher (3be67bd): `gpu_selftests` reads `WRF_GPU_SELFTEST` once (SAVE). When the value is `1` it calls `gpu_selftest_map`, `gpu_selftest_tab`, `gpu_selftest_work`, and `gpu_selftest_fire_ghost` if `ifire > 0`.
- T-MAP: `gpu_selftest_map` walks `grid%head_statevars%next` and calls `acc_is_present` through `work_p1_st_field_present`. No hand-written field list.
