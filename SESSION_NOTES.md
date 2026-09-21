# Session notes

A running log of what changed and why, for picking work back up. `checklist.md`
is the build state; this is the narrative behind it. Newest session first.

---

## 2026-09-21/22 — Phone fixes, Settings, Credits, app icon, New Game / Continue

**Where it got to:** the owner played the game on an Infinix GT 20 Pro, a 20:9
phone, and reported answers floating over the plant, a double Continue on
Level 1 Stage 3 and unreadable Level 2 Correct cards. All three are fixed.
Every stage now has a back / settings row, the hub has settings too, Settings
is a drawn card with music, sound effects and Main Menu, Credits roll up the
finished-game card, the app has its icon and boot splash, and the main menu
has New Game / Continue. An iOS preset was added and then dropped. Eleven
headless suites pass on `master`. **Everything is merged into `master` and
pushed**, at `fae6b49` before these notes.

The last session's notes said `level-4` was not merged. It was: `master`,
`level-4` and `origin/master` were already the same commit when this session
started.

### What was done, in order

1. **`ui/level 3 and 4 answers pinned to the bottom edge`** — the cause of
   the floating answers. Stages were measured from the top on a 1080 x 1920
   screen; a 20:9 phone is ~1080 x 2436 and `canvas_items` + `expand` adds
   the extra height at the bottom. Cards and Level 3's tap plank now anchor
   to the bottom, 60 px off the edge.
2. **`ui/level 1 tray and fun fact lifted off the bottom edge`** — Levels 1
   and 2 were already bottom-anchored; Level 1's fun fact sat 4 px from the
   edge, and moved up 56 px with its tray.
3. **`setup/ios export`** + two follow-ups — asked for by the owner, merged,
   then **removed** at the end of the session (step 14).
4. **`ui/top bar with back, music and sound effects on every stage`** —
   `scenes/components/top_bar.tscn`, headers and high bubbles 150 px down,
   low bubbles measured from the bottom, `AudioDirector` mutes the `Music` /
   `SFX` buses and saves `user://settings.cfg`, `tools/verify_top_bar.gd`.
   Stage back had been falling through to the main menu; it now goes to the
   level's stage select.
5. **`ui/settings card replaces the music and effects buttons`** — the
   owner delivered a settings icon and moved the toggles onto a Settings
   card. Off became "drawn darker"; the code-drawn strike was scrapped.
6. **`levels/level 4 stages 4 and 5 put the plank above the cards`** — see
   the decision below.
7. **`ui/credits on the finished-game card`**, then **`ui/credits roll up the
   screen as plain text`** — first a card, then, at the owner's request, a
   film-style roll that closes itself.
8. **`ui/settings card art, with its title on the plank and an X to close`**
   — the delivered board, "Settings" as live text on its plank, How To
   Play's X on the corner.
9. **`fix/level 1 stage 3's continue covers the painted one`** (+ a hotspot
   follow-up) and **`art/level 2 correct cards from the originals, drawn
   wider`**.
10. **`ui/settings button on the hub`** — the stages' `TopBar` with
    `show_back` off.
11. **`setup/app icon and boot splash`** — the logo's magnifier and sprout,
    cut from the "O" of KNOW, on cream as the launcher icon (legacy, adaptive,
    themed) and Android 12 splash icon; the whole logo on cream as Godot's
    boot splash, held 1.5 s; the Android window background cream too. Checked
    in a built debug APK. `project.godot` and `export_presets.cfg` changed,
    both asked for.
12. **Merged and pushed** `ui/answers-pinned-to-bottom` (fast-forward) and
    the iOS branch (merge commit), in a temporary worktree so the open
    editor's files were not switched under it.
13. **`ui/main menu new game and continue`** — "Start Game" is New Game.
    With a save, Continue appears above it and New Game becomes a
    `HoldButton` with the finished card's hint and reset. New
    `GameStateStore.has_progress()`. Merged and pushed.
14. **`setup/remove the ios export preset`** — Android only. The local
    `setup/ios-export` branch was deleted. Pushed.

### Decisions taken (all by the owner)

- **Answers fixed at the bottom, 60 px margin; room at the top for a row of
  buttons.** Recorded in CLAUDE.md as "a stage is laid out from both edges".
- **The top row is back (left) and settings (right).** Music and effects live
  on the Settings card, which also has Main Menu. The hub gets settings; stage
  select does not.
- **Settings closes by an X on its corner**, a tap on the dim, or Android back.
- **A switched-off toggle is its icon drawn darker.** No strike, no off art.
- **Level 4 Stages 4-5 put their plank just above the cards**, since under
  the header it covered the flower and the fruit on 16:9. Stages 1-3 keep it
  under the header.
- **Credits are plain rolling text on the finished-game card**, below New Game.
  Art: ChatGPT. Music: "On the Farm" by LudoLoon Studio and Towball's Crossing
  Deluxe by Towball, both itch.io. Sound effects: unknown.
- **Options became Settings, with no Credits button.**
- **App icon: the logo's magnifier on warm cream**, #FDF5E2; the splash is the
  whole logo on the same cream.
- **The main menu's New Game hold shows the same hint** as the finished card.
- **Android only.** The iOS preset was built, merged and then removed.

### Things that turned out to be true, and cost time

- **A render script that errors in a window hangs, it does not exit.** A `-s`
  script that touches an autoload before its first `await process_frame`
  fails, and a windowed Godot stops at the debugger and waits forever. Always
  `await process_frame` first, and run renders under `timeout`.
- **The Level 2 Correct cards were 800 px copies with 20-80 px of haze a
  side.** The originals are in `Downloads/Know To Grow Assets/Level 2/
  Situations/`. Worth checking the other levels' older imports the same way.
- **Level 1 Stage 3's card paints its Continue 15 px higher** than Stages 1-2.
  One shared rect is only safe once each card's painted button is measured.
- **The Godot editor rewrites `export_presets.cfg` and `project.godot`** from
  whatever it loaded — it put the iOS preset back into a branch that did not
  have it, and keeps moving `config/icon` below the splash lines. Close the
  editor before switching branches or editing either file, and discard the
  `config/icon` reorder rather than committing it.
- **`master` can be moved without a checkout**: `git fetch . <branch>:master`
  fast-forwards it while another branch is checked out, which kept the open
  editor's files still.
- **Both music packs ask for credit**: LudoLoon Studio's page asks for it by
  name, and Towball's is CC BY 4.0. That settled checklist §5's licence item.
