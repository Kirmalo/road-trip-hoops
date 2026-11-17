# Animation style sample v1 (P6-A0)

One player, Deuce (`ud_deuce`), redrawn at the new size with longer animations. This is for the owner to approve
before every sheet is redrawn. Generator: `tools/art/make_anim_sample.py` (it uses `pixel3d.py`, which is not
changed, and the parts in `crews.json`). There is no source art. It does not touch `assets/` or any game file.

Files: `anim_sample_v1_run.gif`, `_rundribble.gif`, `_dribble.gif`, `_dunk.gif` (SE and E side by side, at the
in-game 2x size, on the gym floor). `_compare.gif` shows the four new animations (SE) next to today's run and
dribble. `_sheet.png` is every frame at 3x, with the hand points marked. `_points.json` holds the hand and ball
points per frame.

## Size and scale
- **Art scale 1.25, drawn 2x in the game.** The same 3D parts are rendered with 25% more pixels per unit. An average
  body (about 40 units) becomes 50 art px, which is **100 px on the 720 px screen**. Deuce is lanky, so he is 53 art px
  (106 px). Today he is 42 art px (84 px).
- Why 2x and not 1x: a 100 px sprite at 1x would have pixels half the size of the courts, the ball, the portraits and
  the map, and it would no longer match the approved chunky style (sample v1). At 2x the world keeps one pixel size.
  The extra 25% goes into detail: sleeves, trim and muscle shading get room, the limbs are 3 to 4 px thick instead of
  2 to 3, and the knees and elbows bend visibly.
- **Frame 64 x 96 art px.** The floor point under the pelvis is on row 88 and the body centre on x 32. Today's frame
  is 40 x 64 with the feet on row 59. The arms-up dunk frames reach row 28, so there is headroom for blocks and
  rim hangs. The widest stride fits with margin, and every frame passes the edge and one-piece checks.

## Animations in the sample (directions SE = yaw 45 and E = yaw 75)
| animation | frames | timing assumed | notes |
|---|---|---|---|
| run | 12 | 50 ms (20 fps), 0.6 s per stride cycle at full speed | the game keeps scaling the rate with the speed, as RUN_FPS does today |
| rundribble | 10 | 60 ms (16.7 fps), 0.6 s, one bounce per stride cycle | legs run as in the run cycle; the ball is pushed ahead, hits the floor on frame 4 and rises back into the hand; the arm follows through |
| dribble | 8 | 80/70 ms alternating, 0.6 s per bounce | knees bent; the hips sink and shift over the ball-side foot on the push and come back on the catch; the off arm guards |
| dunk (two-hand) | 10 | 80, 90, 70, 70, 100, **150 (hang)**, 60 (slam), 110, 150, 320 ms | gather, load, takeoff, rise, cock behind the head, hang, slam, hands on the rim, hanging, land |

- The legs follow **foot targets on the floor** (two-bone IK), so a planted foot slides back at exactly the run
  speed and does not skate. The pelvis height comes from these targets, which gives the bob, the landing dip and the
  crouch. The arms and shoulders counter-swing, and the head stays steady.
- In the dunk, the feet stay on the floor row as they do now, and the game adds the jump height. The preview GIF adds
  an illustrative lift (`DUNK_LIFT`, art px) and a simple rim, and frame 8's lift is matched so the hands stay on
  the rim. After the slam the ball is free (frames 7 to 9 have no ball point), so the game's ball physics takes over.

## Ball and hand points (how the game would read them)
The ball is **not** drawn into the sprite. Each frame stores the following, in art px of the frame (as
`hands.json` does today, with the same mirroring rule: `x' = 63 - x`, swap L and R):
- `hands`: `{L: [x, y], R: [x, y]}`. These are the hand centres (L and R are the player's own hands).
- `ball`: `[x, y, front]` or null. This is the ball centre for the game's 11 px ball (`assets/ball/ball.png` at 2x).
  `front` = 1 means draw the ball over the sprite and 0 means under it. It is decided by a z-buffer vote of the body
  pixels the ball covers, so a ball cocked behind the head is under the sprite and a dribble at the side is over it.
- `ball_floor`: `[x, y]` is the ball's shadow point on the floor, and `ball_h` is the ball's height. The game uses
  these for the shadow and the bounce sound (it plays when `ball_h` is about 0 on the floor frame).
The GIFs draw the ball exactly this way, layer flag included, so what the owner sees is what the game can do.
Suggested file: `assets/players/points.json` with `players.<id>[row][column]`, as `hands.json` does today.

## What a full sheet needs
- **5 drawn directions** (rows S, SE, E, NE, N). SW, W and NW are SE, E and NE mirrored, as today.
- Columns per animation, as a first estimate of the Phase 6 list (about 180 columns): idle 6, run 12, rundribble 10,
  dribble 8, crossover 8, shoot 10, layup 10, dunks 3 x 10 (two-hand, one-hand tomahawk, rim hang), pass chest 6,
  bounce 6, lob 6, catch 4, defensive slide 8, steal swipe 6, block 8, fall on a crossover 8, land 4,
  celebrate 12, react/stumble 8.
- **Texture size:** 180 columns x 64 px is 11,520 px wide, which is over the 4096 px that is safe on Android GL
  Compatibility. So split each player into about 3 sheets of at most 64 columns (4096 x 480 px), for example
  "move" (idle, run, dribbles, crossover, slide), "finish" (shoot, layup, dunks) and "other" (pass, defense,
  reactions, celebrate). `player.gd` then keeps a table of animation to (sheet, column, count).
- **File size:** the 80 sample frames come to 24.5 KB as an indexed PNG (about 0.3 KB per frame), so a full player
  is about 900 frames and 270 KB. 26 sheets (players and recolors) come to about 7 MB, up from about 1 MB today. If
  that is too much for the ZIP, the `_crew` recolors could become a palette-swap shader instead of extra files.
- **Generation time** is about 0.06 s per frame, so a full redraw is about 25 minutes (the work can be split across
  processes per player).
- Open points for the owner: the camera hides the near (dribbling) arm in E for players whose sleeve matches the
  jersey (Deuce's navy sleeve on blue), and the ball covers part of the legs in SE during a running dribble (the
  ball is pushed ahead and to the side; moving it further out would read better but look less natural).
