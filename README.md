# port-wrf-gpu: WRF 4.6.0 and WRF-Fire on GPUs, bit for bit

A port of the Weather Research and Forecasting model (WRF) v4.6.0 with WRF-Fire to GPUs. It is written as Fortran
with OpenMP offload directives, and it must give results bit-for-bit identical to a CPU reference build. The
repository also holds the verification tools, the plan, the long-term roadmap and a textbook.

**Stage 1 (now):** WRF 4.6.0 + WRF-Fire on one NVIDIA GPU. WRF 4.8.0 and NCAR's new fire model CFBM come after it
([roadmap/](roadmap/README.md), ADR-002).

## Layout

The repository is divided into **areas**, each with its own instructions and the paths it may change
([AREAS.md](AREAS.md)). Agents start there.

| Path | Content | Area |
|---|---|---|
| `WRF/` | WRF v4.6.0 with the GPU port (all GPU code under `#ifdef WRF_GPU`; the CPU view is unchanged) | `port`, `port-wp` |
| `WPS/` | WPS v4.6.0, unchanged (makes the cases; stays on the CPU) | — |
| `port/` | the port's tools, tests, gates, run scripts and agent guides ([port/README.md](port/README.md), [port/agent/](port/agent/README.md)) | `review`, `port` |
| `cases/` | the case contract of the Eaton fire case | `review` |
| [plan.md](plan.md), [explain-wrf.md](explain-wrf.md) | the execution plan and the porting guide | `review` |
| [AGENTS.md](AGENTS.md) | instructions of the port agent | `review` |
| [roadmap/](roadmap/README.md) | decisions, analyses, the backlog of half-day tasks | `roadmap` |
| [book/](book/README.md) | the LaTeX textbook (built by CI) | `book` |
| [perf/](perf/README.md) | performance models, tools and reports | `perf` |
| [docs/](docs/README.md) | user documentation (for the release) | `docs` |

## Provenance

The branch `upstream/v4.6.0` holds WRF, WPS and Noah-MP exactly as released. The table records the upstream commits.

| Directory          | Upstream                                              | Version                       | Commit                                     |
|--------------------|-------------------------------------------------------|-------------------------------|--------------------------------------------|
| `WRF/`             | [wrf-model/WRF](https://github.com/wrf-model/WRF)     | v4.6.0                        | `0a11865f97680fdd6865b278ea29d910e5db3ed7` |
| `WRF/phys/noahmp/` | [NCAR/noahmp](https://github.com/NCAR/noahmp)         | submodule pinned by WRF v4.6.0 | `848f54ad3d28c4303151fe5ad83724e232694422` |
| `WPS/`             | [wrf-model/WPS](https://github.com/wrf-model/WPS)     | v4.6.0                        | `335c76a111f84503e8b963abaf273ea8053645bb` |

To check the import against its release (fetching only reads from the upstream repositories):

```sh
git fetch --depth 1 https://github.com/wrf-model/WRF refs/tags/v4.6.0
git diff --stat FETCH_HEAD upstream/v4.6.0:WRF        # only phys/noahmp (submodule link -> vendored files)
git fetch --depth 1 https://github.com/wrf-model/WPS refs/tags/v4.6.0
git diff --stat FETCH_HEAD upstream/v4.6.0:WPS        # empty
```

`git diff upstream/v4.6.0 -- WRF` shows every change the port made to WRF.

## WRF-Fire

- Fire model code is built into WRF: `WRF/phys/module_fr_fire_*.F`.
- Ideal fire case: `WRF/test/em_fire` (`./compile em_fire`).
- Real-data fire runs use WPS `geogrid/GEOGRID.TBL.FIRE` and `namelist.wps.fire`.

## Build

`WRF/` and `WPS/` are siblings, so WPS finds the WRF build in `../WRF` on its own:

```sh
cd WRF && ./configure && ./compile em_real    # or em_fire
cd ../WPS && ./configure && ./compile
```

Noah-MP is stored as plain files instead of a submodule; the WRF build links them from
`WRF/phys/noahmp` as usual.
