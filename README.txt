ROAD TRIP HOOPS - 3v3 full court basketball (Godot 4)

OPEN IT ON THE TABLET
1. Extract this zip (keep the RoadTripHoops folder together).
2. Open Godot, tap Import, and pick the project.godot file inside RoadTripHoops.
3. Open the project and press the Play button (top right). The first open takes a moment while Godot imports the images.

HOW TO PLAY
You are BLUE (the player with the yellow ring). BLUE shoots at the RIGHT hoop.
- Move: put your thumb anywhere on the left half of the screen and drag.
- SHOOT: hold it down and let go when the white marker is in the green zone. Perfect timing = much better odds.
  Shots beyond the arc count 3. Layups are easiest, but defenders nearby lower your odds.
- PASS: throws to your most open teammate, or to the teammate in the direction you are pushing.
- On defense the buttons become STEAL (poke the ball, or block a shot right as it goes up) and SWITCH (take over the
  teammate closest to the ball).
- 4 quarters of 2 minutes, 24 second shot clock, overtime if tied.

EASY THINGS TO CHANGE (scripts/main.gd, at the top)
- QUARTER_LENGTH: seconds per quarter
- SHOT_CLOCK_LENGTH
Shooting odds are in shot_probability() in main.gd. CPU behavior is in scripts/player.gd.

FILES
- main.gd: rules, scoring, clocks, HUD, your controls
- player.gd: movement and the CPU brain (offense spots, driving, passing, man-to-man defense)
- ball.gd: dribbling, passes, shot arcs, rebounds
- court.gd: draws the court and rims
- touch_controls.gd: joystick and buttons

Art: Kenney Sports Pack (www.kenney.nl), CC0.
