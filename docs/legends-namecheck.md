# Legends name check (P9-07; Chapter 2: P10-11)

The hard rule (`docs/legends-plan.md` part 1): every legend is our own character. No legend's full name, nickname
or "first last" may match a real NBA or ABA player or a famous real basketball nickname, closely or exactly. This
doc is the check for Chapter 1 and the list `--legendtest` uses (copied into `scripts/legends_data.gd` as
`REAL_NICKNAMES` and `REAL_NAMES`; keep the two in step). Checked 2026-11-19 by gameplay-programmer A.

## Result: Chapter 1 passes, no swap

| Legend (id) | Full name | Exact match | Close matches looked at | Verdict |
|---|---|---|---|---|
| `lg_steeple` | Ezekiel "Steeple" Oakhurst | none | no surname within 2 letters; "Ezekiel" shortens to "Zeke" (a real player's famous nickname, see the cautions) | keep |
| `lg_gate` | Augustus "Gate" Fenwick | none | Feerick, Feick (2 letters away, unrelated sounds) | keep |
| `lg_set_shot` | Harlan "Set Shot" Vickery | none | Dickey, Hickey, Mickey (2 letters away); "set shot" is a plain basketball term | keep |
| `lg_boxcar` | Cornelius "Boxcar" Dunmore | none | first name shared with Cornelius Cash and with Connie Hawkins (born Cornelius); a first name alone is fine | keep |
| `lg_velvet` | Desmond "Velvet" Ashby | none | first name shared with Desmond Bane, Ferguson, Mason, Penigar; first name only | keep |
| `lg_quarterback` | Otis "Quarterback" Brannigan | none | first name shared with Otis Birdsong, Howard, Smith, Thorpe; surnames starting "Bran" (Branch, Brand, Brandon, Brannum) are 3+ letters away | keep |

No nickname of the six (Steeple, Gate, Set Shot, Boxcar, Velvet, Quarterback) is a known real player's nickname,
and none holds one as a word. The challenge lines, bios, looks and signature texts in `legends_data.gd` name no real
player and use no famous nickname or trademarked move name. **No name was swapped.**

### Cautions for the other Phase 9 tasks
- **Never call Steeple "Zeke"** (story, HUD, plates): "Zeke" is a famous real point guard's nickname. Use STEEPLE,
  Ezekiel, or "the big fella".
- **Steeple's move is the "hook shot"**, never "sky hook" / "skyhook" (a famous center's trademark name for it).
  "Hook" alone is also a famous streetball legend's nickname: never use it as Steeple's name.
- "Finger roll" (Velvet), "set shot" (Set Shot) and "outlet pass" (Quarterback) are plain basketball words, allowed.
- **Numbers**: Steeple 18 (the approved look sample's), Gate 54, Set Shot 9, Boxcar 46, Velvet 19, Quarterback 12 are
  placeholders until the owner approves a list (plan part 1). The kits are our own era colors (`ERA_*` palettes), and
  the test refuses the most famous numbers (`NUMBER_AVOID`: 0, 1, 3, 6, 8, 13, 23, 24, 30, 32, 33, 34, 35, 45, 99).

### Heads-up for Phase 10 (not in the data yet)
The plan's later placeholder names, run through the same player list: Dorian **Vance** (a real player Gene Vance;
also Nance is 1 letter away), Bodie **Ferreira** (a real player Rolando Ferreira) share a surname with little-known
real players; Keon Ridley (Riley), Calloway Briggs (Braggs) and Atlas Varga (Verga, Varda) are 1 letter from real
surnames. None is a full-name or nickname match. Swap or keep at the Phase 10 name check; the owner decides.

## Chapter 2, the Fathers (P10-11): passes after 3 swaps, shown to the owner

Checked 2026-11-21 by gameplay-programmer A, against the same NBA list (step 1 below, 5,198 NBA and 1,228 WNBA entries)
and the lists below extended with the 2000s era (the players and nicknames of the years the Fathers look comes from,
and the streetball mixtape tour names of the time). Owner answer F1 a: the six of the plan, new surnames for Rooftop
and Eyes Closed, the looks spread, names and numbers shown to the owner.

