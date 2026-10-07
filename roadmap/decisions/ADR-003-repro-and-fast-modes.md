# ADR-003: Two build modes — REPRO (bit-for-bit) and FAST

- Status: **decided** (2026-10-06); FAST is implemented only after the REPRO port of a version is verified.

## Decision

- **REPRO** (the current port; the default for validation): the GPU build gives results bit-identical to the CPU
  reference build of the same source. Concretely: no FMA contraction, IEEE arithmetic, the portable elementary
  functions of `module_repro_math`, no reordered sums, recurrences kept sequential. Every port task is verified in
  this mode.
- **FAST** (later; for production users): the same source and the same kernels, built with the vendors' fast
  settings:
  - FMA on, vendor math libraries;
  - optionally the reassociations and parallel reductions that REPRO forbids, each behind a macro so that REPRO stays
    untouched.

  FAST is validated **statistically** against REPRO: ensembles with perturbed initial conditions. An ensemble
  consistency test in the style of the CESM/WRF "ECT" compares the FAST run with the spread of the REPRO ensemble, and
  the fire perimeter is compared against the ensemble envelope.

## Why

- Bit-for-bit is the only way to verify a port of this size: one differing bit is visible at once and points to the
  routine. That is why the port is built and tested this way.
- But REPRO costs performance:
  - FMA is about half the floating-point throughput on GPUs;
  - our portable `exp`, `log` and `pow` are slower than vendor ones;
  - sequential recurrences and forbidden reductions limit parallelism.

  Users running forecasts want speed. Item 6 of the owner's goals (are GPUs really faster, and why) needs both
  numbers: the cost of reproducibility is itself a result to report.
- Keeping one source with mode macros, not two code paths, means FAST inherits every verified kernel.

## Consequences

- Performance work (backlog track P) reports REPRO and FAST timings side by side.
- The bit-for-bit tests stay mandatory for every change. FAST adds the statistical test (task P-12).
- A FAST-only optimization must not change REPRO results: its macro is off in REPRO, which `arith_guard` and the
  REPRO traces check.
