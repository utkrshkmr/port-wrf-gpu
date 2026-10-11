# Environment of the GPU port (plan.md P0.0, P0.1)

Fill in as the Phase 0 steps are done; every comparison in `RESULTS.md` refers to an image and binaries listed here.

## Container image

| Item | Value |
|---|---|
| Definition | `port/container/wrf-gpu.def` |
| NVHPC tag (`--build-arg NVHPC_TAG`) | |
| `.sif` sha256 | |
| `/opt/versions.txt` (nvfortran, MPI, netCDF, Python packages) | |

## Build flags (plan.md §4)

| Mode | Stanza (`./configure`) | Fortran | Device | cpp |
|---|---|---|---|---|
| CPU-REF | NVHPC ... GPU port CPU-REF (dmpar) | `-O2 -Kieee -Mnofma -Mnoflushz -Mnodaz -Mvect=noassoc -tp=haswell -Mrecursive` | – | `-DREPRO_MATH -DWRF_POOL` |
| GPU-REPRO | NVHPC ... GPU port GPU-REPRO | same | `-mp=gpu -gpu=cc80,cc90,nofma,noflushz -Minfo=mp` | + `-DWRF_GPU` |
| GPU-DEBUG | NVHPC ... GPU port GPU-DEBUG | same + `-g -traceback` | + `-gpu=lineinfo` | + `-DWRF_TRACE_FINE` |

`-Mrecursive` (locals on the stack) is used in all three so that host code has the same storage semantics in the
CPU reference and in the GPU build.

Flag spelling check against the pinned NVHPC (`nvfortran -help`, `nvfortran -help -gpu`): _to do_.

## Nodes

| Use | Node type | CPU | GPU | Driver |
|---|---|---|---|---|
| CPU-REF | CCR | | – | – |
| GPU A100 | | | A100 80 GB | |
| GPU H100 | | | H100 80 GB | |

## Compiler feature probes (P0.5b, T-OMP-FEAT)

Paste `port/tests/omp_features/probes_<host>_<date>.md` for the A100 and the H100 node here, and the decisions:

| Probe | A100 | H100 | Decision |
|---|---|---|---|
| F-IFTARGET | | | |
| F-CALLS | | | |
| F-DECLMOD | | | |
| F-PRESENT | | | |
| F-DEFMAP (+ negative) | | | |
| F-PRIVARR | | | |
| F-AUTO | | | |
| F-STMTFN, F-INTPROC, F-OPT, F-CHAR | | | |
| F-RED, F-NAN | | | |
| F-STACK (stack limit, NV_ACC_CUDA_STACKSIZE) | | | |

## Local development machine (Phase 0 work in this repository)

The Phase 0 code was developed in a container without NVHPC or a GPU (the NVIDIA download site is not reachable
from it). Host-side checks there used gfortran 13 (Ubuntu 24.04), netCDF-Fortran 4.5.4, Python 3 with numpy,
netCDF4 and mpmath. See `RESULTS.md`, "Local results".

## GPU-M: the A100 workstation (profile `a100-40x2`, machine `3817a30133b2`; S0-04)

Checkout `/home/csgrad/utkarshk/port-wrf-gpu`, `$WORK` = `/home/csgrad/utkarshk/port-wrf-gpu/work` (git-ignored).
Settings: `port/h100/env.local.sh` (not in git); ENV_H100.md §2a.

