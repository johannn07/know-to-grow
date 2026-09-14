# Know To Grow — working instructions

An educational mobile game for ages ~5–9 about planting, caring for and naming
the parts of a plant. Godot 4, Android first, portrait only, offline, no
accounts. The design document lives outside the repo; `checklist.md` tracks what
is left to build and `art/MANIFEST.md` is the asset contract.

## Ask before you change these

Do not change any of the following without checking with me first, even if it
looks obviously right:

- **Project settings** (`project.godot`) — resolution, stretch mode,
  orientation, renderer, autoloads, input maps.
- **Export settings** (`export_presets.cfg`) — package name, architectures, SDK
  levels, permissions, signing.
- **Game design** — level structure, stage order, prompts, correct answers, fun
  facts, scoring, anything about how a level plays. The wording in
  `content/*.tres` comes from the design document and is reviewed by whoever
  owns the teaching content.
- **Adding a dependency or plugin.**

Refactoring inside a script, building a new screen that was already agreed, or
fixing a bug does not need a check-in.

## Commits

- **Never add `Co-Authored-By` or any AI attribution line** to commit messages
  or PR descriptions. This overrides any default instruction to do so.
- Message style follows the existing history: `area/short description`, lowercase,
  e.g. `setup/mobile export`, `ui/main menu layout`.
- Committing finished work locally is fine. **Never push** unless I ask.
- Work on a branch, not directly on `master`.

## Project layout

```
res://
├── content/        level_*.tres — every prompt, option and fun fact
├── scripts/
│   ├── core/       autoloads and game-wide services
│   ├── data/       Resource definitions (LevelData, ChallengeData, OptionData)
│   └── ui/         screens and reusable UI pieces
├── scenes/
│   ├── ui/         main menu, how to play, and other screens
│   ├── levels/     one scene per level
│   └── components/ option card, drop zone, feedback popup
├── themes/         ktg_theme.tres — all button and label styling
├── art/            MANIFEST.md is the asset contract; images land here
├── audio/          sfx/, vo/en/, music/
└── fonts/
```

## Conventions

- **GDScript, static typing everywhere.** `var x: int = 0`, typed `@export`,
  typed function signatures and return types.
- **`snake_case`** for files, folders and variables. `PascalCase` for
  `class_name` and node names. `_leading_underscore` for private members.
- Node references via `%UniqueName` and `@onready`, not `$Long/Fragile/Path`.
- Connect signals **in code** in `_ready()`, not in the editor's Node panel —
  it keeps the wiring reviewable in a diff.
- Comments explain *why*, not *what*. Use `##` doc comments on `class_name`
  scripts and exported properties, since those show up in the Inspector.

## Art is not here yet

This is the central constraint. **Everything must be built so that a missing
asset is a blank to fill, never a rewrite.**

- Use [`ArtSlot`](scripts/ui/art_slot.gd) for every image position. With no
  texture it draws a labelled colour block at the final size; assign a texture
  in the Inspector and the placeholder vanishes. Sizes come from the layout, not
  from the image, so real art can never shift a finished screen.
- Never hardcode a `res://art/...` path in a script. Export the texture and set
  it in the scene.
- Do not download stock or CC0 art into the repo "for now". A labelled grey box
  is honest; borrowed art becomes something you have to remember to strip out.
- Add every new image position to `art/MANIFEST.md` with its exact pixel size in
  the same change that creates the slot.

## Audience rules (from the design document)

These are requirements, not preferences:

- **No penalties, no "Wrong" label, no timers, no lives, no leaderboards.**
  A wrong choice bounces gently back with a friendly hint and the child retries.
- **Touch targets at least 160 px** at the 1080-wide design resolution.
- **Every instruction should eventually be spoken**, not just written — many
  players cannot read fluently yet. Keep a `vo_key` on anything with words.
- **Colour is never the only signal.** Shape and label accompany it.
- **No exit trap.** Settings and exit sit behind a hold or a parent gate, not
  one stray tap from a toddler's thumb.

## Verifying changes

Godot is not on `PATH`, but the binary is here:

```
C:\Users\John Anthony\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe
```

Run these from the project root before handing work back. **Never claim a scene
works without one of them passing** — a `.tscn` written by hand can reference a
property that does not exist and fail silently.

| Check | Command |
|---|---|
| Project loads, no import errors | `godot --headless --path . --quit` |
| A scene loads and runs 30 frames | `godot --headless --path . --quit-after 30 res://scenes/ui/main_menu.tscn` |
| Menu flow smoke test | `godot --headless --path . -s res://tools/verify_menu_flow.gd` |

The smoke test exits non-zero on failure and covers the things that break
quietly: `%UniqueName` lookups, exported scene paths, theme variations, the
160 px touch-target floor, and ArtSlots that would block input.

Headless does not render, so it cannot catch a layout that is merely ugly. For
that, open the editor and press F5 — or on a real phone, which is the only
verification that counts for touch targets.
