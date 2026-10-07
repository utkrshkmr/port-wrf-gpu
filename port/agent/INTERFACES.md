# Interfaces between the work packages (code-only parallel run)

Every name, argument list and output line here is **fixed**: other work packages already write code against it.
Never change one. If one is wrong or missing, write it into your status file ("Questions and blockers"), and code
against the interface as written.

## I-1 Routes

`WRF/frame/module_gpu_route.F` declares a constant `R_<ROUTE>` for each of the 101 routes of
[ROUTES.md](ROUTES.md), and `gpu_on(R_<ROUTE>)`. Nobody edits this module.

Every kernel of a route carries `if(target: gpu_on(R_<ROUTE>))`. The cards name the route of each routine (extra
routines share the route of their kernel row, e.g. `horizontal_diffusion_v_2` → `R_HORIZONTAL_DIFFUSION_2`).

## I-2 Islands and the call check

Every routine with kernels gets the island generated for it: `port/agent/wp/islands/<ID>/<routine>.txt` (entry
block, exit block, call check; CODING_STANDARD.md §3 rules 1-9).

Inside the routine:

```fortran
USE module_gpu_route, ONLY : gpu_on, gpu_island, gpu_world_host, R_<ROUTE>
USE module_gpu_callcheck
```

`WRF/frame/module_gpu_callcheck.F` is finished; nobody edits it. A routine with a `TYPE(domain)` dummy gets no call
check (the island file says so).

## I-3 Work arrays (`WRF/frame/module_gpu_work.F`, P1-WORK)

- Your arrays go into your own include file `WRF/inc/gpu_work_<id>.inc`. It has three sections, selected by
  `GPU_WORK_SECTION`; the file's comments show an example:
  1. declarations: `REAL, ALLOCATABLE, TARGET, PUBLIC :: work_<id>_<name>(:)`;
  2. allocation: `CALL gpu_work_alloc_r(work_<id>_<name>, <size>, "work_<id>_<name>")`;
  3. self test: `CALL gpu_work_check_r(work_<id>_<name>, "work_<id>_<name>", nwork, nbad)`.
- Sizes available in section 2 (memory sizes of the largest domain so far): `ni`, `nj`, `nk`, `n2d = ni*nj`,
  `n3d = ni*nj*nk`, `n3dp = ni*nj*(nk+1)`, all `INTEGER(KIND=8)` except `ni`, `nj`, `nk`. For another shape, write
  the product of these.
- GPU-only arrays (a new temporary of a GPU kernel) go under `#ifdef WRF_GPU` in all three sections. Arrays of a
  shared refactor (an automatic array of the CPU code) exist in both builds.
- In the routine, remap a pointer with the bounds the automatic array had, then pass it to kernels like any array:

  ```fortran
  USE module_gpu_work, ONLY : work_p2_e1_fqx
  REAL, DIMENSION(:,:,:), POINTER, CONTIGUOUS :: fqx
  fqx(ims:ime,kms:kme,jms:jme) => work_p2_e1_fqx(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
  ```

  For a shared refactor, the pointer declaration and the remap replace the automatic declaration in both builds.
  For a GPU-only array, they go under `#ifdef WRF_GPU`.
- **P1-WORK provides:**
  - `gpu_work_ensure(ims,ime,jms,jme,kms,kme)`: (re)allocates every array when this domain is larger than every
    domain before;
  - `gpu_work_alloc_r(a, n, name)`: allocates, zero-fills on the host, and under `WRF_GPU` maps with
    `enter data map(alloc:)` and zero-fills on the device;
  - `gpu_work_check_r(a, name, nwork, nbad)`;
  - `gpu_selftest_work()`.
- **P1-SYNC calls** `CALL gpu_work_ensure(ims, ime, jms, jme, kms, kme)` in `solve_em`, right after
  `CALL gpu_bracket_begin(grid)`. So the arrays exist before any routine of the step runs.

## I-4 Module tables (P1.4)

Each physics module that owns P1.4 tables provides, under `#ifdef WRF_GPU`:

- `!$omp declare target(<its table variables>)` next to their declarations;
- two PUBLIC routines in the module:

```fortran
SUBROUTINE <m>_gpu_upload()                    ! !$omp target update to(<its table variables>)
SUBROUTINE <m>_gpu_tabcheck(n, nbad, bad)      ! for each variable: an integer bit-sum on the host and in a
   INTEGER, INTENT(OUT) :: n, nbad             !   kernel on the device; n = variables checked, nbad = differing;
   CHARACTER(LEN=*), INTENT(INOUT) :: bad      !   appends the names that differ, blank-separated
```

| `<m>` | Module (file) | Work package | Variables (PHASE1.md P1.4) |
|---|---|---|---|
| `wsm6` | `mp_wsm6` (`phys/physics_mmm/mp_wsm6.F90`) | P3-WSM6 | the 64 SAVE scalars of lines 46-63 and `pidn0s`, `pidnc` (66) |
| `sfclayrev` | `sf_sfclayrev` (`phys/physics_mmm/sf_sfclayrev.F90`) | P3-SFCLAY | `psim_stab`, `psim_unstab`, `psih_stab`, `psih_unstab` (4) |
| `noahlsm` | `module_sf_noahlsm` (`phys/module_sf_noahlsm.F`) | P3-NOAH | the 49 listed in PHASE1.md P1.4 |
| `ra_sw` | `module_ra_sw` (`phys/module_ra_sw.F`) | P3-SW | `CSSCA` (1) |
| `rrtmg_lw` | the module of `RRTMG_LWRAD` (`phys/module_ra_rrtmg_lw.F`) | P3-RRTMG | every RRTMG LW table the kernel reads (after the flattening; plan.md 8.5) |

