# Code-only mode: write Phases 1–3 in parallel, without builds or tests

This guide is for a coding agent that **cannot compile WRF, run it, or use a GPU**. You write the code of Phases
1–3; the project owner's reviewer builds and tests everything afterwards (§7) and sends back findings, which you fix
in a second round. Everything in [AGENTS.md](../../AGENTS.md) still holds, except the points listed in §0.

Read, in this order: AGENTS.md (the rules), this file, [WORKPACKAGES.md](WORKPACKAGES.md),
[INTERFACES.md](INTERFACES.md), [CODING_STANDARD.md](CODING_STANDARD.md), [PITFALLS.md](PITFALLS.md), then the card
of your work package (`port/agent/wp/<ID>.md`) and the phase-card section it names. Skip ENV_H100.md, DEBUGGING.md
and BUILD_SYSTEM.md: they are about running things.

## 0. What changes against AGENTS.md

| AGENTS.md | In code-only mode |
|---|---|
| Rule 3 (locked files) | Unchanged. The one exception is the card of P1-B4 (`module_repro_math.F`, owner-approved). Never edit `protected.md5`, `cpu_view_base`, `REFACTORS.md`, `kernels.csv`, `KERNEL_REFS.md`, `ROUTES.md`: the reviewer does. |
| Rule 4 (one routine per commit, tests named) | One routine (or one Phase 1 task) per commit; the body says `Not compiled or tested (code-only).` and names no test. |
| Rule 5 (static.sh, T-AB, T-TRACE) | Run the Python checks of §3 if you can; you never mark anything tested or done. Your states are `coded`, `n/a`, `blocked` (§6). |
| Rule 6 (workbook) | Only the integrator edits `WORKBOOK.md`. A work package writes only its status file `port/agent/wp/status/<ID>.md`. |
| Rule 7 (branches) | Integration branch `agent/code`; one branch per work package, `agent/wp/<id>` (the card names it). Never use or push `agent/phase-1` (an abandoned run). |
| Rule 10 (three attempts with tests) | You cannot test: when you cannot decide how to port something after a careful re-read, write the question into your status file, mark the item `blocked`, and continue with the next one. |
| Rule 11 (context) | Unchanged: never open a whole large file; read routines by their line ranges from the card. |

## 1. Organization: integrator and work packages

- **36 work packages** (WORKPACKAGES.md): 8 in Phase 1, 18 in Phase 2, 10 in Phase 3. Each **owns** files, routines or
  module specification parts that no other work package owns. The interfaces between them are fixed in advance
  (INTERFACES.md), and every file they need exists already (§9). So **no work package waits for another**: all 36 can
  run at the same time.
- **The integrator** (one session):
  1. works on `agent/code` (area `port-integrate`, [AREAS.md](../../AREAS.md)), which exists already at the handoff
     commit;
  2. writes the exact plan of the run, `port/agent/run/PLAN.md`, before any worker starts (prompt A of PROMPTS.md):
     - every package's items in commit order;
     - the waves of worker slots;
     - coordination and escalation;

     then starts the work packages by that plan, as many in parallel as it can, each with its card (§2);
  3. merges finished work-package branches into `agent/code` with `git merge --no-ff` (no conflicts are expected:
     ownership is disjoint);
  4. keeps `WORKBOOK.md` "Current state" listing every work package with its branch and state;
  5. pushes `agent/code` after every merge;
  6. reports when all 36 are merged (§5).
- **A work package** (one worker session each):
  - works in its own git worktree, on its own branch (area `port-wp`). The branch exists already at the same
    handoff commit as `agent/code`:
    `git fetch origin agent/wp/<id> && git worktree add ../wp_<id> -B agent/wp/<id> origin/agent/wp/<id>`;
  - never merges another branch into its branch, and never edits a file it does not own;
  - pushes its branch after every commit.
- Rules for everyone: never force-push, never rebase pushed history, never push to `main` or to the handoff branch
  `claude/wrf-gpu-port-cpu-7doq8n`.

## 2. The loop of a work package

1. Read your card. It lists what you own, with line numbers of the handoff tree, the kernel rows with their CPU lines
   (base commit; the card gives the offset where a file has moved), routes and call sites, the pre-generated islands,
   tasks, notes, and "Done".
