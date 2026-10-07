# Roadmap: WRF and WRF-Fire on GPUs, for everyone

**Aim:** an open, free, verified GPU version of WRF and its fire models, documented well enough that others can use it,
check it and extend it.

**Order of work (owner's decision, 2026-10-07):**
1. **Stage 1 (now): WRF 4.6.0 + WRF-Fire only**, on one NVIDIA GPU, bit-for-bit identical to the CPU reference. This
   is milestones M0–M3. Nothing of 4.8.0 or CFBM is started before it ends.
2. **Stage 2: WRF 4.8.0** (milestone M5).
3. **Stage 3: CFBM**, NCAR's new fire model (milestone M6).

Stage 1 ends when G5 passes (card A-29). It also ends if the owner records in ADR-002 that bitwise parity is impossible
for a stated reason and accepts the documented alternative. The backlog enforces the order: the first cards of tracks
V and C depend on A-29.

Alongside Stage 1, these do not touch 4.8.0 or CFBM:
- the book;
- the architecture study;
- the performance models;
- the AMD and multi-GPU preparation.

This directory holds the long-term plan. The detailed plan of the 4.6.0 port is [plan.md](../plan.md); its agent
instructions are [AGENTS.md](../AGENTS.md) and [port/agent/](../port/agent/README.md).

## The owner's goals and where each is handled

| # | Goal | Handled by |
|---|---|---|
| 0 | The 4.6.0 GPU port (plan.md) | Track A |
| 1 | Port 4.6 and later versions (4.8); understand NCAR's changes; compare | ADR-002; [analysis/wrf-4.6.0-to-4.8.0.md](analysis/wrf-4.6.0-to-4.8.0.md); Track V |
| 2 | Profile deeply; find the true performance and memory bottlenecks, on one and several GPUs | Track P (models, then measurements); Track M |
| 3 | Understand the design and stack of WRF and WRF-Fire; refactoring options | Track X |
| 4 | Port CFBM, NCAR's new fire model | [analysis/cfbm.md](analysis/cfbm.md); Track C |
| 5 | Run on any GPU: NVIDIA first, AMD if possible | ADR-001; Track G |
| 6 | Bottlenecks, mitigations, alternative algorithms (a GPU is not automatically faster) | ADR-003 (FAST mode); Track P (P-03 ... P-09, P-14, P-15) |
| 7 | A LaTeX textbook on WRF, WRF-Fire, their algorithms and implementation | [book/](../book/README.md); Track B |
| 8 | Small independent tasks within half a day's budget; a free release | [TASK_PROTOCOL.md](TASK_PROTOCOL.md); [BACKLOG.md](BACKLOG.md); Track R |
| 9 | A final decision on the GPU programming stack | [ADR-001](decisions/ADR-001-gpu-programming-model.md) |

## Decisions

| ADR | Decision | Status |
|---|---|---|
| [001](decisions/ADR-001-gpu-programming-model.md) | Fortran with OpenMP offload, one source for NVIDIA, AMD and Intel. No CUDA C rewrite; native kernels only as a measured escape hatch. | decided |
| [002](decisions/ADR-002-wrf-versions.md) | 4.6.0 first, then a forward port to 4.8.0 by three-way merge; submodules flattened. | decided |
| [003](decisions/ADR-003-repro-and-fast-modes.md) | REPRO (bit-for-bit, the default) and FAST (statistically validated) build modes from one source. | decided |
| 004 | License of the port's own files (card R-01). | open (owner) |
| 005 | Multi-GPU halo design (card M-03). | open |

## Milestones

| | Milestone | Main cards | Needs |
|---|---|---|---|
| | **Stage 1: WRF 4.6.0** | | |
| M0 | Phase 0 code written and checked locally (done); Phases 1–3 wired for code-only work (done); Phase 0 runs on CCR and the H100 machine | A-08, A-09, A-20 | ccr, data, gpu-nv |
| M1 | Phases 1–3 written by the code-only agent and **CPU-green** here (gfortran, S-3M bitwise, harness) | A-01 ... A-03, A-04, A-101 ... A-136 | cpu |
| M2 | Phases 1–3 pass their gates on the H100 (G1, G2, G3) | A-20 ... A-27 | gpu-nv, data |
| M3 | **v0.1**: WRF 4.6.0 + WRF-Fire on one NVIDIA GPU, bit-for-bit over the full 17 h Eaton run (G4, G5) | A-05, A-06, A-28, A-29, R-01 ... R-07 | gpu-nv, data, ccr |
| M4 | Performance understood and reported: models against measurements; FAST mode validated; tuned | P-* | gpu-nv |
| | **Stage 2: WRF 4.8.0** (after M3) | | |
| M5 | **v0.2**: WRF 4.8.0 with WRF-Fire (SFIRE), bit-for-bit | V-* | gpu-nv, data |
| | **Stage 3: CFBM** (after M5) | | |
| M6 | **v0.3**: CFBM on the GPU, standalone and inside WRF 4.8.0 | C-* | gpu-nv |
| | **Any stage** | | |
| M7 | AMD GPUs: same results (bitwise on REPRO) and performance numbers | G-* | gpu-amd |
| M8 | Several GPUs per run | M-* | gpu-nv |
| — | The book grows with every milestone | B-* | cpu |

Many cards need only a CPU and can run beside the critical path of Stage 1:
- tracks X and B;
- the models of track P;
- M-01 ... M-04;
- G-02 ... G-04 and G-06.

`python3 roadmap/tools/backlog.py next --env cpu,net` lists them, and `--area <area>` narrows the list to one area
([../AREAS.md](../AREAS.md)).

## Who does what

The repository is divided into **areas** ([../AREAS.md](../AREAS.md)):
- **Ownership.** Each area owns a set of paths and has its own entry instructions. An agent works in one area at a
  time and changes only that area's paths; `port/tools/check_area_scope.py` checks this.
- **Work packages.** Inside the port, the code-only run divides the WRF changes further, into 36 work packages with
  exclusive routines.
- **Roles:**
  - **Code-only agents** (no builds, no tests) write Phases 1–3 in the work packages
    ([port/agent/CODE_ONLY.md](../port/agent/CODE_ONLY.md); prompts in
    [port/agent/PROMPTS.md](../port/agent/PROMPTS.md)).
  - **The reviewer** (area `review`) checks that work in a CPU-only environment with gfortran and no GPU, using
    `bash port/gates/cpu_verify.sh` and the review cards. It also takes cards one by one, within the daily budget.
  - **GPU work** (area `port-gpu`) runs on the H100 machine: the cards with need `gpu-nv`. Later it also runs on an
    AMD machine: `gpu-amd`.

## Files

| Path | Content |
|---|---|
| [TASK_PROTOCOL.md](TASK_PROTOCOL.md) | task sizes, the card format, the loop, rules |
| [BACKLOG.md](BACKLOG.md) | every task, as cards |
| [log/](log/README.md) | one file per finished task |
| [decisions/](decisions/) | architecture decision records (ADR) |
| [analysis/](analysis/) | measured analyses (versions, CFBM, and later ones) |
| `architecture/` | the WRF and WRF-Fire design documents (track X) |
| [tools/backlog.py](tools/backlog.py) | list, check and update cards |
| [../book/](../book/README.md) | the LaTeX textbook |
| `../perf/` | performance tools and reports (track P) |
