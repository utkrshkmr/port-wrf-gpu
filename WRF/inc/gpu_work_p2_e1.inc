! Work arrays of work package P2-E1 (port/agent/INTERFACES.md I-3).
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
!    REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_fqy3(:)
! #endif
! #elif GPU_WORK_SECTION == 2
! #ifdef WRF_GPU
!    CALL gpu_work_alloc_r(work_p2_e1_fqy3, n3d, "work_p2_e1_fqy3")
! #endif
! #elif GPU_WORK_SECTION == 3
! #ifdef WRF_GPU
!    CALL gpu_work_check_r(work_p2_e1_fqy3, "work_p2_e1_fqy3", nwork, nbad)
! #endif
! #endif
!
! Names start with work_p2_e1_ so that no two work packages collide.
! No apostrophes in comments here: cpp reads this file, the WRF sed step does not.
!
! Shared refactor of advect_scalar_pd: fqx, fqy, fqz, fqxl, fqyl, fqzl,
! flux_out and ph_low were automatic arrays
! (its-1:ite+2, kts:kte, jts-1:jte+2).  The pointer keeps those bounds.
! A tile that spans the memory domain needs three extra points in i and in j
! (its-1 .. ite+2), so the allocation is (ni+3)*(nj+3)*nk.

#if GPU_WORK_SECTION == 1
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_fqx(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_fqy(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_fqz(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_fqxl(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_fqyl(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_fqzl(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_flux_out(:)
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_ph_low(:)
#ifdef WRF_GPU
   REAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_scl(:)
   LOGICAL, ALLOCATABLE, TARGET, PUBLIC :: work_p2_e1_lim(:)
#endif
#elif GPU_WORK_SECTION == 2
   CALL gpu_work_alloc_r(work_p2_e1_fqx, INT(ni+3,8)*INT(nj+3,8)*INT(nk,8), "work_p2_e1_fqx")
   CALL gpu_work_alloc_r(work_p2_e1_fqy, INT(ni+3,8)*INT(nj+3,8)*INT(nk,8), "work_p2_e1_fqy")
   CALL gpu_work_alloc_r(work_p2_e1_fqz, INT(ni+3,8)*INT(nj+3,8)*INT(nk,8), "work_p2_e1_fqz")
   CALL gpu_work_alloc_r(work_p2_e1_fqxl, INT(ni+3,8)*INT(nj+3,8)*INT(nk,8), "work_p2_e1_fqxl")
   CALL gpu_work_alloc_r(work_p2_e1_fqyl, INT(ni+3,8)*INT(nj+3,8)*INT(nk,8), "work_p2_e1_fqyl")
   CALL gpu_work_alloc_r(work_p2_e1_fqzl, INT(ni+3,8)*INT(nj+3,8)*INT(nk,8), "work_p2_e1_fqzl")
   CALL gpu_work_alloc_r(work_p2_e1_flux_out, INT(ni+3,8)*INT(nj+3,8)*INT(nk,8), "work_p2_e1_flux_out")
   CALL gpu_work_alloc_r(work_p2_e1_ph_low, INT(ni+3,8)*INT(nj+3,8)*INT(nk,8), "work_p2_e1_ph_low")
#ifdef WRF_GPU
   CALL gpu_work_alloc_r(work_p2_e1_scl, INT(ni+3,8)*INT(nj+3,8)*INT(nk,8), "work_p2_e1_scl")
   IF (.NOT. ALLOCATED(work_p2_e1_lim)) THEN
      ALLOCATE(work_p2_e1_lim((ni+3)*(nj+3)*nk))
!$acc enter data create(work_p2_e1_lim)
   ELSE IF (INT(SIZE(work_p2_e1_lim),8) < INT(ni+3,8)*INT(nj+3,8)*INT(nk,8)) THEN
!$acc exit data delete(work_p2_e1_lim)
      DEALLOCATE(work_p2_e1_lim)
      ALLOCATE(work_p2_e1_lim((ni+3)*(nj+3)*nk))
!$acc enter data create(work_p2_e1_lim)
   END IF
#endif
#elif GPU_WORK_SECTION == 3
   CALL gpu_work_check_r(work_p2_e1_fqx, "work_p2_e1_fqx", nwork, nbad)
   CALL gpu_work_check_r(work_p2_e1_fqy, "work_p2_e1_fqy", nwork, nbad)
   CALL gpu_work_check_r(work_p2_e1_fqz, "work_p2_e1_fqz", nwork, nbad)
   CALL gpu_work_check_r(work_p2_e1_fqxl, "work_p2_e1_fqxl", nwork, nbad)
   CALL gpu_work_check_r(work_p2_e1_fqyl, "work_p2_e1_fqyl", nwork, nbad)
   CALL gpu_work_check_r(work_p2_e1_fqzl, "work_p2_e1_fqzl", nwork, nbad)
   CALL gpu_work_check_r(work_p2_e1_flux_out, "work_p2_e1_flux_out", nwork, nbad)
   CALL gpu_work_check_r(work_p2_e1_ph_low, "work_p2_e1_ph_low", nwork, nbad)
#ifdef WRF_GPU
   CALL gpu_work_check_r(work_p2_e1_scl, "work_p2_e1_scl", nwork, nbad)
#endif
#endif
