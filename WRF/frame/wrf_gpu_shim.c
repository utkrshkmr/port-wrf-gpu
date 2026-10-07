/*
   wrf_gpu_shim.c -- C side of module_gpu_prof (plan.md P1.10, P1.12;
   port/agent/INTERFACES.md I-7; work package P1-PROF).

   Compiled in every build.  Without WRF_GPU every function does nothing
   (wrf_gpu_mem_info_c returns 1 = not available).  Under WRF_GPU:
     wrf_nvtx_push_c / wrf_nvtx_pop_c   NVTX3 header-only API
                                         (#include <nvtx3/nvToolsExt.h>; when the
                                         header is not found at compile time,
                                         keep the empty versions)
     wrf_gpu_mem_info_c                 cuMemGetInfo_v2 through dlopen("libcuda.so.1")
                                         (no link-time CUDA dependency; link -ldl)
*/
#include <stddef.h>

void wrf_nvtx_push_c(const char *name)
{
  (void)name;
  /* TODO(P1-PROF) */
}

void wrf_nvtx_pop_c(void)
{
  /* TODO(P1-PROF) */
}

int wrf_gpu_mem_info_c(size_t *free_b, size_t *total_b)
{
  *free_b = 0;
  *total_b = 0;
  /* TODO(P1-PROF): return 0 after a successful cuMemGetInfo_v2 */
  return 1;
}
