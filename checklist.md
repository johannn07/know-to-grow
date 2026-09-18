# Know To Grow — build checklist

> `SESSION_NOTES.md` carries the narrative — what was decided, what the artwork
> turned out to be like, and what to pick up next. This file is the build state.

Everything between here and a finished game. Ordered so that each section
unblocks the next; inside a section, order is a suggestion.

Legend: `[x]` done · `[ ]` to do · **⚠** needs a decision from the project owner
before it can be started.

---

## 0 · Foundations

- [x] Godot 4 project created, Mobile renderer, portrait locked
- [x] 1080 × 1920 design resolution, `canvas_items` + `expand` stretch
- [x] Audio buses `Music` / `SFX` / `VO` defined in `default_bus_layout.tres`
- [x] `.gitignore` / `.gitattributes` at repo root
- [x] `.godot/` untracked (it was committed before the ignore file existed)
- [x] `CLAUDE.md` — working instructions
- [x] `art/MANIFEST.md` — asset contract
- [x] Android export preset: package name, arm64-v8a, `min_sdk` 24,
      `target_sdk` 34, version name `0.1.0`
- [x] Git LFS active — `git-lfs` is installed and `filter.lfs.process` is
      configured, and `.gitattributes` routes `*.png/jpg/webp/ogg/wav/ogv`
      through it. PNGs can land safely
- [x] `DESIGN.md` — the one-page record of locked decisions (orientation,
      resolution, save location, no analytics, no accounts) so settled questions
      stay settled

## 1 · Main menu — current work

- [x] `ArtSlot` component — labelled colour block until a texture is assigned
- [x] `themes/ktg_theme.tres` — primary/secondary buttons, labels, 160 px targets
- [x] `main_menu.tscn` rebuilt: sky / hills / ground / logo / two mascots, falling
      leaves, Start Game + How To Play
- [x] `how_to_play.tscn` — per-level instructions from the design document
- [x] `level_select_stub.tscn` — placeholder Start Game destination
- [x] Android back gesture handled on all three screens
- [x] `tools/verify_menu_flow.gd` — headless smoke test, 18 checks, all passing
- [x] All three screens load, run and render correctly under Godot 4.7.2
- [ ] Open in the editor and click through it (F5) — the headless checks confirm
      the wiring and the rendering, not that it *feels* right
- [x] Check it on a real phone, not just the editor. Thumb reach, not mouse reach.
      The owner tests each build on a phone as it lands
- [x] Real art wired in from the Figma file — background, logo, both mascots,
      ground, falling leaves, and the green button plate as a 9-patch
- [x] Button press sound — every button, on `button_down`, via `AudioDirector`
- [x] A small scale-bounce on tap — `PressBounce`: squash to 0.93, spring back
      with an overshoot. A themed button bounces itself; a hotspot bounces the
      art under it. **Art laid over art does not bounce**, because shrinking it
      uncovers the picture underneath: the stage select rows, How To Play's X
      and LET'S GO, and Continue / Choose Again where they sit on a feedback
      card's painted button. All keep the 0.82 darken. Anything with nothing
      behind it still bounces — Stage 4's Continue below its card, the three
      overlay cards' Continue over the dim, and the themed menu buttons.
      `StageScreen` derives the feedback case from the art rect; the rest is set
      in the scene. Every `ArtButton` in the project is accounted for
- [x] Menu music loop — `main_menu.mp3`, continuous across the title, How To
      Play and the hub

## 2 · Core gameplay

The four levels are one mechanic in four costumes: show a prompt, the learner
picks one of N options, it is right or it is wrong. Build that once.

- [x] **Data scripts restored** — `scripts/data/level_data.gd`,
      `challenge_data.gd`, `option_data.gd`, recreated at the UIDs the content
      files already referenced. Only `level_1` had actually inlined the schema;
      levels 2-4 still pointed at the missing paths, so they reconnected cleanly
- [x] **Content restructured to the transcript model** — text fields renamed to
      `*_transcript` and never rendered; the artwork carries the words. Every
      spoken line has a `*_vo_key`
- [x] `tools/verify_content.gd` — validates all 19 challenges: correct answers
      exist among their options, transcripts present, voice-over keys unique
- [x] `tools/export_vo_script.gd` — generates `audio/vo/en/SCRIPT.md`, the
      76-line recording script, from the transcripts
