# P12-23 Phase 12 QA: Chapter 4 ("the New Generation") challenge balance

**Report only.** Nothing in `scripts/` changed. Every candidate below ran in scratch project copies.

**Builds tested** (Godot 4.3 stable, Linux, headless, `--fixed-fps 60`):
- **OLD FB** = `c466581` (P12-25 head). FAST BREAK `speed_mult` 1.05, `break_mult` 1.10. Used for the main baseline, Easy,
  the best crew and the first candidates.
- **NEW FB** = `71c3fca`, the owner's pick: `speed_mult` 1.08, `break_mult` 1.20 (stamina 1.15 and dead balls 0.6 kept).
  The coordinator sent it mid-task. Used for a re-check of the baseline, the rim-run candidates and **the final
  package**. Between the two builds the only sim change is `twists.gd` (the `player.gd` diff only touches the combo
  drawing).

Every result row below says which build it ran on.

**Setup.** Two project copies outside the repo, each with its own `config/name`. A fresh absolute `XDG_DATA_HOME` for
every game. At most 2 Godot processes at once. Each game ran `--autoplay --challenge <id> --difficulty <level>
--no-countdown` plus `--expected-roster` or `--best-roster`. BLUE plays Hard in `--autoplay`, and the level changes RED
only.

The expected crew is ud_deuce 70/71/72/72/71, ud_jojo 71/71/73/71/72 and ud_tank 69/68/68/70/69. The best crew is
lg_eyes_closed 95/95/93/93/95, la_boss 93s and ny_q1 82/82/94/94/82. RED's ratings are the same on Easy, Normal and Hard.

**Games.** 1,854 `--autoplay` games, 2 `--humantest` games and 1 `--shots` run.
- Every game reached `FINAL`, printed its `CHALLENGE` line and exited 0.
- 0 `SCRIPT ERROR` lines and 0 shot-clock violations. In the screenshot run, the only `ERROR` line is xvfb's ALSA one.
- Exactly one side switch in every game but one. The exception was an Updraft hold broken at 3-7, before the switch at 6.
- Per game: 36.6 shots (11-86), FG 55.8%, 1.31 interceptions (max 7), 1.20 fouls, 5.3 steals and 5.2 blocks. OREB was
  26.0% of misses, and the loser scored 10.2 points.
- Game time: to 11, 3.8 min (1.7-6.3); to 15, 5.1 min (2.6-8.5); to 21, 7.7 min (5.0-11.9). No game got near
  `--quit-after`, and no player or ball got stuck.
- `--legendtest`: LEGENDTEST OK on `71c3fca`, and OK on a copy with every proposed value below.

## Targets (owner Q3 a)

| | Normal | Hard | Finale |
|---|---|---|---|
| Chapter 3 measured (P11-23, expected crew) | 50 | 40 | N 53, H 33 |
| Chapter 4 target | about 45 | about 30-35 | a bit harder than 53 / 33 |
| Firewall (`score`) | the hardest, met about 15% | | |

## Baseline: first guesses 75 / 14 / 66, expected crew, BLUE met %

| Challenge (type) | Easy OLD (12) | Normal OLD (40) | Hard OLD (40) | Normal NEW (20) | Hard NEW (20) | Normal best OLD (10) | Hard best OLD (10) |
|---|---|---|---|---|---|---|---|
| Overclock (race 11 before 10) | 50 | 55 | 30 | 35 | 45 | 40 | 40 |
| Long Shadow (comeback 0-2, to 15) | 33 | **35** | **10** | 30 | 10 | 40 | 30 |
| Glitch (stop x2, to 15) | 17 | 40 | 25 | 25 | 15 | 40 | 30 |
| Updraft (hold < 6, to 11) | 83 | 57.5 | 50 | 55 | 30 | 60 | 70 |
| Halfcourt (fire, to 15) | 75 | **80** | 50 | 65 | 30 | 70 | 60 |
| Firewall (score 5, to 11) | 8 | 20 | 5 | 5 | 10 | 10 | 10 |
| **Pooled, 6 challenges** | **44.4** (72) | **47.9** (240) | **28.3** (240) | **35.8** (120) | **23.3** (120) | **43.3** (60) | **40.0** (60) |
| **Finale (to 21, at 66)** | 91.7 (12) | **55.0** (40) | **22.5** (40) | **45.0** (20) | **30.0** (20) | 60 (10) | 20 (10) |

