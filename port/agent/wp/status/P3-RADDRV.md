# P3-RADDRV status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: coded
- Branch: agent/wp/p3_raddrv
- Last commit: ozn_p_int (this commit). ozn_time_int c383c60313b0a9784752636e81973ed8d01e68ce.

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-RAD-ACC | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Template A inside the RRTMG LW accumulation select. |
| K-RAD-CLDT | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Template C, k loop seq downward. CPU loop kept under #else. |
| K-RAD-ECL | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Template A. One thread calls solar_eclipse. routine seq is the solar_eclipse commit. |
| K-RAD-COSZ | coded | c05f4f71be2c081c9a56a65a9a6e10f431b9bf31 | Template A, collapse(2). Island pasted. Host scalars da, eot, xt24 stay outside the kernel. |
| K-RAD-CF0 | coded | b4b41a1ea96135a37f91e75506fe9179cf04254d | K-RAD-CF0 zero nest is in radiation_driver 19267e0f8bc371a90489442fb1bd336a23c03921. K-RAD-CF1 is cal_cldfra1, template A collapse(3). |
| K-RAD-Z | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Two template A nests: 2D fluxes/GLAT/GLON, then 3D heating and CEMISS. |
| K-OZT | coded | c383c60313b0a9784752636e81973ed8d01e68ce | Template A collapse(3). Month search and factors stay on the host. Island pasted. |
| K-OZP | coded | this commit | One thread per j, i sequential, as ozn_p_int_gpu. pmid and kupper are work arrays. Host ierr check replaces wrf_error_fatal in the kernel. |
| K-RAD-LWPOST | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Template A. PRESENT(OLR) hoisted to the host. |
| K-RAD-SWPOST | coded | 19267e0f8bc371a90489442fb1bd336a23c03921 | Template A: SW heating, SWDOWN, direct/diffuse split, diffuse_frac. |
| solar_eclipse | coded | 78dcf646decaa5bb5a0f4284df635a7aceab7eba | !$acc routine seq. Device body is the sw_eclipse == 0 zero. CPU body kept under #else. |
| task 1: shared refactor (separate commit): radiation_driver's automatic arrays... | coded | 01f918788f7056be4037148e7e33e90c962462eb | REAL arrays via gpu_work_alloc_r. INTEGER cldfra1_flag and mask_loc allocated in the include (no gpu_work_alloc_i). ozmixt sized n2d*59, aerodt n2d*72. arith_guard CPU-view diffs expected. |
| task 2: shared refactor (separate commit), the hoist of row 8.5:hoist (plan.md... | coded | 973358a4d4e2e3e90f0209365a6f614c9700db0e | Removed the per-call RRTMG_LWINIT in the RRTMG_LWSCHEME case, and dropped rrtmg_lwinit from the USE list. module_physics_init still calls it once. arith_guard CPU-view diffs expected. |

## Scope requests

- P1-WORK: add `gpu_work_alloc_i` / `gpu_work_check_i` (INTEGER, same contract as the REAL pair) so `work_p3_raddrv_cldfra1_flag`, `work_p3_raddrv_mask_loc`, and `work_p3_raddrv_kupper` are allocated and device-mapped inside `module_gpu_work` instead of the inline ALLOCATE / enter data in `WRF/inc/gpu_work_p3_raddrv.inc`. Until then this include allocates them, zero-fills, and under WRF_GPU does `enter data copyin`. They are not in T-WORK (`gpu_work_check_r` is REAL-only). `work_p3_raddrv_pmid` uses `gpu_work_alloc_r`.

## Questions and blockers

- ozmixt work length is `n2d*59` and aerodt is `n2d*12*6` (plan.md P1.7 and the RRTMG settings in module_check_a_mundo). A run with levsiz > 59 or alevsiz*no_src_types > 72 would overrun those arrays. The Eaton case is exactly 59 and 12*6.

## Log

- Shared refactor: radiation_driver P1.7 automatics are POINTER, CONTIGUOUS remaps onto work_p3_raddrv_* . coszr, OZFLG, and the 1D column temps stay automatic (not in the P1.7 list).
- Hoist 8.5: the per-call CALL RRTMG_LWINIT in radiation_driver is gone. NLAYERS stays the value set at init.
- radiation_driver: island pasted, case-path kernels under OpenACC, other schemes stop with wrf_error_fatal before the entry island. Also kernels for qc/qi save and restore, qc_temp, and BL clouds (icloud_bl default 1). kernel_lint 20 kernels, 0 errors, W2 on solar_eclipse until the seq commit. arith_guard GPU-view clean; CPU-view diffs are the shared refactors.
- solar_eclipse: !$acc routine seq. Under WRF_GPU the body is the sw_eclipse == 0 zero and return. The file-read path stays in the CPU view. kernel_lint W2 cleared. arith_guard PASS.
- calc_coszen: K-RAD-COSZ template A. Island and call check pasted. kernel_lint 21 kernels, 0 errors. arith_guard GPU-view clean.
- cal_cldfra1: K-RAD-CF1 template A collapse(3) on the WSM6 path (F_QI, F_QC, F_QS present and true). Absent flags and FER_MP_HIRES stop before the island. CPU loop kept under #else. Island pasted. kernel_lint 22 kernels, 0 errors. arith_guard GPU-view clean.
- ozn_time_int: K-OZT template A collapse(3). Island pasted. kernel_lint 23 kernels, 0 errors. arith_guard GPU-view clean.
- ozn_p_int: K-OZP one thread per j row, matching port/tests/ozn/t_ozn.F90. Work arrays work_p3_raddrv_pmid and work_p3_raddrv_kupper. goto 35 is a done flag and EXIT. The fatal is an ierr checked on the host. CPU body kept under #else. kernel_lint 24 kernels, 0 errors. Two GPU-only length products are in arith_exceptions.d/P3-RADDRV.txt.
