! F-STMTFN (S0-05.5): a statement function used inside a device loop.
program f_stmtfn
  implicit none
  integer, parameter :: n = 2048
  real :: x(n), yd(n), yh(n), g, z
  integer :: i
  g(z) = 3.0*z*z - 1.0
  x = [(0.01*i, i = 1, n)]
  do i = 1, n
    yh(i) = g(x(i))
  end do
!$acc parallel loop copyin(x) copyout(yd)
  do i = 1, n
    yd(i) = g(x(i))
  end do
  if (all(transfer(yd, 1, n) == transfer(yh, 1, n))) then
    print '(a)', 'PROBE F-STMTFN PASS (statement function in device code; bitwise)'
  else
    print '(a)', 'PROBE F-STMTFN FAIL'
  end if
end program
