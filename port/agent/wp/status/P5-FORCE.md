# P5-FORCE status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p5_force
- Last commit:

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| task 1: med_force_domain: the eight steps of plan.md P5.2 when gpu_on(R_COUPLE... | coded | | device path only when gpu_on(R_COUPLE_OR_UNCOUPLE_EM); route off leaves movement to S6 |
| task 2: tools/gen_gpu.c: add the new generated lists (gpu_upd_host_force_slab.... | todo | | |
| task 3: P5.3 step 1: an exclusion list in tools/gen_gpu.c for fields only host... | todo | | |
| task 4: debug self-tests inside mediation_force_domain.F: WRF_GPU_SLAB_POISON=... | todo | | |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

## Log

- Task 1: med_force_domain calls the existing couple and uncouple (device when the route is on, P5-CPL) and the existing host interp. Around them, under WRF_GPU and gpu_on(R_COUPLE_OR_UNCOUPLE_EM): parent INTERP_DOWN j-slab (js, je from the pack-loop rows), nest FORCE_DOWN strip pack (K-NEST-STRIP-PACK into a buffer, gpu_map D2H, host unpack), then gpu_upd_dev_bdy(nest) and gpu_upd_dev_force_full(nest). Wrappers and pack routines are file-level after the subroutine. Includes are produced by task 2. Integer index arithmetic is in arith_exceptions.d/P5-FORCE.txt. Not compiled or tested (code-only).
