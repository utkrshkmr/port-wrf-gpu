!WRF:DRIVER_LAYER:UTIL
!
! module_gpu_work: named work arrays of the GPU port (plan.md P1.7;
! port/agent/INTERFACES.md I-3; work package P1-WORK).
!
! A work array replaces a large automatic array of a routine (a shared
! refactor: both builds) or holds a new temporary of a GPU kernel (GPU view
! only).  It is a 1D REAL, ALLOCATABLE, TARGET module array, allocated once
! for the largest domain so far, zero-filled when allocated, and under WRF_GPU
! mapped to the device (enter data map(alloc:) + a device zero fill).  The
! routine remaps a pointer with the bounds the automatic array had:
!
!    USE module_gpu_work, ONLY : work_p2_e1_fqx
!    REAL, DIMENSION(:,:,:), POINTER, CONTIGUOUS :: fqx
!    fqx(ims:ime,kms:kme,jms:jme) => work_p2_e1_fqx(1:(ime-ims+1)*(kme-kms+1)*(jme-jms+1))
!
! Every work package declares its arrays in its own include file
! WRF/inc/gpu_work_<wp>.inc (sections 1-3, see that file); this module
! includes all of them through the generated WRF/inc/gpu_work_all.inc, so no
! two work packages edit the same file.  Rebuild with --clean after changing
! an include file (make does not track them).
!
! Interface (fixed; other work packages rely on it):
!   gpu_work_ensure(ims,ime,jms,jme,kms,kme)  called by solve_em (P1-SYNC) at
!       every call, right after gpu_bracket_begin: (re)allocates every work
!       array when this domain is larger than every domain before
!   gpu_work_alloc_r(a, n, name)    used in section 2 of the include files
!   gpu_work_check_r(a, name, nwork, nbad)  used in section 3
!   gpu_selftest_work()             T-WORK (called by gpu_selftests, P1-ST)
!
MODULE module_gpu_work

   IMPLICIT NONE
   PRIVATE

   PUBLIC :: gpu_work_ensure, gpu_work_alloc_r, gpu_work_check_r, gpu_selftest_work

   ! memory sizes of the largest domain so far
   INTEGER, SAVE, PUBLIC :: work_ni = 0, work_nj = 0, work_nk = 0

#define GPU_WORK_SECTION 1
#include "gpu_work_all.inc"
#undef GPU_WORK_SECTION

CONTAINS

   SUBROUTINE gpu_work_ensure(ims, ime, jms, jme, kms, kme)
      INTEGER, INTENT(IN) :: ims, ime, jms, jme, kms, kme
      INTEGER :: ni, nj, nk
      INTEGER(KIND=8) :: n2d, n3d, n3dp
      ni = ime - ims + 1
      nj = jme - jms + 1
      nk = kme - kms + 1
      ! TODO(P1-WORK): return at once unless ni > work_ni or nj > work_nj or
      ! nk > work_nk; then set work_ni/nj/nk to the maxima, recompute the sizes
      ! from them and (re)allocate every work array (section 2 below).
      n2d = INT(ni, 8)*INT(nj, 8)
      n3d = n2d*INT(nk, 8)
      n3dp = n2d*INT(nk + 1, 8)
#define GPU_WORK_SECTION 2
#include "gpu_work_all.inc"
#undef GPU_WORK_SECTION
   END SUBROUTINE gpu_work_ensure

   ! Allocate a (if smaller than n), zero-fill it; under WRF_GPU map it and
   ! zero-fill the device copy.
   SUBROUTINE gpu_work_alloc_r(a, n, name)
      REAL, ALLOCATABLE, TARGET, INTENT(INOUT) :: a(:)
      INTEGER(KIND=8), INTENT(IN) :: n
      CHARACTER(LEN=*), INTENT(IN) :: name
      ! TODO(P1-WORK)
   END SUBROUTINE gpu_work_alloc_r

   ! T-WORK: count the array and, under WRF_GPU, add 1 to nbad if it is
   ! allocated but not present on the device (print its name).
   SUBROUTINE gpu_work_check_r(a, name, nwork, nbad)
      REAL, ALLOCATABLE, TARGET, INTENT(IN) :: a(:)
      CHARACTER(LEN=*), INTENT(IN) :: name
      INTEGER, INTENT(INOUT) :: nwork, nbad
      ! TODO(P1-WORK)
   END SUBROUTINE gpu_work_check_r

   ! Prints "gpu_selftest: T-WORK PASS <n> work arrays" or
   ! "gpu_selftest: T-WORK FAIL <k> of <n> work arrays not present"
   SUBROUTINE gpu_selftest_work()
      INTEGER :: nwork, nbad
      nwork = 0
      nbad = 0
#define GPU_WORK_SECTION 3
#include "gpu_work_all.inc"
#undef GPU_WORK_SECTION
      ! TODO(P1-WORK): print the T-WORK line with wrf_message
   END SUBROUTINE gpu_selftest_work

END MODULE module_gpu_work
