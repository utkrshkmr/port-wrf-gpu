!WRF:DRIVER_LAYER:UTIL
!
! module_gpu_prof: NVTX ranges, device memory information, the timing log and
! the memory log of the GPU port (plan.md P1.10-P1.12; port/agent/INTERFACES.md
! I-7; work package P1-PROF).  The C side is WRF/frame/wrf_gpu_shim.c.
!
! Interface (fixed; P1-SYNC places the calls, bench_solve_em_def.h uses the
! NVTX pair):
!   wrf_nvtx_push(name), wrf_nvtx_pop()     NVTX range (no-op without WRF_GPU)
!   gpu_mem_log(where)      prints "gpu_mem: <where> used <X> GB free <Y> GB
!                           total <Z> GB peak <P> GB" (P1.12; no-op without WRF_GPU)
!   gpu_timing_step(id, hour, done)  called by solve_em once per call with the
!                           domain id and the simulated hour of the step;
!                           when WRF_GPU_TIMING=1 prints, per simulated hour and
!                           domain, "gpu_timing: d0N hour H wall_s S range
!                           <name> <s> ..." (P1.11); done=.TRUE. flushes
!
MODULE module_gpu_prof

   USE iso_c_binding
   IMPLICIT NONE
   PRIVATE

   PUBLIC :: wrf_nvtx_push, wrf_nvtx_pop, gpu_mem_log, gpu_timing_step

   INTERFACE
      SUBROUTINE wrf_nvtx_push_c(name) BIND(C, NAME='wrf_nvtx_push_c')
         IMPORT :: C_CHAR
         CHARACTER(KIND=C_CHAR), DIMENSION(*), INTENT(IN) :: name
      END SUBROUTINE wrf_nvtx_push_c
      SUBROUTINE wrf_nvtx_pop_c() BIND(C, NAME='wrf_nvtx_pop_c')
      END SUBROUTINE wrf_nvtx_pop_c
      INTEGER(C_INT) FUNCTION wrf_gpu_mem_info_c(free_b, total_b) BIND(C, NAME='wrf_gpu_mem_info_c')
         IMPORT :: C_INT, C_SIZE_T
         INTEGER(C_SIZE_T), INTENT(OUT) :: free_b, total_b
      END FUNCTION wrf_gpu_mem_info_c
   END INTERFACE

CONTAINS

   SUBROUTINE wrf_nvtx_push(name)
      CHARACTER(LEN=*), INTENT(IN) :: name
      ! TODO(P1-PROF): under WRF_GPU, CALL wrf_nvtx_push_c(TRIM(name)//C_NULL_CHAR)
   END SUBROUTINE wrf_nvtx_push

   SUBROUTINE wrf_nvtx_pop()
      ! TODO(P1-PROF): under WRF_GPU, CALL wrf_nvtx_pop_c()
   END SUBROUTINE wrf_nvtx_pop

   SUBROUTINE gpu_mem_log(where)
      CHARACTER(LEN=*), INTENT(IN) :: where
      ! TODO(P1-PROF): under WRF_GPU, wrf_gpu_mem_info_c, track the peak, print the gpu_mem line
   END SUBROUTINE gpu_mem_log

   SUBROUTINE gpu_timing_step(id, hour, done)
      INTEGER, INTENT(IN) :: id, hour
      LOGICAL, INTENT(IN) :: done
      ! TODO(P1-PROF): when WRF_GPU_TIMING=1 (read once), accumulate and print per hour and domain
   END SUBROUTINE gpu_timing_step

END MODULE module_gpu_prof