| Legend (id) | Full name | Exact match | Close matches looked at | Verdict |
|---|---|---|---|---|
| `lg_rooftop` | Dorian "Rooftop" **Ashcombe** (was Vance) | none | no surname within 2 letters; first name shared with Dorian Finney-Smith (first name only, a different player type) | **new surname** (Vance is Gene Vance's, and 1 letter from Nance) |
| `lg_ankles` | Tremaine "Ankles" Pettaway | none | no surname within 2 letters; first name shared with Tremaine Fowlkes (first name only) | keep |
| `lg_midrange` | Darnell "Midrange" Kingsley | none | Tinsley (Jamaal Tinsley, a 2000s guard) and Kinsey are 2 letters away; first name shared with Darnell Hillman, Jackson, Mee, Valentine | keep |
| `lg_freight` | Bartholomew "Freight" Thackeray | none | Thacker (Tom Thacker) 2 letters away; no Bartholomew in the list | keep |
| `lg_eyes_closed` | Keon "Eyes Closed" **Pemberton** (was Ridley) | none | no surname within 2 letters; first name shared with Keon Clark, Ellis, Johnson (first name only; none a passer of note) | **new surname** (Ridley is 1 letter from Riley: Pat Riley, Eric Riley) |
| `lg_lockbox` | **Corwin** "Lockbox" Hollister (was Shane) | none | no surname within 2 letters; no Corwin in the list | **new first name**: "Shane" + a lockdown wing defender with a buzz cut points at Shane Battier, the best-known lockdown wing of the 2000s (the hard rule's "combination" case). **Owner: keep Corwin, or say if Shane stays** |

No nickname of the six (Rooftop, Ankles, Midrange, Freight, Eyes Closed, Lockbox) is a known real player's nickname,
none holds one as a word, and none is a first or last name in the NBA list. Their bios, looks, signature texts and
challenge lines name no real player and use no listed nickname or trademarked move name.

### The look spread (the board's hard rule)
The small quick crossover guard with cornrows, a single arm sleeve and a headband is one famous real player's look, so
those parts never meet on one legend: **Ankles** (small, quick crossover guard) has short twists and a headband, no
cornrows and no arm sleeve; **Rooftop** (tall lanky wing, the approved look sample) has the cornrows and a left arm
sleeve, no headband; **Lockbox** (rangy wing, buzz cut) has a right arm sleeve, no headband; **Freight** (huge center)
has a headband and a goatee; **Midrange** a fade and a leg sleeve; **Eyes Closed** (the approved sample) a durag,
wristbands and a leg sleeve. P10-14 / P10-15 follow these looks (`look` in `legends_data.gd`).

### Numbers (placeholders until the owner approves them)
Rooftop **27** (the approved sample's), Ankles **16**, Midrange **28**, Freight **48**, Eyes Closed **14** (the
approved sample's), Lockbox **36**. None is in `NUMBER_AVOID` or used by Chapter 1 (18, 54, 9, 46, 19, 12).
`NUMBER_AVOID` reviewed for the era: added 2, 5, 10, 11, 15, 20, 21, 22, 31, 41, 42, 44, 50, 55 (the numbers the
2000s' and the earlier stars made famous); it is now 0, 1, 2, 3, 5, 6, 8, 10, 11, 13, 15, 20, 21, 22, 23, 24, 30,
31, 32, 33, 34, 35, 41, 42, 44, 45, 50, 55, 99.

### Cautions for the other Phase 10 tasks
- Move names stay plain words: "cradle dunk", "double crossover", "turnaround fadeaway", "shoulder-in", "no-look
  pass", "chase-down block". Never "killer crossover", "UTEP two-step", "the shammgod" or any shoe or brand name
  (no "AND1", no "Jumpman"); never a mixtape tour's name.
- Never call Ankles "the answer", Rooftop "Air ..." or anyone "Mr. Big Shot", "Sheed", "Franchise", "the Truth".
- The kits are the made-up `ERA2_*` palettes; a legend's kit never copies a real team's colors (crews.json says how).
- Probes added to the data test: Dorian Vance, Keon Ridley, Shane Battier, "THE ANSWER", "BIG SHOT" must fail.

## How the check was made
1. **Every NBA player**: the static player list in `nba_api` 1.12.0 (PyPI; its data file says "last updated Oct 21
   2026"), 6,426 entries (every NBA player since 1946, plus some WNBA). Read as text, never run. For each legend:
   same surname, same "first last", same first name, surnames within 1 and 2 letters (edit distance), and the
   nickname as a first or last name. Results in the table above.
2. **ABA-only players and nicknames** (and, for Chapter 2, the 2000s nicknames and the streetball tour names; the
   web was again out of reach on 2026-11-21): the web player indexes (basketball-reference, Wikipedia) could not be reached
   from the build machine, so the ABA stars and the famous nicknames below come from the team's knowledge. It is the
   list a fan would think of first; it is not exhaustive. The owner, or anyone with a browser, can add to it: a name
   added here and in `legends_data.gd` is checked on the next `--legendtest`.
3. **The data test** (`--legendtest`, `LegendsData.name_check()`): names are lower-cased with letters, digits and
   spaces only, and a leading "the" dropped. A legend fails when his nickname is a listed nickname, his "first
   nickname last" holds a listed nickname as whole words, his "first last" is a listed name, his last name is a
   listed surname or 1 letter from one (5 letters or more), or a text of his (bio, look, signature, challenge line,
   archetype) holds a listed full name or a nickname of 2 words or more. Probes that must fail (e.g. "AIR", "Bob
   Pettit", "Malon", "THE SKY HOOK", "MAGIC TOUCH") prove the check still bites.

## The list (copied into `scripts/legends_data.gd`)

### Real nicknames (`REAL_NICKNAMES`)
air, air jordan, his airness, magic, bird, larry legend, hick from french lick, dr j, doctor j, doctor, big o,
iceman, ice, pistol, pistol pete, wilt the stilt, stilt, big dipper, dipper, chief, hondo, logo, mr clutch, zeke,
microwave, worm, mailman, admiral, dream, hakeem the dream, glove, answer, ai, black mamba, mamba, greek freak, chef,
chef curry, king, king james, lbj, truth, big ticket, kg, big fundamental, shaq, diesel, big aristotle, superman,
penny, flash, agent zero, white chocolate, glide, clyde the glide, clyde, pearl, earl the pearl, black jesus, round
mound of rebound, sir charles, chuck, human highlight film, nique, spud, skywalker, kangaroo kid, hawk, a train,
captain late, bad news, dr dunk, jet, mr big shot, big shot bob, big shot rob, starbury, beard, brow, joker, dame
time, slim reaper, uncle drew, spida, big game james, zo, tiny, nate the great, sky hook, skyhook, cap, big smooth,
boogie, melo, cp3, d wade, process, unicorn, ant, alien, point god, splash brothers, russ, brodie, houdini of the
hardwood, cooz, easy ed, jumping joe, hot rod, bad boys, showtime, rifleman, rocket, thunder dan, vinsanity, half man
half amazing, air canada, big dog, reign man, big country, bones, mad max, matrix, big e, chairman of the boards,
goat, the goat, hook, destroyer, pee wee, skip to my lou, hot sauce, professor, helicopter, jumpin jackie, fly,
meadowlark, curly, goose, sweet lou, mikan, kareem, the hook, hammer, black hole, manimal, white mamba, the kid, big
shamrock, the mule, the bus, big baby, birdman, the claw, klaw, steady eddie, mr triple double, the stopper, the
general, the hammer, dr k, mr basketball, big red, air georgia, sky, j kidd, mutombo, sleepy floyd, world b free,
world, pops, bobo, smush, tmac, t mac, sweet pea, rainman, the dream team, the jet, mr fundamentals;
P10-11, the 2000s: sheed, big ben, rip, franchise, stevie franchise, manu, big z, ak47, ak 47, captain jack, j rich,
candy man, grindfather, tru warrior, hibachi, krypto nate, kryptonate, j will, big shot, baby shaq, baby jordan, bonzi,
peja, stat, big three, main event, bone collector, escalade, sik wit it, spyda, go get it, air up there, black widow,
high octane, headache, dribbling machine, ao, god shammgod, shammgod, killer crossover, utep two step, cat, the mayor,
bubba chuck, human joystick, jumpman, big nasty, boston strangler, k mart, kmart, chosen one, lob city, sky walker,
dr dunkenstein, slim

(Streetball and touring-team legends are in on purpose: "famous real basketball nicknames" is wider than the NBA.)

### Real players (`REAL_NAMES`; their last words are the surname list)
Michael Jordan, Magic Johnson, Earvin Johnson, Larry Bird, Kareem Abdul-Jabbar, Wilt Chamberlain, Bill Russell, Oscar
Robertson, Jerry West, Elgin Baylor, Julius Erving, George Mikan, Bob Cousy, Bob Pettit, Pete Maravich, Walt Frazier,
Earl Monroe, Dave Bing, John Havlicek, Willis Reed, Wes Unseld, Elvin Hayes, Nate Archibald, Moses Malone, George
Gervin, Connie Hawkins, Cornelius Hawkins, Artis Gilmore, Dan Issel, Mel Daniels, Rick Barry, Spencer Haywood, Bill
Walton, Dave Cowens, David Thompson, Bob Lanier, Bob McAdoo, Isiah Thomas, Kevin McHale, Robert Parish, Dennis
Johnson, James Worthy, Dominique Wilkins, Clyde Drexler, Charles Barkley, Karl Malone, John Stockton, Patrick Ewing,
Hakeem Olajuwon, David Robinson, Scottie Pippen, Dennis Rodman, Shaquille O'Neal, Kobe Bryant, Tim Duncan, Kevin
Garnett, Allen Iverson, Gary Payton, Jason Kidd, Steve Nash, Dirk Nowitzki, Paul Pierce, Ray Allen, Reggie Miller,
Vince Carter, Tracy McGrady, Dwyane Wade, LeBron James, Carmelo Anthony, Chris Paul, Dwight Howard, Kevin Durant,
Stephen Curry, James Harden, Russell Westbrook, Kawhi Leonard, Giannis Antetokounmpo, Nikola Jokic, Luka Doncic, Joel
Embiid, Anthony Davis, Damian Lillard, Kyrie Irving, Jayson Tatum, Victor Wembanyama, Shai Gilgeous-Alexander, Anthony
Edwards, Zion Williamson, Alonzo Mourning, Dikembe Mutombo, Anfernee Hardaway, Grant Hill, Chris Webber, Ben Wallace,
Manu Ginobili, Tony Parker, Yao Ming, Pau Gasol, Paul George, Jimmy Butler, Ja Morant, Klay Thompson, Draymond Green,
Bernard King, Adrian Dantley, Alex English, Sidney Moncrief, Calvin Murphy, Hal Greer, Sam Jones, Paul Arizin, Dolph
Schayes, Nate Thurmond, Jerry Lucas, Billy Cunningham, Lenny Wilkens, Gail Goodrich; ABA: Louie Dampier, Roger Brown,
Zelmo Beaty, Warren Jabali, Mack Calvin, Ron Boone, Willie Wise, James Silas, Darnell Hillman, Marvin Barnes, Freddie
Lewis, Jimmy Jones; streetball and touring teams: Earl Manigault, Demetrius Mitchell, Joe Hammond, Richard Kirkland,
Rafer Alston, Herman Knowings, Jackie Jackson, James Williams, Meadowlark Lemon, Fred Neal, Marques Haynes, Reece
Tatum, Lou Dunbar; the early game: Neil Johnston, Bill Sharman, Tom Heinsohn, K.C. Jones, Jo Jo White, Dave
DeBusschere, Bill Bradley, Wally Szczerbiak, Chet Walker, Gus Johnson, Jack Twyman, Maurice Stokes, Bob Davies, Max
Zaslofsky, Joe Fulks, Jim Pollard, Vern Mikkelsen, Slater Martin, Cliff Hagan, Ed Macauley, Frank Selvy, Tom Gola,
Guy Rodgers, Walt Bellamy, Dick Barnett, Cazzie Russell, Lou Hudson, Bob Love, Jerry Sloan, Norm Van Lier, Tiny
Archibald. P10-11: the Phase 9 heads-up surnames Gene Vance, Larry Nance, Pat Riley, Eric Riley; the 2000s: Rasheed
Wallace, Chauncey Billups, Richard Hamilton, Tayshaun Prince, Shane Battier, Tony Allen, Bruce Bowen, Ron Artest, Metta
World Peace, Stephen Jackson, Jason Terry, Jason Richardson, Gilbert Arenas, Stephon Marbury, Steve Francis, Baron
Davis, Jason Williams, Antoine Walker, Shawn Marion, Amare Stoudemire, Elton Brand, Jermaine O'Neal, Peja Stojakovic,
Mike Bibby, Andrei Kirilenko, Zydrunas Ilgauskas, Michael Redd, Rashard Lewis, Ben Gordon, Gerald Wallace, Josh Smith,
Nate Robinson, Jamal Crawford, Lamar Odom, Michael Finley, Glenn Robinson, Latrell Sprewell, Kenyon Martin, Desmond
Mason, Cuttino Mobley, Larry Hughes, Jamaal Tinsley, Steve Smith, Raja Bell, Ricky Davis, Corey Maggette, Bonzi Wells,
Brad Miller, Sam Cassell, Mike Miller, Joe Johnson, Chris Bosh, Deron Williams, Rajon Rondo, Andre Iguodala, Monta
Ellis, Tyson Chandler, Marcus Camby, Theo Ratliff, Tim Hardaway, Mitch Richmond, Glen Rice, Allan Houston, Antawn
Jamison, Shareef Abdur-Rahim, Darius Miles, Quentin Richardson, Kirk Hinrich, Andre Miller, Mike Dunleavy, Caron
Butler, Luol Deng, Josh Howard, Richard Jefferson, Vlade Divac, Predrag Stojakovic, Hedo Turkoglu, Emeka Okafor, Al
Jefferson, Kevin Martin, Jalen Rose, Eddie Jones, Keith Van Horn, Derek Fisher, Robert Horry, Bobby Jackson, Mo
Williams, Chucky Atkins, Eric Snow, Aaron McKie, Derrick Coleman, Nick Van Exel, Damon Stoudamire, Jerry Stackhouse,
Rod Strickland, Terrell Brandon, Kenny Anderson, Derek Anderson, Brent Barry, Jason Kapono, Fred Jones, Dee Brown,
Harold Miner, God Shammgod; streetball mixtape tours: Grayson Boucher, Philip Champion, Aaron Owens, Waliyy Dixon, Troy
Jackson, Shane Woney.

The full NBA list (step 1) is too long to copy into the game; it was checked once here, and the table above is its
result. A new legend gets a row in the table and the same step-1 check before his art is made.