- **Godot 4.7's splash settings** are `boot_splash/image`, `bg_color`,
  `stretch_mode` and `minimum_display_time` — `fullsize` is gone — and the
  default display time of 0 only flashes the splash.

### Still in progress

- **Nothing from this session has been played on the phone**, only rendered at
  1080 x 1920 and 1080 x 2436 and, for the icons, checked inside a built APK.
- **Sound effects' source**: one of three itch.io packs, unknown which.
  Credits say "Source to be confirmed".
- **16:9 compromises:** Level 1's prompt bubble overlaps the top of the soil
  bed; the Level 4 header touches the tomato on Stage 5; on the main menu with
  a save, How To Play overlaps the flower mascot.
- **The 1024 px project icon is slightly soft** — the magnifier is only ~320
  px in `logo.png`.
- **Android tablets (4:3)** are still unchecked (checklist §8).
- **Hub tabs, swipeable stage select, Garden, Badges and other back buttons**
  (checklist §9) wait on the owner's art.

### Next step

**Export a fresh APK from `master` and play it on the phone**, end to end:
the layout at 20:9, the top bar and Settings card, the app icon and splash,
New Game / Continue with a save and without, and the Credits roll. Then
whatever that test turns up, and after it checklist §9's hub tabs once their
art arrives.

### Verification state

On `master` at `fae6b49`:

| Check | Result |
|---|---|
| Project loads | the known audio line, and a "2 ObjectDB instances leaked" warning that has been there since before this session |
| `verify_level_1.gd` | PASS — incl. Stage 3's own Continue rect |
| `verify_level_2.gd` | PASS |
| `verify_level_3.gd` | PASS |
| `verify_level_4.gd` | PASS — card tops now 1305 / 1495 / 1685 |
| `verify_tap_answer.gd` | PASS |
| `verify_menu_flow.gd` | PASS — incl. New Game / Continue with and without a save, and Credits |
| `verify_game_state.gd` | PASS |
| `verify_audio.gd` | PASS |
| `verify_live_text.gd` | PASS |
| `verify_content.gd` | PASS |
| `verify_top_bar.gd` | PASS — 19 stages, the Settings card, the hub |

---

## 2026-09-21 — Level 4 and the finished game, built end to end

**Where it got to:** the whole game plays through. Level 4 runs from the hub
through its intro, a five-row stage select and five tapped stages, then Level 4
Complete, three badges and the completed-level sign, back to a hub with the
fruiting plant — where the finished-game card comes up by itself, once. Ten
headless suites pass. Built on `level-4` in fourteen commits; **not merged and
not pushed**.

### What was done, in order

1. **`art/import level 4`** — all 39 files from the export's `Level 4` folder,
   into `backgrounds/`, `levels/level_4/`, `plants/`, `ui/stage_select/` and
   `ui/screens/`. Stage select card and rows left uncropped for matching.
2. **`docs/level 4 decisions …`** — the owner's answers (below), and §9 of the
   checklist: the post-Level-4 feature list (back buttons, hub tabs locked until
   Level 1, swipeable stage select, Garden, 3 x 4 badge grid, Options, Credits).
3. **`ui/hub's fourth plant and the level 4 intro`** — the flower once Level 3
   is cleared; `level_intro_l4.tscn`. Closes Level 3's dead-end Grow Now.
4. **`ui/level 4 header on level 2's sign`** — the delivered blank header *is*
   the shared `ui_header_blank.png`; the duplicate was deleted. Header
   transcripts "Stage N" / the part added to the content.
5. **`levels/tap stages can keep their card order`** — `StageScreen.keep_card_order`.
6. **`art/crop level 4 cards to the drawn card`** — see "cost time" below.
7. **`levels/level 4 stage 1`**, then **`stages 2 to 5`** — after full-resolution
   mock-ups of all five were shown to and approved by the owner.
   `verify_level_4.gd` added.
8. **`ui/level 4 stage select`** — rows matched, stars covered, checked in a
   windowed render with all fifteen earned.
9. **`audio/level 4 track`** — `Track.LEVEL_4` (5).
10. **`ui/level 4 ending`** — three badges imported from `Badges/`, Grow Now cut
    from the sign, the hub's fifth plant.
11. **`docs/…`** ×2 — the finished-game screen, New Game / Continue, and the
    press-and-hold decision, onto the checklist.
12. **`ui/finished-game screen`** — `game_complete.tscn` over the hub,
    `Track.LEVEL_5` (6), `HoldButton`, and the saved `finished_shown` flag.

### Decisions taken (all by the owner)

- **Header:** plaque "Stage N", banner the part — "Roots" … "Fruit" — with the
  "Tap the correct function card." plank. It turned out to be Level 2's sign.
- **Cards keep their drawn A/B/C order, never shuffled.** The Correct cards name
  the answer by a drawn letter, "Correct Match: B". Consequence: the answer is B
  on four of five stages.
- **Layout approved from mock-ups:** the plank sits under the header, three
  900 x 175 cards stack at the bottom, the bubble is high (y 370) on Stage 1 —
  the roots glow inside the pot — and low (y 885) on Stages 2-5.
- **The Oops card is Level 1's again**, "That's not the right tool" and all.
- **Badges per level are 1 / 2 / 1 / 3.** Level 4: Plant Power-Up → Super
  Grower → Know to Grow Star.
- **One wording for "make food": "Help make food using sunlight."** Two cards
  are drawn "Make food…" and need re-exporting (checklist §4).
- **Level 4's Reinforcement Facts are accepted as drawn art**, like Level 3's.
- **Finished-game card:** comes up by itself the first time the hub shows the
  fruit; Continue Playing and New Game below it, on the primary plate. Column
  chosen by us, since "Continue Playing" needs 860 px at the theme's size.
- **New Game is press-and-hold whenever there is a save.** On the finished card
  there always is.
- **Main menu gets New Game / Continue**, Continue only with a save — on the
  checklist, not built. Saving per stage clear already existed.

### Things that turned out to be true, and cost time

- **The export pads images with near-invisible haze.** The header and twelve
  of the fifteen cards carried 100-170 px of alpha-under-32 margin, which a
  plain alpha crop keeps. It made the header look a different shape from
  Level 2's (it is identical) and made Stage 2-5 cards draw a third smaller
  than Stage 1's. **Crop new art at alpha 32, not alpha 0.** The screens'
  margins are soft drop shadows and were left alone.
