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
!   gpu_selftest_fire_ghost(grid)
!                           T-FIRE-GHOST (PHASE4): device copies of lfn and
!                           tign_g are 0.0 on the ghost rows and columns of
!                           the fire mesh. Called for every domain with
!                           ifire > 0. "gpu_selftest: T-FIRE-GHOST PASS d0N"
!                           or "... FAIL d0N <count>"
! T-POOL (gpu_selftest_pool, module_gpu_scratch, P1-POOL) is called from
! solve_em, where the pool exists.
!
MODULE module_gpu_selftest
   IMPLICIT NONE
END MODULE module_gpu_selftest

SUBROUTINE gpu_selftests(grid)
   USE module_domain, ONLY : domain
   USE module_gpu_work, ONLY : gpu_selftest_work
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   CHARACTER(LEN=32) :: env
   INTEGER :: st
   LOGICAL, SAVE :: seen = .FALSE.
   LOGICAL, SAVE :: enabled = .FALSE.

   ! Read WRF_GPU_SELFTEST once. Later domains reuse the saved flag.
   IF (.NOT. seen) THEN
      seen = .TRUE.
      env = ' '
      CALL get_environment_variable('WRF_GPU_SELFTEST', env, status=st)
      enabled = (st == 0 .AND. TRIM(ADJUSTL(env)) == '1')
   END IF
   IF (.NOT. enabled) RETURN

   CALL gpu_selftest_map(grid)
   CALL gpu_selftest_tab()
   CALL gpu_selftest_work()
   IF (grid%ifire > 0) CALL gpu_selftest_fire_ghost(grid)
END SUBROUTINE gpu_selftests

SUBROUTINE gpu_selftest_map(grid)
#ifdef WRF_GPU
   USE module_domain, ONLY : domain, fieldlist
#else
   USE module_domain, ONLY : domain
#endif
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
#ifdef WRF_GPU
   TYPE(fieldlist), POINTER :: p
   INTEGER :: n, k, nnames
   CHARACTER(LEN=80) :: one
   CHARACTER(LEN=240) :: names
   CHARACTER(LEN=320) :: msg
   LOGICAL :: work_p1_st_field_present
#endif

   ! Domain ids are positive. This also names grid in the CPU view.
   IF (grid%id < 0) RETURN

#ifdef WRF_GPU
   n = 0
   k = 0
   nnames = 0
   names = ''
   IF (ASSOCIATED(grid%head_statevars)) THEN
      ! The head node is a sentinel (Ndim 0). Fields start at next.
      p => grid%head_statevars%next
      DO WHILE (ASSOCIATED(p))
         IF (p%Ndim >= 1 .AND. (p%Type == 'r' .OR. p%Type == 'd' .OR. &
             p%Type == 'i' .OR. p%Type == 'l')) THEN
            n = n + 1
            IF (.NOT. work_p1_st_field_present(p)) THEN
               k = k + 1
               one = TRIM(ADJUSTL(p%VarName))
               IF (nnames < 8 .AND. LEN_TRIM(one) > 0) THEN
                  IF (LEN_TRIM(names) + 2 + LEN_TRIM(one) <= LEN(names)) THEN
                     IF (nnames == 0) THEN
                        names = TRIM(one)
                     ELSE
                        names = TRIM(names) // ', ' // TRIM(one)
                     END IF
                     nnames = nnames + 1
                  END IF
               END IF
            END IF
         END IF
         p => p%next
      END DO
   END IF
   IF (n > 0 .AND. k == 0) THEN
      WRITE (msg, '(A,I2.2,A,I0,A)') 'gpu_selftest: T-MAP PASS d', grid%id, ' ', n, ' fields present'
   ELSE
      WRITE (msg, '(A,I2.2,A,I0,A,I0,A)') 'gpu_selftest: T-MAP FAIL d', grid%id, &
           ' ', k, ' of ', n, ' fields not present: '
      msg = TRIM(msg) // TRIM(names)
   END IF
   CALL wrf_message(TRIM(msg))
#endif
END SUBROUTINE gpu_selftest_map

! Device copies of lfn and tign_g are 0.0 on the ghost rows and columns
! after init. Ghost columns are ifds-1 and (ifde-sr_x)+1; ghost rows are
! jfds-1 and (jfde-sr_y)+1 (0 and 725 on the dev mesh; 0 and 3241 when the
! fire tile is 1..3240). init_no_fire writes only the tile interior, so the
! allocation zeros in that one-cell halo must still be on the device.
SUBROUTINE gpu_selftest_fire_ghost(grid)
   USE module_domain, ONLY : domain, get_ijk_from_subgrid
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   INTEGER :: ifds, ifde, jfds, jfde, kfds, kfde
   INTEGER :: ifms, ifme, jfms, jfme, kfms, kfme
   INTEGER :: ifps, ifpe, jfps, jfpe, kfps, kfpe
   INTEGER :: ams, ame, bms, bme
   INTEGER :: ilo, ihi, jlo, jhi, nbad
   CHARACTER(LEN=256) :: msg

   nbad = 0
