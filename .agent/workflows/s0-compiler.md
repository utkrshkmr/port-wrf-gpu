---
description: The compiler decision (STAGE0_HANDOFF.md section 3, FIX_LEDGER F-08): steps 1a, 1b, 1c
---
Follow `port/agent/STAGE0_HANDOFF.md` §3 literally, one step per plan/approval cycle:
1. **1a** – the per-file `-O1` list (`port/h100/o1_files.txt`, `build.sh`, `check_build_flags.py` if needed, the
   self-test, TOOL_FIXES row, FIX_LEDGER F-08 "exact change"). Test: `python3 port/tests/tools/test_agent_tools.py`
   and `bash port/gates/static.sh`. Commit, push.
2. **1b** – two NVHPC 25.1 CPU-REF builds (`O1_LIST=none` and `nest_init_utils.o` only), object-file diff, gdb
   coverage of `nest_init_utils` routines in W-T0, W-T0 comparison with `compare.sh`, harness per routine.
   The builds take 10–60 min each: run them under nohup, poll the logs. Record the outcome in RESULTS.md
   ("Compiler decision") and FIX_LEDGER F-08. Commit, push.
   - `RESULT: IDENTICAL` everywhere → go to 1c.
   - any difference → write BLOCKERS B5 with the differing fields/routines, commit, push, and STOP: the owner
     decides.
3. **1c** – pin 26.1 (env.local.sh, persistent deps-26.1, clean build with zero crashes, T-SYM, device tests on both
   GPUs, `machine.sh detect`, `t_machine.sh` PASS, gpu-repro build, gpu_hello, records, F-05/B4 updated). Commit,
   push. Then continue with `/s0-task` on STAGE0_HANDOFF.md §4 in order.
