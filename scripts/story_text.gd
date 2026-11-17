extends RefCounted
# Story scenes for the Road Trip (P5-10, Phase 6 P6-11): plain const data, played by story.gd.
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
#
# Tone (owner Phase 6 Q4 a): light comedy with heart. Each city crew is a rival who respects you after you win, the
# boss offers to join. Arrival scenes 4-6 lines, after-win scenes 3-5. Every arrival names or hints at the city's
# twist (wind, crowd, humid, thin air, wet court, sand, the cage). Running jokes, paid off in New York:
#   - Jojo's napkin math (trip_start, Chicago, New Orleans, Los Angeles -> final_before, ending)
#   - Deuce's knee (trip_start, Memphis, Seattle -> ending)
#   - The Biscuit breaks down once, climbing to Denver (Denver arrive -> final_before, ending)
#   - Tank's grandpa sayings and the cup holder (trip_start, first_loss, Seattle -> ending)

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

	# Hometown: County Line, boss Mayor (ht_boss). No twist: the tutorial city.
	"hometown_arrive": [
		{"who": "narrator", "side": "left",
			"text": "The barn driveway hoop at the edge of town. No wind, no crowd, no tricks. Just corn, and the Mayor."},
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
			"text": "Next stop: Chicago! Tank, you're driving. {van} likes you. She tolerates me."},
		{"who": "ht_boss", "side": "right", "mood": "smug",
			"text": "Go on, then. And if you need a real player for the big city, you know where my chair is."},
	],

	# Chicago: Lakeshore Gusts, boss Big Lou (chi_boss). Twist: wind off the lake.
	"chicago_arrive": [
		{"who": "narrator", "side": "left",
			"text": "Chicago. A rooftop court by the lake, and a wind that never takes a day off."},
		{"who": "ud_jojo", "side": "left",
			"text": "I did the napkin math. Wind from the lake, times our arc... The napkin blew away. Bad sign."},
		{"who": "chi_g1", "side": "right",
			"text": "Farm boys on our roof? Hope you brought sandbags. The lake wind eats long shots for breakfast."},
		{"who": "chi_boss", "side": "right",
			"text": "Easy, Nico. Let 'em play. I'm Big Lou. Nobody scores on me twice in {city}."},
		{"who": "ud_tank", "side": "left",
			"text": "That's okay. I only need to score on you once. Then a different once."},
		{"who": "ud_deuce", "side": "left",
			"text": "Ball up, {crew}. Keep it low, keep it moving, and don't float the lobs."},
	],
	"chicago_won": [
		{"who": "chi_boss", "side": "right",
			"text": "Twice. You scored on me way more than twice. My rooftop's never been this quiet."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "Good game, Lou. That wind made me earn every bucket."},
		{"who": "ud_jojo", "side": "left", "mood": "happy",
			"text": "Somebody write this down! The {crew}, rooftop champs! Somebody? Tank, you got a napkin?"},
		{"who": "chi_boss", "side": "right",
			"text": "New York's a different animal, kid. Want a big man who knows the city game? Just ask."},
	],

	# Memphis: Riverside Soul, boss Smoke (mem_boss). Twist: full house (18 s shot clock, faster, loud).
	"memphis_arrive": [
		{"who": "narrator", "side": "left",
			"text": "Memphis. An old gym by the river, packed to the rafters, and the whole place smells like barbecue."},
		{"who": "mem_boss", "side": "right", "mood": "smug",
			"text": "Welcome to my house. I'm Smoke. This crowd don't wait, so neither does the shot clock: eighteen seconds."},
		{"who": "ud_jojo", "side": "left",
			"text": "EIGHTEEN? I can't even tie my shoes in eighteen seconds! Wait, are they chanting our name?"},
		{"who": "mem_g1", "side": "right",
			"text": "Nah. They're chanting \"brisket\". Smoke brought brisket."},
		{"who": "ud_deuce", "side": "left",
			"text": "Loud gym, quick clock. My knee likes neither. Get it up the floor fast and take the first good look."},
	],
	"memphis_won": [
		{"who": "mem_boss", "side": "right",
			"text": "Mm. Low and slow, that's how I cook. You boys play fast and hot. It works too, I guess."},
		{"who": "ud_tank", "side": "left", "mood": "happy",
			"text": "Mister Smoke, sir. Is the brisket for winners, or for everybody?"},
		{"who": "mem_boss", "side": "right", "mood": "happy",
			"text": "Everybody, big man. And if your crew wants somebody who can cook in the paint, I'm listening."},
	],

	# New Orleans: Bayou Brass, boss Gator (nol_boss). Twist: humid (stamina refills slowly).
	"new_orleans_arrive": [
		{"who": "narrator", "side": "left",
			"text": "New Orleans. A blacktop by the bayou, string lights in the cypress, and air you could drink."},
		{"who": "ud_jojo", "side": "left",
			"text": "Napkin math says it's a hundred percent humidity. The napkin is also a hundred percent wet."},
		{"who": "nol_boss", "side": "right", "mood": "smug",
			"text": "Bayou Brass, baby! I'm Gator. Out here you get tired fast and you STAY tired. We just run anyway."},
		{"who": "nol_g1", "side": "right",
			"text": "We play like the band marches: fast, loud, and nobody stops till the song's over."},
		{"who": "ud_deuce", "side": "left",
			"text": "Then we pick our sprints. Save the legs, make 'em chase. Don't burn the turbo early."},
	],
	"new_orleans_won": [
		{"who": "nol_boss", "side": "right",
			"text": "Whoo! Y'all played that slow and smart, like a funeral march. Then you hit the high note."},
		{"who": "ud_jojo", "side": "left", "mood": "happy",
			"text": "Was that a compliment? It sounded like a compliment. I'm taking it."},
		{"who": "nol_boss", "side": "right", "mood": "happy",
			"text": "It was. Need a man with fast feet and a trombone? The trombone stays home. Probably."},
	],

	# Denver: Switchbacks, boss Ridge (den_boss). Twist: thin air (long shots carry, the ball floats, tired fast).
	# Running joke: the van's one breakdown, on the climb.
	"denver_arrive": [
		{"who": "narrator", "side": "left",
			"text": "Halfway up a mountain road, {van} makes a noise like a goose and stops. Steam. Silence."},
		{"who": "ud_tank", "side": "left",
			"text": "She's just out of breath. Thin air up here. Grandpa says a tired mule still pulls if you sing to her."},
		{"who": "ud_jojo", "side": "left",
			"text": "I'm NOT singing to the van. ...Fine. One verse. ...Hey, she started!"},
		{"who": "den_boss", "side": "right", "mood": "smug",
			"text": "Saw you boys pushing that van up the hill. I'm Ridge. Up here the ball flies and the lungs don't."},
		{"who": "den_g1", "side": "right",
			"text": "Long shots carry a mile up. Lobs hang forever. And you'll be gassed by the second possession."},
		{"who": "ud_deuce", "side": "left",
			"text": "Then we let it fly from deep, and we sub our breath, not our effort. Let's go."},
	],
	"denver_won": [
		{"who": "den_boss", "side": "right",
			"text": "Not bad for flatlanders. You didn't even need the oxygen tank I brought."},
		{"who": "ud_tank", "side": "left", "mood": "happy",
			"text": "Can I borrow it anyway? For {van}. She liked the singing, but I think she'd like oxygen more."},
		{"who": "den_boss", "side": "right", "mood": "happy",
			"text": "Ha! Tell you what: take the tank, and if you want a guy who never runs out of air, take me too."},
	],

	# Seattle: Puddle Jumpers, boss Downpour (sea_boss). Twist: wet court (hard cuts slide).
	"seattle_arrive": [
		{"who": "narrator", "side": "left",
			"text": "Seattle. A park court in the rain. Puddles at both ends. The rain does not stop. Ever."},
		{"who": "ud_deuce", "side": "left",
			"text": "My knee said it was going to rain. Jojo said it's Seattle, it's always going to rain. You were both right."},
		{"who": "sea_boss", "side": "right", "mood": "smug",
			"text": "I'm Downpour. Cut hard on this court at full speed and you'll skate right past your man. Ask him."},
		{"who": "sea_a1", "side": "right",
			"text": "Hi. I'm him. I'd open my umbrella, but then they'd know I'm scared."},
		{"who": "ud_tank", "side": "left",
			"text": "Grandpa says plow slow when the field is wet. Short steps. Crossovers, not hard cuts."},
	],
	"seattle_won": [
		{"who": "sea_boss", "side": "right",
			"text": "You stayed on your feet. Most crews spend the whole game sliding into the bushes."},
		{"who": "ud_jojo", "side": "left", "mood": "happy",
			"text": "I slid into the bushes ONE time. And I found a really nice rock in there."},
		{"who": "sea_boss", "side": "right", "mood": "happy",
			"text": "Keep it. And if you want a man who doesn't mind bad weather, my boat can wait a week."},
	],

	# Los Angeles: Boardwalk Bombers, boss Sunset (la_boss). Twist: sand (everyone slower, turbo matters more).
	"los_angeles_arrive": [
		{"who": "narrator", "side": "left",
			"text": "Los Angeles. A court right on the beach. The sand gets everywhere. Everywhere."},
		{"who": "ud_jojo", "side": "left",
			"text": "Napkin math: sand slows you down, plus sun, plus ocean... equals me taking a nap. Wrong napkin."},
		{"who": "la_boss", "side": "right", "mood": "smug",
			"text": "Sunset, head lifeguard. On sand, everybody's slow. The crew that saves its turbo for the right moment wins."},
		{"who": "la_g1", "side": "right",
			"text": "We grew up sprinting in this stuff. You grew up in... corn? Is corn soft?"},
		{"who": "ud_deuce", "side": "left",
			"text": "Corn's not soft. Neither are we. Walk it up, then burst. One more city and it's New York."},
	],
	"los_angeles_won": [
		{"who": "la_boss", "side": "right",
			"text": "Respect. You picked your sprints like a lifeguard picks a wave. That's the whole job."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "Thanks. My legs feel like they're full of sand. Because they are."},
		{"who": "la_boss", "side": "right", "mood": "happy",
			"text": "New York's next, huh? I've always wanted to see a court with no beach. Want a lifeguard on the bench?"},
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

	# arriving in New York, before the bracket. Twist: the cage (a loose ball bounces off the sideline fence).
	"final_before": [
		{"who": "narrator", "side": "left",
			"text": "New York. The Big City Showdown. {van} coughs once and parks itself next to a fire hydrant."},
		{"who": "ud_tank", "side": "left",
			"text": "Only broke down the one time. On a mountain. I'm counting that as a win for her."},
		{"who": "ud_jojo", "side": "left",
			"text": "We made it! The flyer was REAL! My napkin said eighty percent. Napkins: one for one!"},
		{"who": "ny_boss", "side": "right", "mood": "smug",
			"text": "So you're the {crew}. Heard you came all the way from a cornfield. This is a cage court, farm boys."},
		{"who": "ny_boss", "side": "right",
			"text": "Fence on both sides. The ball bounces off it and stays live. Win three on my courts and you'll see me in the final."},
		{"who": "ud_deuce", "side": "left",
			"text": "Nothing goes out, so nothing's over till it's over. Bracket's up. Let's go."},
	],

	# the final won: the end of the trip, then the title
	"ending": [
		{"who": "ny_boss", "side": "right",
			"text": "...A cornfield. You came out of a cornfield and took my crown. Respect, {crew}."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "The knee held up. Eight cities, rain and sand and mountains, and it held up. Guess this was my second shot."},
		{"who": "ud_tank", "side": "right", "mood": "happy",
			"text": "I'm proud of you guys. And of {van}. She only broke down the one time, and we sang her back."},
		{"who": "ud_jojo", "side": "left", "mood": "happy",
			"text": "Final napkin math: three underdogs, one van, a thousand miles... equals CHAMPIONS. I'm framing this napkin."},
		{"who": "narrator", "side": "left",
			"text": "And so the {crew} drove home to Indiana, the trophy in Tank's cup holder. THE END... for now."},
	],
}