- **A failed import can sit in a commit unnoticed.** `ui_correct_l4_s4.png`
  was recorded `valid=false` in the first import and nothing loaded it until
  Stage 4 existed. Removing the flag and reimporting fixed it with the same
  uid. `grep -rl "valid=false" assets --include=*.import` is now worth running
  after any bulk import.
- **The yellow stage row defeats colour detection.** Its plate's gold touches
  the first star. Found after a morphological opening; all three stars in a row
  then take the row's largest core, placed by their bottom edge.
- **A windowed Godot run can render headlessly-built screens.** A `-s` script
  that sets `root.size`, waits for `frame_post_draw` and saves
  `root.get_texture().get_image()` gives Godot's own render at 1080 x 1920 —
  better than PIL composites. It lives in the session scratchpad, not the repo.
- **Checking the dim by eye is unreliable.** Screenshots looked undimmed; the
  pixels were at 55% of the raw background, exactly the 0.45 dim.

### Still in progress

- **Nothing in Level 4 or the finished card has been played on a phone or in
  the editor.** Windowed renders cover the layout, not the feel — the hold's
  1.5 s in particular, and the cards' 15 px gap to the bottom edge on a
  gesture-navigation phone.
- **The hub's Play after everything is cleared** still reads "Level 4:
  Functions" and replays Level 4, the stopgap. Where it should lead is
  undecided.
- **Two Level 4 cards read "Make food using sunlight."** against the chosen
  "Help make food…", and one lacks a full stop. Art from the owner.
- **"Press and hold to start a New Game"** is live text we wrote, not design
  document wording.
- **`level-4` is not merged into `master` and not pushed.**

### Next step

**Merge `level-4`** once the owner has played it, then **the main menu's New
Game / Continue** (checklist §9): "Start Game" becomes New Game, a Continue
appears above it only when a stage has been cleared, and New Game is a
`HoldButton` with `require_hold` on whenever there is a save — the component
already exists and does a plain tap when it is off. The reset it performs is
the same one the finished card uses. After that, §9's list in the owner's
order, once their art arrives.

### Verification state

| Check | Result |
|---|---|
| Project loads | clean, apart from the known audio line |
| `verify_level_1.gd` | PASS |
| `verify_level_2.gd` | PASS |
| `verify_level_3.gd` | PASS |
| `verify_level_4.gd` | PASS — 5 stages, fixed A/B/C order, drift incl. interaction |
| `verify_tap_answer.gd` | PASS — incl. a tap stage keeping its order over 30 plays |
| `verify_menu_flow.gd` | PASS — all four endings, hub seed → fruit, the finished card |
| `verify_game_state.gd` | PASS — incl. `finished_shown` saved and cleared |
| `verify_audio.gd` | PASS — `LEVEL_4` is 5, `LEVEL_5` is 6, both loop |
| `verify_live_text.gd` | PASS — three signs, 15 headers, 19 prompts |
| `verify_content.gd` | PASS — 19 challenges, 57 voice-over lines |

---

## 2026-09-20/21 — Level 3, built end to end

**Where it got to:** Level 3 is playable from the hub through its intro, a
five-row stage select, five tapped stages, Level 3 Complete, the Mystery Solver
badge and its completed-level sign, back to the hub. It is the first level
answered by **tapping** rather than dragging, with no tray at all. Nine headless
suites pass. Built on `level-3` in eight commits, merged to `master` and pushed.

### What was done, in order

1. **`art/import level 3`** — all 25 files from the export's `Level 3` folder,
   sorted into `backgrounds/`, `levels/level_3/`, `ui/stage_select/` and
   `ui/screens/`. The five answer cards were taken to 640 wide (the 2x rule);
   everything else at source size, cropped to alpha **except** the stage select
   card and its rows, left uncropped so they could be measured against each
   other.
2. **`ui/level 3 header sign`** — `header_sign_l3.tscn`, a second `HeaderSign`
   with its own plate rects, because this sign puts the plaque *on top of* the
   banner. Header transcripts added: "Stage N" / "Identify the Plant Part".
   `verify_live_text` now checks each level against its own sign.
3. **`levels/tap to answer`** — `StageScreen.tap_to_answer`, with
   `OptionCard.draggable` and `keep_art_when_spent`. Both routes meet in one
   `_answer()`. New `tools/verify_tap_answer.gd` walks both routes on a borrowed
   Level 2 stage, so the shared code is covered independently of any level.
4. **`levels/level 3 stage 1`** — the pattern stage, and `verify_level_3.gd`,
   which walks the stage chain so later stages needed no change to it.
5. **`levels/level 3 stages 2 to 5`** — from Stage 1's numbers.
6. **`ui/level 3 stage select`** — `stage_select_l3.tscn`, rows found by
   matching, stars covered, wired to the intro and all five stages.
7. **`audio/level 3 track`** — `Track.LEVEL_3` (4) for all Level 3 screens.
8. **`ui/level 3 ending`** — Level 3 Complete → Mystery Solver → sign → hub.

### Decisions taken

- **Level 3 taps, with no tray.** Three answer cards sit loose on the garden
  under the "Tap the correct answer." plank. A wrong card stays on screen,
  darkened where it stands, since there is no slot behind it to fall back to.
- **The Oops card is Level 1's, "That's not the right tool" and all.** Accepted.
- **Header wording: "Stage N" / "Identify the Plant Part"** on all five — never
  the part's name, which would be the answer.
- **Header, prompt bubble, tap plank and cards all on screen.** The owner chose
  both the bubble and the plank.
- **The five Reinforcement Facts drawn into the Correct cards are accepted as
  art**, like the Oops card's wording — no transcript, no `vo_key`, no rule.
- **Level 3's header sign is 760 px wide**, not Level 2's 660. "Identify the
  Plant Part" measures 557 px at the theme's 51 px and the banner is only 554
  at 660. A wider sign keeps the type the same size as Level 2's rather than
  shrinking Level 3's.
- **The prompt bubble has two positions, and a stage picks one.** The question
  is drawn into the background — one part of the plant glowing, the rest grey —
  at a different height per stage, and a full-width bubble hid the answer on
  three of five. High (y 420) for Stages 2 and 3, low (y 1000) for 1, 4 and 5.
  Nothing else moves.
- **`tap_to_answer` is set in the scene, not read from `interaction`**, because
  a tap stage is built without a `%DropZone` and `level_content` is optional.
  `verify_level_3` asserts the two agree.
