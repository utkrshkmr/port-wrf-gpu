# Tool fixes (infrastructure scripts changed by the coding agent)

The build, run and setup scripts were written without access to the H100 machine, NVHPC or the Eaton inputs, so
first contact will find bugs in them. Those scripts are the **infrastructure tier** (`port/agent/infra.md5`,
written by `port/tools/protect.py`):

everything in `port/h100/` except `compare.sh` and `windows.txt` (builds, windows, dev case, the per-routine
harness `harness.sh`/`gen_harness.py`, `build_cmds.py`, `compile_one.sh`, container runner, setup);
`port/container/*`; `port/make_dev_case.py`, `port/nml.py`.

You may fix them, following the protocol in [WORKFLOW.md](WORKFLOW.md) §8. Every infrastructure file that differs
from `infra.md5` must be named in a row below, or `static.sh` fails (`check_tool_fixes.py`). Everything else under
`port/` (tests, checkers, gates, `compare.sh`, `windows.txt`, the comparison tools) is **locked**. A problem there
goes into BLOCKERS.md.

A tool fix must not change what is compared or how:
- the window definitions (`port/h100/windows.txt`, locked);
- trace levels and `OMP_TARGET_OFFLOAD=MANDATORY` for GPU runs (the gates check `window.info`);
- the compiler flags that fix the arithmetic (`port/tools/check_build_flags.py`, run by the gates on every build);
- the dev-case cut (d02 181×181 around the ignition, columns copied unchanged). If you fix
  `make_dev_case.py` after the dev references exist, remake the case and the references, and say so in the log.

| date | files | problem (command and error) | fix | unchanged (why the comparison is not affected) |
|---|---|---|---|---|
| 2026-10-10 | port/h100/common.sh, port/h100/build.sh (port/h100/env.sh template) | S0-00.3: scripts assumed the machine (`BUILD_JOBS=16` fixed; BUILD_INFO did not say which machine built it) | `machine_get`/`machine_line` in common.sh read `$WORK/machine.json` (machine.sh detect); `BUILD_JOBS` defaults to the detected host cores (16 if undetected); BUILD_INFO gains `machine:` and `build jobs:` lines; new `machine.sh`, `machine.py` (S0-00.1/.2) | compiler flags, stanzas, windows, trace levels and comparisons untouched; make parallelism does not change the objects; BUILD_INFO lines are informational |
| 2026-10-10 | port/h100/gpu_hello.sh, port/h100/gpu_hello/* (new); .gitignore | S0-04 gate had no script; the NVHPC SDK is installed inside the checkout (`Linux_x86_64/`) and `$WORK` is `<checkout>/work` | `gpu_hello.sh` builds an OpenACC and a CUDA Fortran kernel with the GPU-port device flags and runs both on every GPU (+ device query); `.gitignore` excludes the SDK, its installer and `work/` | no WRF build, flag set or comparison changed; the hello programs only test the toolchain |
| 2026-10-10 | port/h100/window.sh, port/h100/common.sh, port/h100/machine.py | S0-00.3/.6: a GPU window could start a case that does not fit the GPU; `GPU_ID` had to be set by hand; reference archives were not keyed by host | window.sh: GPU runs check `machine.py fits` against the profile's G-MEM gate and stop with a message, `GPU_ID=auto` picks the first GPU without compute processes, window.info records the machine; common.sh: `DEV_REF=$WORK/reference/eaton_small/<host key>`, `gpu_trace_dir` | windows, namelist edits, trace levels, ACC_DEVICE_TYPE and the comparison untouched; the memory check only refuses runs; existing DEV_REF can be kept by setting DEV_REF |
| 2026-10-10 | port/h100/sync_tree.py | S0-01.1: `build.sh --worktree` copied a changed `inc/gpu_work_*.inc` (or island include) but make did not rebuild the files that include it: stale objects in cpu_verify | sync_tree.py touches every source file of the build tree that `#include`s / `INCLUDE`s a copied `.inc`/`.h` (listed on stderr); tested on a scratch tree | which files are compiled and with which flags is unchanged; only a stale object is no longer reused |
| 2026-10-11 | port/tools/check_deps.py (locked; owner-directed, S0-01.2) | false D1 on run-1 code: `phys/physics_mmm/mp_wsm6.F90` looked up as `mp_wsm6.o:` in depend.common, which writes `physics_mmm/mp_wsm6.o:` | objects named relative to the top directory that builds them; two self-test cases in test_agent_tools.py (fail without the fix) | D1/D2/D3 rules unchanged; a real missing dependency is still reported (self-test) |
| 2026-10-11 | port/gates/cpu_verify.sh (locked; owner-directed, S0-01.3) | a failed build's result line said only "see compile.log"; the gnu-gpu S-3M run stopped at the first route with an unported option and compared nothing | result lines carry the first compile errors (file:line: message); a route stopping with "not ported to the GPU" is reported as `gpu-view:<route> FAIL` and turned off (WRF_GPU_OFF) for the rest of the S-3M comparison | the comparisons (cpu-view, gpu-view, 4 threads, ref tests) and their pass criteria are unchanged; an unported route is still a FAIL line |
| 2026-10-11 | port/h100/setup_toolchain.sh | `setup_toolchain.sh deps-gnu` -> `Fatal Error: File '.../deps/netcdf/include/netcdf4_f03.mod' ... is not a GNU Fortran module file` (CPPFLAGS pointed gfortran at the include dir that also holds the nvfortran modules) | deps-gnu compiles against a directory with only the netCDF-C headers (`$DEPS/src/netcdf-c-headers`) | library versions and the netCDF-C library are unchanged; only the include path of the gfortran build |
| 2026-10-11 | port/h100/machine.sh, port/h100/machine.py | `machine.sh detect` printed "protocol passed" after a FAILED protocol, and a compiler change did not count as a machine change although the device tests hold for one compiler | detect prints FAILED with the record; `host.txt`/`machine.json` record the nvfortran version and `machine.py diff` reports `compiler` as a change, so t_machine.sh reruns the device tests (key gpu-driver-compiler) | the protocol steps and what they compare are unchanged; it now runs in one more case |
| 2026-10-11 | port/tests/mutants_lib.py (locked; owner-directed) | mutants of tests that USE module_repro_math did not compile; nvhpc mutants were built with OpenMP `-mp=gpu` (and gnu with `-fopenmp`), so the OpenACC kernels of a mutant ran on the host | the module is compiled once (REPRO_MATH) and linked; OpenACC flags (`-acc=gpu`, `-fopenacc`) as in the test Makefiles | the mutations and the caught/missed rule are unchanged; mutants now run where the tests run |
| 2026-10-11 | port/h100/build.sh | NVHPC 25.9/26.1/26.5: `fort2 TERMINATED by signal 11` on frame/module_bittrace.f90 at -O2, then on 21 files that USE its half-written module | every nvfortran build compiles module_bittrace.o alone at -O1 (`module_bittrace.o : FCOPTIM := $(subst -O2,-O1,$(FCOPTIM))` appended to configure.wrf; FIX_LEDGER.md F-08) | the tracer computes integer hashes only (exact at any level) and is compiled alike in CPU-REF and GPU builds; every other file keeps the locked flags |

