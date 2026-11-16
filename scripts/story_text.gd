extends RefCounted
# Story scenes for the Road Trip (P5-10, board "Story script format"): plain const data, played by story.gd.
# Use it through   const StoryText = preload("res://scripts/story_text.gd")   (never instanced).
# Safe to edit on the tablet: a typo shows as a parse error in the Godot editor right away.
#
# A scene is a list of lines, played in order (tap = next line, SKIP = the whole scene):
#   "who"   a cities.gd PLAYERS id (his portrait and short name), or "narrator" (no portrait, no name plate)
#   "side"  "left" or "right": where his portrait stands (portraits face right; the right side is mirrored).
#           Your crew stands left, the other crew right, as in a fighting game.
#   "text"  the line. {crew} = Cornfield Kings, {van} = The Biscuit, {city} = the city this scene is about.
#           Keep a line to about 2 short sentences (the text box holds 3 rows).
#   "mood"  optional: a portrait expression ("happy", "smug"): assets/portraits/<id>_<mood>.png if it exists,
#           else the plain portrait. Missing portraits show a silhouette in the crew's color.
# Scene ids: cities.gd names each city's "arrive" and "won" scene; trip.gd adds trip_start, first_loss, ending.
# ALL TEXT IS PLACEHOLDER (Phase 6 writes the real story).

const SCENES := {
	# the title's NEW TRIP, before the map
	"trip_start": [
		{"who": "narrator", "side": "left",
			"text": "Hometown, Indiana. Population: not much. Corn: a lot."},
		{"who": "ud_jojo", "side": "left", "mood": "happy",
			"text": "Guys. GUYS. Look what was stuck to the slushie machine at my uncle's gas station!"},
		{"who": "ud_deuce", "side": "right",
			"text": "\"Big City Showdown. New York. Streetball crews welcome.\" ...Jojo, that's a thousand miles away."},
		{"who": "ud_jojo", "side": "left",
			"text": "Eight hundred and change! I did the math on a napkin. Then I ate the napkin. Long night."},
		{"who": "ud_tank", "side": "right",
			"text": "The van runs now. Mostly. I put a new belt in her. And a cup holder."},
		{"who": "ud_deuce", "side": "right", "mood": "happy",
			"text": "...Alright. One more shot, bad knee and all. Load up {van}. The {crew} are going to New York."},
	],

	# Hometown: County Line, boss Mayor (ht_boss)
	"hometown_arrive": [
		{"who": "narrator", "side": "left",
			"text": "The county rec court, behind the feed store. Somebody is already sitting on the ball."},
		{"who": "ht_boss", "side": "right", "mood": "smug",
			"text": "Well, well. The {crew}, in MY town? Go home, boys. The county line is mine."},
		{"who": "ud_jojo", "side": "left",
			"text": "Mayor, you're not even the real mayor. You just own a whistle and a folding chair."},
		{"who": "ht_boss", "side": "right",
			"text": "Twenty years I've run this court. Nobody leaves {city} without going through County Line."},
		{"who": "ud_deuce", "side": "left",
			"text": "Then we go through you. Three games. Let's ball."},
	],
	"hometown_won": [
		{"who": "ht_boss", "side": "right",
			"text": "Hmph. Twenty years... and I get beat by a kid who fixes tractors for fun."},
		{"who": "ud_tank", "side": "left", "mood": "happy",
			"text": "Thank you, sir. I also fix lawn mowers."},
		{"who": "ud_jojo", "side": "left", "mood": "happy",
			"text": "We did it! Next stop: Chicago! Tank, you're driving. {van} likes you."},
		{"who": "ht_boss", "side": "right", "mood": "smug",
			"text": "Go on, then. And if you need a real player for the big city, you know where my chair is."},
	],

	# Chicago: Lakeshore Gusts, boss Big Lou (chi_boss)
	"chicago_arrive": [
		{"who": "narrator", "side": "left",
			"text": "Chicago. A rooftop court by the lake, and a wind that never takes a day off."},
		{"who": "ud_jojo", "side": "left",
			"text": "Whoa. The buildings here are taller than our grain silo. Like, WAY taller."},
		{"who": "chi_g1", "side": "right",
			"text": "Farm boys on our roof? Hope you brought sandbags. The lake wind eats shots for breakfast."},
		{"who": "chi_boss", "side": "right",
			"text": "Easy, Nico. Let 'em play. I'm Big Lou. Nobody scores on me twice in {city}."},
		{"who": "ud_tank", "side": "left",
			"text": "That's okay. I only need to score on you once. Then a different once."},
		{"who": "ud_deuce", "side": "left",
			"text": "Ball up, {crew}. Keep it low and keep it moving."},
	],
	"chicago_won": [
		{"who": "chi_boss", "side": "right",
			"text": "Twice. You scored on me way more than twice. My rooftop's never been this quiet."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "Good game, Lou. That wind made me earn every bucket."},
		{"who": "ud_jojo", "side": "left", "mood": "happy",
			"text": "Somebody write this down! The {crew}, rooftop champs! Somebody? Tank, you got a pen?"},
		{"who": "chi_boss", "side": "right",
			"text": "New York's a different animal, kid. Want a big man who knows the city game? Just ask."},
	],

	# the first loss of the trip (once), before the retry
	"first_loss": [
		{"who": "ud_jojo", "side": "left",
			"text": "Okay. That was... a learning experience. I learned we lost."},
		{"who": "ud_tank", "side": "right",
			"text": "My grandpa says a cow that falls in the creek still knows the way home."},
		{"who": "ud_jojo", "side": "left",
			"text": "Tank, I have no idea what that means and somehow it's helping."},
		{"who": "ud_deuce", "side": "right",
			"text": "We don't go home on one loss. Run it back. Same court, same {crew}."},
	],

	# arriving in New York, before the bracket
	"final_before": [
		{"who": "narrator", "side": "left",
			"text": "New York. The Big City Showdown. {van} coughs once and parks itself next to a fire hydrant."},
		{"who": "ud_jojo", "side": "left",
			"text": "We made it! The flyer was REAL! I was like eighty percent sure!"},
		{"who": "ny_boss", "side": "right",
			"text": "So you're the {crew}. Heard you came all the way from a cornfield."},
		{"who": "ny_boss", "side": "right",
			"text": "Win three on my cage courts and you'll see me in the final. Most crews don't."},
		{"who": "ud_deuce", "side": "left",
			"text": "We're not most crews. Bracket's up. Let's go."},
	],

	# the final won: the end of the trip, then the title
	"ending": [
		{"who": "ny_boss", "side": "right",
			"text": "...A cornfield. You came out of a cornfield and took my crown. Respect, {crew}."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "The knee held up. The whole trip, it held up. Guess this was my second shot after all."},
		{"who": "ud_tank", "side": "right", "mood": "happy",
			"text": "I'm proud of you guys. And of {van}. She only caught fire one time."},
		{"who": "ud_jojo", "side": "left", "mood": "happy",
			"text": "Champions of New York! Somebody call my uncle! Tell him to frame the slushie machine!"},
		{"who": "narrator", "side": "left",
			"text": "And so the {crew} drove home to Indiana, a trophy in the cup holder. THE END... for now."},
	],
}

# a scene's lines ([] for an unknown id)
static func scene(id: String) -> Array:
	return SCENES.get(id, [])

static func has_scene(id: String) -> bool:
	return SCENES.has(id)
