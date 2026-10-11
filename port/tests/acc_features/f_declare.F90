! F-DECLARE (S0-05.3): "declare create" of an allocatable module array; the
! device copy follows ALLOCATE; "update device" fills it (P1.4 tables).
module f_declare_m
  implicit none
  real, allocatable :: tab(:)
!$acc declare create(tab)
end module
program f_declare
  use f_declare_m
  implicit none
  integer, parameter :: n = 10000
  real :: y(n)
  integer :: i
  logical :: pres
  allocate(tab(n))
  tab = [(sqrt(real(i)), i = 1, n)]
!$acc update device(tab)
!$acc parallel loop copyout(y) present(tab)
  do i = 1, n
    y(i) = tab(n + 1 - i)
  end do
  pres = .true.
  do i = 1, n
    if (transfer(y(i), 1) /= transfer(tab(n + 1 - i), 1)) pres = .false.
  end do
  if (pres) then
    print '(a)', 'PROBE F-DECLARE PASS (allocatable declare create + update device)'
  else
    print '(a)', 'PROBE F-DECLARE FAIL'
  end if
end program
