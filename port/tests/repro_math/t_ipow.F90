! T-IPOW (plan.md P0.6): integer powers, host vs device.
!
! NVHPC 26.5 evaluates x**n on the host with library calls (__py_powi1_4,
! __pmth_i_dpowi, ...) but multiplies on the device, so x**n differs (BLOCKERS
! B3).  rp_subst.py therefore keeps only the exponents 0, 1, 2 as powers (x**2
! is x*x on both) and rewrites every other integer exponent, literal or named
! constant, and a REAL constant exponent -1, to rp_pow, which multiplies
! explicitly (module_repro_math).  Cases: the powers left in the code (x**2,
! x**2.0 and x**0.0 through named constants, the INTEGER constant 2), and
! rp_pow with the literal exponents ipow_scan.py found before the rewrite (3, 4,
! 8), with the REAL constant -1.0, and with INTEGER variables n = -8..32.
! Pass: identical bits.
!
! Usage: t_ipow [log2_values]   (default 26)

PROGRAM t_ipow
   USE rm_testlib
   IMPLICIT NONE
   INTEGER, PARAMETER :: nlit = 8, nvar = 41
   REAL(r4), PARAMETER :: p2 = 2.0, pm1 = -1.0
   INTEGER, PARAMETER :: ipw = 2
   REAL(r4), ALLOCATABLE :: a(:)
   REAL(r8), ALLOCATABLE :: a8(:)
   INTEGER(i4), ALLOCATABLE :: h4(:,:), d4(:,:)
   INTEGER(i8), ALLOCATABLE :: h8(:,:), d8(:,:)
   INTEGER(i8) :: n, k, seed, nb, total_bad
   INTEGER :: j, lg, nargs
   CHARACTER(LEN=16) :: arg

   lg = 26
   nargs = COMMAND_ARGUMENT_COUNT()
   IF (nargs >= 1) THEN
      CALL GET_COMMAND_ARGUMENT(1, arg)
      READ (arg, *) lg
   END IF
   n = 2_i8**lg
   CALL require_device()
   ALLOCATE (a(n), a8(n), h4(nlit + nvar, n), d4(nlit + nvar, n), h8(nlit + nvar, n), d8(nlit + nvar, n))
   seed = 99_i8
   DO k = 1_i8, n
      ! values of moderate size so that x**32 stays finite for most inputs
      a(k)  = f4(IOR(IAND(splitmix64(seed), INT(Z'807FFFFF', i8)), INT(Z'3E000000', i8)) + &
                 IAND(splitmix64(seed), INT(Z'01800000', i8)))
      a8(k) = REAL(a(k), r8)*(1.0_r8 + 2.0_r8**(-30))
   END DO

!$acc parallel loop gang vector copyin(a, a8) copyout(d4, d8)
   DO k = 1_i8, n
      CALL pw(a(k), a8(k), d4(:, k), d8(:, k))
   END DO
!$omp parallel do
   DO k = 1_i8, n
      CALL pw(a(k), a8(k), h4(:, k), h8(:, k))
   END DO

   total_bad = 0_i8
   DO j = 1, nlit + nvar
      nb = COUNT(h4(j, :) /= d4(j, :)) + COUNT(h8(j, :) /= d8(j, :))
      IF (nb /= 0_i8) THEN
         IF (j <= nlit) THEN
            PRINT '(a,i0,a,i0)', 'FAIL  T-IPOW constant exponent case ', j, ': ', nb
         ELSE
            PRINT '(a,i0,a,i0)', 'FAIL  T-IPOW variable exponent n=', j - nlit - 9, ': ', nb
         END IF
      END IF
      total_bad = total_bad + nb
   END DO
   CALL report('T-IPOW (x**2, named constants, rp_pow 3,4,8,-1.0, variable -8..32; REAL(4) and REAL(8))', total_bad, &
               2_i8*n*(nlit + nvar))
   IF (total_bad /= 0_i8) STOP 1

CONTAINS

   SUBROUTINE pw(x, x8, r4o, r8o)
!$acc routine seq
      REAL(r4), INTENT(IN) :: x
      REAL(r8), INTENT(IN) :: x8
      INTEGER(i4), INTENT(OUT) :: r4o(nlit + nvar)
      INTEGER(i8), INTENT(OUT) :: r8o(nlit + nvar)
      INTEGER :: m
      r4o(1) = bits4(x**2)
      r4o(2) = bits4(rp_pow(x, 3))
      r4o(3) = bits4(rp_pow(x, 4))
      r4o(4) = bits4(rp_pow(x, 8))
      r4o(5) = bits4(x**p2)
      r4o(6) = bits4(x**(p2 - p2))
      r4o(7) = bits4(rp_pow(x, pm1))
      r4o(8) = bits4(x**ipw)
      r8o(1) = bits8(x8**2)
      r8o(2) = bits8(rp_pow(x8, 3))
      r8o(3) = bits8(rp_pow(x8, 4))
      r8o(4) = bits8(rp_pow(x8, 8))
      r8o(5) = bits8(x8**p2)
      r8o(6) = bits8(x8**(p2 - p2))
      r8o(7) = bits8(rp_pow(x8, pm1))
      r8o(8) = bits8(x8**ipw)
      DO m = -8, 32
         r4o(nlit + m + 9) = bits4(rp_pow(x, m))
         r8o(nlit + m + 9) = bits8(rp_pow(x8, m))
      END DO
   END SUBROUTINE pw

END PROGRAM t_ipow
