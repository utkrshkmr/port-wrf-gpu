# P3-SFCDRV status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: coded
- Branch: agent/wp/p3_sfcdrv
- Last commit: (port of surface_driver, this commit)

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-SD-1..8 | coded | this commit | Ten Template A kernels: zero u/v and QGH/CHS/CPM/CHS2; RAINBL accumulation; PSFC and u/v copies; ch=chs; uratx/vratx/tratx; vdfg=0; RA=WSPD/UST**2; SFCEVP/SFCEXC/ACHFX/ACLHF/ACGRDFLX; RAINBL reset; Q2 cap. Island pasted. kernel_lint PASS (10 kernels, 0 errors). |
| task 1: shared refactor (separate commit): surface_driver's large 3D automatic... | coded | 301d32a4e9024d36459d6f20001dfe822dc24574 | u_phytmp and v_phytmp are the only (ims:ime, kms:kme, jms:jme) automatics in surface_driver. They are CONTIGUOUS pointers onto work_p3_sfcdrv_* of length n3d, remapped after the sf_sfclay_physics==0 return. 2D automatics and the allocatable smois_tmp/tslb_tmp are unchanged. arith_guard CPU-view diffs are expected until the reviewer moves the base. |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- q_ref2m is a 3D automatic sized (ims:ime, 1:maxpatch, jms:jme) for CLM, not a full-column (kms:kme) array. maxpatch is not an I-3 allocation size, and the case is Noah (sf_surface_physics=2), not CLM. It stays an automatic array.
- The island generator says the first executable is q_ref2m = 0 and to exit at the sf_sfclay_physics==0 return. That assignment and the SSiB check do not touch moved arrays. The entry is after that return, after the work-array remaps and the tile-bound copy, so the return needs no exit. Same practical placement as P3-PBL.
- QGH, CHS, CQS, CPM, CHS2, CQS2, and IRRIGATION_CHANNEL are GPU-only n2d work pointers. The CPU view keeps the automatic arrays. They are not part of the shared refactor. SFCLAYREV, lsm, seaice_noah, and SFCDIAGS receive them.
- e_bio references in the pasted island are wrapped in `#if (WRF_CHEM == 1)`. CN dummies (including me and wf) are wrapped in `#ifdef CN`. EM_CORE-only dummies such as lakemask, ch, vdfg, fgdp, and dfgdp are left as the generator wrote them; the GPU build is EM_CORE==1.
- On the GPU path, rainshv, ACHFX, ACLHF, ACGRDFLX, ch, vdfg, and qv_curr must be present. The Eaton call passes them. If one is absent the GPU view stops, because present() cannot name an absent optional. The CPU view still uses IF (PRESENT(...)).
- Scheme calls still pass i_start(ij). The kernels use copies taken before the island. Changing the calls would change the CPU view.

## Log

- Shared refactor: u_phytmp and v_phytmp of surface_driver are CONTIGUOUS pointers remapped onto n3d work arrays after the sf_sfclay_physics==0 return. No arithmetic change. Not compiled or tested (code-only).
- K-SD-1..8: ten collapse(2) kernels, k loops sequential, statements copied. UST**2 is unchanged. Unported options call wrf_error_fatal before the entry island. kernel_lint PASS. arith_guard GPU view has no new skeletons; CPU-view diffs are the shared refactor only. Not compiled or tested (code-only).