- [x] `OptionCard` component — draggable, uses `ArtSlot` for its icon, slides
      home on a rejected drop
- [x] `StageScreen` base class — the drag, the feedback card, the 160 px hotspot
      sizing and the wrong-card rule, shared by every stage script
- [x] **Stages are hand-built scenes** — `scenes/levels/level_N/stage_M.tscn`
      with a matching script, so a stage can be rearranged in the editor. The
      generic data-driven `ChallengeScreen` was removed in favour of this
- [x] **Level 1 Stages 1-4 playable — the whole level** — drag an item onto the soil, the garden
      changes state, feedback cards appear, Continue carries the garden into the
      next stage, and the bed runs empty -> hole -> seed -> watered -> sprout.
      `tools/verify_level_1.gd` walks the whole chain headlessly
- [ ] `DropZone` component — currently a plain `Control` rect on the screen.
      Promote it to a component with `zone_id` and hover highlight when a stage
      needs more than one zone (Level 4 does)
- [x] Correct answer: garden advances a state, "Correct Answer!" card with its
      Continue button
- [x] Fun fact strip at the bottom of every stage, visible while the child is
      deciding rather than after the answer
- [x] Tool tray behind the cards, with each card anchored over the slot drawn
      into the tray art
- [ ] Correct answer polish: sparkle and ding
- [x] Wrong answer: card slides back, "Oops!" card with Choose Again, no penalty
      and no "Wrong" label
- [ ] Wrong answer polish: the item's own `wrong_hint`, arrow nudge
- [x] ~~Level 1 Stage 4 blocked on art~~ **Answered: reuse Level 2's card.**
      Stage 4 uses the "Correct Answer! / Sunlight" card from Level 2, which
      looks different from the other three and has no Continue drawn on it, so
      one is drawn just below the card and that button is the tap target
- [ ] **A Level 1 "Correct Answer! / Sun" card, if the mismatch matters.**
      Swapping it in is one texture, plus setting Stage 4's `correct_art_rect`
      and `correct_button_rect` back to the on-card Continue rects
- [ ] **Level 1 ends on a different-looking garden.** `bg_bed_sprout.png` is a
      close-up behind a white fence, not the raised bed the other four use — the
      `.fig` has no sprout in that framing. **⚠**
- [x] Level 1 completion beat — Stage 4 now leads to the Level Complete and
      Badge Unlocked overlays (§3). `bg_bed_sprout.png`, the payoff of the
      level, is the background behind both
- [ ] Option shuffling for **Level 3 only** — its scripted answers sit at
      B, A, C, A, B and children memorise positions faster than content. Levels
      1, 2 and 4 use drawn trays, so a card's position is fixed by the picture
      behind it and cannot be shuffled
- [ ] Level 1 stays in fixed order (`shuffle_challenges = false`) — planting is a
      real-world sequence
- [ ] Progress indicator — the design document specifies `Score: 0/5` for Level 2;
      it only ever goes up
- [ ] **Stars are scored by attempts, which the design document does not ask
      for.** Three for right first time, two on the second, one after that —
      decided by the project owner. The document says Level 1 has no penalties
      and no "Wrong" label, and a grade that falls with attempts sits against
      that, so whoever owns the teaching content should see it. Stars are never
      taken away once earned, and replaying can only improve them. **⚠**
- [ ] Level completion beat: message, final fun fact, continue button
- [ ] Play all 19 stages as grey boxes before any art exists

## 3 · Screen flow

### The sequence a level runs through — decided

Confirmed by the project owner, and the order everything below is built to:

```
Hub → Level overlay → Stage select → Stages 1-4 → Level Complete overlay
    → Badge Unlocked overlay → "You completed Level N" overlay
    → Hub, "Click Me" on the plant → Hub, plant grown
```

The game now runs this sequence as far as Badge Unlocked, then returns to the
hub. The three beats after that — "You completed Level N" and the two hub
states — are still to build.

**Badges are fixed per level, not earned by performance.** Level 1 always
unlocks **Little Planter**.

- [x] **Level overlay** — the card that names the level before it starts.
      `Level 1 / "Ready to grow?"`, with Continue. Art delivered
