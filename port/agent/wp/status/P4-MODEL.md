# P4-MODEL status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p4_model
- Last commit: (this commit; task 1 is 56d26ef)

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-NAN | todo | | stats any-NaN reduction; ported with print_3d_stats |
| K-FM5 | todo | | |
| K-FM6 | todo | | |
| K-FSC | todo | | |
| task 1: hoist set_flags once per domain at init | coded | 56d26ef | call stays in fire_driver_em, gated on fire_ifun_start.eq.1; see Questions |
| task 2: integer NaN counts in print_2d_stats/print_3d_stats | coded | (this commit) | print_2d_stats calls print_3d_stats; the count is there |
| task 3: delete dead post-loop ignition check | todo | | |
| task 4: fuel_frac_burnt, fuel_frac_end, lfn_out work arrays | todo | | |
| task 5: device data (I-12) flags and constants | todo | | |
| task 6: fp on the device (I-12) | todo | | |
| task 7: fire_model kernels K-NAN, K-FM5, K-FM6, K-FSC | todo | | K-FSC is in fire_driver_phys |
| port fire_model | todo | | |
| port fire_driver_em | todo | | |
| port fire_driver_phys | todo | | |
| port set_flags | todo | | |
| port fire_driver_em_init | todo | | |
| port fire_driver_em_step | todo | | |
| port print_2d_stats | todo | | |
| port print_3d_stats | todo | | |

## Scope requests

- `WRF/phys/module_fr_fire_driver.F` module specification (the `public` list, about line 38): add `set_flags` so `fire_driver_em_init` in `module_fr_fire_driver_wrf` can call it. The hoist is behaviorally once per domain (`fire_ifun_start.eq.1`, which only `fire_driver_em_init` passes). The call cannot move into `fire_driver_em_init` until `set_flags` is public. This package does not own that specification part.

## Questions and blockers

- `set_flags` is private. Task 1 gates the existing call instead of moving it into `fire_driver_em_init`. See Scope requests.
- `!$acc update device` of the flags is with task 5 (declare create must exist first). Task 1 is the CPU-view hoist only, per CODE_ONLY.md section 8.

## Log

- Task 1: `set_flags` runs only when `fire_ifun_start.eq.1` (the init driver). The per-step path (`fire_ifun_start.eq.3`) no longer calls it. Values are unchanged: flags are constant for the run. arith_guard reports the new IF as a CPU-view change; expected for this shared refactor. Commit 56d26ef.
- Task 2: `print_3d_stats` counts NaNs with `x /= x` into integer `nnan` instead of a float sum. `print_2d_stats` only calls `print_3d_stats`, so both paths use the count. A nonzero count still falls through to the host scan and `crash`. Non-NaN values with `fire_print_msg.eq.0` still return before the min/max/avg loop. arith_guard CPU-view change expected.
