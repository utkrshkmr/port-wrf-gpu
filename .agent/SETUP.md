# Owner setup of Antigravity / Gemini CLI for this repository

Goal: the agent runs every command and changes every file on its own; only `git` commands wait for the owner.
(Setting names as of Antigravity early 2026; the wording may differ slightly between versions.)

## Antigravity (Settings → Agent)
| Setting | Value | Why |
|---|---|---|
| Terminal command auto execution | **Turbo** ("Always proceed") | commands run without a prompt |
| Terminal deny list | `git` | every command starting with `git` waits for approval (rule 9 keeps git commands unchained) |
| Terminal allow list | empty | not used in Turbo |
| Review policy (plans, artifacts) | **Always proceed** | the agent does not wait for plan approval (rule 10) |
| Agent gitignored file access | **on** | `work/` (logs, builds), `port/h100/env.local.sh`, `EATON/` are git-ignored |
| Agent non-workspace file access | **on** | builds and deps live on `/dev/shm/utkarshk-wrf` (symlinked from `work/`) |
| Model / mode | Planning mode | the plan is written as an artifact, then executed at once |

Open the folder `/home/csgrad/utkarshk/port-wrf-gpu` on the workstation over Remote-SSH. Workspace rules:
`.agent/rules/wrf-gpu-port.md` (loaded automatically). Commands: `/s0-run` (autonomous), `/s0-resume`, `/s0-task`,
`/s0-compiler`, `/s0-checkpoint`.

Safety net on GitHub: branch protection for `agent/s0-00` (no force pushes, no deletion).

## Gemini CLI
`GEMINI.md` is loaded automatically. Start with `gemini --approval-mode=auto_edit` to auto-approve file edits only,
or `gemini --yolo` to auto-approve everything. Gemini CLI has no "ask only for git" mode: with `--yolo`, add to
`.gemini/settings.json` `{"tools": {"exclude": ["run_shell_command(git)"]}}`, and run the git steps yourself.