- [x] **Stage select** — `Level 1 / Planting`, an X back to the hub, and a
      hotspot over each drawn row. Stage 1 live, the rest disabled to match the
      grey they are drawn in
- [x] Stage select rows read progress — a row opens when the stage before it is
      cleared, and its three stars fill with what was earned
- [x] Rows are drawn in the state they have reached — a cleared stage turns its
      plate green and colours its icon, not just its stars
- [ ] **Four of the eight rows are composited, not illustrated.** Only Stage 1
      unlocked and Stages 2-4 locked were ever drawn; the rest are built by
      `tools/build_stage_rows.py` by recolouring the drawn ones. They read as
      one set, but the composited greens are slightly paler than the drawn
      Stage 1. Replacing them with drawn art is a straight file swap — same
      names, same rects, no code change. **⚠** Worth a look before it ships
- [x] **Level Complete overlay** — `Level 1 Complete! / "Great job, little
      gardener!"` with three stars, after Stage 4. Art delivered
- [x] **Badge Unlocked overlay** — the `BADGE UNLOCK!` banner over the
      `Little Planter` badge, with Continue. Art delivered
- [ ] "You completed Level N" overlay — **not in this batch**, no art yet
- [ ] Hub with "Click Me" on the plant, then the plant grown — **not in this
      batch**, no art yet. Both need `GameState` to know the level is done

- [x] `GameState` autoload — one number per stage, the stars earned, saved to
      `user://progress.cfg`. Everything else is derived from it: whether a stage
      is unlocked, whether a level is done, what the hub counts. Checked by
      `tools/verify_game_state.gd`
- [x] ~~Decide whether Start Game resumes or always restarts~~ **Answered:
      neither.** Play always opens the stage select and the child picks. Resume
      falls out of it, since cleared rows stay unlocked
- [x] `AudioDirector` autoload — routes music and effects to the existing buses,
      and keeps a track playing across a scene change so walking hub → level
      overlay → stage select does not restart it. Checked by
      `tools/verify_audio.gd`. VO has a bus but nothing to route yet
- [ ] Real level select, replacing `level_select_stub.tscn` — or wire Start Game
      straight to Level 1 and drop the screen. **⚠**
- [ ] Level scenes: `level_1_planting`, `level_2_monitoring`,
      `level_3_identifying`, `level_4_functions`
- [ ] Video screens between Level 2 → 3 and Level 3 → 4. **⚠** Godot 4 plays
      **Ogg Theora only** — either commission `.ogv` files, or build the clips
      in-engine with `AnimationPlayer` and the hero plant art. In-engine is
      sharper, smaller, skippable and translatable, and reuses art already paid
      for. This decision blocks the animation brief
- [ ] Final completion screen — plant blooms and sparkles, "Fantastic! You know
      the parts of a plant and what each part does!"
- [ ] Sound toggle and exit, behind a press-and-hold or parent gate
- [ ] Resume after the app is backgrounded mid-level

## 4 · Content

The wording in `content/*.tres` already matches the design document. These are
the open content questions, not bugs.

- [x] ~~**Level 2 situation 3 has two valid answers**~~ **Resolved by the
      three-option cut.** The Figma gives each situation three slots, not six,
      so Water is simply not on screen in Situation 3 and Watering Can is the
      only answer. `alternate_correct_ids` is gone. No rewording needed
- [x] ~~**Level 1 stage 2 labels the item two ways**~~ **Answered: "Seed."** The
      item card is drawn `Seed`, so the transcript now says Seed and the
      voice-over line with it. The internal id stays `seed_packet`
- [x] ~~**The Level 1 Oops card says "That's not the right tool."**~~
      **Accepted.** One Oops card is reused for every level, wording and all.
      The tray's drawn "Choose a Tool" is accepted on the same grounds
