# Phase 8 summary: progression

Version stays 1.0.0 (owner). Published to the web link from `1d7783b`. Release files rebuilt in `build/release/`
(not in git): `road-trip-hoops-1.0.0-web.zip`, `road-trip-hoops-1.0.0-debug.apk`. The signed APK needs the owner's key
(`tools/build_android.sh --release`, `docs/release/ANDROID.md`).

## What is new
- Stat points after every win for each starter (1, boss games 2), spent from the points screen or later from the
  lineup; old unspent points become crew points.
- Stars per city game and New York round: 1 on Easy, 2 on Normal, 3 on Hard (72 in all). Best result kept.
- Star rewards: 4 roster slots (12 / 24 / 36 / 48 stars) that draft players from crews beaten on this trip; jerseys,
  balls and van paints on the new LOCKER screen; two star courts (MIDNIGHT, GOLD HALL) in Quick Game; LEGEND at 72.
- One boss in the starting three.
- Replays of beaten city games from the map (stars only, the trip doesn't move).
- 3-2-1-GO! countdown before every game.
- Shots go in more often (about 50%), so games are about 55-90 shots and 7-11 minutes.
- Ramp retuned for the new points: city crews average 40 in Hometown up to 78 in New York; LEGEND adds +12 (cap 95).
- A star jersey switches to the normal look against a crew in close colors.
- 1.0.0 saves load and play on (catch-up points, stars for games already won, extra bosses to the bench).

## QA
- `docs/qa/phase8-saves.md` (old saves), `phase8-screens.md` (every screen), `phase8-ramp.md` (1,420 games),
  `phase8.md` (final: release-ready, no open bugs). Bugs P8-B1..B8 fixed. P7-B1 closed (not reproduced, 20/20 on web).

## Open for the owner
- Play a trip on the tablet: stars, a draft, a replay, the LOCKER.
- Small look questions still open: the LOCKER button color, countdown size and sound, the CLASSIC default name, the
  Kings wearing your jersey when they are the Quick Game opponent.
- Legends (`docs/legends-plan.md`): when to start (suggested Phase 9).
