# Area `book`: instructions for a writing agent

You write the LaTeX textbook in `book/`. This file replaces the root `AGENTS.md` for you: the port's rules there do
not apply, apart from the general ones repeated here.

**You may change** `book/*` and `.github/workflows/book.yml`, apart from this file. You may also change your task's
bookkeeping: the status line of your card in `roadmap/BACKLOG.md`, and your log file `roadmap/log/<date>-<card>.md`.
**Change nothing else.**

**Read, in this order:**
1. this file;
2. [book/README.md](README.md) (status and writing rules);
3. [roadmap/TASK_PROTOCOL.md](../roadmap/TASK_PROTOCOL.md) (task sizes, the loop);
4. your card: `python3 roadmap/tools/backlog.py show <ID>`;
5. the chapter file the card names, with its outline box.

**The loop:**
1. `git switch -c book/<ID> origin/claude/wrf-gpu-port-cpu-7doq8n`.
2. Write the chapter. Replace its `outline` box with the text.
3. `python3 port/tools/check_area_scope.py book --worktree` must print PASS.
4. Commit and push `book/<ID>`.
5. CI builds the book (`.github/workflows/book.yml`); fix every error and undefined reference it reports.
6. Close the card:
   - `python3 roadmap/tools/backlog.py set <ID> done <sha>`;
   - write `roadmap/log/<date>-<ID>.md`, one paragraph: what was written and what is left;
   - commit, push.
7. The reviewer merges.

**Rules:**
- **Write from the source.** Every equation names the routine that implements it (`\src{file}{routine}`).
- **Read WRF code by ranges only.** Use `sed -n 'a,bp'` with at most 300 lines, and `grep -n ... | head`. Never open a
  whole WRF source file: several are larger than your context.
- **Cite only what you have checked.** Cite only entries of `book/refs.bib`; check new ones against the publisher.
  Never invent a reference, a number or a result. Results of the port come from `port/RESULTS.md`, `port/PERF.md` or
  `perf/reports/`, with the source named; until then write "to be reported".
- **Keep the LaTeX simple.** ASCII source apart from accents; only the packages of `preamble.tex`.
- **Mind the size.** A card is at most half a day's budget. If the chapter is larger, write the sections you can,
  then split the card (TASK_PROTOCOL.md §1).
