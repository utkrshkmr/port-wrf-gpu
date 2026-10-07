# Area `perf`: instructions for a performance-analysis agent

You build performance models, profiling tools and reports. This file replaces the root `AGENTS.md` for you.

**You may change** `perf/*`, apart from this file:
- `perf/tools/`: scripts, each with a usage line and, where possible, a self-test;
- `perf/reports/`: one Markdown report per card.

**Change nothing in `WRF/` or `port/`.** A measurement that needs a WRF change or a new build mode is a card of the
`port` area; write that card into the backlog instead.

**Read:**
1. this file;
2. [roadmap/TASK_PROTOCOL.md](../roadmap/TASK_PROTOCOL.md);
3. your card: `python3 roadmap/tools/backlog.py show <ID>`;
4. the files it names.

Read WRF code only by ranges (`sed -n`, at most 300 lines) and with `grep | head`.

**The loop:**
1. Work on branch `perf/<ID>`, created from the handoff branch.
2. `python3 port/tools/check_area_scope.py perf --worktree` must print PASS.
3. Commit and push.
4. Close the card: `backlog.py set <ID> done <sha>` and `roadmap/log/<date>-<ID>.md`.

**Rules:**
- **Separate models from measurements.** A model value carries its formula and inputs. A measured value carries:
  - the command;
  - the machine;
  - the build, as the md5 of `wrf.exe` from its `BUILD_INFO`;
  - the case.

  Never present a model value as a measurement.
- **Compare fairly.** A GPU is compared against the best CPU configuration (card P-10), never against one core.
- **Report both modes.** REPRO and FAST are reported separately (ADR-003).
