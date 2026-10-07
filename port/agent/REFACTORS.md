# Shared refactors and moves of the CPU-view base

A shared refactor changes the CPU view (the code CPU-REF compiles), so it can only be made with bitwise evidence and
then becomes the new CPU-view base (`port/agent/cpu_view_base`). Protocol: [WORKFLOW.md](WORKFLOW.md) §6.
`port/tools/workbook.py check` requires the current base to appear in this table.

| Base (sha) | Refactor commit | What | Evidence (PASS lines) | Date |
|---|---|---|---|---|
| `b1273fbabc18` | (Phase 0) | rp_* rewrite, i1 pool (`-DWRF_POOL`), zolri defined result, YSU BEP guard, SNUPGRD PARAMETER, sections for pooled arguments | port/RESULTS.md: T-SHARED-1, T-SHARED-POOL, T-UNINIT identical (local, gfortran) | 2026-09-29 |
| `37b1f7f9d1e6` | `37b1f7f9d1e6` | P1-B4: repro_math PARAMETER tables (tt, two_over_pi, pio2, npio2_hw, atanhi, atanlo, at) moved, text unchanged, into the one routine that reads each (gfortran -fopenacc rejects module PARAMETER arrays in routine seq procedures) | old vs new module, gfortran CPU view: rp_sin/cos/tan/asin/acos/atan/atan2 on every 7th REAL(4) bit pattern (613M) and 200M REAL(8) patterns, 0 mismatches. t_cpu_view.sh W-T0 W-20 W-100 and t_drift.sh still to run on the GPU machine (compile-time constants only) | 2026-10-07 |
