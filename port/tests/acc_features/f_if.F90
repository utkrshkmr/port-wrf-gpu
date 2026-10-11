! F-IF (S0-05.1): "parallel loop if(.false.)" runs on the host, with host data
! and no data clause; decides the T-AB method (kernel_off).
program f_if
  use openacc
  implicit none
  integer, parameter :: n = 1000
  real :: a(n), b(n)
  integer :: onhost(n), i
  logical :: off
  a = [(real(i), i = 1, n)]; b = 0.; onhost = 0
  off = .false.
!$acc parallel loop if(off)
  do i = 1, n
    b(i) = 2.0*a(i)
    if (acc_on_device(acc_device_host)) onhost(i) = 1
  end do
  if (all(b == 2.0*a) .and. all(onhost == 1)) then
    print '(a)', 'PROBE F-IF PASS (if(.false.) ran on the host with host data)'
  else
    print '(a,i0,a,l1)', 'PROBE F-IF FAIL (host iterations ', sum(onhost), ', values ok ', all(b == 2.0*a)
  end if
end program
