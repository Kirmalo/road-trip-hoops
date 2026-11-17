# Putting Road Trip Hoops on itch.io

Step by step, for a first upload. It works in a tablet browser (Chrome) or on a computer. Plan about 30 minutes.

What you need:
- the web ZIP, `road-trip-hoops-1.0.0-web.zip` (about 38 MB, 8 files inside); see part 0;
- the cover, `docs/release/cover.png` (630 x 500);
- the screenshots in `docs/release/screenshots/` (being made right now; use every PNG in that folder);
- the page text, `docs/release/itch_page.md`.

itch.io changes its pages now and then. If a field's name differs a little from the one written here, pick the one
that means the same. This guide was written without opening itch.io, so names are given as "the field called
something like ..." where we weren't sure.

## Part 0: get the files onto the device

### The web ZIP: two ways
- **From the team (easiest).** The team attaches the ZIP to a GitHub release. On the repo's GitHub page tap
  **Releases** (on the right, or near the bottom on a phone layout), open the newest release, and under **Assets**
  tap `road-trip-hoops-1.0.0-web.zip`. It goes to your Downloads folder.
- **Build it yourself (on a computer with Linux, Godot 4.3 and its web templates).** In the project folder run
  `tools/build_web.sh --zip`. It writes `build/release/road-trip-hoops-1.0.0-web.zip` and prints the number of
  files (8) and the size.

Do **not** unzip it. itch.io wants the ZIP itself. (If the tablet's Files app offers to extract it, say no.)

### The cover, screenshots and text
On the repo's GitHub page open `docs/release/`, tap `cover.png`, then the download button (an arrow pointing down,
or "Download raw file" in the "..." menu). Do the same for each picture in `docs/release/screenshots/`. For the text,
open `docs/release/itch_page.md` on GitHub and keep the page open: you copy parts of it in Part A.

## Part A: the web version

### A1. Create the account (once)
1. Go to **itch.io** and tap **Register** (top right; on a narrow screen it may be under the menu button).
2. Pick a username. It becomes your page address: `username.itch.io`. Fill in the email and password and register.
3. Open the email from itch.io and tap the confirm link. itch.io won't let you publish before that.
4. When it asks what you want to do, pick the option like "I'm interested in distributing content on itch.io" (or
   change it later in Settings; the "Upload new project" button appears once you are a creator).

### A2. Create the project
1. Tap your username or the arrow next to it (top right), then **Upload new project**. (Also on the
   **Dashboard**: **Create new project**.)
2. **Title**: `Road Trip Hoops`
3. **Project URL**: `road-trip-hoops` (itch fills it from the title; the page becomes
   `username.itch.io/road-trip-hoops`).
4. **Short description or tagline**: paste the line under "Short description or tagline" in `itch_page.md`:
   `Drive your underdog crew across America and win the 3v3 streetball tournament in New York.`
5. **Classification**: **Games**.
6. **Kind of project**: **HTML** ("You have a ZIP or HTML file that will be played in the browser").
7. **Release status**: **Released**.

### A3. Pricing
itch.io offers three choices, called something like **$0 or donate**, **Paid** and **No payments**.
- **No payments**: free, and there is no way to tip at all.
- **$0 or donate**: free to play, and players may tip what they want. **This is the one we use**: it is "pay what
  you want with a minimum of $0".
- **Paid**: a minimum price above $0. Not for us.

1. Tap **$0 or donate**.
2. In the field called something like **Suggested donation**, type a small tip, e.g. `2.00` (US dollars). Players
   can still pay $0.
3. To actually receive tips you must set up payouts once: your account menu, **Settings**, then the part called
   something like **Payment settings** or **Payouts** (PayPal or Stripe, and a tax form). You can publish first and
   do this later; tips can't be paid out until it is done. itch.io keeps a share of each payment (you choose it
   there; the default is 10%).

### A4. Upload the ZIP
1. Under **Uploads** tap **Upload files** and pick `road-trip-hoops-1.0.0-web.zip` from Downloads.
2. Wait until the upload bar finishes (38 MB; on a slow connection that takes a few minutes; keep the tab open).
3. Tick **This file will be played in the browser** next to the uploaded file.
4. Leave the platform boxes (Windows, macOS, Linux, Android) unticked for this file: it is the web version.

### A5. Embed options
These appear once the ZIP is marked as played in the browser (a section called something like **Embed options**).
1. The choice called something like **Embed in page** (not "Click to launch in fullscreen"): pick **Embed in page**.
2. **Viewport dimensions**: width `1280`, height `720`.
3. **Mobile friendly**: tick it. In **Orientation** pick **Landscape**.
4. **Automatically start on page load**: leave it **off**. The "Run game" tap is also the tap that lets the
   browser play sound.
