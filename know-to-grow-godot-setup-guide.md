# Know to Grow — Godot 4 setup & pre-asset work plan

A build order for the mobile game described in your design doc, written for the
situation you're actually in: engine ready, art not ready.

The short version: **art is the last thing a game like this needs.** Every level
in your doc is the same interaction under different costumes — show a prompt,
the learner picks one of N items, it's right or it's wrong. If you build that
engine first and keep all the wording in data files, the art becomes a swap-in
job at the end instead of a rewrite.

Assumptions I've made — correct me if any are wrong: Android first, portrait
only, single-player, offline, English (with room for Filipino later), ages ~5–9.

---

## Phase 0 — Decisions to lock before you write code

These are cheap now and expensive in November.

| Decision | Recommendation | Why |
|---|---|---|
| Orientation | Portrait, locked | One-handed play, and your layouts are vertical lists |
| Design resolution | 1080 × 1920 | Maps cleanly to most Android phones; art briefs get one number |
| Renderer | **Mobile** | Compatibility only if you must support very old/cheap devices — decide by testing, not guessing |
| Min Android version | API 24 (7.0) or higher | Godot 4's floor is already high; going lower buys nothing |
| Target devices | Pick 2 real phones: one cheap, one current | "It runs on my laptop" is not a result |
| Language | English now, structure for Filipino | Costs nothing if you set up translations on day one, costs weeks later |
| Save data | Local only (`user://`) | No accounts, no login, no privacy paperwork for a kids' app |
| Analytics | None, or local-only counters | Children's apps + third-party SDKs = a compliance problem you don't want |

Write these into a one-page `DESIGN.md` in the repo. When someone asks "should
we add a timer?", you point at the page instead of re-arguing.

---

## Phase 1 — Create the project (30 minutes)

1. New project → name `know-to-grow` → renderer **Mobile** → Version control:
   **Git**.
2. Project → Project Settings. Turn on **Advanced Settings** (top right), then
   set:

| Setting | Value |
|---|---|
| `display/window/size/viewport_width` | `1080` |
| `display/window/size/viewport_height` | `1920` |
| `display/window/size/window_width_override` | `540` (so the editor window fits your monitor) |
| `display/window/size/window_height_override` | `960` |
| `display/window/stretch/mode` | `canvas_items` |
| `display/window/stretch/aspect` | `expand` |
| `display/window/handheld/orientation` | `portrait` |
| `display/window/size/resizable` | off |
| `rendering/textures/canvas_textures/default_texture_filter` | `Linear` (keep, unless you go pixel-art) |
| `input_devices/pointing/emulate_mouse_from_touch` | on (default) |
| `application/config/name` | `Know to Grow` |

`canvas_items` + `expand` is the combination that makes a 1080×1920 layout
behave on a tall 20:9 phone: nothing stretches, you just get a bit more room
top and bottom. Design your screens so the extra space is harmless.

3. Audio buses: open the Audio panel, add buses `Music`, `SFX`, `VO`. The
   starter kit's `AudioDirector` uses them if they exist. A mute toggle for
   parents is then two lines of code.

4. Commit immediately, before you add anything. First commit = empty project.

---

## Phase 2 — Folder structure and naming

```
res://
├── content/        level_*.tres      ← all wording lives here
├── scripts/
│   ├── data/       resource definitions
│   ├── core/       autoloads (GameState, AudioDirector)
│   └── ui/         reusable UI pieces
├── scenes/
│   ├── levels/     one scene per level
│   ├── screens/    splash, level select, video player, completion
│   └── components/ option card, drop zone, feedback popup
├── art/
│   ├── items/      tools, needs, answer icons
│   ├── stages/     garden and plant states
│   ├── parts/      plant part highlights
│   └── ui/         buttons, panels, particles
├── audio/
│   ├── sfx/        correct.ogg, wrong.ogg, pickup.ogg...
│   ├── vo/en/      one file per spoken line
│   └── music/
├── video/
├── fonts/
└── tools/          editor-only scripts
```

**Naming rule, decided now:** `snake_case`, category prefix, no spaces, no
version numbers in filenames.
`item_shovel.png`, `stage_l1_hole_dug.png`, `part_roots_highlight.png`,
`ui_button_primary.png`. Tell your artist this on day one and put it in the
asset brief. Renaming 50 files after they're referenced in 20 scenes is a
miserable afternoon.

**Git:** the kit includes a `.gitignore` (ignores `.godot/`, exports, keystores)
and a `.gitattributes` for Git LFS. Run `git lfs install` *before* the first
PNG lands — retrofitting LFS onto existing history is painful.

---

## Phase 3 — The one architectural decision that matters

Look at what your four levels actually are:

