# P5-FORCE status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p5_force
- Last commit: d8a3ade3f0809d7dfeaa03e809c0bd0935f23e08

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| task 1: med_force_domain: the eight steps of plan.md P5.2 when gpu_on(R_COUPLE... | coded | d8a3ade3f0809d7dfeaa03e809c0bd0935f23e08 | device path only when gpu_on(R_COUPLE_OR_UNCOUPLE_EM); route off leaves movement to S6 |
| task 2: tools/gen_gpu.c: add the new generated lists (gpu_upd_host_force_slab.... | coded | | gen_gpu_force; existing three lists unchanged |
| task 3: P5.3 step 1: an exclusion list in tools/gen_gpu.c for fields only host... | todo | | |
| task 4: debug self-tests inside mediation_force_domain.F: WRF_GPU_SLAB_POISON=... | todo | | |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- check_generated.py C6 (locked) extracts `grid%(\w+)` from nest_interpdown_pack.inc and only matches `CALL gpu_map_*(grid%name,` with no section. PHASE5.md P5.2 requires the contiguous section `CALL gpu_map_r(grid%x(:,:,js:je), SIZE(grid%x(:,:,js:je),KIND=8), GPU_UPD_FROM)`. Those calls do not match C6, so C6 will report the slab fields missing. The same scan takes `id` from `intermediate_grid%id` and `parent_grid%id`. This package emits the section form and does not add a whole-array duplicate or a fake update of `grid%id`. The three original update lists are unchanged.

## Log

- Task 1: med_force_domain calls the existing couple and uncouple (device when the route is on, P5-CPL) and the existing host interp. Around them, under WRF_GPU and gpu_on(R_COUPLE_OR_UNCOUPLE_EM): parent INTERP_DOWN j-slab (js, je from the pack-loop rows), nest FORCE_DOWN strip pack (K-NEST-STRIP-PACK into a buffer, gpu_map D2H, host unpack), then gpu_upd_dev_bdy(nest) and gpu_upd_dev_force_full(nest). Wrappers and pack routines are file-level after the subroutine. Includes are produced by task 2. Integer index arithmetic is in arith_exceptions.d/P5-FORCE.txt. Not compiled or tested (code-only).
- Task 2: gen_gpu() still writes the three original lists through gen_gpu1/gen_gpu2, then gen_gpu_force writes gpu_upd_host_force_slab.inc (INTERP_DOWN, time level the pack visits, j-slab via gpu_map_call), gpu_pack_force_strips.inc (FORCE_DOWN bdy_interp real ikj/ij/4D packs; other layouts a whole-field D2H), and gpu_upd_dev_force_full.inc (other FORCE_DOWN, whole-field H2D, including o3rad). FOURD flags come from members->next, the same node gen_nest_packunpack uses. Not compiled or tested (code-only).