5. **Fullscreen button**: tick it.
6. **Enable scrollbars**: leave it off.
7. **SharedArrayBuffer support** (marked experimental): leave it **off**. The game is built without threads and
   doesn't need it.

### A6. Description
1. In the **Description** box, paste the text between the two `---` lines of the "Description (long)" section of
   `itch_page.md`.
2. Optional: select each line that starts with `##`, delete the `## `, and make it a heading with the editor's
   heading button. Plain text works too.
3. Keep the credits part: the CC-BY music and sound must be credited there.
4. Don't add a link to the source code or to the GitHub Pages build (your answer for Phase 7).

### A7. Genre, tags and the rest of the details
1. **Genre**: **Sports**.
2. **Tags**: type the 10 tags from `itch_page.md` one at a time and tap itch's suggestion each time. itch allows 10
   at most.
3. Something like **AI generation disclosure** (itch asks whether the project contains output of generative AI):
   answer it truthfully; it is your call. For the facts: the game's code, its story text and the scripts that
   draw all the art were written by AI agents (the art itself is made by those scripts, not by an image
   generator); the music and sounds are by the people in the credits, plus a few synthesized by those scripts.
4. **App store links**: leave empty.
5. **Custom noun**: leave empty.
6. **Community**: **Comments** is enough (or **Disabled** if you don't want to read comments).
7. **Visibility & access**: **Draft** for now.

### A8. Cover and screenshots
1. **Cover image**: upload `cover.png` (630 x 500, the size itch.io asks for).
2. **Screenshots**: tap **Add screenshots** and pick every PNG from `docs/release/screenshots/`. Drag them into the
   order you like (the first is the one people see first).
3. **Gameplay video or trailer**: leave empty.

### A9. Save and test the draft on the tablet
1. Tap **Save & view page** at the bottom.
2. The draft page opens (only you can see it). On the tablet, in landscape:
   - tap **Run game**; the title screen appears and the menu music starts after the first tap;
   - tap itch's **fullscreen** button (under the game, on the right) and check the whole court fits;
   - play a Quick Game for a minute: the joystick, both buttons, sound and music;
   - start a Road Trip, play one game, leave the page, open it again, and check ROAD TRIP > CONTINUE is there;
   - Settings: switch LEFT-HANDED on and check the joystick moves to the right side in the next game; switch it
     back.
3. If something is wrong, don't publish: tell the team what you saw (a screenshot helps).
4. If it all works, also open the page on a computer browser and check the game runs there (keyboard: WASD, J, K).

### A10. Make it public
1. Open the project's edit page again (on the page: **Edit game**, or Dashboard > the project > **Edit**).
2. **Visibility & access**: **Public**.
3. **Save**. The page is live at `username.itch.io/road-trip-hoops`.

## Part B: adding the Android APK later
Do this once you have made the release key and a signed APK (all in `docs/release/ANDROID.md`).
1. Dashboard > Road Trip Hoops > **Edit**.
2. Under **Uploads**, **Upload files**, and pick `road-trip-hoops-1.0.0.apk` (the **release** APK, never the
   `-debug` one).
3. Next to the APK: **don't** tick "played in the browser". Tick the platform **Android**.
4. Optional: in the file's name field (called something like **Display name**), type `Road Trip Hoops for Android`.
5. In the description, delete the "Coming later" part about the Android app (and add a line like "Android: download
   the APK below and open it to install").
6. **Save**, then test on the tablet: download the APK from the page and install it (the checklist is part 4 of
   `ANDROID.md`: "Install unknown apps", "Install anyway", the game opens in landscape and full screen, a trip saves
   and continues after closing the app).
7. Say in the description that a trip played in the browser doesn't carry over to the app (the app has its own
   save).

## Part C: uploading an update later
- **Web**: Edit > Uploads, then on the web ZIP's row use the option called something like **Replace file** (or
  delete the old ZIP and upload the new one, then tick **This file will be played in the browser** again and check
  the embed options are still as in A5). A version number in the file name changes with each build; that's fine.
- **Android**: the new APK needs the same package id, a **higher version code** and the **same release key**
  (`ANDROID.md`, part 5). Replace the old APK the same way, keep **Android** ticked.
- Saves: an updated web build should keep players' saves, since they live in the browser under the same site, but
  we haven't been able to test that on itch.io. Try it on the tablet after the first update (CONTINUE still there?)
  and tell the team.
- Optional: itch.io can post a **devlog** (the page's edit menu) to tell followers what changed.
