ROAD TRIP HOOPS - 3v3 full court basketball (Godot 4)

PLAY IT IN THE BROWSER (easiest, always the latest build)
Open https://kirmalo.github.io/road-trip-hoops/ in Chrome on the tablet. Tap once to start (browsers keep sound off
until you touch the screen). Chrome menu > Add to Home screen gives you an app-style icon. If an update doesn't show,
pull down to refresh.

OPEN IT ON THE TABLET
1. Extract this zip (keep the RoadTripHoops folder together).
2. Open Godot, tap Import, and pick the project.godot file inside RoadTripHoops.
3. Open the project and press the Play button (top right). The first open takes a moment while Godot imports the images.

HOW TO PLAY
You are BLUE (the player with the yellow ring). BLUE shoots at the RIGHT hoop.
- Move: put your thumb anywhere on the left half of the screen and drag.
- SHOOT: hold it down and let go when the white marker is in the green zone. Perfect timing = much better odds.
  Shots beyond the arc count 3. Defenders nearby lower your odds.
- PASS: throws to your most open teammate, or to the teammate in the direction you are pushing.
- On defense the buttons become STEAL (poke the ball, or block a shot right as it goes up) and SWITCH (take over the
  teammate closest to the ball).
- 4 quarters of 2 minutes, 24 second shot clock, overtime if tied.

TURBO
- Moving the joystick normally never sprints. To sprint, pull your thumb past the joystick ring, out to the
  faint orange outer ring. The knob turns orange while you sprint.
- The bar under your player is your stamina. Sprinting drains it; ease off and it refills after a moment.
  If it runs empty you can't sprint until it has refilled a bit.
- You sprint slightly slower with the ball.
- A jump shot right after sprinting is less accurate. Dunks and layups are not affected.

DUNKS AND LAYUPS
- Press SHOOT near the rim (within about 9 ft). There is no meter for these, the shot goes right away.
- Very close and moving fast (or on turbo) = dunk. Otherwise it's a layup.
- A defender close to you can block it, and lowers your odds.

ON FIRE
- Make 3 shots in a row with the same player (dunks and layups count) and he catches fire.
- On fire: bigger orange green zone on the meter, stamina doesn't drain, a flaming ball trail and an orange ring.
- First miss: "He's cooling down." A second miss (or block) puts the fire out. A make in between makes him fully hot
  again. CPU players can catch fire too.

SOUND
The game now has sound effects (swish, rim, bounce, dunk, block, crowd, whistle, fire). Credits are in CREDITS.md.
No sound in the browser? Make sure the tablet's media volume is up (not just the ringer), then tap the screen once.

EASY THINGS TO CHANGE (at the top of each file)
scripts/main.gd:
- QUARTER_LENGTH: seconds per quarter
- SHOT_CLOCK_LENGTH
- FIRE_STREAK: makes in a row to catch fire (3)
- FIRE_MISSES: misses that put the fire out (2)
scripts/player.gd:
- TURBO_PULL (touch_controls.gd): how far past the joystick ring you pull to sprint (1.5 = 1.5x the ring size)
- TURBO_SPEED_MULT: sprint speed (1.35 = 35% faster)
- TURBO_BALL_MULT: sprint speed with the ball (0.95)
- STAMINA_DRAIN / STAMINA_REFILL: how fast the stamina bar empties and fills (per second, 1.0 = full bar)
- TURBO_SHOT_PENALTY: jump shot quality right after sprinting (0.8)
- LAYUP_RANGE: feet from the rim where SHOOT becomes a layup or dunk (9)
- DUNK_RANGE: feet from the rim where a dunk is possible (6)
- DUNK_OPEN_PCT / LAYUP_OPEN_PCT: make chance when nobody is near you
- DUNK_BLOCK_CHANCE / LAYUP_BLOCK_CHANCE: block chance with a defender right on you
- FIRE_GREEN_LO / FIRE_GREEN_HI: green zone while on fire (normal is GREEN_LO / GREEN_HI)
- FIRE_SHOT_BONUS: extra make odds while on fire
scripts/audio.gd:
- MASTER_DB: sound volume (lower = quieter, e.g. -6.0)
Shooting odds are in shot_probability() in main.gd. CPU behavior is in scripts/player.gd.

FILES
- main.gd: rules, scoring, clocks, HUD, your controls, on fire
- player.gd: movement, turbo, dunks and layups, and the CPU brain (offense spots, driving, passing, man-to-man defense)
- ball.gd: dribbling, passes, shot arcs, rebounds
- court.gd: draws the court, rims and nets
- touch_controls.gd: joystick and buttons
- audio.gd: plays the sound effects (files in assets/sfx)
- fx.gd: popups, screen shake, fire trail

Art: Kenney Sports Pack (www.kenney.nl), CC0. Sounds: see CREDITS.md.
