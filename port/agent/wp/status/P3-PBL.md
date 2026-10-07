# P3-PBL status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p3_pbl
- Last commit: (shared refactor, hash recorded in the next commit)

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-PBLD-1 | todo | |  |
| K-YSU | todo | |  |
| 8.4:get_pblh | todo | |  |
| task 1: shared refactor (separate commit): pbl_driver's large 3D automatic arr... | coded | this commit | u_phytmp, v_phytmp, TKE_windfarm, rqncblten, rqnwfablten, rqnifablten, rqnbcablten -> work_p3_pbl_* pointers. 2D automatics (TSKOLD, USTOLD, ZNTOLD, ZOL, PSFC) stay automatic until the kernel port. Allocatable a_u/a_v/... and qke_tmp are not automatic and were left. arith_guard CPU-view diffs are expected until the reviewer moves the base. |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- Shared refactor kept only the large 3D automatic arrays named by plan.md P1.7 (the u_phytmp family plus the other (ims:ime,kms:kme,jms:jme) automatics in pbl_driver). Domain-sized 2D automatics used by K-PBLD-1 will become GPU-view work arrays in the kernel commit if the kernel must present them.

## Log

- Shared refactor: seven 3D automatics of pbl_driver are CONTIGUOUS pointers remapped onto n3d work arrays after the bl_pbl_physics==0 return. No arithmetic change. Not compiled or tested (code-only).
