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
- [ ] Run `git lfs install` **before** the first PNG lands — `.gitattributes`
      already routes images through LFS, but retrofitting it onto existing
      history is painful
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
- [ ] Button press sound and a small scale-bounce on tap
- [ ] Menu music loop

## 2 · Core gameplay

The four levels are one mechanic in four costumes: show a prompt, the learner
picks one of N options, it is right or it is wrong. Build that once.

- [ ] **Restore the data scripts** — `scripts/data/level_data.gd`,
      `challenge_data.gd`, `option_data.gd`. They were deleted in
      `setup/removed prototype data`, so all four `content/*.tres` files now carry
      their own inlined copy of the schema. The content survived intact, but there
      are four divergent copies of the class definitions. **Do this before
      touching the `.tres` files** or the copies will drift further apart
- [ ] `OptionCard` component — tappable and draggable, uses `ArtSlot` for its icon
- [ ] `DropZone` component — `zone_id`, minimum 160 px target, highlight on hover
- [ ] `ChallengeScreen` — reads a `LevelData` and plays it end to end
- [ ] Correct answer: sparkle, ding, stage advances, fun fact appears
- [ ] Wrong answer: gentle bounce-back, the item's own hint, arrow nudge, no
      penalty and no "Wrong" label
- [ ] Option shuffling (`shuffle_options`) — Level 3's scripted answers sit at
      B, A, C, A, B and children memorise positions faster than content
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
- [ ] **Level 1 stage 2 labels the item two ways** — the tray says "Seed Packet",
      the correct choice is listed as "Seed". Pick one and use it in the art, the
      prompt and the voice-over. **⚠**
- [ ] **Level 1 has no completion celebration** in the design document while
      Level 4 does. Give every level the same reward beat
- [ ] Wrong-answer hints are written one per *item* (6 lines for Level 2), not
      one per item × situation (25 lines). Keep it that way
- [ ] Content lock: walk all 19 stages on a phone with whoever owns the teaching
      content, then freeze the wording. Changes after voice-over is recorded mean
      re-recording
- [ ] Structure for Filipino translation now (`.csv` → `.translation`), even if
      only English ships. Costs nothing today, costs weeks later. **⚠**

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

Tracked in detail in `art/MANIFEST.md`.

- [ ] Main menu: 6 slots + the leaf particle texture
- [ ] 15 item icons at 512 × 512
- [ ] Level 1 stage art ×5, Level 2 stage art ×5
- [ ] Hero plant — **the most important drawing in the game**, it carries Levels
      3 and 4. Request it as a layered file
- [ ] Part highlight overlays ×5
- [ ] UI frames ≈15 pieces
- [ ] Display font in `res://fonts/`, wired once in `themes/ktg_theme.tres`
- [ ] Level 4 needs no illustration at all — the function cards are text on a card
      frame. It can be finished before any art arrives

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
6. Is Filipino shipping, or only being structured for?
