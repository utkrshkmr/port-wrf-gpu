! F-NAN (S0-05.7): "x /= x" finds NaNs in device code under -Kieee.
program f_nan
  use, intrinsic :: ieee_arithmetic
  implicit none
  integer, parameter :: n = 100000
  real :: v(n)
  integer :: i, cd, ch
  v = [(real(i), i = 1, n)]
  do i = 1, n, 97
    v(i) = ieee_value(1.0, ieee_quiet_nan)
  end do
  v(5) = ieee_value(1.0, ieee_positive_inf)
  ch = count(ieee_is_nan(v))
  cd = 0
!$acc parallel loop copyin(v) reduction(+:cd)
  do i = 1, n
    if (v(i) /= v(i)) cd = cd + 1
  end do
  if (cd == ch .and. ch > 0) then
    print '(a,i0,a)', 'PROBE F-NAN PASS (', cd, ' NaNs found with x /= x on the device)'
  else
    print '(a,i0,a,i0)', 'PROBE F-NAN FAIL (device ', cd, ', host ', ch
  end if
end program
