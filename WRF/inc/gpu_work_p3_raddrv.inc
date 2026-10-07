! Work arrays of work package P3-RADDRV (port/agent/INTERFACES.md I-3).
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
!    REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_fqy3(:)
! #endif
! #elif GPU_WORK_SECTION == 2
! #ifdef WRF_GPU
!    CALL gpu_work_alloc_r(work_p3_raddrv_fqy3, n3d, "work_p3_raddrv_fqy3")
! #endif
! #elif GPU_WORK_SECTION == 3
! #ifdef WRF_GPU
!    CALL gpu_work_check_r(work_p3_raddrv_fqy3, "work_p3_raddrv_fqy3", nwork, nbad)
! #endif
! #endif
!
! Names start with work_p3_raddrv_ so that no two work packages collide.
! No apostrophes in comments here: cpp reads this file, the WRF sed step does not.
!
! radiation_driver P1.7 automatics (plan.md). Ozone second dimension is 59
! (RRTMG sets levsiz=59). Aerosol shape is alevsiz=12 by no_src_types=6.
! cldfra1_flag and mask_loc are INTEGER. I-3 only provides gpu_work_alloc_r
! for REAL, so those two are allocated here (host zero-fill, and under WRF_GPU
! enter data copyin of that zero fill). They are not passed to gpu_work_check_r.

#if GPU_WORK_SECTION == 1

   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_cemiss(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_glat(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_glon(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_ozmixt(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_aerodt(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_qc_temp(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_qi_save(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_qc_save(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_qs_save(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_qc_cu_weight(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_qi_cu_weight(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_qs_cu_weight(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_cldfra_cu(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_erbe_out(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_sflxd(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_coszen_loc(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_hrang_loc(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_obscur_loc(:)
   INTEGER, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_cldfra1_flag(:)
   INTEGER, ALLOCATABLE, TARGET, PUBLIC :: work_p3_raddrv_mask_loc(:)

#elif GPU_WORK_SECTION == 2

   CALL gpu_work_alloc_r(work_p3_raddrv_cemiss, n3d, "work_p3_raddrv_cemiss")
   CALL gpu_work_alloc_r(work_p3_raddrv_glat, n2d, "work_p3_raddrv_glat")
   CALL gpu_work_alloc_r(work_p3_raddrv_glon, n2d, "work_p3_raddrv_glon")
   CALL gpu_work_alloc_r(work_p3_raddrv_ozmixt, n2d*INT(59,8), "work_p3_raddrv_ozmixt")
   CALL gpu_work_alloc_r(work_p3_raddrv_aerodt, n2d*INT(72,8), "work_p3_raddrv_aerodt")
   CALL gpu_work_alloc_r(work_p3_raddrv_qc_temp, n3d, "work_p3_raddrv_qc_temp")
   CALL gpu_work_alloc_r(work_p3_raddrv_qi_save, n3d, "work_p3_raddrv_qi_save")
   CALL gpu_work_alloc_r(work_p3_raddrv_qc_save, n3d, "work_p3_raddrv_qc_save")
   CALL gpu_work_alloc_r(work_p3_raddrv_qs_save, n3d, "work_p3_raddrv_qs_save")
   CALL gpu_work_alloc_r(work_p3_raddrv_qc_cu_weight, n3d, "work_p3_raddrv_qc_cu_weight")
   CALL gpu_work_alloc_r(work_p3_raddrv_qi_cu_weight, n3d, "work_p3_raddrv_qi_cu_weight")
   CALL gpu_work_alloc_r(work_p3_raddrv_qs_cu_weight, n3d, "work_p3_raddrv_qs_cu_weight")
   CALL gpu_work_alloc_r(work_p3_raddrv_cldfra_cu, n3d, "work_p3_raddrv_cldfra_cu")
   CALL gpu_work_alloc_r(work_p3_raddrv_erbe_out, n2d*INT(8,8), "work_p3_raddrv_erbe_out")
   CALL gpu_work_alloc_r(work_p3_raddrv_sflxd, n2d*INT(4,8), "work_p3_raddrv_sflxd")
   CALL gpu_work_alloc_r(work_p3_raddrv_coszen_loc, n2d, "work_p3_raddrv_coszen_loc")
   CALL gpu_work_alloc_r(work_p3_raddrv_hrang_loc, n2d, "work_p3_raddrv_hrang_loc")
   CALL gpu_work_alloc_r(work_p3_raddrv_obscur_loc, n2d, "work_p3_raddrv_obscur_loc")

   IF (.NOT. ALLOCATED(work_p3_raddrv_cldfra1_flag)) THEN
      ALLOCATE(work_p3_raddrv_cldfra1_flag(n3d))
      work_p3_raddrv_cldfra1_flag(:) = 0
#ifdef WRF_GPU
!$acc enter data copyin(work_p3_raddrv_cldfra1_flag)
#endif
   ELSE IF (SIZE(work_p3_raddrv_cldfra1_flag, KIND=8) < n3d) THEN
#ifdef WRF_GPU
!$acc exit data delete(work_p3_raddrv_cldfra1_flag)
#endif
      DEALLOCATE(work_p3_raddrv_cldfra1_flag)
      ALLOCATE(work_p3_raddrv_cldfra1_flag(n3d))
      work_p3_raddrv_cldfra1_flag(:) = 0
#ifdef WRF_GPU
!$acc enter data copyin(work_p3_raddrv_cldfra1_flag)
#endif
   END IF

   IF (.NOT. ALLOCATED(work_p3_raddrv_mask_loc)) THEN
      ALLOCATE(work_p3_raddrv_mask_loc(n2d))
      work_p3_raddrv_mask_loc(:) = 0
#ifdef WRF_GPU
!$acc enter data copyin(work_p3_raddrv_mask_loc)
#endif
   ELSE IF (SIZE(work_p3_raddrv_mask_loc, KIND=8) < n2d) THEN
#ifdef WRF_GPU
!$acc exit data delete(work_p3_raddrv_mask_loc)
#endif
      DEALLOCATE(work_p3_raddrv_mask_loc)
      ALLOCATE(work_p3_raddrv_mask_loc(n2d))
      work_p3_raddrv_mask_loc(:) = 0
#ifdef WRF_GPU
!$acc enter data copyin(work_p3_raddrv_mask_loc)
#endif
   END IF

#elif GPU_WORK_SECTION == 3

   CALL gpu_work_check_r(work_p3_raddrv_cemiss, "work_p3_raddrv_cemiss", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_glat, "work_p3_raddrv_glat", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_glon, "work_p3_raddrv_glon", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_ozmixt, "work_p3_raddrv_ozmixt", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_aerodt, "work_p3_raddrv_aerodt", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_qc_temp, "work_p3_raddrv_qc_temp", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_qi_save, "work_p3_raddrv_qi_save", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_qc_save, "work_p3_raddrv_qc_save", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_qs_save, "work_p3_raddrv_qs_save", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_qc_cu_weight, "work_p3_raddrv_qc_cu_weight", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_qi_cu_weight, "work_p3_raddrv_qi_cu_weight", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_qs_cu_weight, "work_p3_raddrv_qs_cu_weight", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_cldfra_cu, "work_p3_raddrv_cldfra_cu", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_erbe_out, "work_p3_raddrv_erbe_out", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_sflxd, "work_p3_raddrv_sflxd", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_coszen_loc, "work_p3_raddrv_coszen_loc", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_hrang_loc, "work_p3_raddrv_hrang_loc", nwork, nbad)
   CALL gpu_work_check_r(work_p3_raddrv_obscur_loc, "work_p3_raddrv_obscur_loc", nwork, nbad)

#endif
