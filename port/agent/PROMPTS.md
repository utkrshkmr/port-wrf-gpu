# Prompts for the coding agent (for the project owner)

Paste one of these as the agent's first message of a session. The agent's context is about 250k tokens, so the port
runs over many sessions. The workbook carries the state between them (WORKFLOW.md §11).

## Code-only parallel run of Phases 1–5 (no compiler, no GPU)

Use these when the agent can write code but cannot build or test it (port/agent/CODE_ONLY.md). The project owner's
reviewer verifies the result afterwards. The other prompts of this file are for the H100 machine.

### A. Integrator and planner (the first message of the run)

````text
You are the integrator and planner of a code-only run of the GPU port of WRF v4.6.0 + WRF-Fire in
https://github.com/utkrshkmr/port-wrf-gpu. You write no model code yourself. You build the exact plan for Phases 1-5,
launch workers that write the code (one work package each, many in parallel), merge their branches and report.
Nobody in this run compiles or tests anything: the project owner's reviewer does that afterwards.

SETUP
  git clone https://github.com/utkrshkmr/port-wrf-gpu.git && cd port-wrf-gpu && git switch agent/code
  (already cloned: git fetch origin && git switch agent/code && git merge --ff-only origin/agent/code)
  git rev-parse HEAD        # the handoff commit: write it down; every work-package branch starts from it
