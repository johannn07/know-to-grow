# Session notes

A running log of what changed and why, for picking work back up. `checklist.md`
is the build state; this is the narrative behind it. Newest session first.

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
3. **Levels 2, 3 and 4.** Stages, overlays, progress and audio all exist, so
   each is mostly art extraction and wiring: a `Track` per level in
   `AudioDirectorService` (the MP3s are in the repo) and a `level_id` on each
   stage scene. Level 3 is multiple choice with no tray.
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

- **`.import` and `.uid` files churn on every reimport** — git reports them
  modified with an empty diff, line endings only. `.gitattributes` sets
  `eol=lf` for `.gd`, `.tres` and `.tscn` but not those two. They were
  discarded by hand all session; one line in `.gitattributes` would end it.
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
