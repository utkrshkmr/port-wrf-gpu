# Stage 7 — Other fires, regression, release v0.1

Goal: the port is usable for fires other than Eaton, is guarded by a regression suite that runs by itself, and is
released as v0.1. Spec: plan.md §12 (Phase 7), backlog track R.

| Phase | Title | Tasks | Machine |
|---|---|---|---|
| **S7-01** | Onboarding tools | .1 `manifest.py`, `check_case.py` reviewed against the envelope of plan.md §2.3; .2 `gpu_mem_estimate.py` against the measured peaks of S1-12, S3-25, S5-10 (error ≤ 5 %); .3 A100 40 GB rule: which cases fit one GPU; .4 docs page "Run your fire" | CLOUD, WS-A100 |
| **S7-02** | Regression suite on the workstation | .1 `port/regress.sh` (T-REG-20, T-TRACE-100, T-TRACE-RAD, T-FMA, T-SUBNORM); .2 scheduled nightly run on WS-A100 against the handoff branch (cron or a self-hosted GitHub runner); .3 result page in `port/RESULTS.md`; .4 a failure opens a BLOCKERS.md entry | WS-A100 |
| **S7-03** | Second fire case | .1 choose the fire with the owner (different fuels, terrain, season); .2 WPS/real on the workstation host, case contract `cases/<id>/`; .3 `check_case.py` and memory estimate; .4 CPU-REF 1 h around ignition (host cores); .5 T-CASE-1H on WS-A100 (dev-sized) or GPU80 | CCR, WS-A100, GPU80 |
| **S7-04** | Envelope edges | .1 a case with `e_vert` at `WRF_KMAX`; .2 a nest ratio other than 9; .3 a larger d02 near the memory limit of one A100 40 GB (and of two with S8-04); .4 rebuild with a larger `WRF_KMAX` when needed | WS-A100 |
| **S7-05** | License and release checks | .1 ADR-004 (owner); .2 headers and NOTICE; .3 R-02: no private paths, names or machines in files meant for release | CLOUD (owner decision) |
| **S7-06** | User documentation | .1 build and run guide (container, stanzas, environment variables); .2 troubleshooting from PITFALLS.md; .3 limits (options, memory) | CLOUD |
| **S7-07** | Release v0.1 | .1 tag; .2 CITATION.cff and archive DOI; .3 the book PDF of the release; .4 announcement text | CLOUD |
| **S7-08** | Upstream contact (optional, owner) | .1 summary for NCAR/MMM of the bitwise method and the patches that could go upstream (rp_* math, shared refactors) | CLOUD |

**Gate G7:**
- S7-02 has run nightly for 2 weeks without a failure;
- the second fire passes T-CASE-1H;
- v0.1 is tagged with its PDF and DOI.
