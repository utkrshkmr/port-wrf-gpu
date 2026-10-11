! F-STACK (S0-05.8): NV_ACC_CUDA_STACKSIZE applies; the limit is read back with
! cudaDeviceGetLimit after the OpenACC runtime is initialized (CP-5).
! run_probes.sh runs it with NV_ACC_CUDA_STACKSIZE=65536.
program f_stack
  use cudafor
  use openacc
  implicit none
  integer(kind=cuda_count_kind) :: lim
  integer :: ist, want, i
  character(len=32) :: env
  real :: a(16)
  a = 1.0
!$acc parallel loop copy(a)
  do i = 1, 16
    a(i) = a(i) + 1.0
  end do
  call get_environment_variable('NV_ACC_CUDA_STACKSIZE', env)
  want = 0
  if (len_trim(env) > 0) read(env, *) want
  ist = cudaDeviceGetLimit(lim, cudaLimitStackSize)
  if (ist == 0 .and. want > 0 .and. lim >= want) then
    print '(a,i0,a,i0,a)', 'PROBE F-STACK PASS (stack limit ', lim, ' >= NV_ACC_CUDA_STACKSIZE ', want, ')'
  else
    print '(a,i0,a,i0,a,i0)', 'PROBE F-STACK FAIL (status ', ist, ', limit ', lim, ', requested ', want
  end if
end program
