program hello
  implicit none
  integer, parameter :: n = 1024
  real :: a(n), b(n), c(n)
  integer :: i
  a = 1.5; b = 2.25; c = 0.
!$acc parallel loop copyin(a,b) copyout(c)
  do i = 1, n
    c(i) = a(i)*b(i) + 1.0
  end do
  print '(a,f10.4)', 'c(n)=', c(n)
end program