- **Level 3 gets one badge, Mystery Solver.** Not a choice: every badge in the
  export names what it is for, and it is the only one that says "You found all
  the parts of a plant!". Plant Power-Up and Super Grower are Level 4's; Know
  to Grow Star is the finished-game screen's.
- **The ending sits over `bg_stage_5_l3.png`**, the fruiting plant.

### Things that turned out to be true, and cost time

- **Composite before building.** Mocking all five stages at 1080 x 1920 in PIL
  before writing a scene is what found the bubble covering the answer. Headless
  cannot see it; the composites are the closest thing to F5 without the editor.
- **Stage select rows can be matched, not measured.** Normalised
  cross-correlation of *gradient magnitude* finds each coloured row over the
  grey one painted into the card, and all five matched at scale 1.00 — which is
  why the import left those six files uncropped.
- **Covering a star needs its outline.** The gold core is what colour detection
  finds, but the drawn star is ~13% larger with its dark outline. The ratio was
  measured off `icon_star_filled.png` itself, and the same rects became the
  scene's star slots, so earned stars land exactly.
- **A pill cut from a sign needs its own stadium mask**, or the leaves behind
  it come away with it.
- **The Level 3 music was in the repo all along.** `level_3.mp3` existed; only
  the enum entry was missing. `level_4.mp3` and `level_5.mp3` are there too.
- **Large Bash heredocs holding GDScript or `.tscn` text break on quoting.**
  Writing the generator to the scratchpad with Write and running it is reliable.

### Still in progress

- **Nothing in Level 3 has been seen in the editor.** Everything is verified
  headless plus full-resolution composites, which are arithmetic rather than
  Godot's own render. Stage 2's background is the odd 1024 x 1536 one and loses
  ~840 px off the sides under `KEEP_COVERED`.
- **The hub stops at three.** Grow Now after Level 3 returns to a hub with no
  fourth plant and no fourth level. `plant_leafy_with_flower.png` is in the
  Level 4 export; the button needs `level_intro_l4.tscn`.
- **`icon_leaves_l3` was exported differently** — larger source, hard alpha
  edge — and sits ~6% taller than its neighbours in a row.
- **Stage 1's prompt orphans its last word**: "What am / I?". Fixing it means
  widening the shared bubble's text inset, which touches all 19 prompts.

### Next step

**F5 through Level 3 in the editor**, then **Level 4**. Level 4's export is
already in Downloads: five backgrounds, three answer cards *per stage*
(`icon_stage_N_cM_l4`, not a shared set), a blank header, a "Tap the correct
function card" plank, stage select and rows, the ending, and the game
completion screen. It is also tapped, so `tap_to_answer` and the Level 3 layout
should carry over; the header wording and whether the bubble-placement rule
applies are the first two things to settle. Its first task is the hub's fourth
plant and `level_intro_l4.tscn`, which also closes the end of Level 3.

### Verification state

| Check | Result |
|---|---|
| Project loads | clean, apart from the known audio line |
| `verify_level_1.gd` | PASS |
| `verify_level_2.gd` | PASS |
| `verify_level_3.gd` | PASS — 5 stages, tap route, drift incl. interaction |
| `verify_tap_answer.gd` | PASS — tap and drag routes through `StageScreen` |
| `verify_menu_flow.gd` | PASS — incl. both endings and all press feedback |
| `verify_game_state.gd` | PASS |
| `verify_audio.gd` | PASS — `LEVEL_3` is 4 and loops |
| `verify_live_text.gd` | PASS — both signs, 10 headers, 19 prompts |
| `verify_content.gd` | PASS — 19 challenges, 57 voice-over lines |

---

## 2026-09-18/20 — Level 2, built end to end

**Where it got to:** Level 2 is playable from its intro to its ending. Five
situations, a situation select, two badges, a completed-level sign, and a hub
whose plant has grown into a sprout that offers Level 3. Level 1 was pulled onto
the same blank tray on the way, and the cards of both levels are now shuffled
every play. Seven headless suites pass. All merged to `master` and pushed;
`master` is at `4436c55`.

### What was done, in order

- **Content first.** `content/level_2_monitoring.tres` rewritten to the Figma:
  its five prompts, three options per situation rather than six, and the
  approved distractors. Fun facts taken out of Levels 2-4, since only Level 1
  has a strip — `verify_content` now requires them for Level 1 and forbids them
  elsewhere, and the voice-over script stopped writing empty rows.
- **Prompts became live text.** One blank bubble, `ui_prompt_bubble.png`, with
  the words laid over it as `PromptBubble`. `prompt_transcript` is the one
  transcript that is rendered, so a prompt change never means re-rendering art.
- **Headers became live text too**, on the blank sign: `HeaderSign` with a
  plaque (`header_label_transcript`) and a banner (`header_title_transcript`),
  both new fields on `ChallengeData`. `tools/verify_live_text.gd` lays every
  wording in the game into both components and fails if a line would clip.
- **The blank tray.** `OptionCard.draw_at_rest` and `StageScreen.blank_tray`:
  where a tray has empty slots, a resting card draws itself; on a drawn tray it
  draws nothing, because the picture already has the item.
- **Level 2's own music track**, appended to the `Track` enum — appended, since
  scenes store the track as a number.
- **The stage select learned to take any number of rows.** `row_rects`,
  `close_rect`, `row_art` and `row_art_locked` now come from the scene, so
  `stage_select_l2.tscn` could have five. A row opens only when it has been
  reached *and* its stage scene exists.
- **The completed-level sign and the grown hub**, then **the hub leading on to
  Level 2**: the play button names the level the plant is waiting on.
- **Level 2's five situations**, Situation 1 first as the pattern, then 2-5
  copying its numbers. Chained 1 → 2 → 3 → 4 → 5.
- **The multi-tap bug fixed** (below).
- **Cards shuffled every play** on any blank tray.
- **Level 1 moved onto the blank tray**, all four stages re-anchored, so it
  shuffles too. Its four drawn trays were deleted afterwards.
- **Level 2's ending**: Situation 5 → Level 2 Complete → Plant Helper → Green
  Thumb → "You Completed Level 2!" → hub, where the plant is the new
  `plant_leafy.png`, labelled SPROUT, and the button offers Level 3.

### Decisions taken

- **Three options per situation**, with the owner's distractor table: S1 Shovel
  / Watering Can / Sunlight · S2 Pruning Shears / Shovel / Water · S3 Watering
  Can / Shovel / Fertilizer · S4 Sunlight / Water / Fertilizer · S5 Fertilizer /
  Pruning Shears / Sunlight.
