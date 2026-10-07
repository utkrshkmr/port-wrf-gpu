# P4-LS status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p4_ls
- Last commit: (this commit) Shared refactor: prop_ls_rk3 tend work array

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-PLS-0 | todo | |  |
| K-TLS | todo | |  |
| K-PLS-1..3 | todo | |  |
| K-ROS | todo | |  |
| K-TIGN-1 | todo | |  |
| K-TIGN-G | todo | |  |
| K-FLAME | todo | |  |
| K-RI-0 | todo | |  |
| K-ALR | todo | |  |
| K-RI-F | todo | |  |
| task 1: shared refactor (separate commit): prop_ls_rk3's automatic array tend ... | coded | (this commit) | tend is a contiguous pointer onto work_p4_ls_tend. arith_guard CPU-view change is expected (CODE_ONLY.md §8). |
| task 2: shared refactor (separate commit, PHASE4.md P4.0 item 4): delete the u... | todo | |  |
| task 3: tend_ls: one kernel per point (WENO5/ENO1, plan.md 9.1 K-TLS) calling ... | todo | |  |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- work_p4_ls_tend is sized `n2d*16`. Fire memory extent is `ni*sr_x` by `nj*sr_y` (`get_ijk_from_subgrid`: `ims0=(ims-1)*sr_x+1`, `ime0=ime*sr_x`), and `sr_x=sr_y=4` is fixed (plan.md §2.2). The pointer section length uses `INTEGER(8)` so the product does not overflow default integer on a large fire mesh. `gpu_work_ensure` only sees atmospheric `ni,nj`; `n2d*16` is the fire-sized product of those sizes.

## Log

- Shared refactor: `prop_ls_rk3` automatic `tend(ifms:ifme,jfms:jfme)` replaced by `POINTER, CONTIGUOUS` remapped onto `work_p4_ls_tend`. Both builds. No arithmetic change. Not compiled or tested (code-only).
