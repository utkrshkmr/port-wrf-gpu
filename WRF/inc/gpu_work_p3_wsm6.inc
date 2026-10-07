! Work arrays of work package P3-WSM6 (port/agent/INTERFACES.md I-3).
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
!    REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_wsm6_fqy3(:)
! #endif
! #elif GPU_WORK_SECTION == 2
! #ifdef WRF_GPU
!    CALL gpu_work_alloc_r(work_p3_wsm6_fqy3, n3d, "work_p3_wsm6_fqy3")
! #endif
! #elif GPU_WORK_SECTION == 3
! #ifdef WRF_GPU
!    CALL gpu_work_check_r(work_p3_wsm6_fqy3, "work_p3_wsm6_fqy3", nwork, nbad)
! #endif
! #endif
!
! Names start with work_p3_wsm6_ so that no two work packages collide.
! No apostrophes in comments here: cpp reads this file, the WRF sed step does not.
!
! Shared refactor (both builds): the five tile temporaries qv_tmp, qc_tmp,
! qi_tmp, qs_tmp, qni_tmp of microphysics_driver. Each is one memory-sized
! 3D field (n3d). The routine remaps a pointer onto the tile bounds.

#if GPU_WORK_SECTION == 1
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_wsm6_qv_tmp(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_wsm6_qc_tmp(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_wsm6_qi_tmp(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_wsm6_qs_tmp(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_wsm6_qni_tmp(:)
#elif GPU_WORK_SECTION == 2
   CALL gpu_work_alloc_r(work_p3_wsm6_qv_tmp, n3d, "work_p3_wsm6_qv_tmp")
   CALL gpu_work_alloc_r(work_p3_wsm6_qc_tmp, n3d, "work_p3_wsm6_qc_tmp")
   CALL gpu_work_alloc_r(work_p3_wsm6_qi_tmp, n3d, "work_p3_wsm6_qi_tmp")
   CALL gpu_work_alloc_r(work_p3_wsm6_qs_tmp, n3d, "work_p3_wsm6_qs_tmp")
   CALL gpu_work_alloc_r(work_p3_wsm6_qni_tmp, n3d, "work_p3_wsm6_qni_tmp")
#elif GPU_WORK_SECTION == 3
   CALL gpu_work_check_r(work_p3_wsm6_qv_tmp, "work_p3_wsm6_qv_tmp", nwork, nbad)
   CALL gpu_work_check_r(work_p3_wsm6_qc_tmp, "work_p3_wsm6_qc_tmp", nwork, nbad)
   CALL gpu_work_check_r(work_p3_wsm6_qi_tmp, "work_p3_wsm6_qi_tmp", nwork, nbad)
   CALL gpu_work_check_r(work_p3_wsm6_qs_tmp, "work_p3_wsm6_qs_tmp", nwork, nbad)
   CALL gpu_work_check_r(work_p3_wsm6_qni_tmp, "work_p3_wsm6_qni_tmp", nwork, nbad)
#endif
