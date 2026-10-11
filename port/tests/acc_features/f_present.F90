! F-PRESENT (S0-05.4): a pointer bounds-remapped onto a device-resident work
! (pool) array is passed to an explicit-shape dummy and found "present" there
! (P1.6/P1.7).
module f_present_m
  implicit none
contains
  subroutine work(a, ni, nj)
    integer, intent(in) :: ni, nj
    real, intent(inout) :: a(ni, nj)
    integer :: i, j
!$acc parallel loop collapse(2) present(a)
    do j = 1, nj
      do i = 1, ni
        a(i, j) = real(i) + 1000.*real(j)
      end do
    end do
  end subroutine
end module
program f_present
  use f_present_m
  implicit none
  integer, parameter :: ni = 37, nj = 53, off = 101
  real, target, allocatable :: pool(:)
  real, pointer :: p(:, :)
  integer :: i, j, bad
  allocate(pool(off + ni*nj + 50)); pool = -1.
!$acc enter data copyin(pool)
  p(1:ni, 1:nj) => pool(off + 1:off + ni*nj)
  call work(p, ni, nj)
!$acc update host(pool)
  bad = 0
  do j = 1, nj
    do i = 1, ni
      if (pool(off + i + (j - 1)*ni) /= real(i) + 1000.*real(j)) bad = bad + 1
    end do
  end do
  if (any(pool(1:off) /= -1.) .or. any(pool(off + ni*nj + 1:) /= -1.)) bad = bad + 1
!$acc exit data delete(pool)
  if (bad == 0) then
    print '(a)', 'PROBE F-PRESENT PASS (remapped pool pointer found present through an explicit-shape dummy)'
  else
    print '(a,i0)', 'PROBE F-PRESENT FAIL (bad elements ', bad
  end if
end program
