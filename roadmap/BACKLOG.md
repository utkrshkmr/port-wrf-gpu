# Backlog

Every task of the project after Phase 0, as cards in the format of [TASK_PROTOCOL.md](TASK_PROTOCOL.md).

- Pick the next card: `python3 roadmap/tools/backlog.py next --env <needs>`.
- Validate this file: `python3 roadmap/tools/backlog.py check`.

**Goals** (the owner's list in [README.md](README.md)):
- 0: the 4.6.0 GPU port of `plan.md`;
- 1: versions;
- 2: profiling;
- 3: design and architecture;
- 4: CFBM;
- 5: any GPU;
- 6: bottlenecks and alternative algorithms;
- 7: book;
- 8: small tasks and a free release;
- 9: stack decision.

**Tracks:**

| Track | Content |
|---|---|
| A | the 4.6.0 port |
| V | versions |
| P | performance |
| M | multi-GPU |
| X | architecture |
| C | CFBM |
| G | GPU vendors |
| B | book |
| R | release |

---

## Track A — the WRF 4.6.0 port (Phases 1–7 of plan.md)

Track A cards also follow [AGENTS.md](../AGENTS.md). Phases 1–3 are coded by a code-only agent in 36 work packages
([port/agent/CODE_ONLY.md](../port/agent/CODE_ONLY.md)). The cards below verify that code here on the CPU, then on
the H100.

**Review procedure R** (used by the cards A-101 ... A-136; one work package each):

1. Fetch: `git fetch origin agent/code agent/wp/<id>`. The handoff commit is the merge base of the work-package
   branch and `claude/wrf-gpu-port-cpu-7doq8n`.
2. Scope: `python3 port/tools/check_wp_scope.py <ID> --base <handoff> --head origin/agent/wp/<id>` must pass.
3. Read the diff **routine by routine** next to its CPU lines (`python3 port/tools/ref.py <kernel id>`). Check that:
   - every statement is copied verbatim, with only the allowed index changes;
   - every scalar written inside a kernel is `private`;
   - index ranges and range guards match the card;
   - no host code touches a moved array inside an island (CODING_STANDARD.md §3 rule 9);
   - the status file `port/agent/wp/status/<ID>.md` is honest.
4. Build and run:
   - a worktree of the handoff with only this branch merged;
   - `bash port/gates/cpu_verify.sh --base <handoff> --harness` in it: static, scope, the S-3M bitwise comparisons
     at 1 and 4 threads, the harness.
5. Report: a section `## <ID>` in `port/agent/REVIEW_<n>.md` on `agent/code`. List each finding as file:line, the
   rule it breaks and the fix expected, or write "no findings". The work package then fixes its findings on its own
   branch (prompt D of [PROMPTS.md](../port/agent/PROMPTS.md)), and the card is repeated as `A-1xxb`.

**Done when** for every review card: steps 1–5 are done and the task log (`roadmap/log/`) has the verdict (`accept` or
`findings: <count>`).

### A-01 · Baseline CPU verification of the handoff tree
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu · **Depends:** — · **Status:** done 43819e6
- **Read:** port/agent/CODE_ONLY.md §7; port/gates/cpu_verify.sh (header)
- **Do:** Run `bash port/gates/cpu_verify.sh --base <handoff>` on the handoff branch itself, before any work package
  is merged. In the cloud environment use the host-mode prefix of TASK_PROTOCOL.md §2. Every check must pass on unported code. This proves the gate is sound before it judges anyone's work.
- **Output:** a task log file with the summary block of the run.
- **Done when:** cpu_verify prints PASS for static, the three builds, the three S-3M comparisons and the reference
  tests (scope checks print SKIP: there are no branches yet).

### A-02 · First integration check of agent/code
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-01 · **Status:** todo
- **Read:** port/agent/CODE_ONLY.md §1, §7; port/agent/WORKPACKAGES.md
- **Do:**
  - Fetch `agent/code` and every `agent/wp/*` branch.
  - Run `cpu_verify.sh --base <handoff> --harness` on `agent/code`.
  - Triage each failure to the work package that owns the routine (`port/agent/wp/ownership.json`).
  - Start `port/agent/REVIEW_1.md` with one section per failing work package.
- **Output:** `port/agent/REVIEW_1.md` on `agent/code`; a task log file.
- **Done when:**
  - every failure of the run is attributed to a work package, or to the infrastructure, with a BLOCKERS.md entry;
  - the review cards A-101 ... A-136 are unblocked.

### A-03 · Re-verify agent/code after a fix round (repeatable: A-03a, A-03b, ...)
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** the previous REVIEW_<n>.md
- **Do:**
  - Merge the fixed work-package branches into `agent/code`, or have the integrator do it.
  - Rerun `cpu_verify.sh --harness`.
  - Write `REVIEW_<n+1>.md` with what remains.
- **Output:** `REVIEW_<n+1>.md`; a task log file.
- **Done when:** the run is recorded. The track is CPU-green when a run passes every check (milestone M1).

### A-04 · CPU harness for the Phase 3 column physics
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu · **Depends:** A-01 · **Status:** todo
- **Read:**
  - port/h100/harness.sh and port/h100/gen_harness.py;
  - port/tests/templates (the column template);
  - port/agent/PHASE3.md (T-WSM6-COL, T-YSU-COL, T-NOAH-PT, T-RRTMG-COL)
- **Do:**
  - Extend the harness (infrastructure, tool-fix protocol of WORKFLOW.md §8) so that it can drive one column-physics
    wrapper:
    - `wsm6`, `ysu`, `sfclayrev`, `lsm`, `rrtmg_lwrad`, `swrad`;
    - with inputs taken from an S-3M state dump (not random: physics needs physical profiles).
  - Compare gnu-ref against gnu-gpu.
  - Add a `--harness-phys` option to `cpu_verify.sh`. That script is locked, so this is a reviewer change with a
    checksum update.
- **Output:** harness changes; a TOOL_FIXES.md entry; cpu_verify option.
- **Done when:**
  - on the handoff tree the harness passes for all six wrappers;
  - a deliberately reassociated copy of one WSM6 statement fails it.

### A-05 · Wire Phase 4 (WRF-Fire) as work packages
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:**
  - port/agent/PHASE4.md;
  - port/tools/wp_def.py (structure only);
  - port/agent/KERNEL_REFS.md through `ref.py` for K-A2F, K-TLS, K-ALR, K-FL, K-FT
- **Do:**
  - Add P4-* work packages to `wp_def.py`, about 6:
    - P4-REF: the shared refactors of P4.0;
    - P4-A2F: atm2fire interpolation;
    - P4-LS: level set and the boundary continuation;
    - P4-ROS: rate of spread and flame length;
    - P4-FUEL: ignition, fuel left, heat fluxes;
    - P4-TEND: fire_tendency and the driver call sites.
  - Regenerate the cards, islands and work-array includes with `gen_wp.py`.
  - Add the build dependencies of the touched files to `main/depend.common`.
  - Extend CODE_ONLY.md and PROMPTS.md to Phase 4.
  - This is a reviewer task: it edits locked tools, then runs `protect.py`.
- **Output:** wp_def.py; generated cards; depend.common; guide updates; checksums.
- **Done when:** `gen_wp.py --check` passes, `static.sh` passes, and `cpu_verify.sh` on the unchanged tree still
  passes (the wiring is inert).

### A-06 · Wire Phase 5 (device world) as work packages
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu · **Depends:** A-05 · **Status:** todo
- **Read:** port/agent/PHASE5.md; plan.md §10 (P5.1–P5.4)
- **Do:**
  - Define P5-TRACE (the tracer on the device), P5-CPL (`couple_or_uncouple_em`), P5-FORCE (`med_force_domain` and
    the generated slab, strip and full update lists) and P5-WORLD (removing the bracket, the output sync).
  - The generator extensions for the force lists are in P1.3 of plan.md; check what P1-SYNC already produced.
  - Same procedure as A-05.
- **Output:** as A-05.
- **Done when:** as A-05.

### A-07 · Phase 7 regression script and onboarding guide
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** port/agent/PHASE7.md; plan.md §12
- **Do:**
  - Write `port/regress.sh`: T-REG-20, T-TRACE-100, T-TRACE-RAD, T-FMA, T-SUBNORM and both builds, with a gnu mode
    for the CPU (S-3M instead of the windows).
  - Write the onboarding guide for a new fire case (P7.2).
- **Output:** `port/regress.sh`; `port/agent/ONBOARDING.md`.
- **Done when:** `bash port/regress.sh --gnu` passes on the handoff tree.

### A-08 · Phase 0 on CCR, part 1: environment and CPU-REF reproducibility
- **Goal:** 0 · **Size:** M · **Area:** port-ccr · **Needs:** ccr, data · **Depends:** — · **Status:** todo
- **Read:** port/README.md (runbook); port/RESULTS.md (G0 checklist); port/ccr/ (script headers)
- **Do:** The open G0 rows that run on CCR:
  - build the container image and record its digest (P0.0);
  - `identify_build.sh` (P0.2);
  - `manifest.py check` (P0.3);
  - the CPU-REF build (P0.9);
  - `p0_check.sh` and `p0_tests.sh`: T-DET, T-DEC-B, T-RST, T-XM (with `p0_txm_gpu.sh` on a GPU-node host);
  - `t_shared.sh`.
- **Output:** RESULTS.md rows filled in with the binary md5s.
- **Done when:** every row is bitwise, or has its failure documented as P0.10 prescribes.

### A-09 · Phase 0 on CCR, part 2: references, E0/E1, Prof-CPU
- **Goal:** 0 · **Size:** M · **Area:** port-ccr · **Needs:** ccr, data · **Depends:** A-08 · **Status:** todo
- **Read:** port/README.md (runbook); plan.md P0.11–P0.16
- **Do:**
  - `reference_run.sh`: the full 17 h case and the 02:20 restart; `archive_reference.sh`.
  - `dev_case.sh`: the dev case `eaton_small` and its references.
  - `e0_e1.sh`: E0, E1.
  - `prof_run.sh`: Prof-CPU.
  - The memory estimator on the full case.
  - The long runs are unattended: this card covers submitting them and checking their results.
- **Output:** the archives (on CCR) with md5 lists; RESULTS.md rows.
- **Done when:** G0's remaining rows are filled in (milestone M0 complete).

### A-20 · Entry tasks H0 on the H100 machine
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv · **Depends:** — · **Status:** todo
- **Read:** port/agent/ENV_H100.md; port/agent/PHASE1.md §0 (H0.1–H0.9, and "Without the case data")
- **Do:**
  - H0.1: the toolchain.
  - H0.2: the reproducible-math checks (T-FMA, T-SUBNORM, T-RM-*).
  - H0.3: the OpenMP feature probes.
  - H0.4: the reference tests on the GPU.
  - H0.5: the CPU-REF builds and T-SYM.
  - H0.8, H0.9: on the smoke case.
  - H0.6 and H0.7 need the Eaton inputs: do them as A-20b once the data is on the machine.
- **Output:** `port/ENVIRONMENT.md`, `port/RESULTS.md` entries; a task log file.
- **Done when:** every H0 item without data passes or has a BLOCKERS.md entry. T-FMA, T-SUBNORM and
  F-COMPMAP-ADDR must pass before any GPU gate.

### A-20b · Entry tasks H0.6 and H0.7 (with the case data)
- **Goal:** 0 · **Size:** S · **Area:** port · **Needs:** gpu-nv, data · **Depends:** A-20, A-09 · **Status:** todo
- **Read:** port/agent/PHASE1.md H0.6, H0.7, and the list "Pending the case data" in the workbook
- **Do:** Copy the inputs and the dev-case references from CCR, then run H0.6, H0.7 and the commands owed on the case
  data.
- **Output:** RESULTS.md; the workbook's pending list emptied.
- **Done when:** every command of the pending list has run.

### A-21 · First GPU-REPRO build (P1.1)
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv · **Depends:** A-20, A-03 · **Status:** todo
- **Read:** port/agent/PHASE1.md P1.1; port/agent/BUILD_SYSTEM.md
- **Do:**
  - Build `gpu-repro` and `cpu-ref` of the CPU-green `agent/code` with nvfortran.
  - Fix compile-only problems: nvfortran restrictions in device code, `-Minfo` surprises. Each fix goes to its work
    package's branch, or is applied directly when the owner allows it.
- **Output:** builds; the minfo logs; fixes.
- **Done when:** both builds link and `T-MAP` passes.

### A-22 · Gate G1 on the H100
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** A-21, A-09 · **Status:** todo
- **Read:** port/agent/PHASE1.md (G1)
- **Do:**
  - Run the G1 tests: T-MAP, T-TAB, T-POOL, T-WORK, T-UPD, T-GATE, W-20 bitwise and the first 3 d01 steps.
  - Run G-MEM (first check) on the full case.
  - The dev case and its references come from A-09; copy them to the machine (H0.6, H0.7 = card A-20b).
- **Output:** RESULTS.md entries.
- **Done when:** every G1 criterion passes, or has a BLOCKERS.md entry.

### A-23 · Gates G2.A–G2.C on the H100
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** A-22 · **Status:** todo
- **Read:** port/agent/PHASE2.md (sub-gates)
- **Do:** T-AB for every routine of P2-A1, A2, B1–B6 and C; T-TRACE-100; the call check per route.
- **Output:** RESULTS.md; fixes on the work-package branches.
- **Done when:** the sub-gates pass.

### A-24 · Gates G2.D–G2.E on the H100
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** A-23 · **Status:** todo
- **Read:** port/agent/PHASE2.md
- **Do:** as A-23 for P2-D1..D3, P2-E1, P2-E2.
- **Output:** as A-23.
- **Done when:** the sub-gates pass.

### A-25 · Gates G2.F–G2.G and G2 on the H100
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** A-24 · **Status:** todo
- **Read:** port/agent/PHASE2.md
- **Do:** as A-23 for P2-F and P2-G1..G3, then T-TRACE-TKE, T-NSYS and T-DRIFT (G2).
- **Output:** as A-23.
- **Done when:** G2 passes (milestone M2a).

### A-26 · Gates G3.A–G3.C on the H100
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** A-25, A-04 · **Status:** todo
- **Read:** port/agent/PHASE3.md
- **Do:** T-AB and the column harnesses for the glue, WSM6, sfclayrev, Noah and the surface driver; T-TRACE-100.
- **Output:** as A-23.
- **Done when:** the sub-gates pass.

### A-27 · Gates G3.D–G3.E and G3 on the H100
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** A-26 · **Status:** todo
- **Read:** port/agent/PHASE3.md
- **Do:**
  - YSU, radiation (T-KISS, T-OZN, T-RRTMG-COL, T-TRACE-RAD);
  - G3: G-MEM (second check), T-NSYS, T-DRIFT.
- **Output:** as A-23.
- **Done when:** G3 passes (milestone M2).

### A-28 · Gate G4 (fire) on the H100
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** A-27, A-05 · **Status:** todo
- **Read:** port/agent/PHASE4.md
- **Do:** T-AB of every fire routine; T-FIRE-IGN, T-FIRE-WIN, T-FIRE-GHOST; compare_fire on the three frames.
- **Output:** RESULTS.md.
- **Done when:** G4 passes.

### A-29 · Gate G5 (acceptance) on the H100
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data, ccr · **Depends:** A-28, A-06 · **Status:** todo
- **Read:** port/agent/PHASE5.md
- **Do:**
  - T-FORCE, T-SLAB, T-O3, T-NSYS-CLEAN, T-OUT, T-BDY;
  - the full 17 h run, compared against the CPU-REF archive;
  - T-DRIFT-FULL on CCR; T-XM.
  - The 17 h run is unattended; the card covers starting it and checking the results.
- **Output:** RESULTS.md with md5s.
- **Done when:** all nine G5 items pass (milestone M3).

### A-30 · Second fire case (Phase 7)
- **Goal:** 0 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** A-29, A-07 · **Status:** todo
- **Read:** port/agent/ONBOARDING.md
- **Do:** onboard a second fire case (the owner chooses it) with `check_case.py`, the memory estimate and T-CASE-1H.
- **Output:** `cases/<case>/`; RESULTS.md.
- **Done when:** T-CASE-1H is bitwise.

<!-- review cards: one per work package; generated once, then edited by hand -->

### A-101 · Review P1-SYNC
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P1-SYNC.md; this file, procedure R
- **Do:** Procedure R for P1-SYNC (sync points S1–S6, the solve_em bracket, driver call sites).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-102 · Review P1-TAB
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P1-TAB.md; this file, procedure R
- **Do:** Procedure R for P1-TAB. Review it together with the upload and tabcheck routines of P3-WSM6, P3-SFCLAY,
  P3-NOAH, P3-SW and P3-RRTMG (interface I-4).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-103 · Review P1-ST
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P1-ST.md; this file, procedure R
- **Do:** Procedure R for P1-ST.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-104 · Review P1-POOL
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P1-POOL.md; this file, procedure R
- **Do:** Procedure R for P1-POOL.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-105 · Review P1-WORK
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P1-WORK.md; this file, procedure R
- **Do:** Procedure R for P1-WORK. Also check `inc/gpu_work_*.inc` of every work package against the work-array
  rules.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-106 · Review P1-CHECK
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P1-CHECK.md; this file, procedure R
- **Do:** Procedure R for P1-CHECK, plus a negative test: S-3M with `cu_physics = 1` must stop with the violation
  listed (T-GATE on the CPU).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-107 · Review P1-PROF
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P1-PROF.md; this file, procedure R
- **Do:** Procedure R for P1-PROF. The C shim must compile without CUDA (stubs) and with it (the H100 checks later).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-108 · Review P1-B4
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P1-B4.md; port/agent/BLOCKERS.md (B4); this file, procedure R
- **Do:**
  - Procedure R for P1-B4.
  - It is a shared refactor: run `gnu-ref` of the handoff against `gnu-ref` with only P1-B4 merged, and the
    repro_math tests (`run_ref_tests.sh gnu`).
  - If the results are bit-identical, move the CPU-view base (WORKFLOW.md shared-refactor protocol).
- **Output:** REVIEW_<n>.md section; the moved base if it passes.
- **Done when:** see procedure R, plus the base decision.

### A-109 · Review P2-A1
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-A1.md; this file, procedure R
- **Do:** Procedure R for P2-A1.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-110 · Review P2-A2
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-A2.md; this file, procedure R
- **Do:** Procedure R for P2-A2. Check the x-before-y ordering of the boundary-strip kernels.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-111 · Review P2-B1
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-B1.md; this file, procedure R
- **Do:** Procedure R for P2-B1 (advect_u). Check every per-row and per-column branch of the flux order (5th/3rd/2nd
  order near the edges).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-112 · Review P2-B2
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-B2.md; this file, procedure R
- **Do:** Procedure R for P2-B2 (advect_v).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-113 · Review P2-B3
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-B3.md; this file, procedure R
- **Do:** Procedure R for P2-B3 (advect_w), including the lid terms.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-114 · Review P2-B4
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-B4.md; this file, procedure R
- **Do:** Procedure R for P2-B4 (advect_scalar).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-115 · Review P2-B5
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-B5.md; this file, procedure R
- **Do:** Procedure R for P2-B5 (zero_tend, ww_split, rhs_ph). Check the rhs_ph quirk at i = ids+2 / ide−3.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-116 · Review P2-B6
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-B6.md; this file, procedure R
- **Do:** Procedure R for P2-B6. Check the w_damp reductions and the order of the pg_buoy_w kernels.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-117 · Review P2-C
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-C.md; this file, procedure R
- **Do:** Procedure R for P2-C.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-118 · Review P2-D1
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-D1.md; this file, procedure R
- **Do:** Procedure R for P2-D1.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-119 · Review P2-D2
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-D2.md; this file, procedure R
- **Do:** Procedure R for P2-D2 (advance_uv, advance_mu_t, advance_w): the column recurrences, the range guards and
  the `rhs_col(1) = 0` inside the kernel.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-120 · Review P2-D3
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-D3.md; this file, procedure R
- **Do:** Procedure R for P2-D3.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-121 · Review P2-E1
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-E1.md; port/tests/pdlim; this file, procedure R
- **Do:**
  - Procedure R for P2-E1 (advect_scalar_pd).
  - The limiter split must be the one of `port/tests/pdlim`.
  - Run T-PDLIM (`run_ref_tests.sh gnu`).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-122 · Review P2-E2
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-E2.md; this file, procedure R
- **Do:** Procedure R for P2-E2.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-123 · Review P2-F
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-F.md; this file, procedure R
- **Do:** Procedure R for P2-F (calc_p_rho_phi with `rp_pow` in place of `vspow`, spec_bdy_final, set_w_surface,
  update_phys_fields).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-124 · Review P2-G1
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-G1.md; this file, procedure R
- **Do:** Procedure R for P2-G1 (compute_diff_metrics, cal_deform_and_div: about 40 kernels in source order).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-125 · Review P2-G2
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-G2.md; this file, procedure R
- **Do:** Procedure R for P2-G2. S-3M is an LES with TKE, so its comparisons cover this package.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-126 · Review P2-G3
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P2-G3.md; this file, procedure R
- **Do:** Procedure R for P2-G3 (horizontal and vertical diffusion, the `cal_titau_*` routines, `nba_mij`).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-127 · Review P3-GLUE1
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P3-GLUE1.md; this file, procedure R
- **Do:** Procedure R for P3-GLUE1. Check the backslash-continued statements of moist_physics_finish_em.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-128 · Review P3-GLUE2
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P3-GLUE2.md; this file, procedure R
- **Do:** Procedure R for P3-GLUE2. Check the add_a2c_v `k = kts..kte` quirk.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-129 · Review P3-WSM6
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-02, A-04 · **Status:** todo
- **Read:** port/agent/wp/P3-WSM6.md; this file, procedure R
- **Do:** Procedure R for P3-WSM6, plus the WSM6 column harness of A-04. Check:
  - the CP-3 whole-array rewrites (`(:)` turned into `(1:km)`);
  - the SAVE scalars;
  - that the effective-radius skip is bit-neutral.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-130 · Review P3-SFCLAY
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02, A-04 · **Status:** todo
- **Read:** port/agent/wp/P3-SFCLAY.md; this file, procedure R
- **Do:** Procedure R for P3-SFCLAY, plus its column harness. Check the ψ tables (declare target, upload).
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-131 · Review P3-NOAH
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-02, A-04 · **Status:** todo
- **Read:** port/agent/wp/P3-NOAH.md; this file, procedure R
- **Do:** Procedure R for P3-NOAH, plus its column harness. Check:
  - `iloc`/`jloc` turned into arguments;
  - the integer land-use and soil codes;
  - the error codes in place of FATAL_ERROR;
  - `DO K=1,4` kept.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-132 · Review P3-SFCDRV
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P3-SFCDRV.md; this file, procedure R
- **Do:** Procedure R for P3-SFCDRV.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-133 · Review P3-PBL
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02, A-04 · **Status:** todo
- **Read:** port/agent/wp/P3-PBL.md; this file, procedure R
- **Do:**
  - Procedure R for P3-PBL, plus its column harness.
  - YSU runs on d01 only. S-3M has one domain: check which PBL option S-3M runs, and rely on the harness if it is
    not YSU.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-134 · Review P3-RADDRV
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-02 · **Status:** todo
- **Read:** port/agent/wp/P3-RADDRV.md; port/tests/ozn; this file, procedure R
- **Do:** Procedure R for P3-RADDRV. Run T-OZN (per-column `ozn_p_int`) and check the RRTMG init hoist.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-135 · Review P3-RRTMG
- **Goal:** 0 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-02, A-04 · **Status:** todo
- **Read:** port/agent/wp/P3-RRTMG.md; port/tests/kiss; this file, procedure R
- **Do:** Procedure R for P3-RRTMG, plus T-KISS and its column harness. Check:
  - the flattening of the EQUIVALENCE tables (index arithmetic);
  - the batch work arrays;
  - the `rp_mod` substitutions.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

### A-136 · Review P3-SW
- **Goal:** 0 · **Size:** S · **Area:** review · **Needs:** cpu, net · **Depends:** A-02, A-04 · **Status:** todo
- **Read:** port/agent/wp/P3-SW.md; this file, procedure R
- **Do:** Procedure R for P3-SW, plus its column harness. Check the DATA tables turned into PARAMETERs and the night
  columns' early exit.
- **Output:** REVIEW_<n>.md section.
- **Done when:** see procedure R.

---

## Track V — WRF versions (4.6.0 → 4.8.0; ADR-002)

Stage 2: no card of this track starts before A-29 (the stage gate of ADR-002).

### V-01 · Reproducible version-diff tool
- **Goal:** 1 · **Size:** S · **Area:** versions · **Needs:** cpu, net · **Depends:** A-29 · **Status:** todo
- **Read:** roadmap/analysis/wrf-4.6.0-to-4.8.0.md; port/tools/wp_lib.py (`routine_span`)
- **Do:**
  - Write `roadmap/tools/version_diff.py <old tree> <new tree>`. It prints:
    - the file-level counts (added, removed, changed by directory);
    - the changed lines of every file the port edits;
    - the changed routines of every work package, using `port/agent/wp/ownership.json` and routine spans.
  - Rerun it for 4.6.0 against 4.8.0 and update the analysis.
- **Output:** the tool; the analysis note regenerated from its output.
- **Done when:** the tool reproduces the numbers in the analysis note (or the note is corrected and the difference
  explained).

### V-02 · Import pristine WRF 4.8.0 (flattened)
- **Goal:** 1 · **Size:** S · **Area:** versions · **Needs:** cpu, net · **Depends:** A-29 · **Status:** todo
- **Read:** ADR-002 §6; `git show --stat dda741a` (branch `upstream/v4.6.0`) (how 4.6.0 was imported)
- **Do:**
  - Clone NCAR/WRF at tag `v4.8.0` with submodules at their pinned commits.
  - Copy the tree without `.git` into `WRF/` on a new orphan branch `upstream/v4.8.0`.
  - Do the same for 4.6.0 on `upstream/v4.6.0` if it is not already a branch.
  - Record the submodule commits in `WRF/UPSTREAM.md` on that branch.
- **Output:** branches `upstream/v4.6.0` and `upstream/v4.8.0`.
- **Done when:**
  - `git diff upstream/v4.6.0 upstream/v4.8.0 --stat` matches the analysis' file counts;
  - the submodules are present as plain files.

### V-03 · Check the case contract against the 4.8.0 Registry
- **Goal:** 1 · **Size:** S · **Area:** versions · **Needs:** cpu · **Depends:** V-02 · **Status:** todo
- **Read:** cases/eaton_20250108/namelist.input; plan.md §2.2–2.3; the Registry diff from V-02
- **Do:** For every option in the case namelist and in `gpu_check_config`'s table, check in 4.8.0:
  - whether it exists;
  - whether its default changed;
  - whether new options change executed code in this configuration. Look for new physics switches on the active
    schemes, `ifire` now meaning CFBM for 1, and new diagnostics that are on by default.
- **Output:** `roadmap/analysis/case-contract-4.8.0.md`; a proposed 4.8.0 namelist.
- **Done when:** every option is classified as unchanged, renamed, new default or new option, with a source line.

### V-04 · Forward-port tool (three-way merge per file)
- **Goal:** 1 · **Size:** M · **Area:** versions · **Needs:** cpu · **Depends:** V-02 · **Status:** todo
- **Read:** ADR-002 §2; port/agent/cpu_view_base
- **Do:**
  - Write `roadmap/tools/forward_port.py`. For every file the port changed, it runs `git merge-file` with:
    - base: the 4.6.0 pristine file;
    - ours: the port's file;
    - theirs: the 4.8.0 pristine file.
  - It reports clean merges and conflicts per routine, and lists the port routines whose CPU lines changed in 4.8.0:
    these must be re-ported, even when the merge is clean.
  - It regenerates the per-version data (`KERNEL_REFS.md` line numbers, `cpu_view_base`) for the new base.
- **Output:** the tool; a dry-run report on the current handoff tree.
- **Done when:** the dry run on the handoff tree lists every routine of the analysis' "by routine" table.

### V-05 · Re-port the 4.8.0 driver changes (P1-SYNC)
- **Goal:** 1 · **Size:** M · **Area:** versions · **Needs:** cpu · **Depends:** V-04, A-03 · **Status:** todo
- **Read:** the V-04 report for `solve_em` and `med_before_solve_io`
- **Do:** Apply the forward port of P1-SYNC's routines to 4.8.0. Redo the sync points and island brackets around the
  calls that 4.8.0 added: CFBM, the new diagnostics.
- **Output:** commits on `port/v4.8`.
- **Done when:** gnu-ref and gnu-gpu of the 4.8.0 tree are bitwise on the 4.8.0 S-3M (V-08).

### V-06 · CMake build mode in the port's build scripts
- **Goal:** 1 · **Size:** M · **Area:** versions · **Needs:** cpu · **Depends:** V-02 · **Status:** todo
- **Read:** WRF 4.8.0 `CMakeLists.txt`, `cmake/`, `phys/CMakeLists.txt`; port/h100/build.sh
- **Do:**
  - Add a `--cmake` path to `build.sh` that builds the same modes (gnu-ref, gnu-gpu, cpu-ref, gpu-repro) through
    WRF's CMake build.
  - Map the configure-stanza flags to CMake toolchain settings, and check with `check_build_flags.py` that every file
    gets the REPRO flags.
  - Needed because CFBM is built only by CMake.
- **Output:** build.sh changes (tool fix); BUILD_SYSTEM.md section.
- **Done when:** on 4.8.0, the CMake gnu-ref and the make gnu-ref give bitwise-identical S-3M results.

### V-07 · Registry-driven generators on 4.8.0
- **Goal:** 1 · **Size:** S · **Area:** versions · **Needs:** cpu · **Depends:** V-02, A-03 · **Status:** todo
- **Read:** PHASE1.md P1.2/P1.3; the 4.8.0 Registry diff
- **Do:** Build the 4.8.0 tree with the port's generator changes (gen_allocs, gen_gpu). Check:
  - the generated include files for the new fields;
  - the not-in-use dummies;
  - the `fire_state` derived type (CFBM), which the generators must skip or handle.
- **Output:** generator fixes if needed.
- **Done when:** T-MAP's CPU form (presence checks run on the host) passes on the 4.8.0 S-3M.

### V-08 · 4.8.0 smoke case and CPU verification
- **Goal:** 1 · **Size:** S · **Area:** versions · **Needs:** cpu · **Depends:** V-03, V-05, V-07 · **Status:** todo
- **Read:** port/h100/smoke_case.sh
- **Do:** Make S-3M work on 4.8.0 with the proposed namelist of V-03, then run `cpu_verify.sh` on `port/v4.8`.
- **Output:** smoke-case changes; a task log file.
- **Done when:** cpu_verify passes on 4.8.0.

### V-09 · Re-port the changed physics glue and drivers (P3-GLUE1, P3-GLUE2)
- **Goal:** 1 · **Size:** S · **Area:** versions · **Needs:** cpu · **Depends:** V-04 · **Status:** todo
- **Read:** the V-04 report for these routines
- **Do:** Port again the changed lines of `phy_prep_part2`, `moist_physics_finish_em`, `calculate_phy_tend`,
  `update_phy_ten`, `phy_cu_ten` and `phy_fr_ten`, against their 4.8.0 CPU lines.
- **Output:** commits on `port/v4.8`.
- **Done when:** the harness and S-3M pass.

### V-10 · Re-port microphysics_driver and the wsm6 wrapper (P3-WSM6)
- **Goal:** 1 · **Size:** M · **Area:** versions · **Needs:** cpu · **Depends:** V-04 · **Status:** todo
- **Read:** the V-04 report
- **Do:** as V-09 for `microphysics_driver` (362 changed lines), the `wsm6` wrapper and `mp_wsm6_effectRad_finalize`.
- **Output:** commits.
- **Done when:** the WSM6 column harness and S-3M pass.

### V-11 · Re-port surface_driver, sfclayrev and Noah's lsm (P3-SFCDRV, P3-SFCLAY, P3-NOAH)
- **Goal:** 1 · **Size:** M · **Area:** versions · **Needs:** cpu · **Depends:** V-04 · **Status:** todo
- **Read:** the V-04 report
- **Do:** as V-09 for `surface_driver`, `sfclayrev`, `sf_sfclayrev_run`, `lsm`, `lsm_mosaic` and the sea-ice wrappers.
- **Output:** commits.
- **Done when:** the harnesses and S-3M pass.

### V-12 · Re-port pbl_driver, ysu and calc_coszen (P3-PBL, P3-RADDRV)
- **Goal:** 1 · **Size:** S · **Area:** versions · **Needs:** cpu · **Depends:** V-04 · **Status:** todo
- **Read:** the V-04 report
- **Do:** as V-09.
- **Output:** commits.
- **Done when:** the harnesses and S-3M pass.

### V-13 · GPU gates on 4.8.0
- **Goal:** 1 · **Size:** M · **Area:** versions · **Needs:** gpu-nv, data · **Depends:** V-08, V-09, V-10, V-11, V-12, A-29 · **Status:** todo
- **Read:** the G1–G5 criteria
- **Do:**
  - Rerun the gate scripts on `port/v4.8`.
  - Make a 4.8.0 CPU-REF archive for the Eaton case first (ccr).
  - The 4.8.0 port is accepted when G5 passes on it.
- **Output:** RESULTS.md (4.8.0 section).
- **Done when:** G5 passes on 4.8.0 (milestone M5).

### V-14 · Compare 4.6.0 and 4.8.0 scientifically on the Eaton case
- **Goal:** 1 · **Size:** M · **Area:** versions · **Needs:** data, gpu-nv · **Depends:** V-13 · **Status:** todo
- **Read:** port/compare_fields.py; port/compare_fire.py
- **Do:**
  - Run both versions for 17 h (GPU REPRO builds; CPU-REF would also do).
  - Compare:
    - the fields statistically: RMSE, bias and spatial-correlation maps per field and hour;
    - the fire perimeters per frame;
    - the run time.
  - Attribute differences to NCAR's changes where possible.
- **Output:** `roadmap/analysis/eaton-4.6.0-vs-4.8.0.md`.
- **Done when:** the note has the tables and figures, and the commands that made them.

---

## Track P — profiling, performance, bottlenecks, alternatives (ADR-003)

Reports and tools go to `perf/` (`perf/tools/`, `perf/reports/`). A number in a report is either measured (with its
command) or a model estimate (with its formula).

### P-01 · CPU profile of the reference build on the smoke case
- **Goal:** 2 · **Size:** S · **Area:** perf · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** port/h100/build.sh (gnu modes); port/h100/smoke_case.sh; port/prof_cpu.py
- **Do:**
  - Build gnu-ref with `-pg`, or use `perf record`, and run S-3M.
  - Produce the top 40 routines by self time and inclusive time, and map each to its work package and kernel IDs
    through `ownership.json`.
  - Note the limits: S-3M is small, and the full-case Prof-CPU of P0.15 on CCR is the reference.
- **Output:** `perf/tools/cpu_profile.sh`; `perf/reports/cpu-profile-s3m.md`.
- **Done when:** the script regenerates the report's tables.

### P-02 · Device-memory model for any case and any GPU
- **Goal:** 2 · **Size:** S · **Area:** perf · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** port/gpu_mem_estimate.py (usage); plan.md §3
- **Do:**
  - Validate the estimator against the `alloc_space_field` lines of a gnu-gpu S-3M run.
  - Tabulate the device memory against domain size, for the GPUs in question:
    - A100 40/80 GB;
    - H100 80 GB, H100 NVL 94 GB;
    - H200 141 GB;
    - MI250X (64 GB per GCD), MI300X 192 GB.
  - List the 20 largest consumers and what could shrink them.
- **Output:** `perf/reports/memory-model.md`.
- **Done when:** the estimator agrees with the run within 5 % on S-3M, and the tables are generated by a script.

### P-03 · Static memory-traffic model per kernel
- **Goal:** 2, 6 · **Size:** M · **Area:** perf · **Needs:** cpu · **Depends:** P-04 · **Status:** todo
- **Read:** port/agent/kernels.csv (header); port/tools/ref.py
- **Do:**
  - For every kernel, from its CPU lines:
    - the arrays read and written, the points touched and the bytes moved per call, with the minimum DRAM traffic
      (each array once) and an upper bound (stencil reuse lost);
    - multiplied by the calls per step (P-04), the bytes per d01 and d02 step.
  - The bandwidth floor of a step for A100, H100, MI250X and MI300X.
  - The kernels ranked by predicted time.
- **Output:** `perf/tools/traffic_model.py`; `perf/reports/traffic-model.md`.
- **Done when:** the ranking exists, and its total is compared with the CPU profile's shares (P-01) with comments.

### P-04 · Kernel-launch and call-count model
- **Goal:** 2, 6 · **Size:** S · **Area:** perf · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** plan.md §2.2 (time steps, radiation interval) and §7.4 (launch-count note); `solve_em` call tree (X-01 if
  done)
- **Do:**
  - Count the kernel launches per d01 and per d02 step, by phase:
    - the RK stages;
    - 7 acoustic sub-steps;
    - species loops;
    - radiation steps;
    - fire at RK stage 1.
  - Estimate the launch overhead at 3–8 µs per launch and compare it with the bandwidth floor of P-03.
  - Count, on the CPU, how often each route is entered on S-3M (the call-check counters or the bit-trace), and
    compare with the model.
- **Output:** `perf/reports/launch-model.md`.
- **Done when:** model and S-3M counts agree, or the differences are explained.

### P-05 · Host↔device transfer model, phase by phase
- **Goal:** 2, 6 · **Size:** S · **Area:** perf · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** plan.md P1.5, P1.9, P5.2–P5.4
- **Do:** Model the bytes per step and per run:
  - for each development phase (islands);
  - for the final device world: nest forcing slab, strips and `o3rad`; boundary reads; history; restarts.
  - Give the time over PCIe 4/5 and NVLink-C2C (GH200), and the case of a unified-memory APU (MI300A).
- **Output:** `perf/reports/transfer-model.md`.
- **Done when:** every sync point of plan.md has a byte formula and a number for the Eaton case.

### P-06 · GPU profiling scripts (nsys, ncu, roofline)
- **Goal:** 2 · **Size:** M · **Area:** perf · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** port/h100/window.sh; PHASE6.md P6.1
- **Do:** Write `perf/tools/`:
  - `nsys_window.sh <build> <window>`: an nsys capture with NVTX, then CSV exports of kernel times, memcpy and launch
    gaps;
  - `ncu_top.sh <build> <window> <N>`: ncu on the top-N kernels with the sections SpeedOfLight,
    MemoryWorkloadAnalysis, Occupancy, LaunchStats and SourceCounters;
  - `roofline.py`: the roofline plot from the ncu CSV, with the P-03 predictions overlaid.

  Test the parsers on sample CSVs written by hand.
- **Output:** the scripts; their tests.
- **Done when:** the parser tests pass here. The H100 validation is P-07.

### P-07 · First measured GPU profile (after G2)
- **Goal:** 2, 6 · **Size:** M · **Area:** perf · **Needs:** gpu-nv, data · **Depends:** A-25, P-06, P-03 · **Status:** todo
- **Read:** the P-03, P-04 and P-05 reports
- **Do:**
  - Profile W-100 with the dynamics on the device; the physics are islands.
  - Compare the measured kernel times and bytes with the model.
  - Rank the gaps: launch overhead, low bandwidth, local memory, divergence.
- **Output:** `perf/reports/h100-profile-g2.md`.
- **Done when:** the top 20 kernels have measured and predicted values side by side, with a diagnosis each.

### P-08 · Bottleneck taxonomy and mitigations
- **Goal:** 6 · **Size:** M · **Area:** perf · **Needs:** cpu · **Depends:** P-03, P-04, P-05 · **Status:** todo
- **Read:** the model reports; plan.md §11.3 (O1–O11)
- **Do:** Classify every kernel class, and for each class name its mitigations and mark each one REPRO-safe
  (bit-neutral) or FAST-only. The classes:
  - bandwidth-bound stencils;
  - launch-bound short kernels (the acoustic loop, boundary strips);
  - sequential vertical recurrences (column kernels: parallel only over i and j);
  - local-memory and register-heavy column physics (WSM6, RRTMG, Noah);
  - divergent kernels (WENO fire, night columns, sedimentation sub-steps);
  - host↔device transfers;
  - I/O.
- **Output:** `perf/reports/bottlenecks.md`.
- **Done when:** every kernel of kernels.csv is in a class, and every O-item of plan.md is mapped to a class.

### P-09 · Alternative algorithms study
- **Goal:** 6 · **Size:** M · **Area:** perf · **Needs:** cpu, net · **Depends:** P-08 · **Status:** todo
- **Read:** perf/reports/bottlenecks.md; book/refs.bib
- **Do:** For each bottleneck class, survey the alternatives and say what changes in the results (REPRO-safe,
  FAST-only, or new physics). Cover at least:
  - kernel fusion in the acoustic loop;
  - parallel-in-k tridiagonal solvers (cyclic reduction) against per-column Thomas;
  - RRTMG g-point parallelism with ordered sums, and RRTMGP (the GPU-oriented successor, different code);
  - WSM6 sedimentation with sorted or batched columns;
  - narrow-band level set for the fire;
  - deterministic reductions;
  - mixed layouts (k innermost for column physics).

  Cite sources; quote expected gains only from published measurements, or mark them as estimates.
- **Output:** `perf/reports/alternatives.md`.
- **Done when:** each alternative has: what it changes, the expected gain with its source, its REPRO/FAST status, and
  a go/no-go recommendation.

### P-10 · Fair CPU baseline
- **Goal:** 2, 6 · **Size:** M · **Area:** perf · **Needs:** ccr, data · **Depends:** — · **Status:** todo
- **Read:** cases/eaton_20250108/README.md (the original CCR build)
- **Do:**
  - Time the original optimized CPU build (FMA, -O3) and CPU-REF on 1, 2 and 4 CCR nodes for 1 simulated hour.
  - Record the cost per simulated hour in node-hours, and the energy if RAPL or the scheduler reports it.
  - GPU speedups are quoted against the best CPU configuration, never against one core.
- **Output:** `perf/reports/cpu-baseline.md`.
- **Done when:** the table exists with the job scripts.

### P-11 · Full-run profile on the H100 (Phase 6 metrics)
- **Goal:** 2 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** A-29, P-06 · **Status:** todo
- **Read:** PHASE6.md P6.1
- **Do:** Fill `port/PERF.md` for the H100:
  - seconds per simulated hour per domain;
  - shares per NVTX range;
  - the top 20 kernels;
  - the roofline;
  - launch gaps;
  - peak memory;
  - speedup against P-10.
- **Output:** `port/PERF.md`.
- **Done when:** P6.1 is complete for the H100.

### P-12 · FAST mode: design and statistical test
- **Goal:** 6 · **Size:** S · **Area:** perf · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** ADR-003; refs Baker et al. 2015 and Milroy et al. 2018 (in book/refs.bib)
- **Do:**
  - Specify the FAST build: flags, which `rp_*` map to vendor intrinsics, and the macros for reassociating kernels.
  - Specify the statistical test for a regional fire model, with the ensemble size and the pass/fail rule:
    - an ensemble of REPRO runs with O(ulp) initial perturbations;
    - field-distribution metrics per hour;
    - the fire-perimeter envelope.
- **Output:** `perf/reports/fast-mode-design.md` (ADR-003 annex).
- **Done when:** the design names every flag and every metric, with the pass rule.

### P-13 · FAST build mode
- **Goal:** 6 · **Size:** S · **Area:** port · **Needs:** cpu · **Depends:** P-12 · **Status:** todo
- **Read:** perf/reports/fast-mode-design.md; port/h100/build.sh
- **Do:** Add the `gpu-fast` and `gnu-fast` modes (tool fix) and the `REPRO_MATH`-off path of `module_repro_math`
  (it exists: intrinsics when `REPRO_MATH` is undefined).
- **Output:** build.sh changes; a TOOL_FIXES.md entry.
- **Done when:** gnu-fast builds and runs S-3M, and gnu-ref is unchanged.

### P-14 · FAST validation runs
- **Goal:** 6 · **Size:** M · **Area:** perf · **Needs:** gpu-nv, data · **Depends:** P-13, A-29 · **Status:** todo
- **Read:** the P-12 design
- **Do:** Run the REPRO ensemble and the FAST run, apply the test, time both.
- **Output:** `perf/reports/fast-mode-validation.md`.
- **Done when:** pass/fail and the speedup of FAST over REPRO are reported (the cost of reproducibility).

### P-15 · Energy to solution
- **Goal:** 6 · **Size:** S · **Area:** port · **Needs:** gpu-nv, ccr · **Depends:** P-11, P-10 · **Status:** todo
- **Read:** perf/reports/cpu-baseline.md
- **Do:** Sample the GPU power (`nvidia-smi --query-gpu=power.draw -lms 100`) and the host power during 1 simulated
  hour, and compare kWh per simulated hour with the CPU baseline.
- **Output:** a section in `port/PERF.md`.
- **Done when:** the table exists with the commands.

### P-21 · Optimization O1: fire NaN checks out of production builds
- **Goal:** 6 · **Size:** S · **Area:** port · **Needs:** gpu-nv, data · **Depends:** P-11 · **Status:** todo
- **Read:** PHASE6.md P6.2 (O1)
- **Do:** Implement O1 (bit-neutral).
- **Output:** commit.
- **Done when:** T-REG-20, T-TRACE-100 and T-TRACE-RAD are bitwise, and the timing gain is recorded in PERF.md.

### P-22 · Optimization O2: merged boundary-strip and zero/copy kernels
- **Goal:** 6 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** P-11 · **Status:** todo
- **Read:** PHASE6.md (O2)
- **Do:** Implement O2.
- **Output:** commit.
- **Done when:** as P-21.

### P-23 · Optimization O3: asynchronous independent kernels
- **Goal:** 6 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** P-11 · **Status:** todo
- **Read:** PHASE6.md (O3)
- **Do:** Implement O3 (`nowait`, `depend`).
- **Output:** commit.
- **Done when:** as P-21.

### P-24 · Optimization O4/O5: launch configuration and register tuning per GPU
- **Goal:** 6 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** P-11 · **Status:** todo
- **Read:** PHASE6.md (O4, O5)
- **Do:** Implement O4 and O5.
- **Output:** commit; per-GPU settings in ENVIRONMENT.md.
- **Done when:** as P-21.

### P-25 · Optimization O6: RRTMG performance version
- **Goal:** 6 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** P-11 · **Status:** todo
- **Read:** plan.md §8.5 (performance version)
- **Do:** Implement K-RRTMG-TAU, RT1 and RT2 with the sums kept in order.
- **Output:** commit.
- **Done when:** as P-21, plus T-RRTMG-COL.

### P-26 · Optimization O7: fusion of pointwise sequences
- **Goal:** 6 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** P-11 · **Status:** todo
- **Read:** PHASE6.md (O7)
- **Do:** Implement O7.
- **Output:** commit.
- **Done when:** as P-21.

### P-27 · Optimization O8–O11: output, restarts, o3rad, forcing transfer
- **Goal:** 6 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** P-11 · **Status:** todo
- **Read:** PHASE6.md (O8–O11)
- **Do:** Implement O8 to O11. Split this card if more than one of them is large.
- **Output:** commits.
- **Done when:** as P-21, plus T-O3 and a restart written while `o3rad` is dirty is bitwise.

---

## Track M — multi-GPU

### M-01 · Halo-exchange model of RSL_LITE
- **Goal:** 2 · **Size:** M · **Area:** perf · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** `WRF/dyn_em/solve_em.F` (HALO_EM_* includes, through grep); `WRF/external/RSL_LITE` (rsl_comm, f_pack)
- **Do:**
  - List every halo exchange per d01 and d02 step: the include, the fields, the width, and where it sits in the RK
    and acoustic loops.
  - Compute the bytes per exchange as a function of the decomposition, for 2, 4 and 8 GPUs, and the time over NVLink
    (intra-node) and InfiniBand (inter-node).
- **Output:** `perf/reports/halo-model.md`.
- **Done when:** the count matches a grep of the generated halo includes, and the model has formulas and numbers for
  the Eaton case.

### M-02 · Decomposition independence on the CPU with MPI
- **Goal:** 2 · **Size:** M · **Area:** port · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** plan.md P0.10 (T-DEC); port/h100/build.sh
- **Do:**
  - Build gnu-ref as dmpar, with OpenMPI built into `$WORK/deps` if mpif90 is missing.
  - Run S-3M on 1, 2 and 4 ranks and compare bitwise.
  - On failure, bisect with the trace to the first decomposition-dependent routine.
- **Output:** `build.sh` gnu-mpi mode (tool fix); a task log file.
- **Done when:** 1, 2 and 4 ranks are bitwise identical, or the culprits are recorded in BLOCKERS.md.

### M-03 · Design of device-resident halos with GPU-aware MPI
- **Goal:** 2, 5 · **Size:** M · **Area:** roadmap · **Needs:** cpu · **Depends:** M-01 · **Status:** todo
- **Read:** perf/reports/halo-model.md; RSL_LITE pack/unpack code
- **Do:**
  - Design the device pack and unpack kernels: halos are pure copies, so they are bitwise by construction.
  - Pass device pointers to MPI (`use_device_addr`). This needs CUDA-aware or ROCm-aware MPI, with a host-staging
    fallback.
  - Overlap halos with interior computation where the dependencies allow it.
  - Cover nest forcing across ranks, and keep it portable to AMD.
- **Output:** `roadmap/decisions/ADR-005-multi-gpu.md` (proposed).
- **Done when:** the ADR names every RSL_LITE routine to change and the test plan (T-DEC-GPU).

### M-04 · Implement device halos (CPU-testable part)
- **Goal:** 2, 5 · **Size:** M · **Area:** port · **Needs:** cpu · **Depends:** M-02, M-03 · **Status:** todo
- **Read:** ADR-005
- **Do:** Implement the pack and unpack kernels under `WRF_GPU`. On the CPU, gnu-gpu dmpar runs them on the host:
  1, 2 and 4 ranks must be bitwise.
- **Output:** RSL_LITE changes.
- **Done when:** gnu-gpu dmpar on 1, 2 and 4 ranks is bitwise to gnu-ref with 1 rank.

### M-05 · Multi-GPU runs on the H100 node
- **Goal:** 2 · **Size:** M · **Area:** port · **Needs:** gpu-nv, data · **Depends:** M-04, A-29 · **Status:** todo
- **Read:** ADR-005
- **Do:**
  - Run the full case on 1, 2, 4 and 8 GPUs: T-DEC-GPU bitwise against 1 GPU.
  - Measure strong scaling with nsys halo timing.
  - Test whether 2× A100 40 GB fit the case.
- **Output:** a multi-GPU section in `port/PERF.md`.
- **Done when:** bitwise on every count, and the scaling table is recorded.

### M-06 · Multi-GPU performance report
- **Goal:** 2, 6 · **Size:** S · **Area:** perf · **Needs:** cpu · **Depends:** M-01, M-05 · **Status:** todo
- **Read:** the halo model; the M-05 measurements
- **Do:**
  - Explain the measured scaling with the model.
  - Say when more GPUs pay off: domain size per GPU, interconnect, nest layout.
- **Output:** `perf/reports/multi-gpu.md`.
- **Done when:** model and measurement agree within the stated uncertainty, or the gap is explained.

---

## Track X — architecture and design of WRF and WRF-Fire

### X-01 · Architecture map of WRF
- **Goal:** 3 · **Size:** M · **Area:** roadmap · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** explain-wrf.md; `WRF/main/module_wrf_top.F`, `frame/module_integrate.F`, `dyn_em/solve_em.F` (ranges
  only)
- **Do:** Document:
  - the layers: driver, mediation, model;
  - the domain type and the index ranges (ids, ims, ips, its);
  - tiles and patches;
  - the time loop;
  - the `solve_em` call tree to depth 3, with file:line and the work package of each routine;
  - halo and period includes;
  - the I/O API.
- **Output:** `roadmap/architecture/wrf.md`.
- **Done when:** every routine in the call tree has a file:line that `index.py` confirms.

### X-02 · The Registry and code generation
- **Goal:** 3 · **Size:** S · **Area:** roadmap · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** `WRF/tools/registry.c`, `gen_allocs.c`, `gen_defs.c` (ranges); a Registry entry of each kind
- **Do:**
  - Explain how one Registry line becomes the declaration, the allocation, the I/O, the halo and the nest
    interpolation code.
  - Show where the port hooks in (gen_gpu, gen_allocs, i1 pool).
- **Output:** `roadmap/architecture/registry.md`.
- **Done when:** one field is traced through every generated file, with file:line.

### X-03 · WRF-Fire architecture
- **Goal:** 3 · **Size:** M · **Area:** roadmap · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** `WRF/phys/module_fr_fire_driver.F`, `_model.F`, `_core.F`, `_phys.F`, `_atm.F`, `_util.F` (ranges); PHASE4.md
- **Do:** Document:
  - the fire grid and the refinement;
  - the `fire_driver_em` stages (ifun 1–6);
  - the atmosphere → fire interpolation;
  - level-set propagation and reinitialization;
  - spread rate;
  - fuel consumption;
  - heat fluxes and their feedback into the atmosphere;
  - the call tree with file:line and kernel IDs.
- **Output:** `roadmap/architecture/wrf-fire.md`.
- **Done when:** every Phase 4 kernel is placed in the document.

### X-04 · Data layout and GPU memory access
- **Goal:** 3, 6 · **Size:** S · **Area:** roadmap · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** CODING_STANDARD.md templates A, C and D
- **Do:** Analyse the (i,k,j) layout on GPUs:
  - which templates coalesce;
  - which access patterns stride (column physics gather/scatter, boundary strips along j);
  - the cost of the layout for k-recurrences;
  - what a different layout would cost (transposes) and gain.
- **Output:** `roadmap/architecture/data-layout.md`.
- **Done when:** each template has its access pattern and a predicted efficiency, to be checked by P-07.

### X-05 · Refactoring proposals for GPU-friendly WRF
- **Goal:** 3 · **Size:** M · **Area:** roadmap · **Needs:** cpu · **Depends:** X-01 · **Status:** todo
- **Read:** roadmap/architecture/*; port/agent/REFACTORS.md
- **Do:** Rank refactorings by benefit and cost that would make WRF easier to run on GPUs without changing results.
  Say which of them NCAR has started (physics_mmm, CCPP-style interfaces) and which could go upstream:
  - automatic arrays → work arrays;
  - slab physics → column interfaces;
  - init separated from the step;
  - EQUIVALENCE removal;
  - error codes in place of `wrf_error_fatal` in the physics;
  - Registry-generated device mapping;
  - fewer `grid%` references inside loops.
- **Output:** `roadmap/architecture/refactoring.md`.
- **Done when:** each proposal has an example from the port with file:line, and an effort estimate.

### X-06 · Related GPU work on WRF and similar models
- **Goal:** 3, 9 · **Size:** M · **Area:** roadmap · **Needs:** cpu, net · **Depends:** — · **Status:** todo
- **Read:** ADR-001
- **Do:**
  - Survey published GPU ports and their programming models: GPU WRF physics modules, commercial GPU WRF, MPAS,
    E3SM/SCREAM, ICON, COSMO, FV3 and others found.
  - Give the reported speedups with their baselines.
  - Verify every claim at its source, and cite only what you have checked.
- **Output:** `roadmap/analysis/related-work.md`, with proposed bibliography entries for the book (card B-02 adds them).
- **Done when:** every row has a checked citation, and ADR-001 is either confirmed or flagged for review.

### X-07 · physics_mmm, MPAS and the upstream path
- **Goal:** 3 · **Size:** S · **Area:** roadmap · **Needs:** cpu, net · **Depends:** — · **Status:** todo
- **Read:** `WRF/phys/physics_mmm` (file list); the MPAS-Model repository (physics_mmm usage)
- **Do:** Explain how physics_mmm is shared by WRF and MPAS, and what that means for upstreaming the column ports
  (WSM6, sfclayrev, YSU).
- **Output:** a section in `roadmap/architecture/refactoring.md`.
- **Done when:** the shared files and the upstream repositories are named.

---

## Track C — CFBM, NCAR's Community Fire Behavior Model (analysis: roadmap/analysis/cfbm.md)

Stage 3: no card of this track starts before A-29, and the integration cards wait for track V.

### C-01 · Build and run CFBM standalone on the CPU
- **Goal:** 4 · **Size:** S · **Area:** cfbm · **Needs:** cpu, net · **Depends:** A-29 · **Status:** todo
- **Read:** roadmap/analysis/cfbm.md; the CFBM README and docs
- **Do:**
  - Clone NCAR/fire_behavior at the WRF 4.8.0 pin (`eb77580`) and at `main`.
  - Build the standalone driver with gfortran and CMake: netCDF from `$WORK/deps`, no ESMF.
  - Run its example case.
- **Output:** `cfbm/README.md` (the build steps); `cfbm/build.sh`.
- **Done when:** the example runs and its output is archived with md5.

### C-02 · CFBM kernel inventory and mapping to Phase 4
- **Goal:** 4 · **Size:** M · **Area:** cfbm · **Needs:** cpu · **Depends:** C-01 · **Status:** todo
- **Read:** CFBM `physics/`, `state/`; PHASE4.md kernel table
- **Do:**
  - List every loop nest executed per step, with file:line.
  - Map each to its Phase 4 kernel and to the SFIRE lines.
  - Note every algorithmic difference from SFIRE 4.6.0.
- **Output:** `cfbm/KERNELS.md`.
- **Done when:** every per-step loop is listed and mapped or marked new.

### C-03 · Reproducible build and bit-trace for CFBM
- **Goal:** 4 · **Size:** M · **Area:** cfbm · **Needs:** cpu · **Depends:** C-01 · **Status:** todo
- **Read:** module_repro_math, module_bittrace (interfaces); port/rp_subst.py (usage)
- **Do:**
  - Add the REPRO flags.
  - Apply the `rp_*` substitutions in CFBM's physics.
  - Add a per-step hash of the fire state, in standalone mode.
  - Check that two runs are bitwise and that 1 and 4 OpenMP threads (CPU) are bitwise.
- **Output:** CFBM patches in `cfbm/`, applied to an imported copy (`WRF/phys/fire_behavior` on the 4.8 line).
- **Done when:** the standalone traces are reproducible.

### C-04 · Device data plan for the CFBM state
- **Goal:** 4 · **Size:** M · **Area:** cfbm · **Needs:** cpu · **Depends:** C-02 · **Status:** todo
- **Read:** cfbm/KERNELS.md; PHASE1.md P1.2 (mapping by address)
- **Do:** Design and write the mapping of the `fire_state` components (by address, not `map(state%x)`), the work
  arrays and the module tables.
- **Output:** `cfbm/DEVICE.md`; skeleton module.
- **Done when:** a T-MAP-style presence test of every component passes on the CPU (gnu-gpu).

### C-05 · Port the CFBM level-set propagation
- **Goal:** 4 · **Size:** M · **Area:** cfbm · **Needs:** cpu · **Depends:** C-03, C-04 · **Status:** todo
- **Read:** cfbm/KERNELS.md (level set rows)
- **Do:** Port the tendency (WENO/ENO, normals, spread-rate call) and the RK stages, under a `CFBM_GPU` macro, with
  the same rules as the WRF port.
- **Output:** commits.
- **Done when:** the standalone trace is bitwise on gnu-gpu at 1 and 4 threads.

### C-06 · Port the CFBM reinitialization
- **Goal:** 4 · **Size:** S · **Area:** cfbm · **Needs:** cpu · **Depends:** C-05 · **Status:** todo
- **Read:** cfbm/KERNELS.md
- **Do:** as C-05 for the reinitialization.
- **Output:** commits.
- **Done when:** as C-05.

### C-07 · Port the CFBM spread rate and fuel moisture
- **Goal:** 4 · **Size:** S · **Area:** cfbm · **Needs:** cpu · **Depends:** C-04 · **Status:** todo
- **Read:** cfbm/KERNELS.md
- **Do:** as C-05 for `ros_wrffire_mod`, `fmc_wrffire_mod` and `fuel_anderson_mod`.
- **Output:** commits.
- **Done when:** as C-05.

### C-08 · Port the CFBM ignition, fuel consumption and heat fluxes
- **Goal:** 4 · **Size:** M · **Area:** cfbm · **Needs:** cpu · **Depends:** C-04 · **Status:** todo
- **Read:** cfbm/KERNELS.md
- **Do:** as C-05.
- **Output:** commits.
- **Done when:** as C-05.

### C-09 · CFBM standalone on the H100
- **Goal:** 4 · **Size:** M · **Area:** cfbm · **Needs:** gpu-nv · **Depends:** C-05, C-06, C-07, C-08 · **Status:** todo
- **Read:** cfbm/DEVICE.md
- **Do:** Build with nvfortran, CPU against GPU bitwise on the example case and a large synthetic grid, then time it.
- **Output:** `cfbm/RESULTS.md`.
- **Done when:** bitwise, and the speedup over one CPU node is recorded.

### C-10 · CFBM inside WRF 4.8.0 (ifire = 1) on the device
- **Goal:** 4 · **Size:** M · **Area:** cfbm · **Needs:** cpu · **Depends:** C-08, V-08 · **Status:** todo
- **Read:** the WRF coupling (`start_em`, `module_first_rk_step_part1` in 4.8.0); cfbm.md
- **Do:**
  - Port `Interp_wrfwinds_to_cfbm` and `Provide_atm_feedback`, with data residency between `grid` and
    `grid%fire_state`.
  - Run S-3M with `ifire = 1`: gnu-ref against gnu-gpu.
- **Output:** commits on `port/v4.8`.
- **Done when:** S-3M with `ifire = 1` is bitwise at 1 and 4 threads.

### C-11 · CFBM in WRF on the H100
- **Goal:** 4 · **Size:** M · **Area:** cfbm · **Needs:** gpu-nv, data · **Depends:** C-10, V-13 · **Status:** todo
- **Read:** cfbm/RESULTS.md
- **Do:** Run the Eaton case with `ifire = 1`: GPU against CPU-REF bitwise in a window, then the full run.
- **Output:** RESULTS.md (CFBM section).
- **Done when:** the window is bitwise and the full run completes (milestone M6).

### C-12 · Offer the GPU port upstream to NCAR
- **Goal:** 4, 8 · **Size:** S · **Area:** cfbm · **Needs:** owner · **Depends:** C-09 · **Status:** todo
- **Read:** the CFBM contribution guidelines
- **Do:** Prepare an issue and a pull-request branch for NCAR/fire_behavior: the directives behind a macro, the tests
  and the results. The owner decides when to contact NCAR.
- **Output:** a proposal in `cfbm/UPSTREAM.md`.
- **Done when:** the owner has the proposal.

### C-13 · Track upstream CFBM changes (repeatable: C-13a, C-13b, ...)
- **Goal:** 4 · **Size:** S · **Area:** cfbm · **Needs:** cpu, net · **Depends:** C-02, A-29 · **Status:** todo
- **Read:** cfbm/KERNELS.md
- **Do:** Diff NCAR/fire_behavior `main` against the pinned commit, update `roadmap/analysis/cfbm.md` and list the
  kernels affected.
- **Output:** the analysis update.
- **Done when:** the update is committed.

---

## Track G — NVIDIA, AMD and other GPUs (ADR-001)

### G-00 · Find AMD GPU access
- **Goal:** 5 · **Size:** S · **Area:** roadmap · **Needs:** owner · **Depends:** — · **Status:** todo
- **Read:** ADR-001
- **Do:**
  - List the realistic ways to get MI250X or MI300 time: cloud offers, research allocations, vendor developer
    programmes.
  - Give the cost and lead time of each, verified at the source.
- **Output:** a short note in `roadmap/analysis/amd-access.md`.
- **Done when:** the owner has chosen one.

### G-01 · AMD compiler probes
- **Goal:** 5 · **Size:** M · **Area:** port · **Needs:** gpu-amd · **Depends:** G-00, G-04 · **Status:** todo
- **Read:** port/tests/omp_features; port/tests/repro_math
- **Do:** Run every feature probe and T-FMA, T-SUBNORM and T-RM-* with `amdflang`, and with HPE CCE if available.
- **Output:** an AMD section in `port/ENVIRONMENT.md`.
- **Done when:** every probe result is recorded, with a fallback for each failure.

### G-02 · Compile the GPU view with LLVM Flang (compile only)
- **Goal:** 5 · **Size:** M · **Area:** roadmap · **Needs:** cpu, net · **Depends:** — · **Status:** todo
- **Read:** port/agent/BUILD_SYSTEM.md
- **Do:**
  - Get LLVM Flang, from a release tarball or the ROCm container.
  - Compile the files the port touches with `-fopenmp`, and with `--offload-arch=gfx90a` if the device libraries
    are available.
  - List every error and warning in device code: unsupported constructs, nvfortran extensions.
- **Output:** `roadmap/analysis/flang-portability.md`.
- **Done when:** every touched file is compiled or its error is classified.

### G-03 · Portability lint for device code
- **Goal:** 5 · **Size:** S · **Area:** review · **Needs:** cpu · **Depends:** G-02 · **Status:** todo
- **Read:** roadmap/analysis/flang-portability.md
- **Do:**
  - Write `port/portability/check_portable.py`. It flags constructs known not to work on a target compiler, for
    example vendor-only directives and `-Minfo`-dependent assumptions.
  - Add it to the reviewer's checklist. It does not enter `static.sh` until the owner agrees.
- **Output:** the checker and its tests.
- **Done when:** it flags each construct found in G-02 and passes on clean code.

### G-04 · AMD build modes
- **Goal:** 5 · **Size:** S · **Area:** port · **Needs:** cpu · **Depends:** G-02 · **Status:** todo
- **Read:** port/h100/build.sh; ADR-001 table
- **Do:**
  - Add configure stanzas and build modes `amd-ref`, `amd-repro` (amdflang) and `cce-repro` (HPE CCE).
  - Use the REPRO flags of each compiler: no FP contraction, no fast math, denormals kept on the device.
  - Mark which flags are confirmed and which still need G-01.
- **Output:** stanzas; build.sh (tool fix).
- **Done when:** the CPU-side mode (`amd-ref`) builds here if LLVM Flang is available, or the stanza is reviewed
  against the compiler documentation.

### G-05 · AMD: smoke case and harness bitwise
- **Goal:** 5 · **Size:** M · **Area:** port · **Needs:** gpu-amd · **Depends:** G-01, G-04, A-03 · **Status:** todo
- **Read:** CODE_ONLY.md §7
- **Do:** Run the cpu_verify comparisons with `amd-ref` against `amd-repro` on the AMD GPU: S-3M and the harness.
- **Output:** RESULTS.md (AMD section).
- **Done when:** bitwise, or each difference is traced to a compiler issue with a minimal reproducer.

### G-06 · Cross-compiler reproducibility (REPRO semantics everywhere)
- **Goal:** 5 · **Size:** S · **Area:** roadmap · **Needs:** cpu · **Depends:** G-04 · **Status:** todo
- **Read:** ADR-003; port/tests/repro_math
- **Do:**
  - Compare S-3M from gnu-ref (gfortran) against amd-ref (LLVM Flang, CPU), here.
  - Add a card G-06b for the same comparison against cpu-ref (nvfortran), which runs where the NVHPC container is
    (the H100 machine; no GPU is used).
  - REPRO uses only IEEE basic operations and our own elementary functions, so the results should agree across
    compilers.
  - Find the first difference with the trace and classify it: constant folding, intrinsic, conversion.
- **Output:** `roadmap/analysis/cross-compiler.md`.
- **Done when:** the pairs are bitwise, or every difference has a cause and a proposed fix. Bitwise across
  compilers would mean identical results on every vendor's GPU.

### G-07 · Other NVIDIA GPUs
- **Goal:** 5 · **Size:** S · **Area:** port · **Needs:** gpu-nv · **Depends:** A-29 · **Status:** todo
- **Read:** port/PERF.md
- **Do:** Run W-20 and 1 simulated hour on any other NVIDIA GPU available: A100, L40S or GH200. On GH200, try the
  unified-memory build as a FAST variant.
- **Output:** PERF.md rows.
- **Done when:** bitwise against the H100 run, and the timing is recorded.

### G-08 · Intel GPUs (optional)
- **Goal:** 5 · **Size:** S · **Area:** roadmap · **Needs:** cpu, net · **Depends:** G-02 · **Status:** todo
- **Read:** roadmap/analysis/flang-portability.md
- **Do:** Compile only with `ifx -fiopenmp -fopenmp-targets=spir64`, if the compiler can be obtained.
- **Output:** a section in flang-portability.md.
- **Done when:** the result is recorded.

---

## Track B — the book (book/)

Every chapter cites the WRF source (file and routine), the WRF Technical Note (Skamarock et al. 2019) or papers in
`book/refs.bib`. It is written from the code and the cited sources; the port's documents give the implementation
side. A chapter is done when CI builds the book without errors or undefined references, and every equation names the
routine that implements it.

### B-01 · Book build and CI
- **Goal:** 7 · **Size:** S · **Area:** book · **Needs:** cpu, net · **Depends:** — · **Status:** done db1ba9f
- **Read:** book/README.md
- **Do:** The skeleton, `latexmk` build, and a GitHub Actions job that builds the PDF when `book/` changes.
- **Output:** book/; `.github/workflows/book.yml`.
- **Done when:** the CI job builds the PDF.

### B-02 · Check the bibliography
- **Goal:** 7 · **Size:** S · **Area:** book · **Needs:** net · **Depends:** B-01 · **Status:** todo
- **Read:** book/refs.bib
- **Do:** Check every entry against the publisher (authors, title, journal, volume, pages, year) and add DOIs.
- **Output:** refs.bib.
- **Done when:** every entry has been checked; the entries not checked yet are marked in a comment.

### B-03 · Chapter: governing equations and the vertical coordinate
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** B-01 · **Status:** todo
- **Read:** book/chapters/03-equations.tex outline; the Technical Note ch. 2; `module_big_step_utilities_em.F`
- **Do:** Write the chapter as outlined.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-04 · Chapter: time integration (RK3, split-explicit acoustic steps)
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** B-03 · **Status:** todo
- **Read:** chapter outline; `module_small_step_em.F`; Wicker & Skamarock 2002; Klemp et al. 2007
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-05 · Chapter: spatial discretization and advection
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** B-03 · **Status:** todo
- **Read:** chapter outline; `module_advect_em.F`; Skamarock & Weisman 2009
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-06 · Chapter: boundaries and nesting
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** B-03 · **Status:** todo
- **Read:** chapter outline; `module_bc.F`, `module_bc_em.F`, `mediation_force_domain.F`
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-07 · Chapter: turbulence and diffusion
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** B-03 · **Status:** todo
- **Read:** chapter outline; `module_diffusion_em.F`
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-08 · Chapter: microphysics (WSM6)
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** B-01 · **Status:** todo
- **Read:** chapter outline; `physics_mmm/mp_wsm6.F90`; Hong & Lim 2006
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-09 · Chapter: radiation (RRTMG LW, Dudhia SW)
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** B-01 · **Status:** todo
- **Read:** chapter outline; `module_ra_rrtmg_lw.F`, `module_ra_sw.F`; Mlawer et al. 1997; Iacono et al. 2008;
  Pincus et al. 2003; Dudhia 1989
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-10 · Chapter: surface layer and land surface (sfclayrev, Noah)
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** B-01 · **Status:** todo
- **Read:** chapter outline; `physics_mmm/sf_sfclayrev.F90`, `module_sf_noahlsm.F`; Jiménez et al. 2012; Chen &
  Dudhia 2001
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-11 · Chapter: planetary boundary layer (YSU)
- **Goal:** 7 · **Size:** S · **Area:** book · **Needs:** cpu · **Depends:** B-01 · **Status:** todo
- **Read:** chapter outline; `physics_mmm/bl_ysu.F90`; Hong et al. 2006
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-12 · Chapter: WRF-Fire
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** X-03 · **Status:** todo
- **Read:** chapter outline; roadmap/architecture/wrf-fire.md; Coen et al. 2013; Mandel et al. 2011; Muñoz-Esparza
  et al. 2018; Rothermel 1972
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-13 · Chapter: CFBM
- **Goal:** 7 · **Size:** S · **Area:** book · **Needs:** cpu · **Depends:** C-02 · **Status:** todo
- **Read:** chapter outline; cfbm/KERNELS.md
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-14 · Chapter: software architecture
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** X-01, X-02 · **Status:** todo
- **Read:** chapter outline; roadmap/architecture/wrf.md, registry.md
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-15 · Chapter: floating-point reproducibility (finish the draft)
- **Goal:** 7 · **Size:** S · **Area:** book · **Needs:** cpu · **Depends:** B-01 · **Status:** todo
- **Read:** book/chapters/15-reproducibility.tex (draft); module_repro_math; port/tests/repro_math
- **Do:** Complete the draft: the test results from `port/RESULTS.md` and the table of probes.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-16 · Chapter: GPUs and OpenMP offload for Fortran
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** B-01 · **Status:** todo
- **Read:** chapter outline; ADR-001; CODING_STANDARD.md
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-17 · Chapter: the port, phase by phase
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** A-27 · **Status:** todo
- **Read:** chapter outline; plan.md; port/RESULTS.md
- **Do:** Write the chapter up to the phase reached. Repeat the card (B-17a, ...) when later phases pass.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-18 · Chapter: performance
- **Goal:** 7 · **Size:** M · **Area:** book · **Needs:** cpu · **Depends:** P-11, P-08 · **Status:** todo
- **Read:** chapter outline; perf/reports
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-19 · Chapter: multi-GPU
- **Goal:** 7 · **Size:** S · **Area:** book · **Needs:** cpu · **Depends:** M-06 · **Status:** todo
- **Read:** chapter outline; perf/reports/multi-gpu.md
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-20 · Chapter: WRF versions
- **Goal:** 7 · **Size:** S · **Area:** book · **Needs:** cpu · **Depends:** V-01 · **Status:** todo
- **Read:** chapter outline; roadmap/analysis/wrf-4.6.0-to-4.8.0.md
- **Do:** Write the chapter.
- **Output:** the chapter.
- **Done when:** see the track rule.

### B-21 · Appendices: kernel catalogue and case namelist
- **Goal:** 7 · **Size:** S · **Area:** book · **Needs:** cpu · **Depends:** B-01 · **Status:** todo
- **Read:** port/agent/kernels.csv (header); cases/eaton_20250108/namelist.input
- **Do:** Generate the kernel-catalogue appendix from kernels.csv with a script (`book/tools/kernels_tex.py`), and
  write the annotated case namelist.
- **Output:** the appendices; the script.
- **Done when:** the appendix is generated and builds.

---

## Track R — release to the community

### R-01 · License decision
- **Goal:** 8 · **Size:** S · **Area:** roadmap · **Needs:** owner · **Depends:** — · **Status:** todo
- **Read:** WRF/LICENSE.txt; the CFBM LICENSE (Apache-2.0)
- **Do:** Write `roadmap/decisions/ADR-004-license.md` (proposed). It must:
  - keep the UCAR notice on WRF code;
  - propose a license for the port's own files (tools, tests, documents, book) and for our changes to WRF files;
  - check compatibility with CFBM's Apache-2.0.
- **Output:** the ADR.
- **Done when:** the owner has decided.

### R-02 · Release hygiene scan
- **Goal:** 8 · **Size:** S · **Area:** roadmap · **Needs:** cpu · **Depends:** — · **Status:** todo
- **Read:** TASK_PROTOCOL.md §5
- **Do:**
  - Scan the repository for private data: e-mail addresses, cluster user names and paths, host names, tokens.
  - Scan for large files and for files that must not ship.
  - Write a report with a proposed fix for each hit.
- **Output:** `roadmap/analysis/release-hygiene.md`.
- **Done when:** the report lists every hit, and the owner has approved the fixes.

### R-03 · Continuous integration for the port
- **Goal:** 8 · **Size:** M · **Area:** review · **Needs:** cpu, net · **Depends:** A-01 · **Status:** todo
- **Read:** port/gates/cpu_verify.sh
- **Do:**
  - Write a GitHub Actions workflow: `static.sh`, the gnu-ref and gnu-gpu builds, and the S-3M comparisons.
  - Run it on pull requests and by hand, not on every push. Builds take tens of minutes, and Actions minutes cost
    money on private repositories.
  - Cache the deps build.
- **Output:** `.github/workflows/cpu-verify.yml`.
- **Done when:** a run passes on the handoff branch.

### R-04 · User guide
- **Goal:** 8 · **Size:** M · **Area:** docs · **Needs:** cpu · **Depends:** A-29 · **Status:** todo
- **Read:** plan.md §2.3 (supported options); port/agent/ENV_H100.md
- **Do:** Write `docs/USER_GUIDE.md`. Its readers are users, not agents:
  - what is supported;
  - how to build and run on one GPU;
  - how to check a new case;
  - what results and speed to expect;
  - how to report problems.
- **Output:** the guide.
- **Done when:** someone outside the project can follow it on a fresh machine.

### R-05 · Containers for users
- **Goal:** 8 · **Size:** S · **Area:** docs · **Needs:** cpu · **Depends:** G-04 · **Status:** todo
- **Read:** port/container
- **Do:** Provide user-facing container definitions for NVIDIA (NVHPC) and AMD (ROCm with amdflang), with the deps
  built.
- **Output:** `docs/containers/`.
- **Done when:** the definitions build (on any machine with Apptainer).

### R-06 · Community files
- **Goal:** 8 · **Size:** S · **Area:** docs · **Needs:** cpu · **Depends:** R-01 · **Status:** todo
- **Read:** —
- **Do:** Add `CITATION.cff`, `CONTRIBUTING.md` (pointing to TASK_PROTOCOL.md and the port rules), a code of conduct,
  and issue and pull-request templates.
- **Output:** the files.
- **Done when:** they exist and are consistent with ADR-004.

### R-07 · Release v0.1 (WRF 4.6.0 + WRF-Fire, one NVIDIA GPU, REPRO)
- **Goal:** 8 · **Size:** S · **Area:** review · **Needs:** owner · **Depends:** A-29, R-01, R-02, R-04, R-06 · **Status:** todo
- **Read:** RESULTS.md (G5)
- **Do:** Prepare the release notes, the tag and the archive (for example a Zenodo DOI). The owner publishes.
- **Output:** release notes.
- **Done when:** the owner has published.

### R-08 · Announce
- **Goal:** 8 · **Size:** S · **Area:** roadmap · **Needs:** owner · **Depends:** R-07 · **Status:** todo
- **Read:** the release notes
- **Do:** Draft the announcements for the WRF user community and NCAR contacts. The owner sends them.
- **Output:** drafts in `roadmap/analysis/announce.md`.
- **Done when:** the owner has the drafts.
