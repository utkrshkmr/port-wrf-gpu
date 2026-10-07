# P3-NOAH status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p3_noah
- Last commit: e967539

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-LSM | todo | | wrapper plus the SFLX tree |
| K-SEAICE | todo | |  |
| K-SFCDIAG | todo | |  |
| 1 shared refactor: iloc/jloc as arguments | coded | c568dc4 | threadprivate module copies removed; IILOC/JJLOC stay as the arguments |
| 2 shared refactor: LUTYPE/SLTYPE as integer codes | coded | e967539 | SFLX/REDPRM take integer codes; module LUTYPE/SLTYPE stay CHARACTER for table I/O |
| 3 P1.4 tables (49): declare create, noahlsm_gpu_upload, noahlsm_gpu_tabcheck | coded | | bit-sum via IEOR; kernel_lint PASS; GPU arith exceptions recorded |
| 4 port lsm (K-LSM) | todo | |  |
| 5 port SFLX (K-LSM) | todo | |  |
| 6 port REDPRM (K-LSM) | todo | |  |
| 7 port CSNOW (K-LSM) | todo | |  |
| 8 port SNOW_NEW (K-LSM) | todo | |  |
| 9 port SNFRAC (K-LSM) | todo | |  |
| 10 port ALCALC (K-LSM) | todo | |  |
| 11 port TDFCND (K-LSM) | todo | |  |
| 12 port SNOWZ0 (K-LSM) | todo | |  |
| 13 port PENMAN (K-LSM) | todo | |  |
| 14 port CANRES (K-LSM) | todo | |  |
| 15 port NOPAC (K-LSM) | todo | |  |
| 16 port EVAPO (K-LSM) | todo | |  |
| 17 port DEVAP (K-LSM) | todo | |  |
| 18 port TRANSP (K-LSM) | todo | |  |
| 19 port SMFLX (K-LSM) | todo | |  |
| 20 port FAC2MIT (K-LSM) | todo | |  |
| 21 port SRT (K-LSM) | todo | |  |
| 22 port WDFCND (K-LSM) | todo | |  |
| 23 port SSTEP (K-LSM) | todo | |  |
| 24 port ROSR12 (K-LSM) | todo | |  |
| 25 port SHFLX (K-LSM) | todo | |  |
| 26 port HRT (K-LSM) | todo | |  |
| 27 port TBND (K-LSM) | todo | |  |
| 28 port TMPAVG (K-LSM) | todo | |  |
| 29 port SNKSRC (K-LSM) | todo | |  |
| 30 port FRH2O (K-LSM) | todo | |  |
| 31 port HSTEP (K-LSM) | todo | |  |
| 32 port SNOPAC (K-LSM) | todo | |  |
| 33 port SNOWPACK (K-LSM) | todo | |  |
| 34 port SFLX_GLACIAL (K-LSM) | todo | |  |
| 35 port seaice_noah (K-SEAICE) | todo | |  |
| 36 port SFCDIAGS (K-SFCDIAG) | todo | |  |

## Scope requests

(changes you need outside "You own": file, routine, why; do not make them)

## Questions and blockers

- iloc/jloc: the module copies in SFLX, SFLX_GLACIAL and SFLX_SEAICE were assigned and never read. They are removed. IILOC and JJLOC remain the dummy arguments the driver already passes (I, J). No callee signature changed.
- LUTYPE/SLTYPE: the module variables stay CHARACTER(256) because SOIL_VEG_GEN_PARM reads and broadcasts them as strings. SFLX and REDPRM arguments LLANDUSE and LSOIL were CHARACTER and never read; they are now integers from noahlsm_lutype_code / noahlsm_sltype_code. Unknown names map to 0. That cannot change results, because the old arguments were unused. The A4 soil read still cannot tell STAS from STAS-RUC; the soil tables themselves carry that difference.

## Log

- Shared refactor: dropped write-only threadprivate iloc/jloc in module_sf_noahlsm, module_sf_noahlsm_glacial_only and module_sf_noah_seaice. arith_guard CPU-view diffs are expected (CODE_ONLY.md §8). Not compiled.
- Shared refactor: SFLX and REDPRM take integer land-use and soil dataset codes. Host table I/O is unchanged. arith_guard CPU-view diffs are expected. Not compiled.
- P1.4: declare create of the 49 Noah tables, noahlsm_gpu_upload, noahlsm_gpu_tabcheck. Bit-sum is IEOR of TRANSFER patterns, one thread, loop seq. kernel_lint PASS. CPU-view arith_guard hits are the earlier refactors only. Not compiled.