#ifdef WRF_GPU
   IF (.NOT. ALLOCATED(grid%lfn) .OR. .NOT. ALLOCATED(grid%tign_g) .OR. &
       grid%sr_x < 1 .OR. grid%sr_y < 1) THEN
      nbad = 1
   ELSE
      CALL get_ijk_from_subgrid(grid,                              &
                           ifds, ifde, jfds, jfde, kfds, kfde,    &
                           ifms, ifme, jfms, jfme, kfms, kfme,    &
                           ifps, ifpe, jfps, jfpe, kfps, kfpe)
      ! Same ends fire_driver_em passes into the fire model (ifde-sr_x).
      ilo = ifds - 1
      ihi = ifde - grid%sr_x + 1
      jlo = jfds - 1
      jhi = jfde - grid%sr_y + 1
      ams = LBOUND(grid%lfn, 1)
      ame = UBOUND(grid%lfn, 1)
      bms = LBOUND(grid%lfn, 2)
      bme = UBOUND(grid%lfn, 2)
      IF (LBOUND(grid%tign_g, 1) /= ams .OR. UBOUND(grid%tign_g, 1) /= ame .OR. &
          LBOUND(grid%tign_g, 2) /= bms .OR. UBOUND(grid%tign_g, 2) /= bme) THEN
         nbad = 1
      ELSE
         CALL work_p1_st_fire_count(grid%lfn, grid%tign_g,          &
              ams, ame, bms, bme, ilo, ihi, jlo, jhi, nbad)
      END IF
   END IF
   IF (nbad == 0) THEN
      WRITE (msg, '(A,I2.2)') 'gpu_selftest: T-FIRE-GHOST PASS d', grid%id
   ELSE
      WRITE (msg, '(A,I2.2,A,I0)') 'gpu_selftest: T-FIRE-GHOST FAIL d', grid%id, ' ', nbad
   END IF
   CALL wrf_message(TRIM(msg))
#endif
END SUBROUTINE gpu_selftest_fire_ghost

! Refresh the host copies from the device (same update self bittrace uses),
! then count ghost cells that are not 0.0. One cell that is off the allocated
! mesh counts as two failures (lfn and tign_g). nbad = 1 when the arrays are
! not present, so update self is not called on absent data.
SUBROUTINE work_p1_st_fire_count(lfn, tign, ams, ame, bms, bme, ilo, ihi, jlo, jhi, nbad)
#ifdef WRF_GPU
   USE openacc
#endif
   IMPLICIT NONE
   INTEGER, INTENT(IN) :: ams, ame, bms, bme, ilo, ihi, jlo, jhi
   REAL, INTENT(INOUT) :: lfn(ams:ame, bms:bme)
   REAL, INTENT(INOUT) :: tign(ams:ame, bms:bme)
   INTEGER, INTENT(OUT) :: nbad
   INTEGER :: i, j
   INTEGER :: work_p1_st_ghost_pair

   nbad = 0
   ! A mesh with no interior (or inverted bounds) is not the fire halo.
   IF (ihi <= ilo .OR. jhi <= jlo) THEN
      nbad = 1
      RETURN
   END IF
#ifdef WRF_GPU
   IF (.NOT. acc_is_present(lfn) .OR. .NOT. acc_is_present(tign)) THEN
      nbad = 1
      RETURN
   END IF
!$acc update self(lfn, tign)
#endif
   DO j = jlo, jhi
      nbad = nbad + work_p1_st_ghost_pair(lfn, tign, ams, ame, bms, bme, ilo, j)
      nbad = nbad + work_p1_st_ghost_pair(lfn, tign, ams, ame, bms, bme, ihi, j)
   END DO
   DO i = ilo + 1, ihi - 1
      nbad = nbad + work_p1_st_ghost_pair(lfn, tign, ams, ame, bms, bme, i, jlo)
      nbad = nbad + work_p1_st_ghost_pair(lfn, tign, ams, ame, bms, bme, i, jhi)
   END DO
END SUBROUTINE work_p1_st_fire_count