- **All five Level 2 headers are the blank sign**, for consistency, even though
  the Figma drew S1's.
- **The Figma's wording wins** wherever it disagrees with the content file.
- **The blank tray is used for Level 1 as well**, overriding the earlier plan to
  keep its drawn trays.
- **The score counter is skipped for now**, and the "Click Me" hub beat is
  skipped entirely — Grow Now goes straight to the grown hub.
- **Level 2 gives two badges**, Plant Helper then Green Thumb.
- **The plant after Level 2 is called SPROUT**; the hub then says "Level 3:
  Identifying" and opens the new intro card, whose Continue returns to the hub
  until Level 3's stages exist.

### The multi-tap bug, and why the first test passed

Tapping a card is a tiny drag that lets go on the card, so the card slides home.
A second tap **during** that slide made the card take its half-way point as
home; the two slides then raced and it came to rest ~1300 px away, off screen,
where it could never be tapped again. `OptionCard` now keeps the return tween,
and a tap during a slide finishes that slide first — the home can no longer be
overwritten.

The first version of the test tapped five times and **passed before the fix**,
because an odd number of taps happened to re-home the card. A sweep showed every
double-tap breaks it. The test now does two and three taps at three speeds: five
of those six cases failed before the fix, all six pass after, and a 30-pattern
sweep across both levels ends 0 px from the slot.

### Things that turned out to be true, and cost time

- **A shuffle test has to read the slots before `_ready()`.** `cards()` goes
  through an `@onready` reference, so an un-added scene returns nothing; the
  authored slots are read off the `%Cards` node directly.
- **The Level 2 sign's Grow Now is not Level 1's pill.** They look identical and
  sit at the same x, but differ by ~10/255 on average, so the sign got its own
  pill cut from itself with Level 1's stadium mask. Checked by compositing the
  darkened pill back over the sign: no ring of the painted one shows.
- **Godot rewrites `config/icon` in `project.godot` to a `uid://`** when the
  editor imports. It is not a change worth keeping in a diff — reverted.
- **`2 ObjectDB instances were leaked at exit` is a flake**, not a regression.
  It appears on `--quit` only when the menu music has started first, and two
  worktrees at earlier commits show it on some runs and not others. It travels
  with the `1 resources still in use` line `CLAUDE.md` already says to ignore.

### Still in progress

- **Level 3 has nothing but its intro card.** No stage select card, no stages,
  no content wired to a scene. `level_intro_l3.tscn` returns to the hub.
- **Two transcripts were corrected to new artwork** and need the teaching-content
  owner's eye: Level 2's completion line, and Level 3's instruction, which now
  describes the level as reading *clues*. They join the seven prompts already
  flagged in `checklist.md` §4.
- **Level 2 has no score counter**, which the design document specifies as 0/5.
- `level_select_stub.tscn` is reached by nothing; only the smoke and audio tests
  still load it.
- Level 2's intro art says "Tap", but Level 2 is played by dragging.

### Next step

Level 3: it needs a drawn stage select card with its rows, five stage scenes,
and a decision on whether its headers are live text like Level 2's or drawn like
Level 1's. Level 3 is multiple choice with no tray, so the card layout is not a
copy of Level 2's — worth agreeing the shape of one stage before building five.

---

## 2026-09-18 — DESIGN.md, and the stage select keeps its drawn card

**Where it got to:** the locked decisions are written down, and the stage select
question from the last session is answered — the blank cards are gone, and
neither the rows nor the feedback buttons bounce where they cover other art. All five headless suites pass. On a branch,
`docs/design-decisions`, not pushed.

### What was done, in order

- **`DESIGN.md`** — the one-page record of locked decisions: resolution and
  orientation, the empty Android permission list and the single local progress
  file, the star and unlock rules, English-only with the artwork carrying the
  words, and Figma-over-PDF. Every number taken from `project.godot`,
  `export_presets.cfg` and `default_bus_layout.tres` rather than from prose. It
  opens by saying what it is *not*, so it does not drift into a second
  checklist.
- **The stale gradle note fixed.** The checklist claimed `min_sdk` and
  `target_sdk` were inert until `gradle_build/use_gradle_build` was switched on.
  It is on, and `android/build/` holds the Gradle project at `4.7.2.stable`, so
  the item was already done. Replaced with the part that actually catches
  people: `/android/` is gitignored, so a fresh clone must reinstall the
  template before a gradle export runs.
- **`ui_stage_select_bg_l1..l4.png` deleted.** They were never referenced by a
  scene, only by docs.
- **Stage select rows no longer bounce.** `ArtButton` gained
  `bounce_art: bool = true`, and the four row hotspots set it `false`. The 0.82
  darken still fires.
- **The `.import` churn is gone.** `core.autocrlf=true` meant every text file
  without a `.gitattributes` rule was one git wanted to convert on touch, and
  only `.gd`, `.tres` and `.tscn` were pinned. Replaced the three rules with a
  catch-all, `* text=auto eol=lf`, so `.import`, `.uid`, `.md`, `.py`, `.cfg`
  and `project.godot` are all covered, and marked `.ttf` `-text` since it is a
  binary that is not in LFS. One `git add --renormalize .` cleared the stale
  index entries.
- **The smoke test now asserts the new behaviour** rather than losing the
  coverage: all four rows opt out, their art does not squash, it darkens on
  press and lifts on release. 12 assertions replacing the 4 that encoded the
  bounce.
- **How To Play's X and LET'S GO** were the last two, and the card really does
  have a full LET'S GO button and an X disc painted into it — checked by
  cropping `ui_how_to_play.png` at both rects rather than trusting the comment
  that said so. Composited at 0.93 the painted button rings the shrunken one as
  a visible double outline. Both set `bounce_art = false` in the scene.
- **The three `CardOverlay` screens needed no change.** Their `button_rect`
  starts at y ≈ 1.04, outside the card, so the Continue sits over the dim with
  nothing painted behind it and should bounce — which it already did. The smoke
  test now asserts that, so the distinction is pinned from both sides.
- **The feedback cards followed**, once the rows showed what the problem was.
  Continue and Choose Again are laid exactly over buttons painted into the
  cards, so they had it too. `StageScreen._show_feedback` now **derives**
  `bounce_art` from the art rect rather than taking a per-stage export: a rect
  that falls on the card covers a painted button and does not bounce, one below
  the card has nothing behind it and does. Stage 4's borrowed Level 2 card,
  whose Continue is drawn below it, keeps its bounce and is the case that made
  deriving it worth it. `verify_level_1` checks all eight buttons across the
  four stages — 40 assertions.

