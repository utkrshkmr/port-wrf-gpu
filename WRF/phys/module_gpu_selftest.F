!WRF:MODEL_LAYER:PHYSICS
!
! module_gpu_selftest: the self tests of the GPU infrastructure, run when the
! environment variable WRF_GPU_SELFTEST=1 (port/agent/PHASE1.md P1.2, P1.4, P1.7;
! port/agent/INTERFACES.md I-5; work package P1-ST).  Each test prints one line
!    gpu_selftest: <test> PASS <details>     or     gpu_selftest: <test> FAIL <details>
! which port/gates/t_selftest.sh reads.  In phys/ so that it can USE the table
! modules.
!
! External entry points (called without USE):
!   gpu_selftests(grid)     after the uploads of S1 and S2 (P1-SYNC): when
!                           WRF_GPU_SELFTEST=1 (read once) calls
!                           gpu_selftest_map(grid), gpu_selftest_tab() (P1-TAB)
!                           and gpu_selftest_work() (module_gpu_work, P1-WORK)
!   gpu_selftest_map(grid)  T-MAP: acc_is_present of every in-use field
!                           of grid; "gpu_selftest: T-MAP PASS d0N <n> fields
!                           present" or "... FAIL d0N <k> of <n> fields not
!                           present: <first names>"
! T-POOL (gpu_selftest_pool, module_gpu_scratch, P1-POOL) is called from
! solve_em, where the pool exists.
!
MODULE module_gpu_selftest
   IMPLICIT NONE
END MODULE module_gpu_selftest

SUBROUTINE gpu_selftests(grid)
   USE module_domain, ONLY : domain
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   ! TODO(P1-ST)
END SUBROUTINE gpu_selftests

SUBROUTINE gpu_selftest_map(grid)
   USE module_domain, ONLY : domain
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   ! TODO(P1-ST)
END SUBROUTINE gpu_selftest_map
