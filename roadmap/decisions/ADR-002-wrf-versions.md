# ADR-002: Which WRF versions, and how one port serves two of them

- Status: **decided** (2026-10-06); amended 2026-10-07 (stage gate, below)
- Facts: [../analysis/wrf-4.6.0-to-4.8.0.md](../analysis/wrf-4.6.0-to-4.8.0.md)

## Decision

1. **Two versions:**
   - **WRF 4.6.0**: the version the port is being written for (Phases 0–3). It stays the reference baseline.
   - **WRF 4.8.0** (released 2026-06-08): the current release, and the version the community will use.

   4.6.1, 4.7.0 and 4.7.1 are skipped: nothing in them is needed that 4.8.0 lacks.
2. **4.6.0 first, then a forward port to 4.8.0.** The 4.6.0 port is finished and verified through Phase 3 on 4.6.0
   first. Then its WRF changes are carried to 4.8.0 by a three-way merge:
   - base: pristine 4.6.0;
   - ours: the 4.6.0 port;
   - theirs: pristine 4.8.0.

   A routine NCAR did not change merges cleanly. A routine NCAR changed is re-ported against its 4.8.0 lines and
   verified again.
3. **One repository, one branch per version line.**
   - `port/v4.6` and `port/v4.8` (the current handoff branch becomes `port/v4.6` when the 4.6.0 port is complete);
   - the tooling (`port/tools`, `port/gates`, `port/h100`) is shared and version-agnostic;
   - per-version data (CPU-view base commit, `KERNEL_REFS.md`, `kernels.csv`, `ROUTES.md`, case files) lives on each
     branch and is regenerated from that branch's base.
4. **Bit-for-bit within a version, statistical across versions.**
   - The GPU build of 4.8.0 must equal the CPU build of 4.8.0 bit for bit (REPRO mode, ADR-003), as for 4.6.0.
   - 4.6.0 and 4.8.0 are compared scientifically on the same cases: field differences, fire perimeter, timing. They are
     not compared bit for bit: NCAR changed physics between them.
5. **4.8.0 brings the new fire model.** CFBM, NCAR's Community Fire Behavior Model, is the `phys/fire_behavior`
   submodule of 4.8.0, selected by `ifire = 1`. WRF-Fire/SFIRE (`ifire = 2`) is unchanged from 4.6.0. CFBM is built
   only by WRF's CMake build, so the 4.8.0 port needs CMake support in `port/h100/build.sh` (task V-06).
6. **Submodules are flattened.** The repository imports WRF 4.8.0 with its submodules checked out as plain files at
   the pinned commits (`physics_mmm`, `fire_behavior`, `noahmp`, ...), exactly as 4.6.0 was imported. A version is
   then one tree, and every change is visible in one diff.

## Why

- The port's method is verification line by line against a CPU reference of the **same** source. Porting two
  versions independently would double the work. A three-way forward port reuses every kernel whose CPU lines did not
  change: almost all of dynamics, and all of WRF-Fire (see the analysis).
- 4.8.0 is what users will run, and it is where NCAR's new fire model lives. Stopping at 4.6.0 would ship a port of a
  release that is two versions old.
- Keeping 4.6.0 as a verified baseline lets us separate "the port changed results" (never allowed) from "NCAR changed
  the model" (expected, documented).

## Consequences

- Backlog track V (versions) starts only after Phase 3 is verified on 4.6.0, apart from the read-only analysis tasks,
  which can run any time.
- The case contract (`cases/eaton_20250108/namelist.input`) must be checked against 4.8.0's Registry: renamed,
  removed or new namelist options, and new defaults (task V-03).
- When NCAR releases 4.9, the same procedure applies, from 4.8.0 to 4.9.

## Amendment 2026-10-07: stage gate

The owner decided that the 4.6.0 port comes first and alone:
- **No 4.8.0 work and no CFBM work begins** until the 4.6.0 port passes G5 (bit-for-bit over the full Eaton run,
  card A-29).
- That includes the read-only analysis tasks. The analysis notes written on 2026-10-06 stay as they are, for later
  use.

Bitwise parity is the goal "if possible". If a step of the 4.6.0 port shows that parity cannot be reached on the GPU,
for example a compiler that cannot be kept from contracting FMAs:
1. stop and record the reason here, with the evidence (the failing probe or test and its minimal reproducer);
2. propose the closest alternative, for example a validated statistical criterion as for the FAST mode of ADR-003;
3. the owner decides. Only then does the gate open.

The backlog enforces the gate: V-01, V-02, C-01 and C-13 depend on A-29.