SE: about 7.8 on a 40-game cell, 11 on 20, 3.2 on 240 and 4.4 on 120.

**What this shows:**
- On the old build, 75 nearly hits the bands: Normal 48, Hard 28.
- The levels are about 20 points apart, wider than Chapter 3's 10.
- The six challenges spread too widely. Long Shadow (35 / 10) is as hard as Firewall, and Halfcourt (80 / 50) is far the
  easiest.
- The NEW FB re-check came out lower (36 / 23, 120 games each). The drop is about 2 SE, so it may be partly real (the
  faster game) and partly noise.

## Why Long Shadow is so hard: the rim run (A/B in scratch copies)

| Long Shadow's challenge, expected crew | games | Normal met | Hard met | his points a game (to 15) |
|---|---|---|---|---|
| today: `RIM_RUN_SPEED_MULT` 1.12, start 0-2 (OLD) | 80 | 35 | 10 | 5.8 |
| rim run off (`SIG_RIM_RUN` renamed, OLD) | 80 | 42.5 | 25 | 3.9 |
| start 0-1 only (OLD) | 80 | 32.5 | 25 | |
| `RIM_RUN_SPEED_MULT` 1.06, start 0-2 (NEW) | 60 | 40 | 20 | |
| 1.06 + start 0-1, at 75 (NEW) | 60 | 53.3 | 26.7 | |
| 1.06 + start 0-1, at 74 (NEW, the package) | 60 | 30 | 30 | |

- The rim run is worth about 2 points a game to him, or 47% of his crew's points. By comparison, Chapter 3's step-back
  was worth 0.5 points a game.
- It fires about 22 times a game, for about 2,200 CPU sprint frames.
- The start score alone barely moves Normal.
- A half-size burst (1.06) plus a 1-point start puts him with the others. Pooled over 120 games, the two 1.06 + 0-1 runs
  give Normal 41.7 and Hard 28.3.

## Other single changes (scratch copies)

| Change | Build | Normal met | Hard met |
|---|---|---|---|
| Halfcourt `cool_misses` 2 -> 3 (he stays on fire longer), at 75 | OLD (40 + 40) | 55 (was 80) | 35 (was 50) |
| the same | NEW (20 + 20) | 80 | 40 |
| the same, in the package at 74 | NEW (30 + 30) | 73.3 | 40 |
| Pooled with cool 3 | | **66.7** (90) | **37.8** (90) |

The score goal is judged only at the end, so the same games can be re-judged at any `min`. These are Firewall's
games, expected crew, Normal and Hard, both builds, every key set:

| `min` | 3 | **4** | 5 (today) |
|---|---|---|---|
| met, 180 games | 25.0% | **14.4%** | 8.9% |

"You" scores about 2.8 of 9 points. At 5, Firewall reads 5-20% per cell, under the owner's "about 15%". At 4 it reads
about 14%.

## The package (all proposed values together, NEW FB, expected crew, 30 games a cell)

The copy had `challenge_avg` 74, `mate_drop` 14 and `finale_stage_avg` 66, plus Long Shadow `start_score` [0, 1],
Halfcourt `cool_misses` 3 and `RIM_RUN_SPEED_MULT` 1.06. Firewall was played at `min` 5 and re-judged at 4.

