! Work arrays of work package P2-G1 (port/agent/INTERFACES.md I-3).
! Included three times by WRF/frame/module_gpu_work.F with GPU_WORK_SECTION set:
!   1  declarations, in the module specification part
!   2  allocation, inside gpu_work_ensure (ni, nj, nk: memory sizes of the
!      largest domain so far; n2d = ni*nj, n3d = ni*nj*nk, n3dp = ni*nj*(nk+1))
!   3  self test, inside gpu_selftest_work
! GPU-only arrays (new temporaries of a GPU kernel) go under #ifdef WRF_GPU in
! all three sections; arrays of a shared refactor (an automatic array of the
! CPU code replaced by a pointer) exist in both builds.  Example:
!
! #if GPU_WORK_SECTION == 1
! #ifdef WRF_GPU
!    REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g1_fqy3(:)
! #endif
! #elif GPU_WORK_SECTION == 2
! #ifdef WRF_GPU
!    CALL gpu_work_alloc_r(work_p2_g1_fqy3, n3d, "work_p2_g1_fqy3")
! #endif
! #elif GPU_WORK_SECTION == 3
! #ifdef WRF_GPU
!    CALL gpu_work_check_r(work_p2_g1_fqy3, "work_p2_g1_fqy3", nwork, nbad)
! #endif
! #endif
!
! Names start with work_p2_g1_ so that no two work packages collide.
! No apostrophes in comments here: cpp reads this file, the WRF sed step does not.

#if GPU_WORK_SECTION == 1
#ifdef WRF_GPU
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g1_mm(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g1_zzavg(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g1_zeta_zd12(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g1_tmp1(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g1_hat(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g1_hatavg(:)
#endif
#elif GPU_WORK_SECTION == 2
#ifdef WRF_GPU
   CALL gpu_work_alloc_r(work_p2_g1_mm, n2d, "work_p2_g1_mm")
   CALL gpu_work_alloc_r(work_p2_g1_zzavg, n2d, "work_p2_g1_zzavg")
   CALL gpu_work_alloc_r(work_p2_g1_zeta_zd12, n2d, "work_p2_g1_zeta_zd12")
   CALL gpu_work_alloc_r(work_p2_g1_tmp1, INT(ni+4,8)*INT(nk,8)*INT(nj+4,8), "work_p2_g1_tmp1")
   CALL gpu_work_alloc_r(work_p2_g1_hat, INT(ni+4,8)*INT(nk,8)*INT(nj+4,8), "work_p2_g1_hat")
   CALL gpu_work_alloc_r(work_p2_g1_hatavg, INT(ni+4,8)*INT(nk,8)*INT(nj+4,8), "work_p2_g1_hatavg")
#endif
#elif GPU_WORK_SECTION == 3
#ifdef WRF_GPU
   CALL gpu_work_check_r(work_p2_g1_mm, "work_p2_g1_mm", nwork, nbad)
   CALL gpu_work_check_r(work_p2_g1_zzavg, "work_p2_g1_zzavg", nwork, nbad)
   CALL gpu_work_check_r(work_p2_g1_zeta_zd12, "work_p2_g1_zeta_zd12", nwork, nbad)
   CALL gpu_work_check_r(work_p2_g1_tmp1, "work_p2_g1_tmp1", nwork, nbad)
   CALL gpu_work_check_r(work_p2_g1_hat, "work_p2_g1_hat", nwork, nbad)
   CALL gpu_work_check_r(work_p2_g1_hatavg, "work_p2_g1_hatavg", nwork, nbad)
#endif
#endif
