! F-OPT (S0-05.5): an OPTIONAL argument of an "acc routine seq" (PRESENT() on the device).
module f_opt_m
  implicit none
contains
  real function q(x, s)
!$acc routine seq
    real, intent(in) :: x
    real, intent(in), optional :: s
    if (present(s)) then
      q = x*s
    else
      q = x
    end if
  end function
end module
program f_opt
  use f_opt_m
  implicit none
  integer, parameter :: n = 1024
  real :: x(n), y1(n), y2(n)
  integer :: i
  x = [(real(i), i = 1, n)]
!$acc parallel loop copyin(x) copyout(y1, y2)
  do i = 1, n
    y1(i) = q(x(i), 2.0)
    y2(i) = q(x(i))
  end do
  if (all(y1 == 2.0*x) .and. all(y2 == x)) then
    print '(a)', 'PROBE F-OPT PASS (OPTIONAL argument in device code)'
  else
    print '(a)', 'PROBE F-OPT FAIL'
  end if
end program
