# P3-RRTMG status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p3_rrtmg
- Last commit: 5dbc95f

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| 8.5:hoist | n/a | | P3-RADDRV owns the radiation_driver call-site change that removes the per-call RRTMG_LWINIT. Not ported here. |
| K-RRTMG- | todo | | |
| task 1: flatten EQUIVALENCEd rrlw_kg* tables into 1D arrays | coded | 5dbc95f | ka/absa and kb/absb pairs in rrlw_kg01..16 are ka_s and kb_s. Same column-major order. arith_guard: 336 CPU-view diffs, 0 GPU-view new skeletons (expected; base not moved). |
| task 2: RRTMG LW tables on the device (I-4) | coded | | 285 variables. !$acc declare create, rrtmg_lw_gpu_upload, rrtmg_lw_gpu_tabcheck. INTEGER(8) sum of unsigned 32-bit lanes. kernel_lint pass. GPU-view lane and bound statements are in arith_exceptions.d/P3-RRTMG.txt. The 336 CPU-view diffs are still the flatten. |
| task 3: port RRTMG_LWRAD (K-RRTMG-, K-RRTMG-*) | todo | | batched column kernel of plan.md 8.5 |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- plan.md 8.5 names retab and nlayers as module data of rrtmg_lw_rad. In this source both live in module_ra_rrtmg_lw (retab DATA, nlayers SAVE, written by rrtmg_lwinit). Those are the ones declared and uploaded. The unused nlayers SAVE in module rrtmg_lw_init is not uploaded.
- Tabcheck covers every non-parameter numeric module variable the tables modules hold, including original kao/kbo and *o arrays that cmbgb uses only on the host. rrlw_vsn character strings and PARAMETER values (parrrtm, deltap, ntbl) are not uploaded.
- The bit-sum is a sum of unsigned 32-bit lanes into INTEGER(8), reduced with reduction(+:). It is order-independent and does not overflow. The kernels are gated by gpu_on(R_RRTMG_LWRAD); when that route is off the loop runs on the host and the compare is trivial.

## Log

- Flattened the EQUIVALENCEd combined absorption tables. Each ka/absa pair is one 1D array ka_s(nka*ng). absa(ind,ig) is ka_s(ind+(ig-1)*nka). ka(jt,jp,ig) and the 4D form use the column-major index of the original array. kb/absb the same, with the lower bound 13 on the pressure index. 16 ka_s, 12 kb_s, 376 reads, 28 writes. Original kao/kbo tables are unchanged. Not compiled or tested (code-only).
- Declared 285 RRTMG LW table variables on the device and added rrtmg_lw_gpu_upload and rrtmg_lw_gpu_tabcheck. Not compiled or tested (code-only).
