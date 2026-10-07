!WRF:MODEL_LAYER:PHYSICS
!
! module_gpu_tables: module tables of the physics on the device (plan.md P1.4;
! port/agent/PHASE1.md P1.4; port/agent/INTERFACES.md I-4; work package P1-TAB).
!
! The table variables are declared `!$acc declare create(...)` in their own
! modules, which also provide the upload and the check (three of the four
! modules keep their tables PRIVATE).  Written by the physics work packages:
!   mp_wsm6            (P3-WSM6)    wsm6_gpu_upload(),      wsm6_gpu_tabcheck(n, nbad, bad)
!   sf_sfclayrev       (P3-SFCLAY)  sfclayrev_gpu_upload(), sfclayrev_gpu_tabcheck(n, nbad, bad)
!   module_sf_noahlsm  (P3-NOAH)    noahlsm_gpu_upload(),   noahlsm_gpu_tabcheck(n, nbad, bad)
!   module_ra_sw       (P3-SW)      ra_sw_gpu_upload(),     ra_sw_gpu_tabcheck(n, nbad, bad)
!   (RRTMG_LWRAD module, P3-RRTMG)  rrtmg_lw_gpu_upload(),  rrtmg_lw_gpu_tabcheck(n, nbad, bad)
! all under #ifdef WRF_GPU and PUBLIC; tabcheck: INTEGER, INTENT(OUT) :: n, nbad;
! CHARACTER(LEN=*), INTENT(INOUT) :: bad (appends the names that differ).
!
! External entry points (called without USE from frame/ and main/):
!   gpu_update_tables()   at S1 and S2 (P1-SYNC): every upload routine above
!   gpu_selftest_tab()    T-TAB (called by gpu_selftests, P1-ST): prints
!                         "gpu_selftest: T-TAB PASS <n> tables" or
!                         "gpu_selftest: T-TAB FAIL <nbad> of <n>: <names>"
!
MODULE module_gpu_tables
   IMPLICIT NONE
END MODULE module_gpu_tables

SUBROUTINE gpu_update_tables()
   ! Host upload of every table module (INTERFACES.md I-4). The five routines
   ! are PUBLIC in those modules and exist only under WRF_GPU (P3-WSM6,
   ! P3-SFCLAY, P3-NOAH, P3-SW, P3-RRTMG). This routine does not declare the
   ! tables. frame/ and main/ call it with no USE.
#ifdef WRF_GPU
   USE mp_wsm6, ONLY : wsm6_gpu_upload
   USE sf_sfclayrev, ONLY : sfclayrev_gpu_upload
   USE module_sf_noahlsm, ONLY : noahlsm_gpu_upload
   USE module_ra_sw, ONLY : ra_sw_gpu_upload
   USE module_ra_rrtmg_lw, ONLY : rrtmg_lw_gpu_upload
#endif
   IMPLICIT NONE
#ifdef WRF_GPU
   CALL wsm6_gpu_upload()
   CALL sfclayrev_gpu_upload()
   CALL noahlsm_gpu_upload()
   CALL ra_sw_gpu_upload()
   CALL rrtmg_lw_gpu_upload()
#endif
END SUBROUTINE gpu_update_tables

SUBROUTINE gpu_selftest_tab()
   ! T-TAB (INTERFACES.md I-4, I-5). Each tabcheck sets n and nbad and appends
   ! the names that differ onto bad. This routine sums the counts and prints
   ! exactly one line through wrf_message. The table variables stay in the
   ! physics modules. n is that sum, including the RRTMG tables, not a fixed 120.
#ifdef WRF_GPU
   USE mp_wsm6, ONLY : wsm6_gpu_tabcheck
   USE sf_sfclayrev, ONLY : sfclayrev_gpu_tabcheck
   USE module_sf_noahlsm, ONLY : noahlsm_gpu_tabcheck
   USE module_ra_sw, ONLY : ra_sw_gpu_tabcheck
   USE module_ra_rrtmg_lw, ONLY : rrtmg_lw_gpu_tabcheck
#endif
   IMPLICIT NONE
#ifdef WRF_GPU
   INTEGER :: n, nbad, nsum, nbadsum, nlen
   CHARACTER(LEN=8192) :: bad
   CHARACTER(LEN=8448) :: line
   nsum = 0
   nbadsum = 0
   bad = ''
   CALL wsm6_gpu_tabcheck(n, nbad, bad)
   nsum = nsum + n
   nbadsum = nbadsum + nbad
   CALL sfclayrev_gpu_tabcheck(n, nbad, bad)
   nsum = nsum + n
   nbadsum = nbadsum + nbad
   CALL noahlsm_gpu_tabcheck(n, nbad, bad)
   nsum = nsum + n
   nbadsum = nbadsum + nbad
   CALL ra_sw_gpu_tabcheck(n, nbad, bad)
   nsum = nsum + n
   nbadsum = nbadsum + nbad
   CALL rrtmg_lw_gpu_tabcheck(n, nbad, bad)
   nsum = nsum + n
   nbadsum = nbadsum + nbad
   IF (nbadsum == 0) THEN
      WRITE(line, '(A,I0,A)') 'gpu_selftest: T-TAB PASS ', nsum, ' tables'
   ELSE
      ! Leading blanks dropped so the colon has one space before the first name.
      ! The buffer keeps the front of the list: the first bad names.
      bad = ADJUSTL(bad)
      nlen = LEN_TRIM(bad)
      IF (nlen == 0) THEN
         WRITE(line, '(A,I0,A,I0,A)') 'gpu_selftest: T-TAB FAIL ', &
              nbadsum, ' of ', nsum, ':'
      ELSE
         WRITE(line, '(A,I0,A,I0,A,A)') 'gpu_selftest: T-TAB FAIL ', &
              nbadsum, ' of ', nsum, ': ', bad(1:nlen)
      END IF
   END IF
   CALL wrf_message(TRIM(line))
#endif
END SUBROUTINE gpu_selftest_tab
