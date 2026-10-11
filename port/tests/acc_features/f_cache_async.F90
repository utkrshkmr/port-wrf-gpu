! F-CACHE, F-ASYNC (S0-05.11): "acc cache" and async/wait are accepted and leave
! the bits unchanged (Stage 6).
program f_cache_async
  implicit none
  integer, parameter :: n = 1000000
  real, allocatable :: a(:), b0(:), b1(:), b2(:)
  integer :: i
  allocate(a(0:n + 1), b0(n), b1(n), b2(n))
  a = [(sin(0.001*real(i)), i = 0, n + 1)]
!$acc data copyin(a) create(b0, b1, b2)
!$acc parallel loop present(a, b0)
  do i = 1, n
    b0(i) = 0.25*a(i - 1) + 0.5*a(i) + 0.25*a(i + 1)
  end do
!$acc parallel loop present(a, b1)
  do i = 1, n
!$acc cache(a(i - 1:i + 1))
    b1(i) = 0.25*a(i - 1) + 0.5*a(i) + 0.25*a(i + 1)
  end do
!$acc parallel loop present(a, b2) async(1)
  do i = 1, n
    b2(i) = 0.25*a(i - 1) + 0.5*a(i) + 0.25*a(i + 1)
  end do
!$acc wait(1)
!$acc update host(b0, b1, b2)
!$acc end data
  if (all(transfer(b1, 1, n) == transfer(b0, 1, n))) then
    print '(a)', 'PROBE F-CACHE PASS (cache directive bit-neutral)'
  else
    print '(a)', 'PROBE F-CACHE FAIL'
  end if
  if (all(transfer(b2, 1, n) == transfer(b0, 1, n))) then
    print '(a)', 'PROBE F-ASYNC PASS (async/wait bit-neutral)'
  else
    print '(a)', 'PROBE F-ASYNC FAIL'
  end if
end program