- [ ] **Seven prompts differ between the design document and the artwork.**
      Level 1 Stage 2's bubble reads "What goes inside the hole to start growing
      our plant?", and **all five Level 2 prompts** were statements in the
      content file but questions in the Figma ("The soil is dry and the plant
      looks thirsty. What does it need?"). The artwork wins per the baked-text
      decision and every transcript now matches — but the teaching-content owner
      should see the whole list before voice-over is recorded. **⚠**
- [ ] **Level 1 has no completion celebration** in the design document while
      Level 4 does. Give every level the same reward beat
- [ ] Wrong-answer hints are written one per *item* (6 lines for Level 2), not
      one per item × situation (25 lines). Keep it that way
- [x] **Level 2 shows three options per situation, not six** — the Figma gives
      each situation three slots. The correct answer plus two distractors,
      approved by the owner: S1 Shovel / Watering Can / Sunlight · S2 Pruning
      Shears / Shovel / Water · S3 Watering Can / Shovel / Fertilizer · S4
      Sunlight / Water / Fertilizer · S5 Fertilizer / Pruning Shears / Sunlight.
      The Figma itself only ever showed Level 1 Stage 1's placeholder cards, so
      which three was never drawn
- [x] **Only Level 1 has fun facts.** Decided. The transcripts and voice-over
      keys are out of Levels 2-4, `verify_content` requires them for Level 1 and
      forbids them elsewhere, and the recording script drops from 76 lines to 58
- [ ] Content lock: walk all 19 stages on a phone with whoever owns the teaching
      content, then freeze the wording. Changes after voice-over is recorded mean
      re-recording
- [x] Filipino: **not shipping**. Decided. The artwork carries English text, so
      translating would mean re-rendering every banner — revisit only as a
      deliberate, costed project

## 5 · Audio

- [x] SFX ×4 wired — tap on every button, correct and wrong on an answer, and
      the level complete sting when that card arrives. The tap hangs off
      `button_down`, so it lands under the thumb rather than on release
- [ ] SFX still missing — pickup and drop on a dragged card, and a gentle bounce
      on a card that returns home. Nothing was delivered for those three
- [x] Music — `main_menu.mp3` across the title, How To Play and the hub;
      `level_1.mp3` across the level intro, stage select, all four stages and
      both closing cards. All six tracks had `loop=false` from the importer,
      which would have played each once and left the screen silent
- [ ] Music for levels 2-4 — the tracks are in the repo and named, but those
      levels do not exist yet. Add a `Track` per level as they are built
- [ ] **The music is third-party and its licence is unconfirmed.** The tracks
      arrived named after another game's soundtrack and are now on GitHub under
      neutral names, which hides the provenance without changing it. **⚠**
      Settle this before release
- [ ] Voice-over ≈63 lines per language (19 prompts + 19 fun facts + ~25 item
      names). **Record a scratch version on your phone this week** — a kids' game
      lives or dies on whether the prompt is spoken, and timing needs testing long
      before a studio session
- [ ] Tapping an item speaks its name (free vocabulary teaching, `vo_key` already
      exists in the data schema)
- [ ] Tap-to-hear-again button on every prompt — children look away mid-sentence

## 6 · Art integration

The artwork exists. `Untitled.fig` holds roughly **170 unique full-resolution
assets** — effectively the whole game. Inventory in `assets/art/MANIFEST.md`.

- [x] Main menu: 7 assets extracted, downscaled and wired
- [x] **Decided: the artwork keeps its text.** English only, no Filipino for
      now. `content/*.tres` holds transcripts, not display strings. Verified
      legible at 1080-wide design resolution
- [x] Art sorted into category folders under `assets/art/`
- [ ] 16 item icons (1254 × 1254 in the source) — 13 in the repo, incl. Fertilizer, Water, Pruning Shears
- [x] Stage backgrounds (852 × 1846) — Level 1 and all five Level 2 situations
- [x] **Import the blank header sign** and retire `ui_header_l2_s1.png`.
      Decided: all five situations use the blank sign with "Situation N" on the
      plaque and the title on the banner as live text, which is what the Figma
      already does for Situations 2-5 — S1 was the only one ever rendered. The
      blank is a real Figma export (`e54af65e…`, 1672 x 941), so it drops in
      cleanly. **The five titles are already in `content/level_2_monitoring.tres`**
- [ ] **Swap in the new empty tool tray** for Levels 1 and 2 — decided, deferred.
      It is a newly drawn asset rather than a Figma export, so its proportions
      differ from `ui_tray_l1_s1.png` (alpha ratio 2.0802 against 2.1008, and
      shifted down the canvas). Swapping it means **re-measuring the card
      anchors in all four Level 1 stage scenes**, so it is not a file swap.
      The card side is built: a stage sets `blank_tray` and its cards draw
      themselves at rest, while a wrong card leaves a darkened empty slot. So
      the swap is the texture, `blank_tray = true`, and the re-measured anchors.
      Levels 3 and 4 undecided
- [ ] Item cards for Level 2's six items at the tray's slot size — the three in
      the Figma are Level 1 Stage 1's placeholders, reused in all five situations
- [ ] Hero plant variants, including versions with roots exposed
- [x] ~~Stage select cards for Levels 1-4 imported (`ui_stage_select_bg_l1..l4`)~~
      **Removed.** At 377 x 732 for a ~960 px slot they were a quarter of the
      resolution of `ui_stage_select_l1.png`, the card with its rows already
      drawn in. Decided: keep the drawn card, drop the blanks
- [ ] A **drawn** stage select card for Levels 3 and 4, rows included, like
      Level 1's. Level 2's situation select is `ui_situation_select_l2.png`; the
      other two have nothing
- [x] Level 1 unlocked rows drawn, stars covered with the empty star
- [ ] Level 1 locked rows drawn to match — still composited grey
- [ ] Level 2 situation rows, locked and unlocked
- [ ] Feedback cards, completion badges, tool trays
- [x] Fredoka One in `assets/fonts/`, wired once in `themes/ktg_theme.tres`
- [ ] Prompts as live text on `ui_prompt_bubble.png`, Levels 1-4
- [x] Headers as live text on the blank sign, Level 2 — the `HeaderSign`
      component, with `HeaderLabel` (58 px, white outlined) on the plaque and
      `HeaderTitle` (51 px, dark brown) on the banner. Filled by `StageScreen`
      from the challenge's header transcripts. No stage uses it yet
- [x] ~~Fix `tools/export_vo_script.gd` to write under
      `res://assets/audio/vo/en/`~~ — done, along with the same stale path in
      `option_data.gd`'s doc comment
- [ ] Decide an import policy — sources are up to 4096 × 2896 and the raw `.fig`
      is 290 MB. Everything needs alpha-cropping and downscaling before it lands
      in the repo, or the APK will be enormous

## 7 · Android and release

- [ ] OpenJDK 17 + Android Studio SDK, paths set in Editor Settings
- [ ] Debug keystore, and a **release keystore backed up in two places** with the
      passwords written down somewhere that survives a year. Lose it and the app
      can never be updated under the same listing
- [x] Android Build Template installed — `android/build/` holds the Gradle
      project at `4.7.2.stable`, and `gradle_build/use_gradle_build=true` in
      `export_presets.cfg`, so `min_sdk` 24 / `target_sdk` 34 are live rather
      than inert. **`/android/` is gitignored**, so a fresh clone has to
      reinstall it from the editor (Project → Install Android Build Template)
      before a gradle export will run
- [ ] Launcher icons: 192×192 and the three 432×432 adaptive layers
- [ ] Splash screen art
- [x] **Export a debug APK to a real phone**, and keep doing it — the owner tests
      each build on a device as it lands. Touch targets that feel fine with a
      mouse are often too small for a six-year-old
- [ ] Test on two real devices: one cheap, one current
- [ ] Store listing, screenshots, privacy policy, and the Play Console
      "designed for families" declarations

## 8 · Polish and accessibility

- [ ] Every interactive control ≥ 160 px
- [ ] Colour never the only signal — shape and label always present
- [ ] No timers, no lives, no leaderboards
- [ ] Prompt repeatable on demand
- [ ] Legible on a 20:9 screen and on a 4:3 tablet — the extra room from
      `expand` must stay harmless at both ends
- [ ] Reduce-motion consideration for the particle and celebration effects
- [ ] Frame rate on the cheap test device

---

## Decisions still open

Collected from the **⚠** items above, because these block other people's work:

1. Videos as `.ogv`, or built in-engine? — blocks the animation brief
2. Does Start Game resume or restart? — blocks `GameState`
3. Real level select, or straight into Level 1? — blocks the screen flow
4. Level 2 situation 3: accept both answers, or reword it?
5. "Seed" or "Seed Packet"? — blocks the icon brief and the voice-over script
6. ~~Is Filipino shipping?~~ **Answered: no.** The artwork keeps its English
   text; `content/*.tres` holds transcripts and voice-over keys
7. Level 1's four drawn prompts: keep them, or move them to the blank bubble
   with live text like the other levels?
