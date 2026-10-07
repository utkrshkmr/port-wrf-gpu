# P1-SYNC status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: todo
- Branch: agent/wp/p1_sync
- Last commit:

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| task 1: gpu_bracket_begin/gpu_bracket_end in module_gpu_updates.F (WRF_GPU_UPD... | todo | | |
| task 2: the bracket calls in solve_em.F (after #include "bench_solve_em_init.h... | todo | | |
| task 3: sync points S1, S2', S2, S3, S4, S5, S6 exactly as the PHASE1.md table... | todo | | |
| task 4: after S1 (and after S2): CALL gpu_update_tables(); then IF WRF_GPU_SEL... | todo | | |
| task 5: solve_em.F: CALL gpu_work_ensure(ims, ime, jms, jme, kms, kme) right a... | todo | | |
| task 6: CALL gpu_check_config(...) in module_wrf_top.F after the namelist is r... | todo | | |
| task 7: the logging calls of P1.11/P1.12 (I-7): CALL gpu_mem_log('<where>') at... | todo | | |
| task 8: shared refactor (separate commit): solve_em's automatic arrays h_tende... | todo | | |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

## Log
