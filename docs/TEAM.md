# Road Trip Hoops: Agent Team

The game is built by a small team of Claude Code agents. Agent definitions are in `.claude/agents/`.

| Role | Agent | Does |
|---|---|---|
| Coordinator | the main Claude Code session | Talks to the owner, starts the other agents, merges their work, pushes |
| Lead / producer | `lead-producer` | Splits a phase into tasks on `docs/BOARD.md`, reviews changes, writes the phase summary |
| Gameplay programmer (1-2) | `gameplay-programmer` | Implements gameplay tasks in `scripts/` |
| Art + audio integrator | `art-audio-integrator` | Finds, license-checks and wires in sprites, music and sound; keeps `CREDITS.md` |
| QA / balance tester | `qa-balance-tester` | Runs headless games and screenshots, checks stats, files bugs, tunes constants |

Subagents can't start other subagents, so the main session coordinates and the lead plans and reviews.

## Phase loop
1. **Plan.** The coordinator asks `lead-producer` to plan the next phase from `docs/VISION.md`. Tasks go on
   `docs/BOARD.md`, each with the files it may touch.
2. **Build.** The coordinator starts a `gameplay-programmer` or `art-audio-integrator` per task, each in its own git
   worktree. Tasks that run at the same time never touch the same file.
3. **Test.** `qa-balance-tester` runs the test pass on each finished task and writes `docs/qa/...`.
4. **Review.** `lead-producer` reviews the diff and the QA report: APPROVE or CHANGES.
5. **Merge.** The coordinator merges approved work onto the development branch and re-runs a quick QA pass on the
   combined result.
6. **Check-in.** At the end of the phase the coordinator pushes, and the lead's summary goes to the owner with
   multiple-choice questions. The owner downloads the ZIP, plays on the tablet, and answers. Answers go into
   `docs/VISION.md` before the next phase starts.

## Rules for every agent
- `docs/VISION.md` decides design. Open design questions go to the owner, never guessed.
- Every pushed commit must open and run in the Godot Android editor (Godot 4.3+), because the owner plays straight
  from a ZIP of the repo.
- Only commit to the branch the coordinator names. Only the coordinator pushes.

## Tools in the cloud environment
- **Godot:** not preinstalled. Download the Linux editor from GitHub releases (reachable), for example:
  ```
  mkdir -p ~/godot && cd ~/godot
  curl -sSLO https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
  unzip -o Godot_v4.3-stable_linux.x86_64.zip && ln -sf ~/godot/Godot_v4.3-stable_linux.x86_64 /usr/local/bin/godot
  ```
- `xvfb-run` and Python 3 with Pillow are installed.
- **Network:** as of 2026-11-15, opengameart.org, kenney.nl, itch.io and freesound.org are blocked by this
  environment's network policy. Before an asset task, the coordinator asks the owner to allow the needed hosts, or
  the owner downloads the packs and adds them to the repo.
