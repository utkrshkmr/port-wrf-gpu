# Area `roadmap`: instructions for a planning or analysis agent

You write studies, analyses, architecture documents and proposed decisions in `roadmap/`. This file replaces the
root `AGENTS.md` for you.

**You may change** `roadmap/*`, except these, which are locked:
- this file;
- `roadmap/TASK_PROTOCOL.md`;
- `roadmap/tools/backlog.py`.

**Change nothing outside `roadmap/`.**

**Read:**
1. this file;
2. [roadmap/README.md](README.md);
3. [TASK_PROTOCOL.md](TASK_PROTOCOL.md);
4. your card: `python3 roadmap/tools/backlog.py show <ID>`;
5. only the files the card names.

**The loop:**
1. `git switch -c roadmap/<ID> origin/claude/wrf-gpu-port-cpu-7doq8n`.
2. Do the card.
3. `python3 port/tools/check_area_scope.py roadmap --worktree` must print PASS.
4. Commit and push.
5. Close the card: `backlog.py set <ID> done <sha>` and `roadmap/log/<date>-<ID>.md`.

**Rules:**
- **Measure, do not guess.** Every number is either measured, with the command next to it, or an estimate, with its
  formula. A claim about WRF names the file and routine, which you read by ranges: `sed -n 'a,bp'` with at most 300
  lines, and `grep -n | head`. Never open a whole WRF source file.
- **Propose, never decide.** Decisions belong to the owner. An ADR you write has the status `proposed`.
- **Respect the stage gate.** Do not start work on WRF 4.8.0 or CFBM: the `versions` and `cfbm` areas are closed
  until the 4.6.0 port passes G5 (ADR-002).
- **Record new work as cards.** Work you find goes into `BACKLOG.md` as new cards, with an area, a size of at most M
  and their needs. `python3 roadmap/tools/backlog.py check` must pass.