2. For each routine you own, in the order of the card:
   1. read the whole routine (`sed -n 'a,bp'` with the card's lines, at most about 300 lines at a time);
   2. list its loop nests; map each one to a kernel row of the card and its template (CODING_STANDARD.md §5, and the
      tested examples it names);
   3. write the kernels under `#ifdef WRF_GPU` or as directive lines, per the template;
   4. paste the island of `port/agent/wp/islands/<ID>/<routine>.txt` (entry, exit and call check; CODING_STANDARD.md
      §3 rules 1 and 7);
   5. make every branch the case does not take stop under `#ifdef WRF_GPU`, before the entry island
      (`CALL wrf_error_fatal('<routine>: <option> not ported to the GPU')`);
   6. go through the self-review of §4, line by line;
   7. commit: `WP <ID>: port <routine> (<kernel ids>)` with a body saying what you did, the template, anything
      uncertain, and `Not compiled or tested (code-only).` Update your status file in the same commit; push.
3. Shared refactors named on your card come **first**, each alone in one commit (§8).
4. When every item is `coded`, `n/a` or `blocked`: set your status `State: coded`, commit, push, tell the integrator.

## 3. What you may run (only if your environment has python3 and git)

None of these needs a compiler. If you cannot run them, write code that would pass them; the reviewer runs them.

```sh
python3 port/tools/check_wp_scope.py <ID> --worktree     # you changed only what you own
python3 port/tools/arith_guard.py <your WRF files>       # CPU view unchanged, no new arithmetic
python3 port/tools/kernel_lint.py <your WRF files>       # directive rules
python3 port/tools/gen_island.py <file> <routine> --route R_<ROUTE>   # an island (the cards have them already)
python3 port/tools/ref.py <kernel id>                    # the CPU lines of a kernel row
bash port/gates/static.sh                                # everything above and more
```

A shared-refactor commit makes `arith_guard` report CPU-view changes against the base: expected, note it in your
status file (§8).

## 4. Self-review, instead of tests

Do it for every kernel; most porting mistakes are in this list.

- **Statements.** Copied verbatim, in the same order, with the same parentheses. Only the indices of arrays whose
  shape changes (a slab becomes a column) may change. No `a/b` → `a*(1/b)`, no factoring, no reordered sums, no
  fused loops that change the order of operations.
- **Ranges.** Every loop runs over exactly the range of the CPU loop it replaces (`its..itf`, staggered ends
  `ite`/`ide`, `kts..ktf` vs `kte`). Template C: the kernel runs over the union of the ranges, and each statement
  group keeps its own range with a guard.
- **Recurrences.** A loop that carries a value from one iteration to the next (a vertical sweep, a running sum) stays
  sequential inside one thread, in its original direction.
- **Data-sharing clauses.** `default(none)`. Every array is `shared`. Every scalar the kernel only reads is
  `firstprivate`. Every scalar or fixed-size column array it writes is `private`. Loop indices of inner loops are
  `private`. Module variables (e.g. the species indices `P_QV`) are copied to local scalars before the kernel and
  passed `firstprivate`; gfortran rejects a module variable missing from a `default(none)` list.
- **Collapse.** `collapse(n)` only over loops whose bounds do not depend on each other.
- **Calls in device code.** Every routine called from a kernel is `!$omp declare target`, and so is everything it
  calls. Such routines contain no I/O, no `wrf_message`, no `ALLOCATE`, and no automatic arrays sized at run time
  (use fixed sizes, `WRF/inc/gpu_col.h`).
- **Reductions.** No floating-point reduction across threads: it changes the order of a sum. Integer counts are fine.
- **Islands.** The entry block sits at the first executable statement, after early `RETURN`s that do no work, at the
  top level of the routine. The exit block sits before **every** `RETURN` after the entry and before
  `END SUBROUTINE`. The call-check label is unique in the routine.
- **Inside an island** (CODING_STANDARD.md §3 rule 9). Between entry and exit, no host code reads or writes a moved
  array. Every such loop the case runs is a kernel; the others stop (unported branch). The host fallback of §7
  **cannot** see this mistake.
- **CPU view.** Every change outside a directive line is inside `#ifdef WRF_GPU`, or is an allowed CPU-view addition
  (`USE module_gpu_*`, `CALL gpu_*`, route tests). Shared refactors are the only exception (§8).
- **Syntax.** Standard Fortran and OpenMP only, in the forms of the tested templates. gfortran must compile it (§7);
  no `!$acc`, no NVHPC-only clauses, no `defaultmap(present...)` until probe F-DEFMAP has run on the H100.
  Continuation lines of directives start with `!$omp&`. No `/*` or `*/` in Fortran files, and no apostrophes in
  comments of `.inc` files (cpp reads them).

## 5. Done

- **A work package** is done when every item of its card is `coded`, `n/a` (with the reason) or `blocked` (with the
  question), its status file says `State: coded`, and its branch is pushed.
- **The run** is done when the integrator has merged all 36 branches into `agent/code`, runs `static.sh` if it can,
  updates `WORKBOOK.md` (Current state: every work package with its state; a log entry "CODE-ONLY run 1 complete"),
  pushes, and reports:
  - the branch and commit;
  - the work packages with blocked items and their questions;
  - the scope requests.

Nothing is "done" in `kernels.csv` until the reviewer has verified it.

## 6. Status files

`port/agent/wp/status/<ID>.md` belongs to its work package (the generator created it with every item set to `todo`).
Keep it current in every commit:

- `State:` todo → in-progress → coded (or blocked);
- one row per kernel row and task: `coded` with the commit, `n/a` with the reason, or `blocked` with the question;
- "Scope requests": a change you need outside what you own (file, routine, why). Do not make it;
- "Questions and blockers": what the reviewer must decide;
- "Log": entries of at most 25 lines, newest last.

## 7. Verification (what the reviewer runs; write code that passes it)

The reviewer's environment has CPUs and no GPU. Items 1-4 are one command, `bash port/gates/cpu_verify.sh` on
`agent/code`, and run with gfortran on the CPU. Item 5 needs the H100 machine and comes later.

1. `static.sh`, and `check_wp_scope.py <ID>` for every work-package branch.
2. Three gfortran builds:
   - `build.sh gnu-ref`: the CPU view of `agent/code`;
   - `build.sh gnu-gpu`: the GPU view of `agent/code`. It must compile with gfortran 13, and its target regions run on
     the host (no offload);
   - `gnu-ref` of the handoff commit.
3. The smoke case S-3M (em_fire ideal with the Eaton physics), compared bit for bit:
   - `gnu-ref` of the handoff vs `gnu-ref` of `agent/code`: the CPU view is unchanged, and every shared refactor is
     exact;
   - `gnu-ref` vs `gnu-gpu`, one thread: every kernel on the smoke case's code paths keeps the arithmetic;
   - `gnu-ref` vs `gnu-gpu` with `OMP_NUM_THREADS=4`: the kernels really run in parallel, so a missing `private` or a
     wrong data-sharing clause shows up as a difference.
4. The reference tests (`port/tests/run_ref_tests.sh gnu`), and with `cpu_verify.sh --harness` every Phase 2 routine
   in `harness.sh` (random inputs, `gnu-ref` vs `gnu-gpu`). That reaches code paths the smoke case does not, and names
   the first differing element of a wrong kernel. Checked on the handoff tree: the tested Template C port of
   `calc_coef_w` passes, and the same port with one product reassociated fails.
5. Later, on the H100: nvfortran builds, T-AB, T-TRACE, the call check and the gates of the phase cards. They find
   what the CPU cannot:
   - data movement and islands: host and "device" memory are the same on the CPU, so CODING_STANDARD.md §3 rule 9
     matters most;
   - nvfortran restrictions and device stack size;
   - the code paths the smoke case does not run: nest, boundary file, restart start, d02 LES options.

Findings come back per work package. The same work package fixes them on the same branch, in new commits.

## 8. Shared refactors

A shared refactor changes the CPU view on purpose: an automatic array becomes a pointer into a work array (plan.md
P1.7), the RRTMG table flattening, DATA → PARAMETER, Noah `iloc`/`LUTYPE`, P1-B4. In code-only mode:

- **One commit per refactor**, before any GPU code of the same routine: `Shared refactor: <what> (WP <ID>)`. Nothing
  else goes in that commit; it changes no arithmetic and keeps every value bit for bit.
- **Do not move the base**, and do not edit `cpu_view_base`, `REFACTORS.md` or `protected.md5`. The reviewer proves
  the refactor bit-identical (`gnu-ref` against the base on S-3M here; CPU-REF on the H100 later), then moves the
  base.
- Work arrays of a refactor exist in both builds: declare them in your include file **outside** `#ifdef WRF_GPU`
  (INTERFACES.md I-3).

## 9. Already in place (do not recreate)

- **Skeleton modules** with `TODO(<WP>)` bodies, already in every Makefile, CMakeLists.txt and `main/depend.common`:
  - `WRF/frame/module_gpu_work.F` (P1-WORK)
  - `WRF/frame/module_gpu_prof.F`, `WRF/frame/wrf_gpu_shim.c` (P1-PROF)
  - `WRF/phys/module_gpu_tables.F` (P1-TAB)
  - `WRF/phys/module_gpu_selftest.F` (P1-ST)
  - `WRF/share/module_gpu_check.F`, `WRF/inc/gpu_check_table.inc` (P1-CHECK)
- **Includes and headers:**
  - one work-array include per work package, `WRF/inc/gpu_work_<id>.inc`;
  - `WRF/inc/gpu_col.h`.
- **`main/depend.common`** already lists `module_gpu_route`, `module_gpu_callcheck` and `module_gpu_work` for every
  file a work package owns. Never edit a Makefile, `CMakeLists.txt` or `depend.common`. If you need another module
  dependency, write a scope request.
- **Islands:** `port/agent/wp/islands/<ID>/` holds one per routine, with its call check (`gen_island.py` at the
  handoff).
- **Arith exceptions:** `port/agent/arith_exceptions.d/<ID>.txt`, one per work package, for statements `arith_guard`
  reports that are verbatim copies, each with a reason (the reviewer checks every line).
