# P4-MODEL status

Written by the work package only (CODE_ONLY.md §6). States: todo, in-progress, coded, n/a, blocked.

- State: in-progress
- Branch: agent/wp/p4_model
- Last commit: (this commit; through c095f21)

## Items

| Item | State | Commit | Note |
|---|---|---|---|
| K-NAN | todo | | stats any-NaN reduction; ported with print_3d_stats |
| K-FM5 | coded | f0eafa1 | Template A copy of lfn_out into lfn |
| K-FM6 | coded | f0eafa1 | Template A fuel fraction update |
| K-FSC | coded | (this commit) | Template A scale after sum_2d_cells; island re-enters for this loop only |
| task 1: hoist set_flags once per domain at init | coded | 56d26ef | call stays in fire_driver_em, gated on fire_ifun_start.eq.1; see Questions |
| task 2: integer NaN counts in print_2d_stats/print_3d_stats | coded | 42952d8 | print_2d_stats calls print_3d_stats; the count is there |
| task 3: delete dead post-loop ignition check | coded | 275692c | ifun 3 loop never ran; print_chsum kept |
| task 4: fuel_frac_burnt, fuel_frac_end, lfn_out work arrays | coded | 326985c | 16*n2d; sr_x=sr_y=4 |
| task 5: device data (I-12) flags and constants | coded | fe37559 | flags after set_flags; cmbcnst after init_fuel_cats |
| task 6: fp on the device (I-12) | coded | fb22d22 | attach every associated component; not fuel_time |
| task 7: fire_model kernels K-NAN, K-FM5, K-FM6, K-FSC | in-progress | | K-FM5, K-FM6, K-FSC coded; K-NAN waits on print_3d_stats |
| port fire_model | coded | f0eafa1 | island plus host bracket around fuel init |
| port fire_driver_em | coded | c095f21 | round-trip island; does not hold the device |
| port fire_driver_phys | coded | (this commit) | round-trip, then re-enter around K-FSC |
| port set_flags | todo | | |
| port fire_driver_em_init | todo | | |
| port fire_driver_em_step | todo | | |
| port print_2d_stats | todo | | |
| port print_3d_stats | todo | | |

## Scope requests

- `WRF/phys/module_fr_fire_driver.F` module specification (the `public` list, about line 38): add `set_flags` so `fire_driver_em_init` in `module_fr_fire_driver_wrf` can call it. The hoist is behaviorally once per domain (`fire_ifun_start.eq.1`, which only `fire_driver_em_init` passes). The call cannot move into `fire_driver_em_init` until `set_flags` is public. This package does not own that specification part.

## Questions and blockers

- `set_flags` is private. Task 1 gates the existing call instead of moving it into `fire_driver_em_init`. See Scope requests.
- `!$acc update device` of the flags is task 5, not task 1, because `declare create` has to exist first. Task 1 is the CPU-view hoist only.
- `fp%fuel_time` is never associated in `fire_driver_em`. Task 6 does not attach it.
- The ifun 2 gradient loop is a `reduction(max:)` of two reals. It feeds a host message only. It is not a sum. The loop runs on the case, so it is a kernel.
- K-FSC re-enters the island inside the OpenMP tile loop. Tiles must run one at a time. The case uses one thread. A multi-thread tile loop would race on `gpu_world_host`.

## Log

- Task 1: `set_flags` runs only when `fire_ifun_start.eq.1` (the init driver). The per-step path (`fire_ifun_start.eq.3`) no longer calls it. Values are unchanged: flags are constant for the run. arith_guard reports the new IF as a CPU-view change; expected for this shared refactor. Commit 56d26ef.
- Task 2: `print_3d_stats` counts NaNs with `x /= x` into integer `nnan` instead of a float sum. `print_2d_stats` only calls `print_3d_stats`, so both paths use the count. A nonzero count still falls through to the host scan and `crash`. Non-NaN values with `fire_print_msg.eq.0` still return before the min/max/avg loop. arith_guard CPU-view change expected. Commit 42952d8.
- Task 3: deleted the ifun 3 ignition-failure loop in `fire_driver_phys`. Ignition runs at ifun 5, so the count was always 0 and the loop body never ran. The ifun 3 `print_chsum` calls stay. Dropped the unused `wrf_dm_maxval` use and the locals that only that loop used. arith_guard CPU-view deletions expected. Commit 275692c.
- Task 4: `lfn_out`, `fuel_frac_burnt` and `fuel_frac_end` are contiguous pointers onto `work_p4_model_*`, same bounds as the automatic arrays. Allocation is `16*n2d` because fire memory is `sr*(atm memory)` on each axis and `sr_x=sr_y=4` is fixed. `gpu_work_ensure` runs before each remap. With one thread, tiles reuse the fuel arrays in order. arith_guard flags the pointer remaps; `call gpu_work_ensure` is an allowed CPU-view addition. Commit 326985c.
- Task 5: `!$acc declare create` of every flag `set_flags` writes, and of `cmbcnst` (the only `module_fr_fire_phys` scalar device code reads; `heat_fluxes`). `print_2d_stats_gpu_flag_upload` runs at the end of `set_flags`. `fire_phys_gpu_upload` runs at the end of `fire_driver_em_init`, after `init_fuel_cats`, so a namelist `cmbcnst` is the uploaded value. `hfgl`, `fuelmc_*` and `fuelheat` stay host-only. Commit fe37559.
- Task 6: after the `fp%` pointer assignments, `enter data copyin(fp)` then `attach` of vx, vy, zsf, dzdxf, dzdyf, bbb, betafl, phiwc, r_0, fgip, ischap, iboros, fmc_g. Before return, `detach` those components and `delete(fp)`. `fp%fuel_time` is never associated, so it is not attached. Commit fb22d22.
- fire_model: pasted the `R_FIRE_MODEL` island at the first executable and before `END`. K-FM5 and K-FM6 are unchanged loops with a Template A directive. The ifun 2 slope check is a message-only max reduction (`present(fp)`). Observed perimeter, constant heat, `fire_print_msg.ge.1`, and `run_fuel_moisture` call `wrf_error_fatal` before the island. `set_nfuel_cat`, `set_fire_params`, and `init_no_fire` have no route, so the island downloads around those three calls and uploads again. `DEBUG_OUT` array dumps are host-only. kernel_lint: 3 kernels, 0 errors. Commit f0eafa1.
- fire_driver_em: pasted the island, then the exit immediately, then `gpu_isl = .FALSE.` so the exit before `END` is a no-op. A held island would hide `fire_model` host fuel setup and the ifun 1 and 2 writers that have no route. Moisture run, moisture interpolation, moisture only, and `tracer_opt.eq.3` stop before the island. Commit c095f21.
- fire_driver_phys: same round trip at entry, so ifun 1 and 2 host writers see host data. After `sum_2d_cells`, the island re-enters for K-FSC only, then exits before `print_2d_stats`. Observed perimeter, fuel moisture, and moisture advance stop before the island. kernel_lint: 1 kernel, 0 errors.