! 0 when both values at (i,j) are 0.0; 1 or 2 otherwise. An index outside the
! allocated mesh counts as 2 (the cell cannot be 0.0 on the device).
INTEGER FUNCTION work_p1_st_ghost_pair(lfn, tign, ams, ame, bms, bme, i, j)
   IMPLICIT NONE
   INTEGER, INTENT(IN) :: ams, ame, bms, bme, i, j
   REAL, INTENT(IN) :: lfn(ams:ame, bms:bme)
   REAL, INTENT(IN) :: tign(ams:ame, bms:bme)
   INTEGER :: n
   n = 0
   IF (i < ams .OR. i > ame .OR. j < bms .OR. j > bme) THEN
      n = 2
   ELSE
      IF (lfn(i, j) /= 0.) n = n + 1
      IF (tign(i, j) /= 0.) n = n + 1
   END IF
   work_p1_st_ghost_pair = n
END FUNCTION work_p1_st_ghost_pair

! True when the fieldlist pointer for this rank is associated and present
! on the device. Scalars are not passed here (Ndim >= 1). A rank the type
! does not store (logical rank 3 and above) is not present.
LOGICAL FUNCTION work_p1_st_field_present(p)
   USE module_domain, ONLY : fieldlist
#ifdef WRF_GPU
   USE openacc
#endif
   IMPLICIT NONE
   TYPE(fieldlist), INTENT(IN) :: p
   LOGICAL :: here
   here = .FALSE.
   IF (p%Ndim < 1 .OR. p%Ndim > 7) THEN
      work_p1_st_field_present = .FALSE.
      RETURN
   END IF
#ifdef WRF_GPU
   SELECT CASE (p%Type)
   CASE ('r')
      SELECT CASE (p%Ndim)
      CASE (1)
         IF (ASSOCIATED(p%rfield_1d)) here = acc_is_present(p%rfield_1d)
      CASE (2)
         IF (ASSOCIATED(p%rfield_2d)) here = acc_is_present(p%rfield_2d)
      CASE (3)
         IF (ASSOCIATED(p%rfield_3d)) here = acc_is_present(p%rfield_3d)
      CASE (4)
         IF (ASSOCIATED(p%rfield_4d)) here = acc_is_present(p%rfield_4d)
      CASE (5)
         IF (ASSOCIATED(p%rfield_5d)) here = acc_is_present(p%rfield_5d)
      CASE (6)
         IF (ASSOCIATED(p%rfield_6d)) here = acc_is_present(p%rfield_6d)
      CASE (7)
         IF (ASSOCIATED(p%rfield_7d)) here = acc_is_present(p%rfield_7d)
      END SELECT
   CASE ('d')
      SELECT CASE (p%Ndim)
      CASE (1)
         IF (ASSOCIATED(p%dfield_1d)) here = acc_is_present(p%dfield_1d)
      CASE (2)
         IF (ASSOCIATED(p%dfield_2d)) here = acc_is_present(p%dfield_2d)
      CASE (3)
         IF (ASSOCIATED(p%dfield_3d)) here = acc_is_present(p%dfield_3d)
      CASE (4)
         IF (ASSOCIATED(p%dfield_4d)) here = acc_is_present(p%dfield_4d)
      CASE (5)
         IF (ASSOCIATED(p%dfield_5d)) here = acc_is_present(p%dfield_5d)
      CASE (6)
         IF (ASSOCIATED(p%dfield_6d)) here = acc_is_present(p%dfield_6d)
      CASE (7)
         IF (ASSOCIATED(p%dfield_7d)) here = acc_is_present(p%dfield_7d)
      END SELECT
   CASE ('i')
      SELECT CASE (p%Ndim)
      CASE (1)
         IF (ASSOCIATED(p%ifield_1d)) here = acc_is_present(p%ifield_1d)
      CASE (2)
         IF (ASSOCIATED(p%ifield_2d)) here = acc_is_present(p%ifield_2d)
      CASE (3)
         IF (ASSOCIATED(p%ifield_3d)) here = acc_is_present(p%ifield_3d)
      CASE (4)
         IF (ASSOCIATED(p%ifield_4d)) here = acc_is_present(p%ifield_4d)
      CASE (5)
         IF (ASSOCIATED(p%ifield_5d)) here = acc_is_present(p%ifield_5d)
      CASE (6)
         IF (ASSOCIATED(p%ifield_6d)) here = acc_is_present(p%ifield_6d)
      CASE (7)
         IF (ASSOCIATED(p%ifield_7d)) here = acc_is_present(p%ifield_7d)
      END SELECT
   CASE ('l')
      SELECT CASE (p%Ndim)
      CASE (1)
         IF (ASSOCIATED(p%lfield_1d)) here = acc_is_present(p%lfield_1d)
      CASE (2)
         IF (ASSOCIATED(p%lfield_2d)) here = acc_is_present(p%lfield_2d)
      END SELECT
   END SELECT
#endif
   work_p1_st_field_present = here
END FUNCTION work_p1_st_field_present