| Level | Prompt | Options | Input | Correct? |
|---|---|---|---|---|
| 1 Planting | "Which tool do we use?" | 3 items | drag onto soil | one right |
| 2 Monitoring | "The soil is hard and dry." | 6 items | drag onto plant | one right |
| 3 Identifying | "I am green and flat." | 3 answers | tap | one right |
| 4 Functions | "What do the roots do?" | 3 cards | drag onto part | one right |

That's **one** mechanic with four skins. So build one screen that reads a data
file, and write four data files. The starter kit does exactly this:

- `OptionData` — one item: id, label, icon, wrong-answer hint
- `ChallengeData` — one prompt: options, correct id, fun fact, target zone,
  which visual state to show
- `LevelData` — a list of challenges plus the completion text
- `ChallengeScreen` — reads a `LevelData` and plays it

The payoff: your teacher/content reviewer can fix a prompt in the Inspector
without opening a script, and you can playtest all 19 stages before a single
drawing exists.

`tools/build_content.gd` in the kit already contains every prompt, option,
hint and fun fact from your PDF. Run it once and you have all four levels as
editable `.tres` files.

---

## Phase 4 — Build order (what to do first, concretely)

### Week 1 — vertical slice, no art

1. Drop in the starter kit, register the two autoloads, run `build_content.gd`.
2. Make `challenge_screen.tscn`, assign `level_1_planting.tres`, press F5.
   You should be dragging labelled colour blocks onto a grey rectangle and
   getting fun facts. **That is the whole game.** Everything after this is
   presentation.
3. Play the other three `.tres` files with the same scene. Fix anything that
   feels wrong in the *data*, not the code.
4. Export a debug APK and put it on a real phone. Do this in week 1, not week 6.
   Touch targets that feel fine with a mouse are often too small for a
   six-year-old's thumb.

### Week 2 — feel and flow

5. Feedback polish: bounce-back, sparkle (a `CPUParticles2D` with the default
   white dot is fine as a placeholder), the happy ding, the gentle "let's try
   again". Your doc is specific about this and it's the difference between a
   quiz and a game.
6. Screen flow: splash → level select → level → video → level → completion.
   Build every screen as a grey box with a working button. A broken flow found
   in week 2 costs an hour; found in week 8 it costs a weekend.
7. Save/resume, sound toggle, a parent-facing "exit" that isn't one tap away
   from a toddler's thumb.

### Week 3 — content lock

8. Sit with whoever owns the teaching content and go through all 19 stages on
   the phone. Lock the wording. Content changes after VO is recorded mean
   re-recording.
9. Freeze the asset list (Phase 6) and send the brief.

### Week 4+ — swap in art as it arrives

Each asset is a one-line change: set `icon` on an `OptionData`, or replace the
grey stage rectangle with the illustrated scene. Nothing structural changes.

---

## Phase 5 — Placeholder strategy while you wait

Do **not** wait for art, and do **not** download random art you'll have to
strip out. Three options, in order of preference:

1. **Coloured blocks with labels** (what the kit does). Ugly, unambiguous,
   zero licensing risk, and every placeholder has a visible name so playtesters
   can tell you "the pruning shears one is confusing".
2. **A free CC0 icon set** for the feel of real art — Kenney's asset packs are
   the usual choice for this. Fine for internal testing; make a checklist so
   none of it ships.
3. **Your own 5-minute pencil sketches**, photographed. Genuinely useful for
   checking composition and for showing the artist what you mean.

Whichever you pick, the important part is the **size contract**: decide that
item icons are 512×512 with transparent backgrounds and build every placeholder
at that size. Then real art drops in without layout surprises.

---

## Phase 6 — The asset brief (the highest-value thing you can do right now)

While you can't *use* assets, you can *specify* them completely. Here's your
list, derived from the design doc.

### Item icons — 512 × 512 PNG, transparent, centred, consistent light source

| Group | Items | Count |
|---|---|---|
| Tools | shovel, watering can, pruning shears, gloves | 4 |
| Planting | seed packet, single seed, flower | 3 |
| Basic needs | sunlight icon, water icon, fertilizer icon | 3 |
| Sky | sun, cloud, moon | 3 |
| Distractors | rock, leaf | 2 |

**13 icons.** Note the sun appears both as a sky object (L1) and as a "basic
need" card (L2) — decide whether that's one drawing or two.

### Stage art — 1080 × ~1300 PNG, or one layered file

| Level | States | Count |
|---|---|---|
| 1 Planting | empty bed, hole dug, seed covered, soil watered, sprout | 5 |
| 2 Monitoring | hard/dry soil, brown leaves, thirsty plant, sad/low-light plant, pale/undernourished plant | 5 |
| 3 & 4 | one hero plant showing roots, stem, leaves, flower, fruit at once | 1 |
| 3 & 4 highlights | a glow/outline overlay per part | 5 |

**16 pieces.** The hero plant is the most important drawing in the game — it
carries two whole levels. Ask for it as a layered file so you can animate parts
separately.

### UI — 9-patch where it stretches

