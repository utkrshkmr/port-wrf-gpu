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
