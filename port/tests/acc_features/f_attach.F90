! F-ATTACH (S0-05.9): "enter data copyin" of a derived type, then of its pointer
! component (attached), used in a kernel through the parent (fp of WRF-Fire, I-12).
module f_attach_m
  implicit none
  type fire_params
    real, pointer :: fuel(:, :) => null()
    real :: scale = 1.0
  end type
end module
program f_attach
  use f_attach_m
  implicit none
  integer, parameter :: ni = 64, nj = 48
  type(fire_params) :: fp
  real, allocatable, target :: store(:, :)
  integer :: i, j
  allocate(store(ni, nj)); store = 1.0
  fp%fuel => store
  fp%scale = 3.0
!$acc enter data copyin(fp)
!$acc enter data copyin(fp%fuel)
!$acc parallel loop collapse(2) present(fp)
  do j = 1, nj
    do i = 1, ni
      fp%fuel(i, j) = fp%fuel(i, j)*fp%scale + real(i + j)
    end do
  end do
!$acc exit data copyout(fp%fuel)
!$acc exit data delete(fp)
  if (all(store == reshape([((3.0 + real(i + j), i = 1, ni), j = 1, nj)], [ni, nj]))) then
    print '(a)', 'PROBE F-ATTACH PASS (derived type + attached pointer component)'
  else
    print '(a)', 'PROBE F-ATTACH FAIL'
  end if
end program
