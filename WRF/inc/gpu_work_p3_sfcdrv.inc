! Work arrays of work package P3-SFCDRV (port/agent/INTERFACES.md I-3).
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
!    REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_sfcdrv_fqy3(:)
! #endif
! #elif GPU_WORK_SECTION == 2
! #ifdef WRF_GPU
!    CALL gpu_work_alloc_r(work_p3_sfcdrv_fqy3, n3d, "work_p3_sfcdrv_fqy3")
! #endif
! #elif GPU_WORK_SECTION == 3
! #ifdef WRF_GPU
!    CALL gpu_work_check_r(work_p3_sfcdrv_fqy3, "work_p3_sfcdrv_fqy3", nwork, nbad)
! #endif
! #endif
!
! Names start with work_p3_sfcdrv_ so that no two work packages collide.
! No apostrophes in comments here: cpp reads this file, the WRF sed step does not.
!
! Shared refactor (plan.md P1.7): the large 3D automatic arrays of surface_driver.
! Both builds. Shape (ims:ime, kms:kme, jms:jme) maps onto n3d.
#if GPU_WORK_SECTION == 1
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_sfcdrv_u_phytmp(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_sfcdrv_v_phytmp(:)
#elif GPU_WORK_SECTION == 2
   CALL gpu_work_alloc_r(work_p3_sfcdrv_u_phytmp, n3d, "work_p3_sfcdrv_u_phytmp")
   CALL gpu_work_alloc_r(work_p3_sfcdrv_v_phytmp, n3d, "work_p3_sfcdrv_v_phytmp")
#elif GPU_WORK_SECTION == 3
   CALL gpu_work_check_r(work_p3_sfcdrv_u_phytmp, "work_p3_sfcdrv_u_phytmp", nwork, nbad)
   CALL gpu_work_check_r(work_p3_sfcdrv_v_phytmp, "work_p3_sfcdrv_v_phytmp", nwork, nbad)
#endif
