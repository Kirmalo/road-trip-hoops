# Baseline before Phase 1

Build: commit e409911 (starter game, unchanged). Godot 4.3-stable, headless, `--autoplay`, 3 games.

| Game | Final | Shots | Makes | FG% | Passes | Steals | Blocks | Intercepts | Shots < 5 ft | Shots 15 ft+ |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | BLUE 20 - RED 8 | 43 | 15 | 35% | 102 | 8 | 6 | 3 | 39 | 1 |
| 2 | BLUE 10 - RED 8 | 45 | 10 | 22% | 79 | 9 | 7 | 8 | 38 | 3 |
| 3 | BLUE 18 - RED 10 | 43 | 16 | 37% | 81 | 9 | 6 | 4 | 40 | 3 |

## Findings
- **Scores are below the CLAUDE.md target** (15-30 per team): RED scored 8-10, BLUE 10-20.
- **Almost every shot is at the rim** (about 90% under 5 ft) and **no threes were made** in 3 games. CPU handlers
  drive to the rim nearly every time, and contested layups (0.66 x 0.55 = 36%) miss a lot. Phase 1 dunks will make
  rim attacks even stronger unless contests matter, so check shot spread after dunks land.
- **BLUE won all 3 games.** Too few games to call it a bias, but worth watching: check over 10+ games whether
  team 0 has an edge (start-of-game possession, sprite sizes, or AI asymmetry).
- Intercepts ranged from 3 to 8 per game; the 8 is on the high side.