| Challenge | Normal | Hard |
|---|---|---|
| Overclock (race) | 60 | 23.3 |
| Long Shadow (comeback 0-1) | 30 | 30 |
| Glitch (stop x2) | 36.7 | 30 |
| Updraft (hold < 6) | 60 | 53.3 |
| Halfcourt (fire, cool 3) | 73.3 | 40 |
| Firewall at `min` 5 / at `min` 4 | 6.7 / 10 | 3.3 / 23.3 |
| **Pooled, Firewall at 5** | **44.4** (180) | **30.0** (180) |
| **Pooled, Firewall at 4** | **45.0** | **33.3** |

Both levels land inside the owner's bands.

The finale is not touched by these keys: its legends are Overclock, Updraft and Halfcourt, at `finale_stage_avg` 66 +
20, shaped. It measured N 45 / H 30 on NEW (20 + 20) and N 55 / H 22.5 on OLD (40 + 40), so 51.7 / 25 pooled. That is
a bit harder than Chapter 3's 53 / 33, as asked. **Keep 66.**

The opponents at 74 (Normal = Hard):
- Overclock 95/74/74/64/59 (speed still at the 95 cap: 74 + 25), with Halfcourt 60/85/50/55/50 and Firewall 65/50/60/80/45.
- Long Shadow 79/64/89/84/54.
- Glitch 89/79/69/69/64.
- Updraft 79/59/94/79/59.
- Halfcourt 74/95/64/69/64 (still at the cap).
- Firewall 79/64/74/94/59.

The finale legends are Overclock 95/86/86/76/71, Updraft 91/71/95/91/71 and Halfcourt 86/95/76/81/76.

## Checks

| Check | Result |
|---|---|
| Expected crew, Normal about 45% | **PASS with the package:** 44.4 (Firewall at 5) or 45.0 (at 4). The first guess (75) gave 47.9 on OLD and 35.8 on NEW. |
| Expected crew, Hard about 30-35% | **PASS with the package:** 30.0 or 33.3. The first guess gave 28.3 on OLD and 23.3 on NEW. |
| Finale a bit harder than 53 / 33 | PASS at 66: 51.7 / 25 pooled, with NEW alone 45 / 30. |
| Firewall the hardest, about 15% | At `min` 5 he is the hardest but too hard (8.9%). At 4 he is 14.4% and still the hardest. |
| Harder level = lower share | Normal > Hard everywhere pooled. **Watch:** Easy (OLD, 72 games) pooled 44.4, no higher than Normal's 47.9. That is inside noise on 72 games (SE 6), but Chapter 3 read 67 > 50. Glitch Easy was 2/12 and Firewall Easy 1/12. Worth a bigger Easy cell in P12-26 or a later pass. |
| Best crew wins more | **Watch:** best Normal 43.3 and Hard 40.0 (60 each, OLD), against 47.9 / 28.3 for the expected crew. Finale Hard best: 2/10 on OLD, 6/10 on NEW, 5/10 with `--twist none`. So the 2/10 was mostly noise, but in Chapter 4 the 92-rated crew is not clearly ahead on Normal. |
| Cyber legends no harder than the natural ones beyond the goal | PASS. Each legend's share of his crew's points: Overclock 44%, Glitch 39%, Firewall 29% (cyber, mean 37%); Long Shadow 47%, Updraft 33%, Halfcourt 32% (natural, mean 37%). Win share without the goal (Normal, OLD): Glitch's crew 55%, Firewall's 62.5%, Updraft's 60%, Halfcourt's 80%. The hardest natural one, Long Shadow, comes from his rim run, not a cyber part. |
| Every goal type met and failed | PASS: race, comeback, stop, hold, fire, score, finale. |
| Signature moves seen (OLD, his own challenge, per game) | top gear 48 activations; rim run 22; hesitation 2.9 (combo frames 5.3, NEW `anim_combo_l` 2.6); putback 0.38 (tips 0.2, dunks 0.2); hot hand re-fires 0.18 (he starts on fire); swat 1.0 try a game |
| `--humantest` (NEW) | 2 runs, both ended exit 0. Firewall Normal: failed 8-11, "you" 2 of 8. Glitch Normal: met 15-10, 3 stops (3 steals). The HUD reads "SCORE 5 ON FIREWALL: n" and "BLOCK OR STEAL ON GLITCH: n/2". |
| Screenshot (`--shots --challenge lg_firewall`, xvfb, 3 frames, NEW) | The goal line "SCORE 5 ON FIREWALL: 0" is readable under the top bar, and the FAST BREAK banner sits under it. The HUD, the pause button and the PASS / SHOOT buttons stay clear of the play. Nothing is off screen at 1280x720. |

