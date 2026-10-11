# Acceptance case eaton_mid (S0-09.5, S0-09.6)

The acceptance case every machine profile can run (ADR-006 rev 2): the full Eaton case (`cases/eaton_20250108`) with
the same dates, physics, fire options and ignition, d01 unchanged, and d02 cut to the largest square that fits one
A100 40 GB within the memory gate.

## Size (S0-09.5)

`port/gpu_mem_estimate.py` on the full case's namelist with d02 = n x n (n = 9k + 1, the nest ratio), A100 resident
threads (108 SMs x 2048), 2026-10-11:

| d02 | fire grid | RRTMG 4096 | RRTMG 2048 |
|---|---|---|---|
| 181 (dev case) | 760² | 24.21 GB | 21.96 GB |
| 397 | 1624² | 29.05 GB | 26.80 GB |
| 469 | 1912² | 31.71 GB | 29.45 GB |
| 505 | 2056² | 33.59 GB | 31.34 GB |
| **523** | **2128²** | 34.59 GB | **32.34 GB** |
| 541 | 2200² | 35.62 GB | 33.36 GB |
| 550 | 2236² | 36.14 GB | 33.89 GB |
| 811 (full) | 3280² | 55.13 GB | 52.88 GB |

The gate is 34 GB (85 % of 40 GB). The largest d02 under it is 550 (RRTMG 2048, 33.89 GB, 0.3 % headroom). The
estimator is not yet validated against WRF's own allocation lines (P0.15 accepts 5 %), so the case keeps a 5 %
margin: **d02 523 x 523 with `WRF_RRTMG_BATCH=2048`, estimate 32.34 GB**. When the first GPU run of this case
measures the peak (S5-08), the size can be revisited; the cut is cheap to remake.

## The cut (S0-09.6)

| Item | Value |
|---|---|
| d02 size | 523 x 523 (was 811 x 811), 60 levels |
| window in the full d02 (0-based mass points) | i 144..666, j 144..666 |
| i_parent_start, j_parent_start | 196, 196 (was 180, 180) |
| fire mesh | sr_x = sr_y = 4 |
| ignition | (34.18604, -118.09325), nest point (262, 258) |
| made by | `python3 port/make_dev_case.py --case-dir <inputs> --namelist cases/eaton_20250108/namelist.input --out $WORK/cases/eaton_mid --n 523` |

Every column of this nest is a column of the full nest, so the initial state is the full case's initial state
restricted to the window. wrfinput_d01, wrfbdy_d01 and the tables are those of the full case (manifest.md5).
