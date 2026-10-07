# P3-RADDRV status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p3_raddrv
- Last commit: solar_eclipse routine seq (this commit). radiation_driver 19267e0f8bc371a90489442fb1bd336a23c03921. Hoist 973358a4d4e2e3e90f0209365a6f614c9700db0e. Task 1 01f918788f7056be4037148e7e33e90c962462eb.

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-RAD-ACC | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Template A inside the RRTMG LW accumulation select. |
| K-RAD-CLDT | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Template C, k loop seq downward. CPU loop kept under #else. |
| K-RAD-ECL | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Template A. One thread calls solar_eclipse. routine seq is the solar_eclipse commit. |
| K-RAD-COSZ | todo | |  |
| K-RAD-CF0 | todo | | Zero nest is in the radiation_driver commit. cal_cldfra1 (K-RAD-CF1) still open. |
| K-RAD-Z | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Two template A nests: 2D fluxes/GLAT/GLON, then 3D heating and CEMISS. |
| K-OZT | todo | |  |
| K-OZP | todo | |  |
| K-RAD-LWPOST | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Template A. PRESENT(OLR) hoisted to the host. |
| K-RAD-SWPOST | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Template A: SW heating, SWDOWN, direct/diffuse split, diffuse_frac. |
| solar_eclipse | coded | this commit | !$acc routine seq. Device body is the sw_eclipse == 0 zero. CPU body kept under #else. |
| task 1: shared refactor (separate commit): radiation_driver's automatic arrays... | coded | 01f918788f7056be4037148e7e33e90c962462eb | REAL arrays via gpu_work_alloc_r. INTEGER cldfra1_flag and mask_loc allocated in the include (no gpu_work_alloc_i). ozmixt sized n2d*59, aerodt n2d*72. arith_guard CPU-view diffs expected. |
| task 2: shared refactor (separate commit), the hoist of row 8.5:hoist (plan.md... | coded | 973358a4d4e2e3e90f0209365a6f614c9700db0e | Removed the per-call RRTMG_LWINIT in the RRTMG_LWSCHEME case, and dropped rrtmg_lwinit from the USE list. module_physics_init still calls it once. arith_guard CPU-view diffs expected. |

## Scope requests

- P1-WORK: add `gpu_work_alloc_i` / `gpu_work_check_i` (INTEGER, same contract as the REAL pair) so `work_p3_raddrv_cldfra1_flag` and `work_p3_raddrv_mask_loc` are allocated and device-mapped inside `module_gpu_work` instead of the inline ALLOCATE / enter data in `WRF/inc/gpu_work_p3_raddrv.inc`. Until then this include allocates them, zero-fills, and under WRF_GPU does `enter data copyin`. They are not in T-WORK (`gpu_work_check_r` is REAL-only).

## Questions and blockers

- ozmixt work length is `n2d*59` and aerodt is `n2d*12*6` (plan.md P1.7 and the RRTMG settings in module_check_a_mundo). A run with levsiz > 59 or alevsiz*no_src_types > 72 would overrun those arrays. The Eaton case is exactly 59 and 12*6.

## Log

- Shared refactor: radiation_driver P1.7 automatics are POINTER, CONTIGUOUS remaps onto work_p3_raddrv_* . coszr, OZFLG, and the 1D column temps stay automatic (not in the P1.7 list).
- Hoist 8.5: the per-call CALL RRTMG_LWINIT in radiation_driver is gone. NLAYERS stays the value set at init.
- radiation_driver: island pasted, case-path kernels under OpenACC, other schemes stop with wrf_error_fatal before the entry island. Also kernels for qc/qi save and restore, qc_temp, and BL clouds (icloud_bl default 1). kernel_lint 20 kernels, 0 errors, W2 on solar_eclipse until the seq commit. arith_guard GPU-view clean; CPU-view diffs are the shared refactors.
- solar_eclipse: !$acc routine seq. Under WRF_GPU the body is the sw_eclipse == 0 zero and return. The file-read path stays in the CPU view. kernel_lint W2 cleared. arith_guard PASS.
