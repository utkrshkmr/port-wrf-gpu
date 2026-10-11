! F-CHAR (S0-05.5): a CHARACTER argument compared in device code (option
! strings of WRF routines).
module f_char_m
  implicit none
contains
  real function c(x, opt)
!$acc routine seq
    real, intent(in) :: x
    character(len=*), intent(in) :: opt
    if (opt(1:1) == 'a') then
      c = x + 1.0
    else
      c = x - 1.0
    end if
  end function
end module
program f_char
  use f_char_m
  implicit none
  integer, parameter :: n = 1024
  real :: x(n), y1(n), y2(n)
  integer :: i
  x = [(real(i), i = 1, n)]
!$acc parallel loop copyin(x) copyout(y1, y2)
  do i = 1, n
    y1(i) = c(x(i), 'add')
    y2(i) = c(x(i), 'sub')
  end do
  if (all(y1 == x + 1.0) .and. all(y2 == x - 1.0)) then
    print '(a)', 'PROBE F-CHAR PASS (CHARACTER argument in device code)'
  else
    print '(a)', 'PROBE F-CHAR FAIL'
  end if
end program