### Decisions taken

| Decision | Who |
|---|---|
| Keep `ui_stage_select_l1.png`, the card with rows drawn in; delete the blank `_bg_l1..l4` cards | owner |
| Stage select rows darken on press but do not scale | owner |
| The feedback cards' Continue / Choose Again do the same | owner |
| Levels 3 and 4 need a *drawn* card each, rows included, not a blank one | follows from the above |
| A button's bounce is derived from whether its art covers anything, not set per stage | Claude, since Stage 4 differs from the other three |
| How To Play's two buttons darken without squashing; the overlay cards' Continue keeps its squash | owner |

### Why the blank cards had to go

Measured rather than eyeballed: `ui_stage_select_bg_l1.png` is **377 × 732**
against the **1633 × 2456** card it would have replaced, for the same ~960 px
slot — a quarter of the resolution. Wiring it in meant a visibly softer card
*and* re-measuring every row and star rect, then re-measuring them again after a
higher-resolution re-export. The drawn card is already sharp and already
measured.

### The churn was never line endings

Worth recording, because the diagnosis sitting in the last session's
housekeeping was wrong and cost a detour. The 117 files reported as modified
were **byte-identical to `HEAD`** — `git diff` printed nothing for any of them,
and the files on disk were already pure LF, exactly as Godot had written them.

What was stale was the index's **stat cache**. Because `core.autocrlf=true` and
no attribute pinned these paths, git treated them as files it might have to
convert, so it kept marking their cached stat data as untrustworthy and
reporting them as modified. `git update-index --refresh` would not clear it — it
reports `needs update` and refuses. `git add --renormalize .` did, and staged no
content, which is the proof there was none to stage.

So the `.gitattributes` line is the real fix and the renormalize is the one-time
cleanup. Verified by deleting `.godot/imported` and running `--import` to
regenerate all 254 assets: Godot rewrote every `.import` file and `git status`
stayed empty.

### Why deriving the bounce beat exporting it

Three of Level 1's four stages put Continue on the card; Stage 4 puts it below,
because its card is borrowed from Level 2 and has no Continue painted on it. A
`bounce_art` export on `StageScreen` would have meant setting it by hand on all
nineteen stages and getting it wrong on the one that differs. The rect already
says which case a stage is — `WHOLE_CARD.intersects(art_rect)` — so the
behaviour follows from the measurement that was already there.

The bounce and the card turn out to be the same problem. The row art is laid
*exactly over* the row painted into the card, so `PressBounce` squashing it to
0.93 uncovers the painted row around its edges — the press reads as the card
showing through rather than as a button moving. Any card with rows drawn into it
has this, which is why the opt-out lives on `ArtButton` rather than being a
tweak to `PressBounce`.

### Still in progress

- **Levels 3 and 4 have no stage select card**, and now no blank fallback. Level
  2 has `ui_situation_select_l2.png`.
- Nothing outstanding on the bounce. Every `ArtButton` in the project was
  enumerated and accounted for; see the table in `CLAUDE.md`.
- `core.autocrlf` is still `true` in the local git config. The `.gitattributes`
  rules override it for this repo, so it does not need changing — but it is why
  a repo without those rules will do the same thing on this machine.
- The `[ ]` items from the last session are untouched: locked rows still
  composited grey, Level 2 headers for Situations 2-5, and
  `tools/export_vo_script.gd` still writing to `res://audio/vo/en/`.

### Next step

`tools/export_vo_script.gd` writes to `res://audio/vo/en/`, which has not
existed since the `assets/` move — small and currently broken. After that, the
prompt bubble with live text in Level 1's stages.

---

## 2026-09-17 — Asset folders, Level 2 art, stage select art and the font

**Where it got to:** the art is sorted into category folders, the Level 2 and
hub art from the `Know To Grow Assets` export is in the repo, Level 1's stage
select shows the newly drawn coloured rows, and every screen uses Fredoka One.
Nothing new is wired into gameplay yet. Merged to `master` and pushed. All five
headless suites pass, and a real render of stage select with every star filled
confirmed the stars line up.

### What was done, in order

- **Art sorted into folders** — the 89 loose PNGs in `assets/art/` now live in
  `backgrounds/`, `branding/`, `characters/`, `effects/`, `plants/`, `items/`,
  `ui/{buttons,common,hub,screens,stage_select}/` and `levels/level_N/`.
  Filenames and texture IDs unchanged; every scene, the theme and the row tool
  were repointed. The layout is in `CLAUDE.md` and `assets/art/MANIFEST.md`.
- **27 new images imported** from the export's 40, under proper names: Level 2
  headers, Correct cards, backgrounds and situation select card and rows;
  Fertilizer, Water and Pruning Shears cards; Level 2 intro and complete,
  the Plant Helper badge, the "You Completed Level 1" sign, Click Me and Grow
  Now buttons, and the hub's sprout. **13 were duplicates** of art already here
  and were skipped.
- **Situations mapped from the delivered file names.** Situation 2's background
  is the existing `bg_bed_sprout.png` and Situation 4's Correct card is the
  existing `ui_correct_l1_s4.png`; both are reused, not copied.
- **Stage select cards** — the four blank "Level N" cards are
  `ui_stage_select_bg_l1..l4.png`.
- **Drawn Level 1 rows** replace the composited unlocked ones. Their drawn
  filled stars are covered with the empty star in the image, and the scene's
  star slots were moved onto them. `build_stage_rows.py` now writes only the
  locked rows.
- **Fredoka One** in `assets/fonts/fredoka_one/`, set as the theme's default
  font. The owner then removed the old system-font overrides from the main menu
  and hub in the editor so the font shows there too.
- **`CLAUDE.md`** now records the asset layout and three new rules: prompts are
  live text on one shared bubble, Fredoka One is the only typeface, and how
  stage select rows and stars work.

### Decisions taken

| Decision | Who |
|---|---|
| Every prompt, Levels 1-4, is live text on `ui_prompt_bubble.png` | owner |
| Art that already has its words drawn in is kept, not rebuilt as text | owner |
| Fredoka One for all text | owner |
| `ui_stage_select_bg_l1..l4` are the stage select backgrounds | owner |
| Drawn rows' stars are covered with the empty star | owner |
| `prompt_transcript` is the one transcript that gets rendered | Claude, following from the above |
| Duplicates are reused by their existing name, never copied | Claude |

