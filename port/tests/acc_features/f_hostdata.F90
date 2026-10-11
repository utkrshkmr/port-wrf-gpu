! F-HOSTDATA (S0-05.10): "host_data use_device" passes OpenACC device data to a
! CUDA Fortran kernel (the CUDA Fortran escape hatch, ADR-001).
module f_hostdata_m
  use cudafor
  implicit none
contains
  attributes(global) subroutine twice(a, n)
    integer, value :: n
    real, device :: a(n)
    integer :: i
    i = (blockIdx%x - 1)*blockDim%x + threadIdx%x
    if (i <= n) a(i) = 2.0*a(i) + 1.0
  end subroutine
end module
program f_hostdata
  use f_hostdata_m
  implicit none
  integer, parameter :: n = 10000
  real :: a(n), ref(n)
  integer :: i, ist
  a = [(real(i), i = 1, n)]
  ref = 2.0*a + 1.0
!$acc data copy(a)
!$acc host_data use_device(a)
  call twice<<<(n + 127)/128, 128>>>(a, n)
!$acc end host_data
  ist = cudaDeviceSynchronize()
!$acc end data
  if (all(a == ref)) then
    print '(a)', 'PROBE F-HOSTDATA PASS (host_data use_device into a CUDA Fortran kernel)'
  else
    print '(a)', 'PROBE F-HOSTDATA FAIL'
  end if
end program
