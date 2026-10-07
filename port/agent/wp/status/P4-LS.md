# P4-LS status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: coded
- Branch: agent/wp/p4_ls
- Last commit: (this commit) WP P4-LS: port advance_ls_reinit

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-PLS-0 | coded | 14c3810 | Template A, collapse(2), directive on the lfn_0 copy. |
| K-TLS | coded | 9cb0383 | One thread per point. reduction(max:tbound); reciprocal on the host. |
| K-PLS-1..3 | coded | 14c3810 | Template A, three kernels in source order (dt/3, dt/2, dt). tend is present. |
| K-ROS | coded | 4ffbddb | !$acc routine seq. No island and no call check. fp% references unchanged. |
| K-TIGN-1 | coded | c7784bc | Template A on the ignition-time loop. |
| K-TIGN-G | coded | c7784bc | Two integer any-reductions; host repeats the original crash loops if any point is burning in the guard. |
| K-FLAME | coded | b868984 | Template A. rp_pow(..., 0.46) unchanged. |
| K-RI-0 | coded | 56421a4 | Template A. lfn_s0 and lfn_s3 in one loop. |
| K-ALR | coded | (this commit) | One kernel per call; reinit_ls_rk3 calls it three times. Case 4 and the edge ENO1 branch. |
| K-RI-F | coded | 56421a4 | Template A. min(lfn_s3, lfn_in) after the host RK iteration loop. |
| task 1: shared refactor (separate commit): prop_ls_rk3's automatic array tend ... | coded | 272220f | tend is a contiguous pointer onto work_p4_ls_tend. arith_guard CPU-view change is expected (CODE_ONLY.md §8). |
| task 2: shared refactor (separate commit, PHASE4.md P4.0 item 4): delete the u... | coded | 585f4d7 | Deleted unused automatic tend_1, tend_2, tend_3. They were never referenced. |
| task 3: tend_ls: one kernel per point (WENO5/ENO1, plan.md 9.1 K-TLS) calling ... | coded | 9cb0383 | Calls fire_ros. Other upwinding and upwind_split values fatal before the island. |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- work_p4_ls_tend is sized `n2d*16`. Fire memory extent is `ni*sr_x` by `nj*sr_y` (`get_ijk_from_subgrid`: `ims0=(ims-1)*sr_x+1`, `ime0=ime*sr_x`), and `sr_x=sr_y=4` is fixed (plan.md §2.2). The pointer section length uses `INTEGER(8)` so the product does not overflow default integer on a large fire mesh. `gpu_work_ensure` only sees atmospheric `ni,nj`; `n2d*16` is the fire-sized product of those sizes.
- `select_eno`, `select_4th` and `select_weno5` are outside P4-LS, so they were not given `!$acc routine seq`. The tend_ls and advance_ls_reinit kernels call verbatim copies `tend_ls_gpu_eno`, `tend_ls_gpu_4th` and `tend_ls_gpu_weno5` (`#ifdef WRF_GPU`, inserted immediately after `end subroutine tend_ls`).
- `fire_ros` contains an unused internal function `nrm2`. It is compiled only when `WRF_GPU` is undefined, so the device routine has no internal procedure. The CPU view is unchanged.
- K-TIGN-G host rescan runs after `!$acc update self(lfn_out)` when the world is on the device, so the original crash message sees the current level set. `lfn_out` is intent(in) and is not in the generated exit copy.

## Log

- Shared refactor: `prop_ls_rk3` automatic `tend(ifms:ifme,jfms:jfme)` replaced by `POINTER, CONTIGUOUS` remapped onto `work_p4_ls_tend`. Both builds. No arithmetic change. Not compiled or tested (code-only).
- Shared refactor: deleted unused `tend_1`, `tend_2`, `tend_3` automatics of `reinit_ls_rk3`. Bit-neutral. Not compiled or tested (code-only).
- Ported `prop_ls_rk3` (K-PLS-0, K-PLS-1..3): Template A directives on the four 2D loops, island of R_PROP_LS_RK3 (whole state of grid, no call check). Halo includes and `tend_ls` calls stay on the host. Not compiled or tested (code-only).
- Ported `tend_ls` (K-TLS): one kernel per point for `fire_upwinding=9` and `fire_upwind_split=0`. `reduction(max:tbound)` then `tbound=1/(tbound+tol)` on the host. `! island of R_FIRE_ROS in tend_ls` next to the kernel. Not compiled or tested (code-only).
- Ported `fire_ros` (K-ROS): `!$acc routine seq`, called from `tend_ls`. No island, no call check, signatures and `fp%` references unchanged. The `ros_max` cap is copied verbatim. Not compiled or tested (code-only).
- Ported `tign_update` (K-TIGN-1, K-TIGN-G): Template A on the ignition loop. Guard strips are integer any-reductions; a set flag reruns the original host loops, which crash with the original message. Not compiled or tested (code-only).
- Ported `calc_flame_length` (K-FLAME): Template A on the 2D loop. `rp_pow` call unchanged. Not compiled or tested (code-only).
- Ported `reinit_ls_rk3` (K-RI-0, K-RI-F): Template A on the opening and closing loops. The iteration loop stays on the host and calls `advance_ls_reinit` and `continue_at_boundary`. Not compiled or tested (code-only).
- Ported `advance_ls_reinit` (K-ALR, K-ALR x3): one kernel, run on each of the three host calls. Edge points use ENO1; the interior uses reinit scheme 4 (WENO5 inside the band, ENO1 outside). Other schemes fatal before the island. Not compiled or tested (code-only).