### Still in progress

- **Stage select still uses the old Level 1 card**, the one with its rows drawn
  in. The new blank cards are imported, not wired.
- **Locked rows don't match the drawn unlocked ones** — grey composites against
  orange, blue and yellow art.
- **Level 1's four drawn prompts**: the rule keeps them, but "all prompts,
  Levels 1-4" could mean they move to the bubble too. Needs the owner's answer.
- **The new level cards are ~377 px wide** for a ~960 px slot and will look
  soft. A larger export is needed.
- **Level 2 has no headers for Situations 2-5.**
- `tools/export_vo_script.gd` and the doc comment in `option_data.gd` still
  point at `res://audio/vo/en/`, not `res://assets/audio/vo/en/`. Running the
  export now writes to a folder that doesn't exist.

### Next step

> **Superseded 2026-09-18 — do not do this.** The blank cards were deleted and
> the drawn `ui_stage_select_l1.png` was kept. See the entry above.

Wire the new stage select card: put `ui_stage_select_bg_l1.png` behind Level 1's
rows in `stage_select.tscn`, choose the row rects fresh (the card has no rows
baked in), and re-measure the star slots in a real render. After that, the
prompt bubble with live text in Level 1's stages, once the owner confirms
whether the drawn prompts go.

---

## 2026-09-16/17 — The level loop closes, with progress and sound

**Where it got to:** a full run of Level 1 now goes hub → level overlay → stage
select → Stages 1-4 → Level Complete → Badge Unlocked → hub, with progress saved
between launches and music and effects throughout. Everything is merged to
`master` and pushed. Five headless suites pass, and the owner has been
playing each build on a phone as it lands.

### What was built, in order

- **Button art** — the X and LET'S GO on How To Play, and Continue / Choose
  Again on the feedback cards, laid *over* the plain buttons already painted
  into those cards. Every rect found by aligning the new button's body to the
  painted one.
- **How To Play's two failing hotspots fixed** — anchored to the button art and
  grown to 160 px in code. The padding helpers moved up into `SubScreen`.
- **Press feedback** — `ArtButton` tints the art under an invisible hotspot:
  0.82 held (the value `PrimaryButton` uses), 1.08 on hover.
- **Stage 4 gets a Continue**, drawn below its borrowed Level 2 card. Its tap
  target is now that button rather than the whole card.
- **Audio tracked through LFS** — `*.mp3` was missing from `.gitattributes`.
  Music renamed `main_menu.mp3` and `level_1..5.mp3`.
- **Four level-flow screens**, each on its own branch: `level_intro`,
  `stage_select`, `level_complete`, `badge_unlocked`. Three are `CardOverlay`
  — card, optional banner above, button below, all placed in fractions of the
  card. Stage 4 now ends on Level Complete, not the hub. `bg_bed_sprout.png`
  is finally used, behind the two closing cards.
- **`GameState`** — one number per stage (stars 1-3, 0 = never finished) in
  `user://progress.cfg`. Unlocking, level completion and the hub's star count
  all derive from it.
- **Stage select rows go live** — rows open as stages clear, stars fill with
  what was earned, and each row is drawn in the state it has reached.
- **Eight stage rows** — four were drawn; four are *composited* by
  `tools/build_stage_rows.py` from the drawn ones (plate and label recoloured
  separately, by luminance rank).
- **`AudioDirector`** — `main_menu.mp3` outside a level, `level_1.mp3` inside
  it, continuous across scene changes. Tap on every button (on `button_down`),
  correct and wrong on an answer, the level-complete sting on that card.

### Decisions taken

| Decision | Who |
|---|---|
| Sequence: hub → level overlay → stage select → stages → level complete → badge → "you completed" → hub with Click Me → hub, plant grown | owner |
| Badges are fixed per level; Level 1 always unlocks Little Planter | owner |
| Stars by attempts: 3 first try, 2 second, 1 after | owner |
| Play always opens the stage select, rather than resuming or restarting | owner |
| Continue sits below a card that has none drawn on it | owner |
| Merge each piece to `master` and push | owner |
| Stars are never taken away; a replay can only raise them | Claude, in `GameState` |
| Music renamed to `snake_case` rather than "Main menu" | Claude, per `CLAUDE.md` |

Two `project.godot` changes — the `GameState` and `AudioDirector` autoloads —
were made on the strength of the request itself. `CLAUDE.md` normally wants
those checked first.

### Things that turned out to be true, and cost time

- **A `godot -s` tool script is compiled before autoloads are registered.**
  `GameState` as a bare identifier does not compile in one, so
  `stage_screen.gd` quietly stopped compiling under `verify_level_1` while the
  game itself was fine — **and the suite still printed PASS**. Autoloads are
  now reached through `SubScreen.progress` / `SubScreen.audio`, typed by
  `GameStateStore` / `AudioDirectorService`. Written into `CLAUDE.md`.
- **A typed node export can't be hand-written into a `.tscn`.** The editor
  stores it as a NodePath only it resolves; typed by hand it is silently null.
  `ArtButton.art_path` is a plain `NodePath` for that reason.
- **Godot re-saves hand-written scenes with `unique_id=` on each node**, so a
  script searching for an exact `[node ...]` header stops matching. Search on
  the prefix.
- **Every music track imported with `loop=false`.** All six now loop.
- **Once music has played, `--quit` reports `1 resources still in use at
  exit`.** It is the audio server's playback outliving the tree; nothing in
  GDScript clears it, and a run with no music exits clean. Ignore that line.
- **The delivered loose stage-select parts don't match the composed card** —
  the "Stage N" pill is ratio 5.17 against the card's 3.12, and no row plate
  was delivered. Only the stars (1.05 against 1.06) fit.
- **Hanging the tap on `pressed` broke eleven smoke-test assertions**
  ("connected to exactly one action"). `button_down` fixes that and feels
  better under the thumb.
- **`ConfigFile.get_section_keys()` errors on a missing section**, which is
  exactly what `reset()` leaves behind.

### Corrections to this session's own work

- A Python `str.replace` that matched nothing still printed success, so Stage 4
  briefly had no `done_scene_path`. Caught by reading the file back; patches
  since then assert their anchor exists.
- Two files cut as "row plates" were really the blank *label* pill, and are
  renamed `ui_stage_label_plate*.png`.
