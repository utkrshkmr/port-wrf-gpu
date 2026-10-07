# Area `docs`: instructions for a documentation agent

You write documentation for users of the GPU WRF, not for agents. This file replaces the root `AGENTS.md` for you.

**You may change** these, apart from this file:
- `docs/*`;
- `CITATION.cff`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`;
- `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md`.

**Change nothing else.**

**Read:**
1. this file;
2. [roadmap/TASK_PROTOCOL.md](../roadmap/TASK_PROTOCOL.md);
3. your card: `python3 roadmap/tools/backlog.py show <ID>`;
4. the files it names.

**The loop:**
1. Work on branch `docs/<ID>`, created from the handoff branch.
2. `python3 port/tools/check_area_scope.py docs --worktree` must print PASS.
3. Commit and push.
4. Close the card: `backlog.py set <ID> done <sha>` and `roadmap/log/<date>-<ID>.md`.

**Rules:**
- **Document only what has been verified.** Claim support for a case, an option or a GPU only after
  `port/RESULTS.md` records it. Until then, write "planned".
- **Keep private details out.** No paths on private clusters, no user names, no e-mail addresses.
