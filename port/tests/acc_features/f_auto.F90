! F-AUTO, F-PRIVARR (S0-05.12): an automatic array in an "acc routine seq", and a
! runtime-sized private array in a kernel (CP-3).
module f_auto_m
  implicit none
contains
  real function colsum(x, nk)
!$acc routine seq
    integer, intent(in) :: nk
    real, intent(in) :: x(nk)
    real :: w(nk)
    integer :: k
    do k = 1, nk
      w(k) = 2.0*x(k)
    end do
    colsum = 0.
    do k = 1, nk
      colsum = colsum + w(k)
    end do
  end function
end module
program f_auto
  use f_auto_m
  implicit none
  integer :: nk, ncol, i, k
  real, allocatable :: x(:, :), yd(:), yh(:), y2(:), tmp(:)
  nk = 60; ncol = 5000
  allocate(x(nk, ncol), yd(ncol), yh(ncol), y2(ncol), tmp(nk))
  do i = 1, ncol
    do k = 1, nk
      x(k, i) = 0.001*real(k) + real(i)
    end do
  end do
  do i = 1, ncol
    yh(i) = colsum(x(:, i), nk)
  end do
!$acc parallel loop copyin(x) copyout(yd)
  do i = 1, ncol
    yd(i) = colsum(x(:, i), nk)
  end do
  if (all(transfer(yd, 1, ncol) == transfer(yh, 1, ncol))) then
    print '(a)', 'PROBE F-AUTO PASS (automatic array in a routine seq; bitwise)'
  else
    print '(a)', 'PROBE F-AUTO FAIL'
  end if
!$acc parallel loop copyin(x) copyout(y2) private(tmp)
  do i = 1, ncol
    do k = 1, nk
      tmp(k) = 2.0*x(k, i)
    end do
    y2(i) = 0.
    do k = 1, nk
      y2(i) = y2(i) + tmp(k)
    end do
  end do
  if (all(transfer(y2, 1, ncol) == transfer(yh, 1, ncol))) then
    print '(a)', 'PROBE F-PRIVARR PASS (runtime-sized private array; bitwise)'
  else
    print '(a)', 'PROBE F-PRIVARR FAIL'
  end if
end program
