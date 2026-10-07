# P4-LS status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p4_ls
- Last commit: (this commit) WP P4-LS: port prop_ls_rk3

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-PLS-0 | coded | (this commit) | Template A, collapse(2), directive on the lfn_0 copy. |
| K-TLS | todo | |  |
| K-PLS-1..3 | coded | (this commit) | Template A, three kernels in source order (dt/3, dt/2, dt). tend is present. |
| K-ROS | todo | |  |
| K-TIGN-1 | todo | |  |
| K-TIGN-G | todo | |  |
| K-FLAME | todo | |  |
| K-RI-0 | todo | |  |
| K-ALR | todo | |  |
| K-RI-F | todo | |  |
| task 1: shared refactor (separate commit): prop_ls_rk3's automatic array tend ... | coded | 272220f | tend is a contiguous pointer onto work_p4_ls_tend. arith_guard CPU-view change is expected (CODE_ONLY.md §8). |
| task 2: shared refactor (separate commit, PHASE4.md P4.0 item 4): delete the u... | coded | 585f4d7 | Deleted unused automatic tend_1, tend_2, tend_3. They were never referenced. |
| task 3: tend_ls: one kernel per point (WENO5/ENO1, plan.md 9.1 K-TLS) calling ... | todo | |  |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- work_p4_ls_tend is sized `n2d*16`. Fire memory extent is `ni*sr_x` by `nj*sr_y` (`get_ijk_from_subgrid`: `ims0=(ims-1)*sr_x+1`, `ime0=ime*sr_x`), and `sr_x=sr_y=4` is fixed (plan.md §2.2). The pointer section length uses `INTEGER(8)` so the product does not overflow default integer on a large fire mesh. `gpu_work_ensure` only sees atmospheric `ni,nj`; `n2d*16` is the fire-sized product of those sizes.

## Log

- Shared refactor: `prop_ls_rk3` automatic `tend(ifms:ifme,jfms:jfme)` replaced by `POINTER, CONTIGUOUS` remapped onto `work_p4_ls_tend`. Both builds. No arithmetic change. Not compiled or tested (code-only).
- Shared refactor: deleted unused `tend_1`, `tend_2`, `tend_3` automatics of `reinit_ls_rk3`. Bit-neutral. Not compiled or tested (code-only).
- Ported `prop_ls_rk3` (K-PLS-0, K-PLS-1..3): Template A directives on the four 2D loops, island of R_PROP_LS_RK3 (whole state of grid, no call check). Halo includes and `tend_ls` calls stay on the host. Not compiled or tested (code-only).
