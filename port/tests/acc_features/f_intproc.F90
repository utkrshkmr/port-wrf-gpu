! F-INTPROC (S0-05.5): an internal procedure called from a device loop.
program f_intproc
  implicit none
  integer, parameter :: n = 2048
  real :: x(n), yd(n), yh(n)
  integer :: i
  x = [(0.01*i, i = 1, n)]
  do i = 1, n
    yh(i) = h(x(i))
  end do
!$acc parallel loop copyin(x) copyout(yd)
  do i = 1, n
    yd(i) = h(x(i))
  end do
  if (all(transfer(yd, 1, n) == transfer(yh, 1, n))) then
    print '(a)', 'PROBE F-INTPROC PASS (internal procedure in device code; bitwise)'
  else
    print '(a)', 'PROBE F-INTPROC FAIL'
  end if
contains
  real function h(z)
!$acc routine seq
    real, intent(in) :: z
    h = 2.0*z + 0.5
  end function
end program
