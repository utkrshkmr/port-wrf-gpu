# ADR-007: Port WPS and real.exe too; the files between the programs are the contract

- Status: **deferred** (owner, 2026-10-15): the port stays `wrf.exe` only; WPS and `real.exe` are small and fast and
  are not started now. The design below (file boundaries as the contract, the order of the tracks, the data
  needed) is kept for when they are taken up. The compatibility invariant of point 2 holds today without any
  work: `wrf.exe`-GPU reads the standard files that a CPU WPS and CPU `real.exe` write, and every gate compares
  it with `wrf.exe`-CPU on exactly such files. The scope sentence of [plan-4.6/README.md](../plan-4.6/README.md)
  ("What stays on the CPU in every stage: WPS, `real.exe`, `ideal.exe`") stands.

## Context

A WRF-Fire simulation is a pipeline of three programs joined by files:

```
 raw data                      WPS                          real.exe                   wrf.exe
 GRIB (GFS/HRRR) ──► ungrib ─┐                                                         
 static geo data ──► geogrid ─┴► metgrid ──► met_em.d0X.*  ──►  vertical interp.,  ──► wrfinput_d01, wrfinput_d02,
 (terrain, land use,                        (netCDF)            base state,            wrfbdy_d01 (netCDF)
  fuel, slope)                                                  boundaries                      │
                                                                                                ▼
                                                                                    the 17 h simulation (hours)
```

- `wrf.exe` is where the time goes: hours per case on 56 cores. WPS and `real.exe` run **once per case** and take
  minutes; most of their time is reading and writing files. That is why the plan kept them on the CPU.
- The owner wants every part ported, and one invariant kept: **a precompiled CPU WPS and CPU `real.exe` must be
  able to feed `wrf.exe`-GPU, and the result must equal `wrf.exe`-CPU on the same files.**

## Decision (proposed)

1. **Three programs, three independent tracks, one kind of test: the file boundary.** Each program's GPU version
   is verified against its own CPU version by bitwise comparison of the files it writes (`compare_fields.py`,
   which already compares netCDF files field by field):
   - `T-WPS`: `met_em.d0X.*` of GPU-geogrid/metgrid = CPU-geogrid/metgrid, every field, every time;
   - `T-REAL`: `wrfinput_d0X`, `wrfbdy_d01` of GPU-`real.exe` = CPU-`real.exe`;
   - `T-TRACE` (existing): `wrf.exe`-GPU = `wrf.exe`-CPU on the same inputs.

   `ungrib` stays on the CPU: it decodes GRIB and writes an intermediate format; there is no arithmetic worth a GPU.
2. **The compatibility invariant is a consequence, pinned by a test.** File formats and the Registry I/O do not
   change (I/O stays on the CPU in every stage). If each stage's GPU output equals its CPU output bit for bit, then
   every mix of CPU and GPU stages gives the same result, including the owner's case (CPU WPS + CPU real → GPU wrf).
   `T-INPUT-COMPAT` makes it explicit: `wrf.exe`-GPU and `wrf.exe`-CPU on the NCAR-produced Eaton inputs (made by
   a different machine and compiler) are bitwise equal. This is exactly the Eaton case of the current plan, so it
   is already part of every gate; the ADR only names it.
3. **Order of the tracks.** The owner proposed WPS → `real.exe` → `wrf.exe`. This ADR proposes the reverse, and
   the owner decides:

   | Track | Proposed position | Why |
   |---|---|---|
   | `wrf.exe` | first (Stages 0–7, in progress) | all the runtime; its discipline (reproducible math, locked flags, bitwise gates, fix ledger) is what the other two ports reuse |
   | `real.exe` | second: a new stage after G5, or a parallel track once Stage 1's infrastructure exists | same source tree, same build (`compile em_real` makes both), same compiler and flags; its routines (`module_initialize_real.F`, `nest_init_utils.F`, `share/`) are already under the shared-refactor rules; the port is column work (vertical interpolation, base state, boundary arrays) with templates that exist |
   | WPS | third: a parallel track in its own area (`wps`) | separate source tree and build; needs its own configure stanzas with the locked flags, `module_repro_math` for the map-projection trigonometry of `module_map_utils`, and interpolation kernels (geogrid: 4-point, 16-point, average_gcell, nearest; metgrid the same plus masks); needs data that is not on the machine (below) |

   The boundary tests (`T-WPS`, `T-REAL`) and the CPU pipeline of point 4 can be set up **now**, in parallel with
   Stage 0, because they are cheap and do not depend on any port.
4. **Prerequisite: a CPU pipeline on the workstation that regenerates the Eaton inputs from raw data.** The Eaton
   `wrfinput`/`wrfbdy` files on the machine were made by NCAR on CCR with another build; they can only be compared
   statistically (E0), never bit for bit. For `T-WPS` and `T-REAL` the reference must be *our* CPU-WPS and
   CPU-`real.exe` output on this machine, with the pinned compiler. So:
   - acquire the raw data of the Eaton case: the GRIB files NCAR used (`EATON/ncar/config/real.pbs` and
     `namelist.wps.fire` say which), the WPS static dataset (`WPS_GEOG`, ~30 GB standard, plus the high-resolution
     fuel and terrain data of the fire grid); **none of this is in `EATON/` today**;
   - run CPU-WPS + CPU-`real.exe` once, compare to NCAR's files statistically (E0 style), archive the outputs as the
     references of `T-WPS` and `T-REAL` (md5 lists in git, data on a persistent disk);
   - the `wrf.exe` port keeps using NCAR's inputs as the case contract (unchanged).
5. **Same rules everywhere.** Same compiler version, the locked arithmetic flags, `module_repro_math` for every
   transcendental, bitwise or nothing, every fix in `FIX_LEDGER.md`. WPS gets stanzas `WPS-CPU-REF` and
   `WPS-GPU-REPRO` in `WPS/arch/configure.defaults` and `check_build_flags.py` learns them.

## Consequences

- `AREAS.md`: a new area `wps` (entry `WPS/AGENTS.md`, branch `wps/<card>`, paths `WPS/*`, `port/wps/*`); `real.exe`
  stays in the `port` area. Backlog cards for: W0 data and CPU pipeline, W1 boundary tests, R1 `real.exe` port,
  W2 geogrid, W3 metgrid.
- plan-4.6's scope sentence changes to "ported in their own tracks (ADR-007); until then on the CPU".
- Expected gain in runtime: small (minutes per case). Expected cost: the WPS port is a second repro-math and
  kernel effort on a separate tree. The owner accepts this for an end-to-end GPU pipeline.
- Nothing in Stage 0 changes; `STAGE0_HANDOFF.md` stays the order of work on the machine.
