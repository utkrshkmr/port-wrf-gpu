# GEMINI.md: context for Gemini CLI and Antigravity in this repository (same text as .agent/rules/wrf-gpu-port.md)

You are the coding agent of this repository. Everything you need is in the repository; do not guess.

1. **Read in this order, before any change:** `AGENTS.md` (the rules), `port/agent/STAGE0_HANDOFF.md` (status of every
   task, the environment, the hazards, the next steps), `port/agent/WORKBOOK.md` "Current state" (where the last
   session stopped), then only the section of `roadmap/plan-4.6/stage-0-ground-truth.md` for the task at hand.
2. **The machine is the A100 workstation**, checkout `/home/csgrad/utkarshk/port-wrf-gpu`, branch `agent/s0-00`.
   Every build, test and run happens there. `port/h100/env.local.sh` must exist with the content given in
   `STAGE0_HANDOFF.md` §1; recreate it if it is missing. Run `bash port/h100/machine.sh detect` first in a session.
3. **Non-negotiable:** AGENTS.md rules 1–12. In short: never change arithmetic; never change the CPU view outside
   the shared-refactor protocol; never edit a locked test, gate or checker unless the task says "owner-directed"
   (then regenerate `protected.md5`); every fix that could change numbers gets a `port/agent/FIX_LEDGER.md` entry
   in the same commit; `bash port/gates/static.sh` must print `== static: PASS` before every commit.
4. **One task at a time**, as `STAGE0_HANDOFF.md` lists them, in order. For each: implement, run the task's tests,
   record the result (RESULTS.md / ENVIRONMENT.md / the ledger as the task says), update `WORKBOOK.md`, commit,
   push (`git push origin agent/s0-00`). Never batch several tasks into one commit.
5. **Hazards** (STAGE0_HANDOFF.md §1): `/home` is a degraded RAID (owner accepts the risk; references go there
   anyway); builds live on the RAM disk `/dev/shm/utkarshk-wrf` and vanish on reboot; a compiler crash in one file
   cascades into others, so always find the *first* crash in `compile.log`; never `pkill -f <pattern>`, kill by PID.
6. **Long commands** (builds 10–60 min, reference runs hours) run under `nohup ... > $WORK/logs/<name>.log 2>&1 &`
   and are polled; never block the session on them, never kill them to "retry" without reading the log.
7. **When a test fails:** follow `port/agent/DEBUGGING.md` and WORKFLOW.md "When a test fails". After three honest
   attempts, write `port/agent/BLOCKERS.md` and move to the next independent task. Never loosen a comparison.
8. **Ask the owner** only for the decisions the handoff marks as the owner's (compiler pin if step 1b fails, run
   lengths of S0-10, small fire inputs for T1). Everything else is decided by the documents.
