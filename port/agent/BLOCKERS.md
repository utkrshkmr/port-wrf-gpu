# Blockers

Problems the coding agent cannot solve alone and that need the project owner: a tool or test that seems wrong, a
missing input, a compiler limitation that the fallbacks of plan.md §15 do not cover, a failure that DEBUGGING.md
could not explain after three honest attempts. Rules: [WORKFLOW.md](WORKFLOW.md) §8–9. Newest last. Mark resolved
entries `[resolved <date>: <how>]`; never delete them.

Format:

```
## B<n> <YYYY-MM-DD> <short title>   [open]
- Task / kernel: ...
- What happens (command and output): ...
- What was tried: ...
- What is needed: ...
```

## B1 2026-10-10 Storage for $WORK on the A100 workstation   [resolved 2026-10-10: the owner freed space (171 GB free on /home); $WORK = <checkout>/work]
- Task / kernel: S0-04 onwards (toolchain, builds, cases, references); S0-00 itself needs only a few MB.
- What happens (command and output): `df -h /home` -> `/dev/md0 7.3T 6.9T 7.8G 100% /home`; `/` has 85 GB free but
  no user directory; `/data` is root-owned. ENV_H100.md §1 asks for >= 300 GB for `$WORK` (image ~10 GB, NVHPC
  builds 30-90 min each, the dev and acceptance references).
- What was tried: `$WORK=/home/csgrad/utkarshk/wrf_gpu_work` for the machine records and gate logs only.
- What is needed: the owner names a directory with >= 300 GB free (or frees space on `/home`); then set `WORK` in
  `port/h100/env.local.sh` and ENV_H100.md §2a.

## B2 2026-10-10 No usable container runtime or NVHPC on the A100 workstation   [resolved 2026-10-10: the owner installed NVHPC SDK 26.5 natively in <checkout>/Linux_x86_64/26.5; CONTAINER=none]
- Task / kernel: S0-04.1 (NVHPC), and so S0-05 ... S0-13 (everything that compiles with nvfortran).
- What happens (command and output): `which apptainer singularity podman` -> nothing; `docker info` -> "permission
  denied while trying to connect to the Docker daemon socket" (user not in the docker group); no
  `/opt/nvidia/hpc_sdk`, no `module` command. Present: CUDA 11.4/11.8/13.x toolkits, nsight-systems,
  nsight-compute, gfortran 11.4, system mpif90, driver 595.91.07 (CUDA 13.2).
- What was tried: S0-00 runs with `CONTAINER=none`, nvidia-smi on the host; `t_machine.sh` records S0-04/05/06 as
  pending.
- What is needed (owner decides one): (a) add the user to the `docker` group (then `CONTAINER=docker`, image
  `nvcr.io/nvidia/nvhpc:25.1-devel-cuda12.6-ubuntu22.04`); or (b) install Apptainer (unprivileged install is
  possible if user namespaces are enabled); or (c) install the NVHPC SDK 25.1 tarball natively without root into
  `$WORK` (`CONTAINER=none`, `NVHPC_ROOT=...`; ~12 GB, needs B1 first). Driver 595 supports CUDA 12.6 images.

## B3 2026-10-10 T-MINMAX and T-IPOW fail on the A100s with nvfortran 26.5   [resolved 2026-10-11: the plan's remedy (owner's choice): rp_max/rp_min and integer powers as products, shared refactor 75c28b7 + 1f1f452, base moved (REFACTORS.md); NVHPC 25.1 behaves the same]
- Task / kernel: S0-06.2, S0-06.5 (gate S0-06, G0); affects every kernel with MIN/MAX of possibly signed zeros and
  every integer power.
- What happens (command and output): `port/tests/repro_math/run_tests.sh` on GPU 0 and GPU 1 (identical):
  `FAIL T-SIGNZERO/T-MINMAX/T-SUBNORM specials REAL(4) 3 of 6912 differ` (MIN/MAX of +0/−0 return different zeros
  on host and device) and `FAIL T-IPOW ... 3984817592 of 6576668672 differ`. Diagnosis in RESULTS.md: the host
  calls LIBNVCPUMATH power routines (`__py_powi1_4`, `__pmth_i_dpowi`, ...), the device multiplies. T-FMA, T-IEEE,
  T-RM-EXH/POW/D and run_ref_tests.sh pass.
- What was tried: reproduced on both GPUs and in a 30-line program (`$WORK/s0-06/ipow/ip.F90`); `nm` shows the
  host library calls. Not tried: NVHPC 25.1 (the plan's pinned version; 26.5 is installed), host flags that
  inline integer powers.
- What is needed (owner decides): (a) apply the plan's remedies: `rp_min`/`rp_max`(/`rp_sign`) with IEEE
  branches and integer powers as explicit products, in the locked `module_repro_math.F` and substituted in the
  in-scope files (a shared refactor certified in S0-12); or (b) first check whether NVHPC 25.1 (the pin) behaves
  differently, then decide; (c) both. Until then S0-06 and the machine-change protocol (step b) stay FAIL, and
  GPU gates refuse to run on this machine (`machine.sh check`).

## B4 2026-10-11 nvfortran 26.5 cannot build WRF at the CPU-REF flags   [resolved 2026-10-11: NVHPC 25.1 (the plan's pin) installed in <checkout>/Linux_x86_64/25.1 builds CPU-REF completely; env.local.sh uses it; 26.5 stays installed, unused]
- Task / kernel: S0-07.1 (CPU-REF build), and every NVHPC build.
- What happens (command and output): `build.sh cpu-ref --worktree` -> `nvfortran-Fatal-.../tools/fort2 TERMINATED
  by signal 11` on 12 files at `-O2` (module_dm, module_bittrace, module_cpl, module_optional_input, mediation_integrate,
  module_wrf_top, real_em, module_initialize_real, module_madwrf, tc_em, solve_em, nest_init_utils; list in
  `$WORK/logs/crash_files.txt`), reproducible serially, with plain nvfortran too, gone at -O1/-O0; and
  `NVFORTRAN-S-0038-Symbol, isnan, has not been explicitly declared` (module_wind_mav.F: 26.5 dropped the `isnan`
  extension).
- What was tried: 16 instead of 56 make jobs (same crashes); bisection of the flags (only -O2 matters; -O2 is locked
  by check_build_flags.py); isnan -> `ieee_is_nan` in module_wind_mav.F (standard Fortran, in the B3 refactor).
- What is needed: NVHPC 25.1, the version the plan pins (ENV_H100.md §1), is being installed next to 26.5
  (`<checkout>/Linux_x86_64/25.1`) to check the build, T-IPOW and T-MINMAX with it; the owner then chooses the pin.

