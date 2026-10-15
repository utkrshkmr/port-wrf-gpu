---
description: End a session safely: workbook current, static PASS, everything committed and pushed
---
1. `bash port/gates/static.sh` must print `== static: PASS`; if not, fix or revert the uncommitted change that
   breaks it (never commit a failing static).
2. `port/agent/WORKBOOK.md`: "Current state" rewritten (every key has a value; "Next step" is one exact action),
   log entry for what was done, including unfinished work and where its logs are.
3. `git add -A && git commit` (message: task id + what passed) `&& git push origin agent/s0-00`; then
   `git status -sb` must show `agent/s0-00...origin/agent/s0-00` with nothing ahead or behind.
4. List any background job still running (`ps -u $USER -o pid,etime,args | grep -E "build.sh|wrf.exe|run_tests"`)
   with its log path, so the next session can pick it up.
