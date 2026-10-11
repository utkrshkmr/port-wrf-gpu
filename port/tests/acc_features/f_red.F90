! F-RED (S0-05.6): reduction(+:) and reduction(ieor:) on INTEGER(8), reduction(max:) on REAL
! (bit tracer, NaN counts).  Integer reductions are exact; max is order-independent.
program f_red
  implicit none
  integer, parameter :: n = 3000000
  integer(8) :: s, x, sh, xh
  real :: m, mh
  real, allocatable :: v(:)
  integer :: i
  allocate(v(n))
  do i = 1, n
    v(i) = real(mod(int(i, 8)*7919_8, 100003_8)) * 0.37
  end do
  sh = 0; xh = 0; mh = -huge(1.0)
  do i = 1, n
    sh = sh + int(transfer(v(i), 1), 8)
    xh = ieor(xh, int(transfer(v(i), 1), 8)*int(i, 8))
    mh = max(mh, v(i))
  end do
  s = 0; x = 0; m = -huge(1.0)
!$acc parallel loop copyin(v) reduction(+:s) reduction(ieor:x) reduction(max:m)
  do i = 1, n
    s = s + int(transfer(v(i), 1), 8)
    x = ieor(x, int(transfer(v(i), 1), 8)*int(i, 8))
    m = max(m, v(i))
  end do
  if (s == sh .and. x == xh .and. transfer(m, 1) == transfer(mh, 1)) then
    print '(a)', 'PROBE F-RED PASS (INTEGER(8) + and ieor, REAL max: equal to the host)'
  else
    print '(a,3l2)', 'PROBE F-RED FAIL (+, ieor, max equal:', s == sh, x == xh, m == mh
  end if
end program
