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
#
# Legends, Chapter 1 (P9-14): legends_data.gd names the scenes: the chapter's "intro_scene" (the first time the
# chapter opens), each legend's "unlock_scene" (after his challenge is won; he speaks, like a recruit's line) and the
# "finale_scenes" before / after. A legend's "who" is his legends_data.gd id (lg_<id>): his portrait is
# assets/portraits/lg_<id>.png (moods: "happy" only). The legends stand right, your crew left. No {city} in these
# scenes (they are not about a trip city). Grandfathers-and-grandkids banter; Tank's grandpa is in the crowd.
# Name check cautions (docs/legends-namecheck.md): Steeple is STEEPLE, Ezekiel or "the big fella", never by a
# short form of Ezekiel; his move is the "hook shot", nothing else.
# Legends, Chapter 2 (P10-16): the Fathers, the generation between the Grandfathers and the kids; they grew up
# watching the old men in the wood gym (theme only, no families) and moved outside: the night park court, ISO BALL.
# Their running joke: the shorts (Tank's grandpa says they are too long). Cautions (docs/legends-namecheck.md
# "Chapter 2"): move names stay plain words (cradle dunk, double crossover, turnaround fadeaway, shoulder-in, no-look
# pass, chase-down block); never "the answer", "the truth", "franchise", "big shot", "Air ...", no brand or tour name.

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

	# ---------------- Legends, Chapter 1: the Grandfathers (P9-14) ----------------
	# the first time the chapter opens: the old gym, the six, the deal, a hint of the OLD SCHOOL rules
	"legends_grand_intro": [
		{"who": "narrator", "side": "left",
			"text": "Back home, behind the feed store, there's an old wood gym nobody has opened in years. Tonight the lights are on."},
		{"who": "ud_jojo", "side": "left",
			"text": "Napkin math says this place closed before my dad was born. So who's paying the electric bill?"},
		{"who": "lg_quarterback", "side": "right",
			"text": "We are, son. Otis Brannigan. Folks call me Quarterback. Heard you kids have been making noise out on the road."},
		{"who": "lg_steeple", "side": "right",
			"text": "Ezekiel Oakhurst. Steeple, to friends. Six of us played here, back when shorts were short and socks were tall."},
		{"who": "ud_tank", "side": "left",
			"text": "My grandpa talks about a gym like this. He says the floor creaked so loud you could hear a pump fake."},
		{"who": "lg_steeple", "side": "right", "mood": "happy",
			"text": "Smart man. Here's the deal: beat each of us at his own game, and we'll teach you. Then our best three take you on."},
		{"who": "ud_deuce", "side": "left",
			"text": "Old school, huh? Slower legs, long shots that won't fall, close ones that will. My knee's going to love it here."},
	],

	# Steeple's challenge won (hold him under 7, to 15)
	"lg_steeple_unlock": [
		{"who": "lg_steeple", "side": "right",
			"text": "Under seven. Nobody's held me that low since the rims were nailed to barn walls."},
		{"who": "ud_jojo", "side": "left", "mood": "happy",
			"text": "Napkin math says you're about seven feet tall. How did we even... Tank sat on your arm, didn't he."},
		{"who": "ud_tank", "side": "left",
			"text": "I only leaned. Grandpa says lean on a fence post long enough and it leans back."},
		{"who": "lg_steeple", "side": "right", "mood": "happy",
			"text": "Ha! All right, you earned the big fella. Find me in the Hall, and I'll teach your bigs some touch at the rim."},
	],

	# Gate's challenge won (reach 11 before his crew gets 10)
	"lg_gate_unlock": [
		{"who": "lg_gate", "side": "right",
			"text": "Eleven before ten. Forty years I kept this lane shut, and you ran right past the gate."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "We didn't try to go through you, Mr. Fenwick. We went around. Fast."},
		{"who": "ud_jojo", "side": "left",
			"text": "Also, you never jumped! Not once! Is that the trick? Just... not jumping?"},
		{"who": "lg_gate", "side": "right", "mood": "happy",
			"text": "The trick is jumping once, at the right time. Call me Gate. Come see me in the Hall and I'll show you when."},
	],

	# Set Shot's challenge won (he starts on fire, win to 15)
	"lg_set_shot_unlock": [
		{"who": "lg_set_shot", "side": "right",
			"text": "I was on fire, son. Both hands, feet planted. And you still won. That does not happen."},
		{"who": "ud_jojo", "side": "left",
			"text": "Sir, you were shooting from the parking lot. A car honked at you."},
		{"who": "lg_set_shot", "side": "right", "mood": "happy",
			"text": "That was my wife. She honks when I make one. Come by the Hall and I'll give your shooters some range."},
		{"who": "lg_set_shot", "side": "right",
			"text": "One condition: no more dunking in my gym. The dunk is a fad."},
		{"who": "ud_tank", "side": "left", "mood": "happy",
			"text": "Mr. Vickery, with respect, it's been a fad for a real long time."},
	],

	# Boxcar's challenge won (2 blocks or steals on him, and win, to 15)
	"lg_boxcar_unlock": [
		{"who": "lg_boxcar", "side": "right",
			"text": "Twice you took it off me. Thirty years in the rail yard, and nothing ever moved me."},
		{"who": "ud_tank", "side": "left", "mood": "happy",
			"text": "We didn't move you, sir. We just delayed you."},
		{"who": "lg_boxcar", "side": "right", "mood": "happy",
			"text": "Ha! That's MY line, big man. Fine. Find me in the Hall and I'll teach your crew to dunk from a step further out."},
		{"who": "ud_jojo", "side": "left",
			"text": "Do we bring anything? Like a gift? A wrench?"},
		{"who": "lg_boxcar", "side": "right",
			"text": "Bring snacks. Old men run on snacks."},
	],

	# Velvet's challenge won (hold him under 6, to 11)
	"lg_velvet_unlock": [
		{"who": "lg_velvet", "side": "right",
			"text": "Under six. On my finger roll. You made me sweat, children, and on my good shirt."},
		{"who": "ud_jojo", "side": "left",
			"text": "Mr. Ashby, it's a tank top."},
		{"who": "lg_velvet", "side": "right", "mood": "happy",
			"text": "It's a SILK tank top, young man. Come by the Hall, and I'll teach your guards to slip a layup past a hand."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "Only if you teach me to glide like you. My knee's about done running."},
		{"who": "lg_velvet", "side": "right", "mood": "happy",
			"text": "Gliding is just running with good manners. You'll get there."},
	],

	# Quarterback's challenge won (start down 0-2, come back, to 15)
	"lg_quarterback_unlock": [
		{"who": "lg_quarterback", "side": "right",
			"text": "Down two before the tip, and you came back anyway. I gave you a head start the wrong way!"},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "We've been the underdogs since Indiana, sir. Down two felt like home."},
		{"who": "ud_jojo", "side": "left",
			"text": "Can you teach me the no-look pass? And what's the whistle for? You never blow it."},
		{"who": "lg_quarterback", "side": "right", "mood": "happy",
			"text": "The whistle's for emergencies. Haven't had one yet. Find me in the Hall and I'll make your passes quicker."},
		{"who": "lg_quarterback", "side": "right",
			"text": "The no-look pass? I just threw you one. You didn't see it. That's the lesson."},
	],

	# before the Grandfathers finale (the Kings against Steeple, Velvet and Quarterback, to 21)
	"legends_grand_finale_before": [
		{"who": "narrator", "side": "left",
			"text": "Every banner in the old gym is lit. Half the town squeezed into the bleachers, and most of them are grandparents."},
		{"who": "lg_steeple", "side": "right",
			"text": "The six of us picked our three. Me, Velvet and Otis. Old school, to twenty-one, the way we always played it."},
		{"who": "lg_velvet", "side": "right", "mood": "happy",
			"text": "Don't worry, children. We'll go easy on you. ...That was a joke. We have never gone easy on anybody."},
		{"who": "ud_tank", "side": "left",
			"text": "Grandpa's in the third row. He says he's rooting for both teams. And for the popcorn."},
		{"who": "ud_jojo", "side": "left",
			"text": "Napkin math: add up their ages and you get older than most towns in Indiana. Somehow that makes it scarier."},
		{"who": "ud_deuce", "side": "left",
			"text": "They taught us what they know. Now we show them what we did with it. {crew}, ball up."},
	],

	# the finale won: the end of Chapter 1
	"legends_grand_finale_after": [
		{"who": "lg_quarterback", "side": "right", "mood": "happy",
			"text": "Well, that's the game. A bunch of kids beat the grandfathers, in our own gym."},
		{"who": "lg_steeple", "side": "right", "mood": "happy",
			"text": "Don't look so sad, Otis. That's how it's supposed to go. We just didn't think it'd be this soon."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "You never stopped playing. Bad knees and all. That's what I'll remember."},
		{"who": "lg_velvet", "side": "right", "mood": "happy",
			"text": "Our names are on those banners. Yours go up right next to them. Hang them straight, now."},
		{"who": "ud_tank", "side": "left", "mood": "happy",
			"text": "Grandpa's crying. He says it's the popcorn. It's not the popcorn."},
		{"who": "narrator", "side": "left",
			"text": "And so the Grandfathers gave the {crew} the keys to the old gym, and kept a spare. CHAPTER 1: DONE."},
	],

	# ---------------- Legends, Chapter 2: the Fathers (P10-16) ----------------
	# the first time the chapter opens: the night park court, the six, the deal, a hint of the ISO BALL rules
	"legends_fathers_intro": [
		{"who": "narrator", "side": "left",
			"text": "Across town, the old park court has new lights. A boom box is up loud, and the shorts are very, very long."},
		{"who": "ud_jojo", "side": "left",
			"text": "Napkin math: those shorts are forty percent of that man. Is that a basketball outfit or a tent?"},
		{"who": "lg_rooftop", "side": "right",
			"text": "Dorian Ashcombe. Rooftop. We grew up sneaking into the old wood gym to watch the old men. Then we moved outside."},
		{"who": "lg_eyes_closed", "side": "right",
			"text": "Keon Pemberton. Eyes Closed. I'm looking right at you, by the way. You just can't tell."},
		{"who": "ud_tank", "side": "left",
			"text": "My grandpa says shorts that long are just pants that gave up halfway."},
		{"who": "lg_midrange", "side": "right", "mood": "happy",
			"text": "Your grandpa never had to hide a crossover in all this cloth. Out here it's ISO BALL: one man, one move."},
		{"who": "lg_rooftop", "side": "right", "mood": "happy",
			"text": "Same deal the old men gave us: beat each of us at his own game and we'll teach you. Then our best three come."},
		{"who": "ud_deuce", "side": "left",
			"text": "Crossovers that stick, dunks from further out, a higher arc, all under the lights. My knee's sweating already."},
	],

	# Rooftop's challenge won (2 blocks or steals on him, and win, to 15)
	"lg_rooftop_unlock": [
		{"who": "lg_rooftop", "side": "right",
			"text": "Twice you took it off me. In the AIR. Nobody bothers me up there. There's no room up there for two."},
		{"who": "ud_tank", "side": "left", "mood": "happy",
			"text": "I didn't jump, Mr. Ashcombe. I just stood where you were going to land."},
		{"who": "ud_jojo", "side": "left",
			"text": "Napkin math: you hung up there about three seconds. I timed it. I also had time to buy a pretzel."},
		{"who": "lg_rooftop", "side": "right", "mood": "happy",
			"text": "Ha! My mother used to hide the ladder. Find me in the Hall and I'll teach your crew to dunk through a hand."},
	],

	# Ankles' challenge won (reach 11 before his crew gets 10)
	"lg_ankles_unlock": [
		{"who": "lg_ankles", "side": "right",
			"text": "Eleven before ten. I keep a list of every man I ever sat down, and not one of you made it today."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "Close, though. On that second crossover my knee went left and the rest of me went right."},
		{"who": "lg_ankles", "side": "right",
			"text": "Fine. You're on the list. Small print, at the bottom, next to a mailbox."},
		{"who": "ud_jojo", "side": "left",
			"text": "Can I be on the list? In big print? I'll fall down right now. Look. I'm falling."},
		{"who": "lg_ankles", "side": "right", "mood": "happy",
			"text": "Get up, kid. Find me in the Hall, and I'll teach you a crossover that puts the other guy on the floor."},
	],

	# Midrange's challenge won (he starts on fire, win to 15)
	"lg_midrange_unlock": [
		{"who": "lg_midrange", "side": "right",
			"text": "I was on fire. I cleared out the whole side, waved everybody away... and you still won. Rude."},
		{"who": "ud_jojo", "side": "left",
			"text": "You waved your OWN teammates away! Freight went and sat in the bleachers!"},
		{"who": "lg_midrange", "side": "right", "mood": "happy",
			"text": "Twenty years my coach told me not to take that shot. I took it anyway. It went in. That's my whole story."},
		{"who": "lg_midrange", "side": "right",
			"text": "Come by the Hall. I'll teach your shooters a pull-up from the spot nobody guards anymore."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "Inside the arc? Mr. Kingsley, my knee and I have been living there all trip."},
	],

	# Freight's challenge won (hold him under 7, to 15)
	"lg_freight_unlock": [
		{"who": "lg_freight", "side": "right",
			"text": "Under seven. In my own driveway. Nobody parks in my driveway."},
		{"who": "ud_tank", "side": "left", "mood": "happy",
			"text": "I didn't park, sir. I just stood there with my hazards on."},
		{"who": "ud_jojo", "side": "left",
			"text": "Napkin math says you weigh about as much as {van}. With us inside. And the cooler."},
		{"who": "lg_freight", "side": "right", "mood": "happy",
			"text": "Ha! Your van's got good taste. See me in the Hall, and I'll teach your bigs to keep the ball when hands come."},
	],

	# Eyes Closed's challenge won (start down 0-1, come back, to 15)
	"lg_eyes_closed_unlock": [
		{"who": "lg_eyes_closed", "side": "right",
			"text": "Down one before the tip, and you came back. I saw the whole thing. Well. I heard it."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "Down one is how we start every morning, Mr. Pemberton. We're used to it."},
		{"who": "ud_jojo", "side": "left",
			"text": "Who are you even talking to? You're looking at the hot dog stand."},
		{"who": "lg_eyes_closed", "side": "right", "mood": "happy",
			"text": "I'm talking to you, kid. Find me in the Hall and I'll teach your passes to sneak past the hands."},
		{"who": "lg_eyes_closed", "side": "right",
			"text": "Old Quarterback showed me that one at the wood gym, back when I was your size. Don't tell him I got better."},
	],

	# Lockbox's challenge won (score 6 points yourself on him, and win, to 11)
	"lg_lockbox_unlock": [
		{"who": "lg_lockbox", "side": "right",
			"text": "Six points. You, yourself, on me. I walked you from one free-throw line to the other, and you still got six."},
		{"who": "ud_jojo", "side": "left",
			"text": "Mr. Hollister, you never shot. Not ONCE. Is that even allowed?"},
		{"who": "lg_lockbox", "side": "right",
			"text": "I'm never in a hurry to shoot. I'm only in a hurry to make you miss."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "Then teach us that. We've been on the wrong end of quick hands since Indiana."},
		{"who": "lg_lockbox", "side": "right", "mood": "happy",
			"text": "Find me in the Hall. I'll give your crew quicker hands. Bring patience. I'm not in a hurry."},
	],

	# before the Fathers finale (the Kings against Rooftop, Midrange and Freight, to 21)
	"legends_fathers_finale_before": [
		{"who": "narrator", "side": "left",
			"text": "Every light on the park court is on. The boom box has new batteries. The whole block brought lawn chairs."},
		{"who": "lg_rooftop", "side": "right",
			"text": "We picked our three: me, Midrange and Freight. ISO BALL, to twenty-one, under the lights."},
		{"who": "lg_midrange", "side": "right", "mood": "happy",
			"text": "Don't take it personal when I wave my teammates away. I do it to everybody."},
		{"who": "lg_freight", "side": "right",
			"text": "My driveway's open tonight, kids. Come on in. You just can't leave."},
		{"who": "ud_tank", "side": "left",
			"text": "Grandpa came. He brought a lawn chair and a pair of shorts he calls \"sensible\". They are very short."},
		{"who": "ud_jojo", "side": "left",
			"text": "Napkin math: we beat each of them once. All three at once is... the napkin just says \"yikes\"."},
		{"who": "ud_deuce", "side": "left",
			"text": "They grew up chasing the old men. We grew up chasing them. {crew}, ball up."},
	],

	# the finale won: the end of Chapter 2
	"legends_fathers_finale_after": [
		{"who": "lg_rooftop", "side": "right", "mood": "happy",
			"text": "That's the game. We used to sneak into the wood gym to watch the old men. Now some kids sneak up on us."},
		{"who": "lg_freight", "side": "right", "mood": "happy",
			"text": "First time anybody ever backed me out of my own driveway. Felt kind of nice, honestly."},
		{"who": "lg_midrange", "side": "right", "mood": "happy",
			"text": "You took the shot nobody told you to take. Then you took it again. You're ready."},
		{"who": "ud_deuce", "side": "left", "mood": "happy",
			"text": "Knee's sore, legs are gone, and I don't care. Best night under the lights I ever had."},
		{"who": "ud_tank", "side": "left", "mood": "happy",
			"text": "Grandpa says he's proud of everybody. He also says your shorts are still too long."},
		{"who": "narrator", "side": "left",
			"text": "And so the Fathers left the park lights on for the {crew}, and turned the boom box down. Some. CHAPTER 2: DONE."},
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
	# Legends, the Grandfathers (P9-B3: drafted into a star slot; never "Zeke", never "sky hook")
	"lg_steeple": "Knees are sixty years old, elbow's still twenty. Feed me the ball low and step out of the way.",
	"lg_gate": "Nobody gets to the rim on my watch. Not in my gym, not in yours. I'll bring my own knee pads.",
	"lg_set_shot": "Two hands, feet set, follow through. And nobody touches the radio in the van but me.",
	"lg_boxcar": "Thirty years in the rail yard. A van ride across the country? That's a nap with a view.",
	"lg_velvet": "I pack light: one silk tank top, one headband, and a finger roll you'll be telling grandkids about.",
	"lg_quarterback": "I'll see the open man before he does. Somebody save me the front seat. I call the plays.",
	# Legends, the Fathers (P10-16; plain move names only, see the Chapter 2 cautions at the top)
	"lg_rooftop": "I'd ride on the roof of the van, but my mother would hide the ladder. Feed me lobs and look up.",
	"lg_ankles": "Bring me the best defender in every city. I've got room on my list. Lots of room.",
	"lg_midrange": "Clear out the left side and I'll take it from there. The left side of the van too. I like the window.",
	"lg_freight": "I'll take the back seat. All of the back seat. Need a road block in the paint? I'm the road block.",
	"lg_eyes_closed": "Don't worry, I'm watching the road. You can't tell, but I am. Somebody else should still drive.",
	"lg_lockbox": "I'll guard their best man in every city. And the snacks. Nobody gets the snacks past me.",
}

# a recruit's joining line ("" for a player without one)
static func recruit_line(id: String) -> String:
	return str(RECRUIT_LINES.get(id, ""))

# a scene's lines ([] for an unknown id)
static func scene(id: String) -> Array:
	return SCENES.get(id, [])

static func has_scene(id: String) -> bool:
	return SCENES.has(id)