**P1-TAB** (`WRF/phys/module_gpu_tables.F`) provides two external subroutines:

- `gpu_update_tables()`: USEs the five modules and calls the five upload routines;
- `gpu_selftest_tab()`: calls the five tabcheck routines and prints `gpu_selftest: T-TAB PASS <n> tables` (120 of
  PHASE1.md P1.4 plus the RRTMG tables) or `gpu_selftest: T-TAB FAIL <nbad> of <n>: <names>`.

## I-5 Self tests (`WRF_GPU_SELFTEST=1`)

| Routine | Where | Work package | Called by |
|---|---|---|---|
| `gpu_selftests(grid)` (external) | `WRF/phys/module_gpu_selftest.F` | P1-ST | P1-SYNC, after the uploads of S1 and S2 |
| `gpu_selftest_map(grid)` (external) | same | P1-ST | `gpu_selftests` |
| `gpu_selftest_tab()` (external) | `WRF/phys/module_gpu_tables.F` | P1-TAB | `gpu_selftests` |
| `gpu_selftest_work()` | `module_gpu_work` | P1-WORK | `gpu_selftests` (`USE module_gpu_work`) |
| `gpu_selftest_pool()` | `module_gpu_scratch` | P1-POOL | P1-SYNC in `solve_em`, once, after `#include "i1_assoc.inc"`, when `WRF_GPU_SELFTEST=1` |

Every test prints exactly one line: `gpu_selftest: <T-NAME> PASS <details>` or `gpu_selftest: <T-NAME> FAIL
<details>` (port/gates/t_selftest.sh).

## I-6 Startup gate (P1.8)

`gpu_check_config(id)`, external, in `WRF/share/module_gpu_check.F` (P1-CHECK). The output contract is in PHASE1.md
P1.8. P1-SYNC calls it:

- in `WRF/main/module_wrf_top.F` after the namelist is read (for domain 1 and every domain of the namelist);
- in `alloc_and_configure_domain` (`WRF/frame/module_domain.F`) for each nest: `CALL gpu_check_config(domain_id)`,
  without USE.

## I-7 Profiling and logs (P1.10-P1.12; `WRF/frame/module_gpu_prof.F`, P1-PROF)

- `wrf_nvtx_push(name)`, `wrf_nvtx_pop()`: used by `BENCH_START`/`BENCH_END` in `WRF/inc/bench_solve_em_def.h`
  under `WRF_GPU` (P1-PROF edits that header). For that, P1-SYNC adds `USE module_gpu_prof` to `solve_em`.
- `gpu_mem_log(where)`: P1-SYNC calls it at startup (`'startup'`), after each domain's init (`'init d0N'`), after the
  first step of each domain (`'first step d0N'`), and once per simulated hour (`'hour H'`).
- `gpu_timing_step(id, hour, done)`: P1-SYNC calls it at the end of every `solve_em` call, with `grid%id` and the
  simulated hour of the step. `done = .TRUE.` at the last step.
- C side (`wrf_gpu_shim.c`): `wrf_nvtx_push_c`, `wrf_nvtx_pop_c`, `wrf_gpu_mem_info_c`. `dlopen` needs no `-ldl`
  with glibc ≥ 2.34 (the NVHPC container has 2.35): do not edit `arch/configure.defaults`.

## I-8 State updates and the bracket (P1-SYNC)

`WRF/frame/module_gpu_updates.F` provides:

- existing: `gpu_upd_dev_all(grid)`, `gpu_upd_host_all(grid)`, `gpu_upd_dev_bdy(grid)`,
  `gpu_upd_host_stream(grid, stream)`;
- P1-SYNC adds: `gpu_bracket_begin(grid)`, `gpu_bracket_end(grid)` (PHASE1.md P1.5 + P1.9).

Only P1-SYNC calls them. Phase 2 and 3 routines never move the whole state: each one moves only its own arguments,
in its island.

## I-9 Fixed column sizes (Phase 3)

`WRF/inc/gpu_col.h`: `WRF_KMAX`, `WRF_NLAYMAX`, `WRF_NSOILMAX` and the declaration macros `GPU_I`, `GPU_K`, `GPU_K1`,
`GPU_IK`, `GPU_IK1`, `GPU_IKN(n)`, `GPU_L`, `GPU_L1`, `GPU_S`. Include it under `#ifdef WRF_GPU` and write each
fixed-size declaration twice (CODING_STANDARD.md §5.7). Nobody edits it.

## I-10 Names

To avoid collisions between parallel work packages:

- work arrays: `work_<id>_<name>`, with `<id>` the lowercase work-package ID with `_` (e.g. `work_p2_b1_fqy3`);
- new module procedures you add to a file you own: `<routine>_gpu_<what>` (e.g. `advect_u_gpu_flux5`);
- route constants: only those of I-1.