| Item | Value |
|---|---|
| Toolchain | **NVHPC SDK 25.1 installed natively** in `<checkout>/Linux_x86_64/25.1` (`CONTAINER=none`, `NVHPC_ROOT`, `DEPS=$WORK/deps-25.1`), the plan's pinned version, since 2026-10-11. 26.5 (the owner's first install, `<checkout>/Linux_x86_64/26.5`) crashes on 12 WRF files at -O2 (BLOCKERS B4) and is not used; results marked 26.5 below are kept for the record |
| `nvfortran --version` | `nvfortran 25.1-0 64-bit target on x86-64 Linux -tp icelake-server` (26.5-0 before 2026-10-11) |
| CUDA (SDK) | 13.2 (`nvcc` V13.2.78) |
| MPI | HPC-X 2.50 / Open MPI 5.0.10rc2 of the SDK (the system Open MPI 4.1.2 in /usr/bin is not used: `x` puts the SDK first) (`comm_libs/mpi` → `hpcx`); `mpif90` wraps nvfortran |
| Driver | 595.91.07 (CUDA 13.2) |
| GPUs | 2 × NVIDIA A100-PCIE-40GB, cc 8.0, 108 SMs, 40960 MiB, ECC on, MIG off, max SM clock 1410 MHz, memory clock 1215 MHz, VBIOS 92.00.25.00.08; GPU0–GPU1 link `SYS` (PCIe across sockets, no NVLink) |
| Host | 2 × Intel Xeon Gold 6330 (28 cores each, 56 physical, 112 logical), 503 GB RAM; RAPL not readable by the user |
| Profilers | nsys 2026.2.1, ncu, compute-sanitizer (from the SDK) |
| `nvidia-smi -q` | `$WORK/logs/nvidia-smi-q.txt` |
| netCDF/HDF5 (nvfortran) | HDF5 1.14.4-3, netCDF-C 4.9.2, netCDF-Fortran 4.6.1 built with 25.1 in `$WORK/deps-25.1/netcdf`; gfortran netCDF-Fortran in `$WORK/deps-25.1/netcdf-gnu` |

### OpenACC feature probes (S0-05, `port/tests/acc_features/run.sh`): nvfortran 26.5 (2026-10-10) and 25.1 (2026-10-11), same results

Every probe built with the GPU-REPRO device flags and ran on **GPU 0 and GPU 1** (A100-PCIE-40GB) with the same
result; each device probe launched its kernel (checked with `NV_ACC_NOTIFY=1`), F-IF none (host), as intended.

| Probe | A100 (nvfortran 26.5) | Decides | gfortran 11.4 `-fopenacc` (host; compile check) |
|---|---|---|---|
| F-IF | PASS: `if(.false.)` runs on the host with host data | T-AB method (kernel_off) usable | PASS |
| F-ROUTINE | PASS: routine seq reads module PARAMETER and `declare create` data, bitwise | B4 form; tables | **build fails**: "‘ptab’ requires a ‘declare’ directive for use in a ‘routine’" |
| F-DECLARE | PASS: allocatable `declare create` + `update device` | P1.4 tables | PASS |
| F-PRESENT | PASS: remapped pool pointer present through an explicit-shape dummy | P1.6/P1.7 | PASS |
| F-STMTFN | PASS, bitwise | statement functions allowed in device code | PASS |
| F-INTPROC | PASS, bitwise | internal procedures allowed | PASS |
| F-OPT | PASS | OPTIONAL allowed | PASS |
| F-CHAR | PASS | CHARACTER arguments allowed | PASS |
| F-RED | PASS: INTEGER(8) `+`, `ieor`; REAL `max` equal to the host | tracer, NaN counts | PASS |
| F-NAN | PASS: `x /= x` finds NaNs under `-Kieee` | NaN checks | PASS |
| F-STACK | PASS: `NV_ACC_CUDA_STACKSIZE=65536` read back by `cudaDeviceGetLimit` | CP-5 | (device only) |
| F-ATTACH | PASS: derived type + attached pointer component | I-12 (`fp`) | PASS |
| F-HOSTDATA | PASS: `host_data use_device` into a CUDA Fortran kernel | escape hatch | (device only) |
| F-CACHE, F-ASYNC | PASS, bit-neutral | Stage 6 | PASS |
| F-AUTO, F-PRIVARR | PASS, bitwise | CP-3 | **ICE** in gfortran 11.4 (`expand_oacc_for`); CLOUD has gfortran 13: recheck there |
| **F-BOUND** | **FAIL** (known): `rp_min` in the inner bound of a `collapse(2)` loop with variable lower bounds and `default(none)` runs no iteration, silently, on 25.1 and 26.5; with a second kernel in the program it can work | **fallback:** MAX/MIN in DO-loop bounds stay intrinsics (rp_subst.py; INTEGER, exact); never call a procedure in a bound of a collapsed loop | PASS |

No fallback is needed on nvfortran 26.5. For the gfortran views (CLOUD, `gnu-gpu`): a module PARAMETER array read
in an `acc routine` needs `!$acc declare copyin(...)` or a local copy (run 1 used local PARAMETER tables, P1-B4, which
avoids it); F-AUTO/F-PRIVARR must be rechecked with gfortran 13. Reviewer: carry these into CODING_STANDARD.md.

