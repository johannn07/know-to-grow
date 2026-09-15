# Know To Grow — build checklist

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
- [ ] `DESIGN.md` — the one-page record of locked decisions (orientation,
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
- [ ] Check it on a real phone, not just the editor. Thumb reach, not mouse reach
- [x] Real art wired in from the Figma file — background, logo, both mascots,
      ground, falling leaves, and the green button plate as a 9-patch
- [ ] Button press sound and a small scale-bounce on tap
- [ ] Menu music loop

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
      looks different from the other three and carries no Continue button, so
      the whole card is tappable
- [ ] **A Level 1 "Correct Answer! / Sun" card, if the mismatch matters.**
      Swapping it in is one texture plus clearing `correct_button_rect`
- [ ] **Level 1 ends on a different-looking garden.** `bg_bed_sprout.png` is a
      close-up behind a white fence, not the raised bed the other four use — the
      `.fig` has no sprout in that framing. **⚠**
- [ ] Level 1 completion beat — [107] "Level 1 Complete!" and the [116] "Little
      Planter" badge are drawn and unused. Stage 4 currently returns to the hub.
      **`bg_bed_sprout.png` belongs here**: it is the payoff of the level and is
      no longer shown anywhere, now that stages keep one garden each
- [ ] Level 1 completion beat — [107] "Level 1 Complete!" and the [116] "Little
      Planter" badge are drawn and unused
- [ ] Option shuffling for **Level 3 only** — its scripted answers sit at
      B, A, C, A, B and children memorise positions faster than content. Levels
      1, 2 and 4 use drawn trays, so a card's position is fixed by the picture
      behind it and cannot be shuffled
- [ ] Level 1 stays in fixed order (`shuffle_challenges = false`) — planting is a
      real-world sequence
- [ ] Progress indicator — the design document specifies `Score: 0/5` for Level 2;
      it only ever goes up
- [ ] Level completion beat: message, final fun fact, continue button
- [ ] Play all 19 stages as grey boxes before any art exists

## 3 · Screen flow

- [ ] `GameState` autoload — current level, per-level completion, save to
      `user://`. Removed with the prototype; the menu currently does not read
      progress. **⚠** Decide whether Start Game resumes or always restarts
- [ ] `AudioDirector` autoload — routes SFX/VO/music to the existing buses
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

- [ ] **Level 2 situation 3 has two valid answers.** "The soil is dry and the
      plant needs a drink" is solved equally well by *Watering Can* and *Water*,
      and both are on screen. The prototype accepted both — either keep that or
      reword the situation. **⚠**
- [x] ~~**Level 1 stage 2 labels the item two ways**~~ **Answered: "Seed."** The
      item card is drawn `Seed`, so the transcript now says Seed and the
      voice-over line with it. The internal id stays `seed_packet`
- [ ] **The Level 1 Oops card says "That's not the right tool."** It is wired
      level-wide, but Stage 2's wrong answers are a rock and a leaf. Re-render
      it with wording that fits all four stages, or accept it. **⚠**
- [ ] **Two prompts differ between the design document and the artwork.** Stage 2
      is the one found so far: the bubble reads "What goes inside the hole to
      start growing our plant?" The artwork wins per the baked-text decision, and
      the transcript was updated to match — but the teaching-content owner should
      see the list before voice-over is recorded. **⚠**
- [ ] **Level 1 has no completion celebration** in the design document while
      Level 4 does. Give every level the same reward beat
- [ ] Wrong-answer hints are written one per *item* (6 lines for Level 2), not
      one per item × situation (25 lines). Keep it that way
- [ ] Content lock: walk all 19 stages on a phone with whoever owns the teaching
      content, then freeze the wording. Changes after voice-over is recorded mean
      re-recording
- [x] Filipino: **not shipping**. Decided. The artwork carries English text, so
      translating would mean re-rendering every banner — revisit only as a
      deliberate, costed project

## 5 · Audio

- [ ] SFX ×6 — correct ding, gentle bounce, pickup, drop, level complete, tap
- [ ] Music ×2 — calm garden loop, celebration sting
- [ ] Voice-over ≈63 lines per language (19 prompts + 19 fun facts + ~25 item
      names). **Record a scratch version on your phone this week** — a kids' game
      lives or dies on whether the prompt is spoken, and timing needs testing long
      before a studio session
- [ ] Tapping an item speaks its name (free vocabulary teaching, `vo_key` already
      exists in the data schema)
- [ ] Tap-to-hear-again button on every prompt — children look away mid-sentence

## 6 · Art integration

The artwork exists. `Untitled.fig` holds roughly **170 unique full-resolution
assets** — effectively the whole game. Inventory in `art/MANIFEST.md`.

- [x] Main menu: 7 assets extracted, downscaled and wired
- [x] **Decided: the artwork keeps its text.** English only, no Filipino for
      now. `content/*.tres` holds transcripts, not display strings. Verified
      legible at 1080-wide design resolution
- [ ] 16 item icons (1254 × 1254 in the source)
- [ ] Stage backgrounds (852 × 1846) — Level 1 and Level 2 states
- [ ] Hero plant variants, including versions with roots exposed
- [ ] Level select plates, locked and unlocked, with star rows
- [ ] Feedback cards, completion badges, tool trays
- [ ] Display font in `res://fonts/`, wired once in `themes/ktg_theme.tres`
- [ ] Decide an import policy — sources are up to 4096 × 2896 and the raw `.fig`
      is 290 MB. Everything needs alpha-cropping and downscaling before it lands
      in the repo, or the APK will be enormous

## 7 · Android and release

- [ ] OpenJDK 17 + Android Studio SDK, paths set in Editor Settings
- [ ] Debug keystore, and a **release keystore backed up in two places** with the
      passwords written down somewhere that survives a year. Lose it and the app
      can never be updated under the same listing
- [ ] Install the Android Build Template — `min_sdk` and `target_sdk` in
      `export_presets.cfg` are inert until `gradle_build/use_gradle_build` is on
- [ ] Launcher icons: 192×192 and the three 432×432 adaptive layers
- [ ] Splash screen art
- [ ] **Export a debug APK to a real phone now**, with the grey-box build. Touch
      targets that feel fine with a mouse are often too small for a six-year-old
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
