# P3-PBL status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p3_pbl
- Last commit: ef11412cc94a3a5c62d3ab2f2c93ca093f938a6b

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-PBLD-1 | coded | this commit | Template A. Island pasted. 2D automatics TSKOLD, USTOLD, ZNTOLD, PSFC are GPU-only work pointers. QNI, non-YSU, idiff=1, fasdas, windfarm, gwd, grav_settling, scalar_pblmix, active tracer diff4d, and distributed_ahe stop with wrf_error_fatal. |
| K-YSU | todo | | ysu wrapper and bl_ysu_run still to port |
| 8.4:get_pblh | todo | |  |
| task 1: shared refactor (separate commit): pbl_driver's large 3D automatic arr... | coded | ef11412cc94a3a5c62d3ab2f2c93ca093f938a6b | u_phytmp, v_phytmp, TKE_windfarm, rqncblten, rqnwfablten, rqnifablten, rqnbcablten. arith_guard CPU-view diffs are expected until the reviewer moves the base. |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- The generated pbl_driver island names chem and vd, which are declared only under `#if (WRF_CHEM == 1)`. Those references in the pasted island are wrapped in the same guard so a non-chemistry build compiles. The call-check slot 184 is skipped when WRF_CHEM is not 1.
- Domain-sized 2D automatics TSKOLD, USTOLD, ZNTOLD, and PSFC are GPU-only work arrays (n2d), not part of the shared refactor. ZOL stays an automatic; K-PBLD-1 does not touch it.
- tracer_pblmix defaults to 1. The diff4d call stays. It is a no-op when num_tracer is below param_first_scalar (plan.md 8.4). If that comparison is false the GPU view stops.
- The island generator's "first executable" line (177) is a USE continuation. The entry is after `if (bl_pbl_physics .eq. 0) return`, which does no array work (d02).

## Log

- Shared refactor: seven 3D automatics of pbl_driver are CONTIGUOUS pointers remapped onto n3d work arrays after the bl_pbl_physics==0 return. No arithmetic change. Not compiled or tested (code-only).
- K-PBLD-1: one collapse(2) kernel over the tile, k loops sequential, statements copied. Host logicals replace PRESENT. Tile bounds are copied to i_start_h before the island. kernel_lint PASS. arith_guard GPU view clean with one hoisted-bound exception; CPU-view diffs are the shared refactor. Not compiled or tested (code-only).
