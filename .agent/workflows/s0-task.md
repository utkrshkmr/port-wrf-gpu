---
description: Implement one Stage 0 task end to end without stopping (plan, implement, test, record, commit, push)
---
Task: the one named by the user, or the "Next step" of `port/agent/WORKBOOK.md`.
1. Read the task's instructions in `port/agent/STAGE0_HANDOFF.md` (§3 or §4) and its row in
   `roadmap/plan-4.6/stage-0-ground-truth.md` ("What", "Size", "Done when"). Read only the files those name.
2. Write an implementation plan: files to change, commands to run, the tests that prove it, and what goes into
   RESULTS.md / ENVIRONMENT.md / FIX_LEDGER.md / TOOL_FIXES.md. Note which files are locked (`port/agent/protected.md5`)
   and whether the handoff allows an owner-directed edit of them. Do not wait for approval: continue with step 3
   (rule 10).
3. Implement. Infrastructure scripts (`port/h100/*`, `port/container/*`, `port/make_dev_case.py`, `port/nml.py`)
   changed → a row in `port/agent/TOOL_FIXES.md`. A change that could alter numbers → an entry in
   `port/agent/FIX_LEDGER.md` (what failed, root cause, exact change, effect on numbers, evidence, what to check).
4. Run the task's tests exactly as the handoff says; long ones under nohup with the log in `$WORK/logs/`. Paste the
   PASS/FAIL lines, never summarize them away. A FAIL is a FAIL: do not weaken the test.
5. Record results where the task says. Update `port/agent/WORKBOOK.md`: "Current state" (every key filled, "Next
   step" exact) and a log entry `### YYYY-MM-DD <task id> <title>`.
6. If a locked file was changed (owner-directed): regenerate `port/agent/protected.md5` with
   `python3 -c "import sys; sys.path.insert(0,'port/tools'); import protect as p; l,i=p.files(); p.write(p.OUT,l)"`.
7. `bash port/gates/static.sh` → must end with `== static: PASS`. Then, as separate commands (rule 9),
   `git add -A`, `git commit -m "<task id>: <tests that passed>"`, `git push origin agent/s0-00`. Confirm `git status -sb` shows
   the branch in sync with origin.
8. Write a walkthrough: what changed, the test lines, what the next task is. Then start the next task (rule 10)
   unless it is an owner decision or the user asked for one task only.
