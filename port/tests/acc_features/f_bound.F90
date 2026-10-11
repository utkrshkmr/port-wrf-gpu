! F-BOUND: rp_min (module_repro_math, an "acc routine seq" generic) in the inner
! bound of a collapsed loop with variable lower bounds and default(none).  With
! NVHPC 25.1 and 26.5 this kernel runs no iteration, silently; with a second
! kernel in the same program it can work, so the behaviour depends on context.
! Fallback: MAX/MIN in DO bounds stay intrinsics (port/rp_subst.py; loop bounds
! are INTEGER, exact); never call a procedure in a bound of a collapsed loop.
program f_bound
  use module_repro_math
  implicit none
  integer, parameter :: ni = 50, nj = 40
  real :: a(ni, nj)
  integer :: i, j, its, ite, ide, jts, jtf
  its = 3; ite = 30; ide = 45; jts = 2; jtf = 37
  a = 0.
!$acc parallel loop gang vector collapse(2) default(none) copy(a) firstprivate(its, ite, jts, jtf, ide)
  do j = jts, jtf
    do i = its, rp_min(ite+1, ide)
      a(i, j) = a(i, j) + 1.
    end do
  end do
  if (sum(a) == real((31 - 3 + 1)*(37 - 2 + 1))) then
    print '(a)', 'PROBE F-BOUND PASS (rp_min in a collapsed inner bound)'
  else
    print '(a,f8.0,a,i0,a)', 'PROBE F-BOUND FAIL (rp_min in a collapsed inner bound ran ', sum(a), &
          ' iterations, want ', (31 - 3 + 1)*(37 - 2 + 1), '; fallback: intrinsic MIN/MAX in DO bounds)'
  end if
end program