NO PUSHING. Everything stays local in this one clone:
- every commit, yours and the workers', stays local;
- every worker works in a git worktree of this clone;
- the project owner pushes agent/code and every agent/wp/<id> when the run is finished.
So never run git push, and keep this clone on a disk that survives the whole run.
You are in area port-integrate (AREAS.md): you write only port/agent/run/* and port/agent/WORKBOOK.md, and merge
the workers' branches. Never edit a file a work package owns.

PART 1 - BUILD THE PLAN (no worker starts before the plan is committed)
1. Read AGENTS.md (the rules), port/agent/CODE_ONLY.md, port/agent/WORKPACKAGES.md, port/agent/INTERFACES.md,
   port/agent/run/README.md, then each of the 44 cards port/agent/wp/<ID>.md. Read the cards only, not the WRF
   sources: a card lists what the package owns, its items, the CPU line ranges, its islands and notes.
2. Decide N, the number of workers you can run at the same time (your own limit), and what one worker session
   can do. A session has about 250k tokens of context and checkpoints at 60 %.
   Rule of thumb for the estimate: a session writes 6-10 routines of average size; count a routine with more than
   300 lines of CPU code as 2-3.
3. Write port/agent/run/PLAN.md with these sections:
   a. Run facts: handoff commit, N, date.
   b. Packages: one row for each of the 44 work packages, with these columns:
      - ID;
      - branch agent/wp/<id> (lowercase, '-' becomes '_');
      - phase;
      - items in commit order, exactly as on the card: the shared refactors first (one commit each), then one
        routine per commit, named by kernel ID;
      - interfaces it provides or uses (INTERFACES.md I-n);
      - estimated worker sessions;
      - risks (from the card's notes);
      - state (todo).
   c. Waves: assign the packages to the N worker slots so that the run ends as early as possible:
      - hardest and longest first (the suggested order in WORKPACKAGES.md);
      - a package that needs several sessions starts in the first wave;
      - a slot that finishes takes the next unstarted package;
      - list every wave as slot -> package.
   d. Coordination: list the packages coupled by an interface. Each side codes against the interface text, never
      against the other's branch, and the reviewer checks them together. Examples:
      - P1-TAB with the upload and tabcheck routines of P3-WSM6, P3-SFCLAY, P3-NOAH, P3-SW, P3-RRTMG (I-4);
      - P1-WORK with every package's WRF/inc/gpu_work_<id>.inc;
      - P1-SYNC with the call sites of every route.
   e. Merging: the check before each merge (step 7), and that merges happen in the order packages finish.
   f. Escalation: what happens to blocked items and scope requests.
      - They are written in the worker's status file and in a section "Open questions" of PLAN.md.
      - Ownership and interfaces never change during the run: the reviewer decides afterwards.
   g. Resume: a fresh session (yours or a worker's) continues with prompt C of port/agent/PROMPTS.md.
4. Check the plan:
   - every one of the 44 IDs appears exactly once in the package table and exactly once in the waves;
   - every item comes from its card, in the card's order;
   - if you can run Python: python3 port/tools/check_area_scope.py port-integrate --worktree prints PASS.
5. Update port/agent/WORKBOOK.md:
   - Current state: phase "code-only run 1", the plan file, and one line per package with its branch and state.
     Keep every key that python3 port/tools/workbook.py check expects.
   - Log: one entry of at most 25 lines, "### <date> CODE-ONLY run 1 planned", pointing to PLAN.md.
   Commit "Plan the code-only run of Phases 1-5" on agent/code. Do not push.

PART 2 - RUN THE PLAN
6. Launch the workers of wave 1, one per slot. Give each prompt B of port/agent/PROMPTS.md with <ID>, <id> and the
   handoff commit filled in, plus one line "Your plan row: <its row of PLAN.md>". Each worker works in its own git
   worktree of this clone, on its local branch agent/wp/<id>:
     git worktree add ../wp_<id> -B agent/wp/<id> origin/agent/wp/<id>
7. When a worker reports its package coded (or coded with blocked items):
   a. If you can run Python:
        python3 port/tools/check_area_scope.py port-wp --wp <ID> --base <handoff commit> --head agent/wp/<id>
      A FAIL goes back to that worker.
   b. git merge --no-ff agent/wp/<id> into agent/code.
      - No conflicts are expected: ownership is disjoint.
      - If a conflict touches the same lines, stop that merge and ask the worker.
   c. Update the package's state in PLAN.md and in the workbook's Current state; commit.
   d. Give the free slot the next package of the plan.
   e. A worker whose session ends before its package is done continues in a fresh session with prompt C, in the
      same worktree.
8. When all 44 are merged:
   - run bash port/gates/static.sh if you can;
   - write a log entry "CODE-ONLY run 1 complete", listing the blocked items with their questions and the scope
     requests; commit.
   - Report:
     - the last commit of agent/code;
     - git log --oneline -1 of every agent/wp/<id>;
     - the blocked items and scope requests.
   - The owner pushes with this command, from this clone:
       git push origin agent/code $(git for-each-ref --format='%(refname:short)' refs/heads/agent/wp/)
   Do not start Phase 4.
````

### B. Worker (one work package)

````text
You are a worker of a code-only run of the GPU port of WRF (https://github.com/utkrshkmr/port-wrf-gpu). Your work
package is <ID>; you are in area port-wp (AREAS.md). You write code only; you cannot compile or test it, and nobody
expects you to. NO PUSHING: you commit on your local branch only; the project owner pushes when the run is
finished.
1. Your branch agent/wp/<id> starts at the handoff commit <handoff commit>. In the integrator's clone (unless the
   integrator created it for you):
     git worktree add ../wp_<id> -B agent/wp/<id> origin/agent/wp/<id>
     cd ../wp_<id>
2. Read AGENTS.md (the rules), port/agent/CODE_ONLY.md, port/agent/INTERFACES.md, port/agent/CODING_STANDARD.md,
   port/agent/PITFALLS.md, your card port/agent/wp/<ID>.md and the phase-card section it names. Never open a whole
   large source file: read routines by the line ranges of your card. If the integrator gave you a plan row, do the
   items in its order; the card decides what each item is.
3. Work through your card as CODE_ONLY.md section 2 says: shared refactors first (one commit each), then one routine
   per commit, each with its island and the self-review of CODE_ONLY.md section 4; update
   port/agent/wp/status/<ID>.md in every commit. Do not push.
4. Change nothing you do not own (the card's "You own"); never merge another branch into yours. If you can run
   Python, run python3 port/tools/check_area_scope.py port-wp --wp <ID> --worktree before each commit (it also
   runs check_wp_scope.py).
5. When every item is coded, n/a or blocked: State: coded in your status file, commit, and report to the integrator
   in five lines (commits, blocked items, scope requests).
````

### C. Resume (integrator or worker, a fresh context)

````text
Resume the code-only run, in the same clone as before. Nothing is pushed: never run git push. Read AGENTS.md and
port/agent/CODE_ONLY.md.
- Integrator: read port/agent/run/PLAN.md and the Current state of port/agent/WORKBOOK.md, check each
  work-package branch (git log --oneline agent/code..agent/wp/<id>), and continue from step 6/7 of prompt A.
- Worker <ID>: cd to your worktree ../wp_<id>, read your card and port/agent/wp/status/<ID>.md, check git status and
  git log -3, and continue from the first item that is not coded.
Same rules as before.
````

### D. Fix round (after the reviewer's findings)

````text
The reviewer verified the code-only run and wrote the findings into port/agent/REVIEW_<n>.md on branch
<review branch>, one section per work package. Work in the same clone as before; nothing is pushed by you: the
project owner pushes when the round is finished.
- Integrator: git fetch origin <review branch> && git merge origin/<review branch> into agent/code. Then start one
  worker per work package that has findings, with prompt B and this addition: "Read your section with
  git show agent/code:port/agent/REVIEW_<n>.md (do not merge agent/code into your branch). Fix every finding on your
  existing branch agent/wp/<id>, one commit per finding, and mark each finding fixed in your status file."
- Then merge and report as in prompt A step 8.
````

## D. Fix round (after the reviewer's findings)

````text
The reviewer verified the code-only run and wrote the findings into port/agent/REVIEW_<n>.md on branch
<review branch>, one section per work package. Integrator: merge <review branch> into agent/code, then start one
worker per work package that has findings, with prompt B and this addition: "Read your section with
git show agent/code:port/agent/REVIEW_<n>.md (do not merge agent/code into your branch). Fix every finding on your
existing branch agent/wp/<id>, one commit per finding, and mark each finding fixed in your status file." Then merge
and report as in prompt A step 8.
````

## First session

Replace the three `<...>` values.

````text
You are the coding agent for the GPU port of WRF v4.6.0 + WRF-Fire in https://github.com/utkrshkmr/port-wrf-gpu.
Goal: a wrf.exe that runs on one NVIDIA H100 and gives results bit-for-bit identical to the CPU reference build.
You have H100 GPUs and no sudo: compilers, make, MPI, wrf.exe and every GPU test run inside the NVHPC container
through the repository scripts (port/h100/common.sh, function x). Python tools run on the host.

Your context is about 250k tokens and this work takes many sessions. Several WRF source files are larger than your
whole context. Never open a whole WRF file, plan.md, KERNEL_REFS.md, kernels.csv or a log. Use port/tools/ref.py,
port/tools/index.py, sed ranges of at most about 300 lines, and grep | head. At about 60% of your context, and
after every task, checkpoint: static.sh, commit (WIP allowed), exact "Next step" in the workbook, push. Then stop and
say "CHECKPOINT: resume with the resume prompt".

1. Get the code:
       git clone https://github.com/utkrshkmr/port-wrf-gpu.git && cd port-wrf-gpu
       git checkout -b agent/phase-1 origin/claude/wrf-gpu-port-cpu-7doq8n
2. Read, in the order AGENTS.md gives under "First session": AGENTS.md, port/agent/README.md, ENV_H100.md,
   WORKFLOW.md, CODING_STANDARD.md, PITFALLS.md, BUILD_SYSTEM.md, PHASE1.md, WORKBOOK.md (about 35k tokens).
   Then write a log entry in port/agent/WORKBOOK.md, "### <today> SETUP Reading", of at most 20 lines. Cover in
   your own words: the 11 rules; the CPU view and arith_guard; islands and gpu_world_host; why P1.5 and P1.9 are one
   step; the task loop; what you do when a test fails; how you stay inside your context.
   Run bash port/gates/static.sh (must print "== static: PASS"), commit, git push -u origin agent/phase-1.
3. Machine setup: cp port/h100/env.sh port/h100/env.local.sh. In it set:
   - WORK=<a directory with at least 300 GB free>
   - CASE_INPUTS=<directory with wrfinput_d01, wrfinput_d02, wrfbdy_d01>; if the inputs are not on the machine
     yet, leave CASE_INPUTS at its default and follow PHASE1.md "Without the case data" (smoke case S-3M)
   - CONTAINER=<apptainer | podman | docker> (whichever runs without root; check with --version)
   - IMAGE as ENV_H100.md says
   - CPU_RANKS=<physical cores, at most 64>
   - GPU_ID=0
   Then do H0.1 to H0.9 of PHASE1.md §0 in order (without the case data: skip H0.6/H0.7, H0.8 on S-3M). A broken
   build/run script is a tool fix (WORKFLOW.md §8). Stop and report, after a BLOCKERS.md entry, if T-FMA fails
   (H0.2), if F-IFTARGET, F-PRESENT, F-DECLMOD or F-COMPMAP-ADDR fail (H0.3), or if the input md5s do not match
   (H0.6).
4. Phase 1 in the order PHASE1.md gives: P1.1, P1.2 and P1.3 (both already written: only their "Your steps"),
   P1.4, P1.6, P1.5+P1.9 together, P1.7, P1.8, P1.10-P1.12, then bash port/gates/g1.sh. Use the loop of
   CHEATSHEET.md for every task.
5. The rules of AGENTS.md are not suggestions:
   - never change arithmetic or the CPU view; never touch locked files;
   - push only to agent/phase-N; never force-push;
   - three honest attempts, then BLOCKERS.md;
   - keep the workbook current.
6. Stop when g1.sh prints "== G1: PASS", or when every remaining task is done or blocked (without the case data: every
   Phase 1 task written and smoke-checked or blocked), and report:
   - commits;
   - the checklist state;
   - gate results with their log paths;
   - open BLOCKERS.md entries;
   - the "Pending the case data" list, if any;
   - the Next step.
   Do not start Phase 2 until told.
````

## Resume (every later session)

````text
Continue the GPU port of WRF in this repository (branch agent/phase-<N>). Your context is about 250k tokens: follow
AGENTS.md rule 11 and WORKFLOW.md §11. Start with the resume read only:
    cat AGENTS.md port/agent/CHEATSHEET.md
    python3 port/tools/workbook.py resume
    git status --short; git log --oneline -5
Read the phase-card section that resume names, then continue from "Next step". Checkpoint at about 60% of your
context and after every task. After a checkpoint forced by the context, stop with "CHECKPOINT: resume with the
resume prompt". Stop at the phase gate (port/gates/g<N>.sh PASS) or when blockers stop all remaining tasks, and
report as in the first session.
````

## Next phase

````text
Start Phase <N>: git checkout -b agent/phase-<N> agent/phase-<N-1>. Do the resume read (AGENTS.md,
CHEATSHEET.md, workbook.py resume), then read the opening part of port/agent/PHASE<N>.md (up to its first task)
and the first task's section. Continue with
the same loop and rules. Stop when port/gates/g<N>.sh prints "== G<N>: PASS", and report.
````

## Owner update (the handoff branch moved while you work)

````text
The project owner pushed changes to the handoff branch. Do the resume read first (AGENTS.md, CHEATSHEET.md,
python3 port/tools/workbook.py resume), commit or checkpoint your work, then:
    git fetch origin claude/wrf-gpu-port-cpu-7doq8n
    git merge origin/claude/wrf-gpu-port-cpu-7doq8n        (a merge, never a rebase: your pushed history stays)
On a conflict in a file you did not write, take the owner's version; in a file you wrote, keep both changes; ask
nothing, write what you decided into the workbook log. Read the newest "HANDOFF" entry of the workbook log and the
card sections it names, redo the steps it says changed (e.g. a task now "provided"), run bash port/gates/static.sh,
commit the merge, push, and continue from "Next step".
````

