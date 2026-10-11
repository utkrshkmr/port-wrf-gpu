# Development case eaton_small (plan.md P0.16)

Made by `port/make_dev_case.py` from `/home/csgrad/utkarshk/port-wrf-gpu/EATON/input/wrfinput_d02`.

| Item | Value |
|---|---|
| d02 size | 181 x 181 (was 811 x 811) |
| window in the full d02 (0-based mass points) | i 315..494, j 315..494 |
| i_parent_start, j_parent_start | 215, 215 (was 180, 180) |
| fire mesh | 724 x 724, offset (1260, 1260) |
| ignition | (34.18604, -118.09325), nest point (91, 87) |

wrfinput_d01, wrfbdy_d01 and the tables are those of the full case.
Every column of this nest is a column of the full nest, so the initial state
is the full case's initial state restricted to the window.
