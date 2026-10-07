# Task protocol: small, independent, verifiable tasks

The project is built one task at a time, by different agents and people, over months. Each task must be small enough
to finish within half a day's coding budget, independent enough to be started from the repository alone, and leave
the repository in a state anyone can continue from.

## 1. Sizes

| Size | Budget | Typical content |
|---|---|---|
| **S** | ≤ ¼ of a daily coding budget: one fresh session, finished below 60 % of the context | one routine ported, one tool, one analysis note, one book section, one review of a work package |
| **M** | ≤ ½ of a daily coding budget: at most two sessions, with a checkpoint commit between them | a group of related routines, a tool with tests, a book chapter, a measurement campaign on one machine |

**No task is larger than M.** A card that turns out larger is split:
1. checkpoint what is done;
2. set the card to `split`;
3. add cards `<ID>a`, `<ID>b`, ... for the remainder, each with its own acceptance.

Rough proxies, when unsure:

| Size | Changed lines of code | Pages of text | Real-data runs |
|---|---|---|---|
| S | ≤ 300 | ≤ 8 | ≤ 1 hour |
| M | ≤ 800 | ≤ 20 | ≤ 3 hours |

## 2. Where a task can run

Every card says what it **needs**. A task runs only where all of its needs are met.

| Need | Meaning | Available in |
|---|---|---|
| `cpu` | Linux, gfortran 13, python3, git; no GPU | the cloud coding environment (this one), any workstation |
| `net` | internet access to GitHub (clone NCAR repositories) | the cloud environment (GitHub only), workstations |
| `gpu-nv` | an NVIDIA GPU (H100/A100) with the NVHPC container (`port/h100`) | the H100 machine |
| `gpu-amd` | an AMD Instinct GPU (MI250X/MI300) with ROCm and `amdflang` or HPE CCE | a machine still to be found (task G-00) |
| `data` | the Eaton case inputs (`cases/eaton_20250108/manifest.md5`), about 1.3 GB, not in git | CCR, the H100 machine |
| `ccr` | CCR CPU nodes (multi-node CPU-REF runs) | CCR |
| `owner` | a decision only the project owner can make | — |

**Running the port's scripts in the cloud environment** (`cpu`): there is no container runtime, and gfortran and
netCDF are installed natively. Prefix every `port/h100`, `port/gates` script with the host-mode settings, or it looks
for `apptainer` and fails:

```sh
CONTAINER=none WORK=<scratch dir>/h100work NETCDF=/opt/netcdf BUILD_JOBS=4 bash port/gates/cpu_verify.sh --base <rev>
```

## 3. A card

Every task is a card in [BACKLOG.md](BACKLOG.md), in this exact form (`roadmap/tools/backlog.py` parses it):

```
### V-03 · Check the case contract against the 4.8.0 Registry
- **Goal:** 1 · **Size:** S · **Area:** versions · **Needs:** cpu · **Depends:** V-02 · **Status:** todo
- **Read:** the files to open first (and nothing else is needed)
- **Do:** what to do, concretely
- **Output:** the files the task creates or changes
- **Done when:** the acceptance check, which someone else can repeat
```

The fields:
- **Goal:** the owner's goal numbers (0–9, see [README.md](README.md)).
- **Area:** the area the task works in ([AREAS.md](../AREAS.md)). It decides the entry instructions, the branch and
  the files the task may change.
- **Status:** one of `todo`, `doing`, `done <commit>`, `blocked <reason>`, `split`.
- **Depends:** card IDs that must be `done` first; `—` if none.

## 4. The loop

1. **Pick.** The owner names the card, or you list the candidates:
   `python3 roadmap/tools/backlog.py next --env cpu,net --area <area>` lists the open cards whose dependencies are
   done. Cards of closed areas are never listed (the stage gate of ADR-002).
2. **Enter the area.** Read the area's entry file ([AREAS.md](../AREAS.md)) and only what the card's *Read* line
   names. Track A cards also follow [AGENTS.md](../AGENTS.md); its rules win where they are stricter.
3. **Branch.** Create the area's branch from the handoff branch (`book/<ID>`, `perf/<ID>`, ...), and set the card to
   `doing` there (`backlog.py set <ID> doing`).
4. **Do** the work. Commit at least once per session; WIP commits are fine.
5. **Check:**
   - `python3 port/tools/check_area_scope.py <area> --worktree` must print PASS before every commit;
   - check the *Done when* condition and quote its result in the commit message.
6. **Close:**
   - `backlog.py set <ID> done <sha>`;
   - write `roadmap/log/<date>-<ID>.md`: one paragraph with the result and what the next person must know;
   - commit, push.

   The reviewer verifies and merges the branch into the handoff branch.
7. **New work** found on the way goes in as new cards, not into the current task. Give each the next free ID of its
   track, an area and status `todo`. Areas other than `roadmap` and `review` may not add cards themselves: put the
   proposal in your log file, and the reviewer adds it.

## 5. Rules that apply to every task

- **The repository stays green.** `bash port/gates/static.sh` prints `== static: PASS` before every commit that
  touches `WRF/` or `port/`.
- **Results come from runs.** A number in a document comes from a command recorded next to it (script and
  arguments), or is marked as an estimate with its formula. Never write a measured-looking number that was not
  measured.
- **Sources are cited.** Book and analysis text cites the WRF source (file and routine), the WRF Technical Note, or
  a paper in `book/refs.bib`. Do not invent references; check every new entry against the publisher.
- **Owner decisions are not made by agents.** A card with need `owner` produces a short proposal
  (`roadmap/decisions/ADR-<n>-<topic>.md` with status `proposed`) and stops.
- **Stay in your area.** Change only the paths of your card's area (`check_area_scope.py`). Work on the area's
  branch; never push to the handoff branch or `main`, never force-push, never rewrite pushed history.
- **No secrets, no private data in the repository.** Paths on CCR, user names, e-mail addresses and machine names
  stay out of files meant for release (task R-02 checks this).