# The recruit's joining line (owner Q4: "the recruit joins with a funny line"): recruit.gd shows it with his portrait
# right after you sign him. One per recruitable player (every city's 2 good players and its boss), in his own voice;
# the same placeholders as the scenes. Keep a line to about 2 short sentences (the box holds 3 rows). A player
# without a line here simply joins with the banner.
const RECRUIT_LINES := {
	# Hometown: County Line
	"ht_g1": "I told the feed store I'd be back Monday. I didn't say which Monday. Let's go.",
	"ht_g2": "I throw hay bales all summer. Throwing city boys out of the paint can't be much harder.",
	"ht_boss": "I'm bringing the folding chair. And the whistle. Somebody has to keep you boys organized.",
	# Chicago: Lakeshore Gusts
	"chi_g1": "No wind inside a van, right? Good. My jumper's been waiting its whole life for still air.",
	"chi_g2": "I'll ride in the van. But if traffic gets slow, I'm getting out and pedaling. Kidding. Mostly.",
	"chi_boss": "You scored on me way more than twice. Better to be on your side. Make room in the back, I'm big.",
	# Memphis: Riverside Soul
	"mem_g1": "I'll warm up my voice in the van. Don't worry, I only know two songs, and both are about winning.",
	"mem_g2": "A van with brakes? ALL of them working? Fellas, this is already the nicest ride of my life.",
	"mem_boss": "I packed a cooler of brisket for the road. Low and slow, boys. The food, not the fast break.",
	# New Orleans: Bayou Brass
	"nol_g1": "I left the trumpet with my cousin. But if we win New York, I'm playing a parade on the van roof.",
	"nol_g2": "This van got a turbo button? No? That's okay. I'll push. Been pushing boats my whole life.",
	"nol_boss": "The trombone stayed home, like I promised. I brought a kazoo. Nobody said nothing about a kazoo.",
	# Denver: Switchbacks
	"den_g1": "Down at sea level my shots might come up short. Good thing I practice from the parking lot.",
	"den_g2": "I've hung off a cliff by two fingers. A thousand miles in the back of your van? Easy.",
	"den_boss": "I packed the oxygen tank. It's for {van}. And for Jojo, if he keeps talking this fast.",
	# Seattle: Puddle Jumpers
	"sea_g1": "I brought my espresso machine. It plugs into the lighter. Probably. Who wants a triple?",
	"sea_g2": "Told all three of my bands I'm going on tour. Can my bass ride in the cup holder? ...Tank says no.",
	"sea_boss": "The fish can wait a week. Fair warning: wherever I go, the rain comes too. Pack a towel.",
	# Los Angeles: Boardwalk Bombers
	"la_g1": "My board fits under the seat. If {van} breaks down again, I'll skate us to New York.",
	"la_g2": "No waves in New York, huh? That's cool. I'll ride the crowd noise all the way to the rim.",
	"la_boss": "Lifeguard's on duty, {crew}. Nobody goes under on my watch. Not in the sand, not in the big city.",
}

# a recruit's joining line ("" for a player without one)
static func recruit_line(id: String) -> String:
	return str(RECRUIT_LINES.get(id, ""))

# a scene's lines ([] for an unknown id)
static func scene(id: String) -> Array:
	return SCENES.get(id, [])

static func has_scene(id: String) -> bool:
	return SCENES.has(id)