Card frame (normal + lifted + correct + wrong), primary button (3 states),
panel/popup frame, score chip, star, arrow hint, sparkle burst, confetti,
home / sound / back icons. **≈ 15 pieces.**

### Level 4 needs no illustrations

The function cards are text on a card frame. That's a typography job, not an
art job — it can be built and finished this week.

### Audio

- SFX: correct ding, gentle bounce, pickup, drop, level complete, button tap — **6**
- Music: one calm garden loop, one celebration sting — **2**
- Voice-over: 19 prompts + 19 fun facts + ~25 item names ≈ **63 lines** per
  language. Record a temporary version yourself on your phone this week; kids'
  games live or die on whether the prompt is *spoken*, and you want to test
  timing long before the real recording session.

### Video — read this before commissioning anything

Godot 4 plays **Ogg Theora (`.ogv`) only**. MP4/H.264 will not play without a
third-party add-on. So either:

- get the two animated clips delivered as `.ogv` (quality is mediocre, files
  are large), or
- **build them in-engine instead** with `AnimationPlayer` and the art you
  already have. This is what I'd do: it's sharper, smaller, skippable,
  pausable, translatable, and it reuses the hero plant drawing instead of
  paying for separate animation.

---

## Phase 7 — Android export prep (do it now, it's all waiting)

None of this needs assets, and all of it will block you on a deadline day.

1. Install **OpenJDK 17** (the version Godot 4 expects — confirm against the
   docs for your exact build).
2. Install Android Studio, then the SDK, platform-tools and build-tools via its
   SDK Manager.
3. Godot → Editor → Editor Settings → Export → Android: set the Java SDK and
   Android SDK paths.
4. Create a debug keystore with `keytool` and point the editor settings at it.
5. Create a **release keystore now**, back it up in two places, and write the
   passwords somewhere you'll still have in a year. Lose it and you can never
   update the app under the same listing.
6. Project → Install Android Build Template (needed once you add any plugin).
7. Enable Developer Options + USB debugging on your test phone, and export a
   debug APK today with the grey-box build.

---

## Phase 8 — Rules for a 5–9 year old audience

Your doc already gets the big one right (no penalties, no "Wrong" label). Add
these to the design page:

- **Touch targets ≥ 160 px** at 1080 wide (~1 cm). The kit enforces this on
  drop zones. Small hands, imprecise aim, no frustration budget.
- **Every instruction is spoken**, not just written. Many of your players can't
  read fluently. Tapping an item should also say its name — that's free
  vocabulary teaching, and it's already wired in the kit via `vo_key`.
- **No timers, no lives, no leaderboards.** Your doc's 0/5 score is the only
  progress signal needed, and it only goes up.
- **Repeatable prompt**: a tap-to-hear-again button on the prompt. Children
  will look away mid-sentence.
- **No exit trap**: exit and settings behind a press-and-hold or a simple
  parent gate, so nobody loses progress by fat-fingering a corner.
- **Colour is never the only signal** — about 1 in 12 boys has some colour
  vision deficiency. Shape and label always accompany colour.

---

## Content notes from your design doc

Small things worth fixing before you lock content, not bugs:

1. **Level 2, situation 3 has two valid answers.** "The soil is dry and the
   plant needs a drink" is solved equally well by the *Watering Can* (tool) and
   *Water* (basic need), and both are on screen. Either accept both or reword.
   The kit accepts both.
2. **Level 2's wrong-answer messages** would need 25 lines if written per
   situation. Write one hint per *item* instead (6 lines) and it reads
   correctly everywhere. The kit takes this approach.
3. **Level 3's correct answers sit at B, A, C, A, B.** Children learn positions
   faster than content. Shuffle option order at runtime — it's one flag in the
   data.
4. **Level 1, stage 2**: the tray shows a "Seed Packet" but the correct choice
   is listed as "Seed". Pick one label and use it in the art, the prompt and
   the VO.
5. **Levels 3 and 4 cover identical parts back-to-back.** That's pedagogically
   sound (name it, then explain it), but five identical-feeling rounds twice in
   a row is where attention drops. The video between them is doing important
   work — keep it short (under 60 seconds) and let it be skippable on replay.
6. **Level 1 has no completion celebration** in the doc, while Level 4 does.
   Give every level the same reward beat.

---

## Quick checklist for this week

- [ ] `DESIGN.md` with the Phase 0 decisions
- [ ] Project created with the Phase 1 settings, committed to Git
- [ ] Git LFS installed before any binary asset arrives
- [ ] Starter kit added, autoloads registered, content generated
- [ ] All four levels playable as grey boxes
- [ ] Debug APK running on a real phone
- [ ] Asset brief sent, with the naming convention and sizes
- [ ] Temporary voice-over recorded on your phone
- [ ] Release keystore created and backed up
- [ ] Decision made on video: `.ogv` files vs. in-engine animation
