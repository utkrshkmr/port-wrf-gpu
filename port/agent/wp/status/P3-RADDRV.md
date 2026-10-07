# P3-RADDRV status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p3_raddrv
- Last commit: (hoist, this commit; task 1 is 01f918788f7056be4037148e7e33e90c962462eb)

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-RAD-ACC | todo | |  |
| K-RAD-CLDT | todo | |  |
| K-RAD-ECL | todo | |  |
| K-RAD-COSZ | todo | |  |
| K-RAD-CF0 | todo | |  |
| K-RAD-Z | todo | |  |
| K-OZT | todo | |  |
| K-OZP | todo | |  |
| K-RAD-LWPOST | todo | |  |
| K-RAD-SWPOST | todo | |  |
| task 1: shared refactor (separate commit): radiation_driver's automatic arrays... | coded | 01f918788f7056be4037148e7e33e90c962462eb | REAL arrays via gpu_work_alloc_r. INTEGER cldfra1_flag and mask_loc allocated in the include (no gpu_work_alloc_i). ozmixt sized n2d*59, aerodt n2d*72. arith_guard CPU-view diffs expected. |
| task 2: shared refactor (separate commit), the hoist of row 8.5:hoist (plan.md... | coded | this commit | Removed the per-call RRTMG_LWINIT in the RRTMG_LWSCHEME case, and dropped rrtmg_lwinit from the USE list. module_physics_init still calls it once. arith_guard CPU-view diffs expected. |

## Scope requests

- P1-WORK: add `gpu_work_alloc_i` / `gpu_work_check_i` (INTEGER, same contract as the REAL pair) so `work_p3_raddrv_cldfra1_flag` and `work_p3_raddrv_mask_loc` are allocated and device-mapped inside `module_gpu_work` instead of the inline ALLOCATE / enter data in `WRF/inc/gpu_work_p3_raddrv.inc`. Until then this include allocates them, zero-fills, and under WRF_GPU does `enter data copyin`. They are not in T-WORK (`gpu_work_check_r` is REAL-only).

## Questions and blockers

- ozmixt work length is `n2d*59` and aerodt is `n2d*12*6` (plan.md P1.7 and the RRTMG settings in module_check_a_mundo). A run with levsiz > 59 or alevsiz*no_src_types > 72 would overrun those arrays. The Eaton case is exactly 59 and 12*6.

## Log

- Shared refactor: radiation_driver P1.7 automatics are POINTER, CONTIGUOUS remaps onto work_p3_raddrv_* . coszr, OZFLG, and the 1D column temps stay automatic (not in the P1.7 list).
- Hoist 8.5: the per-call CALL RRTMG_LWINIT in radiation_driver is gone. NLAYERS stays the value set at init.
