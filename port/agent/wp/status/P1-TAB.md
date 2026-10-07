# P1-TAB status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: coded
- Branch: agent/wp/p1_tab
- Last commit: b399785badddfc4154d371a7cc27ac3a4a28b53a

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| task 1: gpu_update_tables(): calls the upload routine of each table module (INTERFACES.md I-4) | coded | b399785badddfc4154d371a7cc27ac3a4a28b53a | USE and CALL wsm6_gpu_upload, sfclayrev_gpu_upload, noahlsm_gpu_upload, ra_sw_gpu_upload, rrtmg_lw_gpu_upload under WRF_GPU only |
| task 2: gpu_selftest_tab(): calls each module_gpu_tabcheck, sums n and nbad, prints the T-TAB line | coded | (this commit) | one wrf_message line; n is the sum, not a hardcoded 120 |

## Scope requests

- `WRF/main/depend.common`, object `module_gpu_tables.o`: add `module_ra_rrtmg_lw.o` (same spelling `check_deps.py` asks for, and the spelling used by `module_physics_init.o`). Both routines USE `module_ra_rrtmg_lw`, the module that contains `RRTMG_LWRAD` (INTERFACES.md I-4). P1-TAB does not own `depend.common`.
- Do not add `../phys/physics_mmm/mp_wsm6.o` or `../phys/physics_mmm/sf_sfclayrev.o`. Those objects are already dependencies, as `physics_mmm/mp_wsm6.o` and `physics_mmm/sf_sfclayrev.o` (the spelling every other `phys/` object uses, including `module_physics_init.o`). `check_deps.py` asks for the `../phys/physics_mmm/` form because `dep_name` treats `phys/physics_mmm/` as a different directory. That spelling would be a wrong make prerequisite. The checker is locked; this package cannot change it.

## Questions and blockers

- `python3 port/tools/check_deps.py WRF/phys/module_gpu_tables.F` fails three D1 lines. One is the real missing `module_ra_rrtmg_lw.o` (scope request above). The other two are the `physics_mmm` path spelling above: the make lines are already present. `static.sh` runs `check_deps.py`, so the gate stays red until the reviewer fixes `dep_name` for a module that lives in a subdirectory of the same top directory, or teaches it that `physics_mmm/mp_wsm6.o` satisfies a USE of `mp_wsm6` from `phys/`. Not blocking the code: I-4 requires the USE.
- Decision (not blocking): RRTMG routines are `USE module_ra_rrtmg_lw`. `RRTMG_LWRAD` is inside `MODULE module_ra_rrtmg_lw`. The 120 table variables stay in the physics modules; this package only calls the upload and tabcheck names.
- Decision (not blocking): `gpu_selftest_tab` prints `<n>` from the summed tabcheck counts (Phase 1 list plus the RRTMG tables, I-4), passes one `bad` buffer through all five calls, and prints that text from the front (8192 characters) as the first bad names. The line goes out through external `wrf_message` so it lands in `rsl.error.0000`.

## Log

- Task 1 coded: `gpu_update_tables` calls the five I-4 upload routines under `#ifdef WRF_GPU`. CPU view is an empty external subroutine. Not compiled or tested (code-only).
- Task 2 coded: `gpu_selftest_tab` calls the five tabchecks, sums n and nbad, prints `gpu_selftest: T-TAB PASS <n> tables` or `gpu_selftest: T-TAB FAIL <nbad> of <n>: <first bad names>`. Not compiled or tested (code-only).
