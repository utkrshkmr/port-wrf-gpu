! Work arrays of work package P3-PBL (port/agent/INTERFACES.md I-3).
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
!    REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_fqy3(:)
! #endif
! #elif GPU_WORK_SECTION == 2
! #ifdef WRF_GPU
!    CALL gpu_work_alloc_r(work_p3_pbl_fqy3, n3d, "work_p3_pbl_fqy3")
! #endif
! #elif GPU_WORK_SECTION == 3
! #ifdef WRF_GPU
!    CALL gpu_work_check_r(work_p3_pbl_fqy3, "work_p3_pbl_fqy3", nwork, nbad)
! #endif
! #endif
!
! Names start with work_p3_pbl_ so that no two work packages collide.
! No apostrophes in comments here: cpp reads this file, the WRF sed step does not.
!
! Shared refactor (plan.md P1.7): the large 3D automatic arrays of pbl_driver.
! Both builds. Shape (ims:ime, kms:kme, jms:jme) maps onto n3d.
#if GPU_WORK_SECTION == 1
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_u_phytmp(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_v_phytmp(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_tke_windfarm(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_rqncblten(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_rqnwfablten(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_rqnifablten(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_rqnbcablten(:)
#elif GPU_WORK_SECTION == 2
   CALL gpu_work_alloc_r(work_p3_pbl_u_phytmp, n3d, "work_p3_pbl_u_phytmp")
   CALL gpu_work_alloc_r(work_p3_pbl_v_phytmp, n3d, "work_p3_pbl_v_phytmp")
   CALL gpu_work_alloc_r(work_p3_pbl_tke_windfarm, n3d, "work_p3_pbl_tke_windfarm")
   CALL gpu_work_alloc_r(work_p3_pbl_rqncblten, n3d, "work_p3_pbl_rqncblten")
   CALL gpu_work_alloc_r(work_p3_pbl_rqnwfablten, n3d, "work_p3_pbl_rqnwfablten")
   CALL gpu_work_alloc_r(work_p3_pbl_rqnifablten, n3d, "work_p3_pbl_rqnifablten")
   CALL gpu_work_alloc_r(work_p3_pbl_rqnbcablten, n3d, "work_p3_pbl_rqnbcablten")
#elif GPU_WORK_SECTION == 3
   CALL gpu_work_check_r(work_p3_pbl_u_phytmp, "work_p3_pbl_u_phytmp", nwork, nbad)
   CALL gpu_work_check_r(work_p3_pbl_v_phytmp, "work_p3_pbl_v_phytmp", nwork, nbad)
   CALL gpu_work_check_r(work_p3_pbl_tke_windfarm, "work_p3_pbl_tke_windfarm", nwork, nbad)
   CALL gpu_work_check_r(work_p3_pbl_rqncblten, "work_p3_pbl_rqncblten", nwork, nbad)
   CALL gpu_work_check_r(work_p3_pbl_rqnwfablten, "work_p3_pbl_rqnwfablten", nwork, nbad)
   CALL gpu_work_check_r(work_p3_pbl_rqnifablten, "work_p3_pbl_rqnifablten", nwork, nbad)
   CALL gpu_work_check_r(work_p3_pbl_rqnbcablten, "work_p3_pbl_rqnbcablten", nwork, nbad)
#endif
! GPU view only: 2D automatics of pbl_driver that K-PBLD-1 writes
! (TSKOLD, USTOLD, ZNTOLD, PSFC). The CPU view keeps the automatic arrays.
#if GPU_WORK_SECTION == 1
#ifdef WRF_GPU
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_tskold(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_ustold(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_zntold(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_pbl_psfc(:)
#endif
#elif GPU_WORK_SECTION == 2
#ifdef WRF_GPU
   CALL gpu_work_alloc_r(work_p3_pbl_tskold, n2d, "work_p3_pbl_tskold")
   CALL gpu_work_alloc_r(work_p3_pbl_ustold, n2d, "work_p3_pbl_ustold")
   CALL gpu_work_alloc_r(work_p3_pbl_zntold, n2d, "work_p3_pbl_zntold")
   CALL gpu_work_alloc_r(work_p3_pbl_psfc, n2d, "work_p3_pbl_psfc")
#endif
#elif GPU_WORK_SECTION == 3
#ifdef WRF_GPU
   CALL gpu_work_check_r(work_p3_pbl_tskold, "work_p3_pbl_tskold", nwork, nbad)
   CALL gpu_work_check_r(work_p3_pbl_ustold, "work_p3_pbl_ustold", nwork, nbad)
   CALL gpu_work_check_r(work_p3_pbl_zntold, "work_p3_pbl_zntold", nwork, nbad)
   CALL gpu_work_check_r(work_p3_pbl_psfc, "work_p3_pbl_psfc", nwork, nbad)
#endif
#endif
