! Work arrays of work package P2-G2 (port/agent/INTERFACES.md I-3).
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
!    REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g2_fqy3(:)
! #endif
! #elif GPU_WORK_SECTION == 2
! #ifdef WRF_GPU
!    CALL gpu_work_alloc_r(work_p2_g2_fqy3, n3d, "work_p2_g2_fqy3")
! #endif
! #elif GPU_WORK_SECTION == 3
! #ifdef WRF_GPU
!    CALL gpu_work_check_r(work_p2_g2_fqy3, "work_p2_g2_fqy3", nwork, nbad)
! #endif
! #endif
!
! Names start with work_p2_g2_ so that no two work packages collide.
! No apostrophes in comments here: cpp reads this file, the WRF sed step does not.

! calculate_N2 tile temporaries. GPU view only; the CPU routine keeps its
! automatic arrays. 3D tiles use n3d; 2D tiles use n2d.
#if GPU_WORK_SECTION == 1
#ifdef WRF_GPU
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g2_n2_tmp1(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g2_n2_qvs(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g2_n2_qctmp(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g2_n2_tmp1sfc(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g2_n2_tmp1top(:)
#endif
#elif GPU_WORK_SECTION == 2
#ifdef WRF_GPU
   CALL gpu_work_alloc_r(work_p2_g2_n2_tmp1, n3d, "work_p2_g2_n2_tmp1")
   CALL gpu_work_alloc_r(work_p2_g2_n2_qvs, n3d, "work_p2_g2_n2_qvs")
   CALL gpu_work_alloc_r(work_p2_g2_n2_qctmp, n3d, "work_p2_g2_n2_qctmp")
   CALL gpu_work_alloc_r(work_p2_g2_n2_tmp1sfc, n2d, "work_p2_g2_n2_tmp1sfc")
   CALL gpu_work_alloc_r(work_p2_g2_n2_tmp1top, n2d, "work_p2_g2_n2_tmp1top")
#endif
#elif GPU_WORK_SECTION == 3
#ifdef WRF_GPU
   CALL gpu_work_check_r(work_p2_g2_n2_tmp1, "work_p2_g2_n2_tmp1", nwork, nbad)
   CALL gpu_work_check_r(work_p2_g2_n2_qvs, "work_p2_g2_n2_qvs", nwork, nbad)
   CALL gpu_work_check_r(work_p2_g2_n2_qctmp, "work_p2_g2_n2_qctmp", nwork, nbad)
   CALL gpu_work_check_r(work_p2_g2_n2_tmp1sfc, "work_p2_g2_n2_tmp1sfc", nwork, nbad)
   CALL gpu_work_check_r(work_p2_g2_n2_tmp1top, "work_p2_g2_n2_tmp1top", nwork, nbad)
#endif
#endif

! smag2d_km deformation tile. GPU view only.
#if GPU_WORK_SECTION == 1
#ifdef WRF_GPU
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g2_smag_def2(:)
#endif
#elif GPU_WORK_SECTION == 2
#ifdef WRF_GPU
   CALL gpu_work_alloc_r(work_p2_g2_smag_def2, n3d, "work_p2_g2_smag_def2")
#endif
#elif GPU_WORK_SECTION == 3
#ifdef WRF_GPU
   CALL gpu_work_check_r(work_p2_g2_smag_def2, "work_p2_g2_smag_def2", nwork, nbad)
#endif
#endif

! tke_km dthrdn tile. GPU view only.
#if GPU_WORK_SECTION == 1
#ifdef WRF_GPU
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_g2_tke_dthrdn(:)
#endif
#elif GPU_WORK_SECTION == 2
#ifdef WRF_GPU
   CALL gpu_work_alloc_r(work_p2_g2_tke_dthrdn, n3d, "work_p2_g2_tke_dthrdn")
#endif
#elif GPU_WORK_SECTION == 3
#ifdef WRF_GPU
   CALL gpu_work_check_r(work_p2_g2_tke_dthrdn, "work_p2_g2_tke_dthrdn", nwork, nbad)
#endif
#endif
