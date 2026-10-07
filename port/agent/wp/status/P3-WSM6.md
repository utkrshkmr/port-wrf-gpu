# P3-WSM6 status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p3_wsm6
- Last commit: 413bdd5 shared refactor; tables in this commit

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-WSM6 | todo | |  |
| 8.2:CP-3 | todo | |  |
| 8.2:CP-4 | todo | |  |
| 8.2:rp_ | done | | Phase 0 |
| 8.2:effective-radius | todo | |  |
| 8.2:minor-loop | todo | |  |
| task 1: the P1.4 tables of mp_wsm6 (the SAVE scalars of mp_wsm6.F90:46-64): !$... | coded | this commit | 66 SAVE scalars; wsm6_gpu_upload and wsm6_gpu_tabcheck |
| task 2: shared refactor (separate commit): microphysics_driver's large 3D auto... | coded | 413bdd5 | qv/qc/qi/qs/qni_tmp pointers into work_p3_wsm6_*; arith_guard CPU-view diffs expected |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- The only large 3D locals in microphysics_driver are the allocatable tile arrays
  qv_tmp, qc_tmp, qi_tmp, qs_tmp, qni_tmp (Thompson pert_thom path), not Fortran
  automatic arrays. They are the P1.7 row for this driver. WSM6 does not touch them.
  Each tile is remapped onto a memory-sized work array (n3d). The tile extent is
  at most the memory extent, so the pointer section fits.

## Log

- Shared refactor: replaced ALLOCATE/DEALLOCATE of the five tile temporaries with
  pointer remaps onto work_p3_wsm6_qv_tmp, work_p3_wsm6_qc_tmp, work_p3_wsm6_qi_tmp,
  work_p3_wsm6_qs_tmp, work_p3_wsm6_qni_tmp. Same bounds (its:ite, kts:kte, jts:jte).
  No arithmetic change. CPU-view edits are the P1.7 exception (arith_guard will
  report them; the base is not moved). Not compiled or tested (code-only).
- P1.4: !$acc declare create of the 66 SAVE scalars (qc0 through rslopeg3max,
  plus pidn0s and pidnc). wsm6_gpu_upload does !$acc update device. wsm6_gpu_tabcheck
  compares a host integer bit-sum with the same sum in one kernel (R_WSM6).
  Names that differ are appended blank-separated. kernel_lint and arith_guard
  pass (four T-TAB exceptions). Not compiled or tested (code-only).