## Watch items from P12-17

- **Firewall's swat.** Of 267 logged swat tries, 252 were at the 1.0 cap and 253 were blocks (95%). The base chance on
  those tries was already 0.84 on average, so the multiplier adds little. The swat makes about 0.1-0.5 extra blocks a
  game, and Firewall makes about one swat try a game. It is not a balance problem; it only reads as "never fails". If
  the owner wants a sometimes-miss: `SWAT_BLOCK_MULT` 1.5 -> 1.2 (player.gd). Not measured.
- **Updraft's putbacks are rare.** 0.25-0.50 a game in his own challenge (to 11), 0.45-0.70 in the finale (to 21). The
  balance is fine as is. If the owner wants to see the move more: `PUTBACK_RIM_FT` 7 -> 9 or `PUTBACK_CRASH_FT` 14 ->
  18. Not measured.
- **Long Shadow and the finale at 0 for 3.** With 40-game cells, Long Shadow was really the hardest after Firewall (35 /
  10), caused by the rim run (above). The finale is fine at 66.
- At 74, Overclock's speed (74 + 25) and Halfcourt's shooting (74 + 25) are still at the 95 cap; 75 -> 74 changes nothing for those two stats.

## Proposal (for the lead and the owner)

| Where | Key | Now | Proposed | Why |
|---|---|---|---|---|
| `legends_data.gd`, `next` row | `challenge_avg` | 75 | **74** | With the three changes below, on NEW FB: N 44.4-45.0, H 30.0-33.3 |
| | `mate_drop` | 14 | 14 | kept |
| | `finale_stage_avg` | 66 | 66 | kept: 51.7 / 25 pooled (NEW: 45 / 30) |
| `lg_long_shadow` challenge | `start_score` | [0, 2] | **[0, 1]** | with the rim-run change: about 42 / 28 instead of 35 / 10 |
| `player.gd` P12-17 | `RIM_RUN_SPEED_MULT` | 1.12 | **1.06** | the move was worth about 2 points a game; at 1.06 he plays like the others |
| `lg_halfcourt` challenge | `cool_misses` | 2 | **3** | the easiest at 80 / 50; with 3: 67 / 38 pooled |
| `lg_firewall` challenge | `min` | 5 | **4** (owner's call) | 14.4% met against 8.9% at 5; still the hardest |

If the owner keeps Firewall at 5, the rest still lands (N 44.4, H 30.0). Firewall then reads about 9%.

If the owner doesn't want a signature constant touched, use Long Shadow `start_score` [0, 0]. That wouldn't be a
comeback any more, so it isn't a good option. The other way is to keep 1.12 and accept Long Shadow as a second very hard
challenge; the pooled numbers then drop about 3 points.

## Stale story lines for P12-29 (only if the owner takes the changes)

In `scripts/story_text.gd`:
- Line 713, `lg_long_shadow_unlock`: "Down two before the tip, and you came back to fifteen." This becomes "Down one"
  with [0, 1].
- Line 755, `lg_halfcourt_unlock`: "Two misses in a row, and the flame just went out." This becomes "Three misses in a
  row" with `cool_misses` 3.
- Line 769, `lg_firewall_unlock`: "Five points on me, and the win." Line 775: "... going in. Five times." Both become
  four with `min` 4.

The HUD goal lines come from the data, so they follow on their own. With no change, every Chapter 4 line still
matches.

## Bugs

None found. 0 errors, 0 crashes, 0 stuck games.
