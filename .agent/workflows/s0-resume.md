---
description: Start a Stage 0 session: read the state, detect the machine, say what the next task is
---
1. Read `AGENTS.md`, `port/agent/STAGE0_HANDOFF.md`, and the "Current state" section of `port/agent/WORKBOOK.md`.
2. In the workstation terminal, from `/home/csgrad/utkarshk/port-wrf-gpu`, as separate commands (rule 9):
   `git status -sb`, `git log --oneline -5`, then `bash port/h100/machine.sh detect`. If `port/h100/env.local.sh` is missing, recreate it from
   STAGE0_HANDOFF.md §1. If `work/builds` points to an empty RAM disk (machine rebooted), note that builds and
   `deps-25.9`/`deps-26.1` must be rebuilt before use.
3. Run `python3 port/tools/workbook.py resume`.
4. Report in a few lines: the current task (from WORKBOOK "Next step" and STAGE0_HANDOFF §2–§4), what evidence
   exists for it, what the task's "done when" is. Then start that task with the `/s0-task` steps at once (rule 10).
