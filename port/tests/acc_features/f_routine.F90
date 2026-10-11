! F-ROUTINE (S0-05.2): an "acc routine seq" callee reads a module PARAMETER
! array and module "declare create" scalars and arrays (B4 form; tables).
module f_routine_m
  implicit none
  real, parameter :: ptab(4) = [1.5, 2.5, 3.5, 4.5]
  real :: sscal
  real :: darr(4)
!$acc declare create(sscal, darr)
contains
  real function f(x, k)
!$acc routine seq
    real, intent(in) :: x
    integer, intent(in) :: k
    f = x*ptab(k) + sscal*darr(k)
  end function
end module
program f_routine
  use f_routine_m
  implicit none
  integer, parameter :: n = 4096
  real :: x(n), yd(n), yh(n)
  integer :: i
  x = [(0.001*i, i = 1, n)]
  sscal = 0.75; darr = [10., 20., 30., 40.]
!$acc update device(sscal, darr)
  do i = 1, n
    yh(i) = f(x(i), mod(i, 4) + 1)
  end do
!$acc parallel loop copyin(x) copyout(yd)
  do i = 1, n
    yd(i) = f(x(i), mod(i, 4) + 1)
  end do
  if (all(transfer(yd, 1, n) == transfer(yh, 1, n))) then
    print '(a)', 'PROBE F-ROUTINE PASS (routine seq reads PARAMETER and declare-create module data; bitwise)'
  else
    print '(a,i0)', 'PROBE F-ROUTINE FAIL (differing values: ', count(yd /= yh)
  end if
end program
