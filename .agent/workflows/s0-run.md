---
description: Work through Stage 0 autonomously, task after task, until an owner decision or a blocker
---
1. Do `/s0-resume` steps 1–3 (read the state, `git status -sb`, `machine.sh detect`, `workbook.py resume`).
2. Loop: take the next task (WORKBOOK "Next step"; order of `STAGE0_HANDOFF.md` §3, then §4) and do every step of
   `/s0-task` for it, including the commit and push (each `git` command on its own line; the owner approves them).
   Do not ask for permission for anything else (rule 10).
3. While a long job runs (build, reference run), poll its log every few minutes; meanwhile work on the next task
   that does not depend on it, as STAGE0_HANDOFF.md allows. Never start two builds into the same build directory.
4. Stop only when: an owner decision is reached (rule 8; write BLOCKERS.md, commit, push); a task failed three honest
   attempts (BLOCKERS.md, then continue with the next independent task; stop if none is left); or G0 is reached.
5. On stopping, do `/s0-checkpoint`.
