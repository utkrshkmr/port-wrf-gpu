# ADR-001: GPU programming model

- Status: **decided** (2026-10-06)
- Scope: every GPU port in this repository (WRF 4.6.0, WRF 4.8.0, WRF-Fire, CFBM), for NVIDIA, AMD and Intel GPUs.

## Decision

**One source: Fortran with OpenMP 5.x `target` offload directives, the subset the port already uses and the
compiler probes verify (`port/tests/omp_features`).** No CUDA C, no HIP/CUDA rewrite, no C++ layer (Kokkos, SYCL,
RAJA), no OpenACC.

| Vendor | Compiler (Fortran + OpenMP offload) | Status in this project |
|---|---|---|
| NVIDIA (A100, H100, newer) | NVHPC `nvfortran -mp=gpu` | primary target; the build stanzas exist |
| AMD (MI250X, MI300A/X) | AMD `amdflang` (LLVM Flang, ROCm) or HPE Cray `ftn` (CCE) | second target; probes and stanzas still to write (backlog track G) |
| Intel (Data Center GPU Max) | Intel `ifx -fiopenmp -fopenmp-targets=spir64` | possible later; not planned |
| CPU (reference) | `nvfortran`, `gfortran` (CPU-REF, `gnu-ref`, `gnu-gpu` checks) | in use |

**Escape hatch, used only where measured to matter.** A single kernel may get a native implementation (CUDA or HIP,
called through `ISO_C_BINDING`) when all of these hold:

1. profiling shows the OpenMP version is the bottleneck;
2. the native version is at least 2× faster on the whole step, not just the kernel;
3. it is bit-identical to the OpenMP version in REPRO mode (ADR-003).

The OpenMP version stays, as the reference and the fallback for other vendors. Each such kernel is recorded in this
file.

## Why

- **WRF is Fortran.**
  - The port touches a few hundred thousand lines of a code base of over a million.
  - A C++ performance-portability rewrite (Kokkos, SYCL, RAJA, HIP) would be a multi-year rewrite. It would lose the
    line-by-line correspondence with NCAR's source that the bit-for-bit method and the forward ports (ADR-002) rely on,
    and NCAR could not take it upstream.
  - The same holds for CFBM: about 13,000 lines of modern Fortran.
- **OpenMP offload is the only standard that every GPU vendor supports in its own Fortran compiler.**
  - OpenACC: strong on NVIDIA; on AMD only through HPE Cray and GCC.
  - CUDA Fortran: NVIDIA only.
  - `do concurrent` with `-stdpar`: no control over data placement, and uneven support across vendors.
  - NCAR's own GPU work on MPAS uses OpenACC. That works for an NVIDIA-first code. It is not this project's goal: any
    GPU, NVIDIA first.
- **Bit-for-bit reproducibility needs control the compiler must honour**: no FMA contraction, IEEE behaviour, our own
  elementary functions (`module_repro_math`). OpenMP keeps the arithmetic in the Fortran source, where `arith_guard`
  can check it. The same rules apply on AMD (`-ffp-contract=off` and the probes T-FMA, T-IEEE).
- **No programming model guarantees performance on every GPU.** Performance portability is measured, kernel by kernel
  and vendor by vendor (backlog tracks P and G). The decision is about the source: one source we can verify and keep
  aligned with NCAR. Tuning happens through clauses, loop structure, data layout and, rarely, the escape hatch.

## Risks and how we handle them

| Risk | Mitigation |
|---|---|
| A compiler mis-compiles or rejects a construct (for example nvfortran S-1054, blocker B4) | Feature probes per compiler and version (`port/tests/omp_features`), run before any port work on a new compiler; use only probed constructs. |
| AMD Fortran OpenMP offload is less mature than NVIDIA's | Probes on AMD hardware first (task G-01). If `amdflang` fails a required probe, use HPE CCE where available, and file compiler bugs with minimal reproducers. |
| OpenMP kernels slower than native ones | Measure (track P); tune clauses, data layout and launch configuration; use the escape hatch only under its three conditions. |
| Many small kernels: launch latency dominates | Fusing kernels where it keeps the arithmetic (bit-neutral), asynchronous launches (`nowait`/`depend`), fewer host round trips (Phase 5 device world). |

## What would reopen this decision

- A required feature (for example `declare target` on module data, or deep-copy-free mapping) cannot be made to work
  on a target vendor's compilers after the probes and vendor bug reports.
- Measured performance stays below the CPU baseline on a target GPU after the tuning of track P, for reasons that only
  a native programming model can fix.
