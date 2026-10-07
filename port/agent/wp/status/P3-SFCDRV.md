# P3-SFCDRV status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p3_sfcdrv
- Last commit: (shared refactor, hash recorded in the next commit)

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-SD-1..8 | todo | |  |
| task 1: shared refactor (separate commit): surface_driver's large 3D automatic... | coded | this commit | u_phytmp and v_phytmp are the only (ims:ime, kms:kme, jms:jme) automatics in surface_driver. They are CONTIGUOUS pointers onto work_p3_sfcdrv_* of length n3d, remapped after the sf_sfclay_physics==0 return. 2D automatics and the allocatable smois_tmp/tslb_tmp are unchanged. arith_guard CPU-view diffs are expected until the reviewer moves the base. |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- q_ref2m is a 3D automatic sized (ims:ime, 1:maxpatch, jms:jme) for CLM, not a full-column (kms:kme) array. maxpatch is not an I-3 allocation size, and the case is Noah (sf_surface_physics=2), not CLM. It stays an automatic array.

## Log

- Shared refactor: u_phytmp and v_phytmp of surface_driver are CONTIGUOUS pointers remapped onto n3d work arrays after the sf_sfclay_physics==0 return. No arithmetic change. Not compiled or tested (code-only).
