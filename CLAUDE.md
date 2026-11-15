# Road Trip Hoops

Top-down 3v3 full-court basketball game in Godot 4 (GDScript), played by touch on an Android tablet.
The owner edits and plays it in the Godot Android editor, and gets updates by downloading the repo as a ZIP and
re-importing it. There is no Git on the tablet, so keep the project self-contained and runnable as is.

## Layout
- `project.godot`: 1280x720 landscape, stretch `canvas_items` + `expand`, GL Compatibility renderer, nearest filtering.
  The features version is "4.3" so older Android editors open it without a warning. Keep code compatible with Godot 4.3+.
- `main.tscn`: a single Node2D with `scripts/main.gd`. Everything else is built in code (no other scenes).
- `scripts/main.gd`: game manager. Rules, clocks, scoring, possession, inbounds, quarters/OT, HUD, input routing.
- `scripts/player.gd`: movement and CPU AI (offense spots, ball handler drive/shoot/pass, man-to-man defense).
- `scripts/ball.gd`: ball states HELD, PASS, SHOT, LOOSE, DEAD; `z` is height drawn as an upward offset.
- `scripts/court.gd`: draws the floor (one instance) and the rims (second instance, drawn above the players).
- `scripts/touch_controls.gd`: floating joystick on the left half, A and B buttons on the right.
- `assets/`: Kenney Sports Pack sprites (CC0). Player sprites face right (+x).

## Conventions
- Units: `FT = 12` pixels per foot. Court is 94 x 50 ft. Team 0 (BLUE, human) attacks the right hoop.
- GDScript: don't use `:=` when the right side is untyped (e.g. `game.something`, or `min`/`max`/`clamp`); use an
  explicit type or `minf`/`maxf`. Otherwise the script fails to parse.
- Touch first: every feature must be usable with the joystick plus the two buttons. Keyboard (WASD, J, K) is for
  desktop testing only.

## Testing (no tablet needed)
Download a Godot 4 Linux editor binary from the GitHub releases, then:

```
godot --headless --path . --import
# full CPU vs CPU game, prints quarter scores, final score and stats
godot --headless --path . --fixed-fps 60 --quit-after 40000 -- --autoplay
# scripted human inputs, exercises shoot/pass/steal/switch code paths
godot --headless --path . --fixed-fps 60 --quit-after 40000 -- --humantest
# screenshots to /tmp/hoops_*.png (needs xvfb)
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --fixed-fps 60 -- --shots
```
After gameplay changes, run several `--autoplay` games and check the stats look sane. A typical game is about
45-70 shots, roughly 15-30 points per team over 4 x 2 minute quarters, and few interceptions or shot-clock violations.
Look at a screenshot after visual changes.

## Ideas not done yet
Sound effects, free throws and fouls, difficulty setting, turbo, out-of-bounds rule, halftime side switch, title menu.