- The first composited rows had grey rectangles under the icon and stars, and a
  label that vanished into its plate. Both found by looking at the output.

---

## 2026-09-15/16 — Level 1 built end to end

**Where it got to:** the whole of Level 1 plays. Menu → hub → Stage 1 → 2 → 3 →
4 → back to the hub. Verified headless, not yet on a phone.

### What was built

- **Hub screen** (`scenes/ui/hub.tscn`) — the screen between the menu and a
  level. Greeting, star count, the plant's stage on a sign, and the play button.
  Star count and plant stage are Inspector placeholders; there is no `GameState`
  to persist them. The three bottom tabs (Lessons / Garden / Badges) are drawn
  but `disabled`, because they have nowhere to go.
- **Level 1, all four stages** — Dig the Hole, Drop the Seed, Water the Soil,
  Give Sunlight. Drag an item onto the soil; right or wrong; feedback card;
  Continue. No wording was written by hand anywhere: every word on screen is
  drawn into the artwork, straight from `Untitled.fig`.
- **`StageScreen`** (`scripts/levels/stage_screen.gd`) — the shared drag,
  feedback card, hotspot sizing and wrong-card rule that every stage extends.
- **`tools/verify_level_1.gd`** — walks the stage chain and plays each stage
  headlessly: a drop away from the target, a wrong answer, a right answer.

### Decisions taken (and who took them)

| Decision | Who |
|---|---|
| Hub sits between menu and level; its button names the level rather than repeating "Start Game" | owner |
| Options are separate draggable cards, tap-then-drag, per the design document | owner |
| The Figma prototype outranks `Know To Grow.pdf` when they disagree | owner |
| "Seed", not "Seed Packet" | follows from the above |
| Stage 4 reuses Level 2's "Correct Answer! / Sunlight" card | owner |
| Stage scenes are hand-owned, one folder per level | owner |
| A stage's garden never changes while the stage is on screen | owner |

### Things that turned out to be true about the artwork

These cost time to discover and are worth not rediscovering:

- **The garden backgrounds are independent drawings, not one scene in five
  states.** Diffing `bg_bed_empty` against `bg_bed_hole` lights up the entire
  frame — every cloud, tree and fence post moves, and they are different pixel
  sizes. They can never be cross-faded or swapped mid-stage. This is why the
  garden now only changes at a stage boundary.
- **The item cards carry thicker frames than the slots drawn into the tray, by
  different amounts per art family.** No scaling aligns them all. Hence a
  resting card draws nothing and the tray's own art shows through; the card
  appears only while dragged, and a tried option tints its slot instead.
- **Only three Level 1 "Correct Answer!" cards exist** — shovel, seed, watering
  can. There is none for Sun, and Level 2's cards carry no Continue button.
- **Two stages' wording differs between the artwork and the PDF** (Stage 2's
  prompt, Stage 4's fun-fact comma). Both transcripts were corrected to the art.
  Expect more; keep the list for the teaching-content owner.

### Corrections made to earlier work

- `OptionCard.return_home()` was leaving `top_level` without restoring the local
  position, so a returning card landed a screen-height below its row and looked
  deleted.
- The hub's `_ready()` aborted partway when a label was removed in the editor,
  which left the play button unconnected and the screen with no exit.
- Feedback hotspots are now padded to 160 px **in code** rather than by
  hand-tuned offsets, which is how How To Play's silently fell under the floor.

---

## Still in progress / next steps

Ordered by what unblocks the most.

1. **Act on what the phone shows.** The owner is testing each build on a
   device as it lands, which is the only check that covers what headless
   cannot — whether a drag feels right, whether a small thumb can hit a stage
   row, how the music sits against the effects. Anything reported from there
   goes ahead of the items below. Not yet covered: a cheap second device.
2. **The last three beats of the loop** — "You completed Level N", then the hub
   with "Click Me" on the plant, then the hub with the plant grown. No art has
   been delivered for any of them. `GameState.is_level_cleared()` already
   answers the question the hub will need to ask.
3. **Level 4.** Levels 2 and 3 are built. Level 4 is tapped like Level 3, so
   `tap_to_answer` and Level 3's layout carry over; it needs its own `Track`
   (`level_4.mp3` is in the repo), the hub's fourth plant and
   `level_intro_l4.tscn`.
4. **Three missing effects** — pickup and drop on a dragged card, and a bounce
   when one returns home. Nothing delivered for them.

## Open questions for the project owner

- **Music licence.** The tracks arrived named after another game's soundtrack
  and are on GitHub under neutral names, which hides where they came from
  without changing it. Settle before release.
- **Stars by attempts against "no penalties".** The design document says
  Level 1 has no penalties and no "Wrong" label; a grade that drops with
  attempts sits against that. Chosen deliberately — the teaching-content owner
  should still see it.
- **Four composited stage rows** are slightly paler than the drawn Stage 1.
  Swapping in drawn art is a file swap, no code.
- The Oops card says *"That's not the right tool."* — Stage 2's wrong answers
  are a rock and a leaf. One card is shared by all four stages.
- Stage 4's Correct card is Level 2's, in a different style from the other
  three.
- The Correct cards carry an explanation paragraph that exists nowhere in
  `content/*.tres`. That would be a `correct_transcript` field.

## Housekeeping

- ~~**`.import` and `.uid` files churn on every reimport**~~ **Fixed
  2026-09-18.** `.gitattributes` now pins `* text=auto eol=lf`. The diagnosis
  in this entry was half right: the files really were unpinned, but nothing
  about them had ever changed — not even the line endings. See the entry at the
  top.
- `CLAUDE.md`'s project layout still says `art/` and `audio/`; both have lived
  under `assets/` since `66c2429`.
- `README.md` still describes the original starter kit.

## Verification state at the end of this session

| Check | Result |
|---|---|
| Project loads | clean, apart from the known audio line |
| `verify_game_state.gd` | PASS — star rule, unlocking, reload |
| `verify_audio.gd` | PASS — tracks, loops, buses, every effect's use |
| `verify_level_1.gd` | PASS — and asserts a played stage was recorded |
| `verify_menu_flow.gd` | PASS — incl. rows unlocking, drawn state, stars |
| `verify_content.gd` | PASS — 19 challenges, 76 voice-over lines |

`verify_game_state`, `verify_audio`, `verify_level_1` and `verify_menu_flow`
all write to `user://progress.cfg` and reset it afterwards.
