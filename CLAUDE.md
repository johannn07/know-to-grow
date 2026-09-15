# Know To Grow — working instructions

An educational mobile game for ages ~5–9 about planting, caring for and naming
the parts of a plant. Godot 4, Android first, portrait only, offline, no
accounts. The design document lives outside the repo; `checklist.md` tracks what
is left to build and `art/MANIFEST.md` is the asset contract.

## One thing at a time

Do one task, finish it, report it, and stop. Wait for the next instruction
before starting anything else.

This means:

- **No bundling.** If I ask for the How To Play screen, do that screen. Do not
  also refactor the theme, update three docs and generate a tool in the same
  turn, however related they look.
- **No scope creep from discovery.** Finding something interesting mid-task is
  a thing to mention at the end, not a licence to go and do it.
- **Finish before flagging.** A half-built thing plus a list of observations is
  worse than one finished thing.
- If a task genuinely cannot be done without a second change, say so and ask,
  rather than doing both and explaining afterwards.

Large bundled turns are hard to review, hard to revert, and bury the thing I
actually asked for.

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

## Figma access is rationed

The Figma MCP connector is authorised as `johnanthonysb@gmail.com`, a **View
seat on a Starter plan**. That tier allows **20 tool calls per month** — not per
day. `whoami`, `create_new_file` and `add_code_connect_map` are exempt;
everything that reads a file (`get_metadata`, `get_design_context`,
`get_screenshot`, `download_assets`) counts.

Access is also gated on **edit** rights, not view rights: reading a file through
the MCP fails with "you don't have edit access to this file" unless the
authorising account is an editor on that specific file. Confirm access before
planning a sequence of calls.

So: **never browse a Figma file.** Plan the exact calls first, then make them.
The efficient shape for pulling art is two calls — `get_metadata` on the frame
to see the layer structure, then `download_assets` on that same frame, which
returns the rendered export plus every source image and vector in the subtree
(capped at 20 each) in a single response. Download the returned URLs with curl,
which costs nothing against the quota.

When the goal is simply "get these PNGs into the repo", exporting by hand from
the Figma UI costs zero calls and is usually the better trade.

## The artwork carries the words — decided

The Figma artwork has its English text drawn into the pixels: prompt banners,
stage headers, feedback cards, several buttons. **That is the agreed design.**
`Know To Grow.pdf` and the Figma files are the sources of truth, English only,
no Filipino for now. Verified legible at the 1080-wide design resolution.

So `content/*.tres` is no longer a display layer. Its text fields are
**transcripts** — `prompt_transcript`, `fun_fact_transcript`,
`instruction_transcript`, `completion_transcript`, `final_fun_fact_transcript`.
They are never drawn on screen. They exist so the wording stays greppable,
diffable, reviewable, and usable as a voice-over script.

Rules that follow from this:

- **Never render a `*_transcript` field.** If a screen needs to show words, it
  shows the art that has them. A transcript in a `Label` is a bug.
- **A transcript must match its artwork exactly.** If the art is re-rendered
  with different wording, update the transcript in the same change.
- **Voice-over is planned**, so every spoken line has a `*_vo_key` and audio
  lives at `res://audio/vo/en/<key>.ogg`.
- `audio/vo/en/SCRIPT.md` is **generated**, not written. Re-run
  `tools/export_vo_script.gd` after any content change.
- Changing wording now means re-rendering art *and* re-recording a line. Get the
  teaching-content reviewer through all 19 stages before commissioning voice-over.

## Audience rules

Keep these two groups apart. Do not cite the second group as though the client
asked for it.

### Actually in the design document

- **No penalties and no "Wrong" label.** Stated twice, for Level 1 and Level 4.
  A wrong choice bounces gently back with a friendly hint and the child retries.
- **A friendly voice or text line on a wrong answer** — "Oops, let's try again!"
  The document says "voice/text", so audio is permitted here, not mandated.
- **Level 2 shows a 0/5 score** that only goes up.

That is the whole of what the design document specifies about audience handling.
It says nothing about spoken instructions, touch-target sizes, colour-blindness,
timers, lives, leaderboards or exit gates.

### Proposed in the setup guide, never ratified

`know-to-grow-godot-setup-guide.md` Phase 8 lists these under "Add these to the
design page" — they are recommendations awaiting a decision, not requirements:

- Touch targets at least 160 px at the 1080-wide design resolution.
- Every instruction spoken, not just written, with a `vo_key` on anything with
  words, and a tap-to-hear-again button on each prompt.
- No timers, no lives, no leaderboards.
- Colour never the only signal.
- Exit and settings behind a hold or a parent gate.

Phase 0 of the same guide also assumes "English now, structure for Filipino",
under an explicit "correct me if any of these are wrong".

Building to these is reasonable and they are already partly implemented (the
160 px floor is enforced by the menu smoke test). But when weighing a trade-off,
they carry the weight of a suggestion, not of a client requirement — and they
should be confirmed with the project owner before they decide anything.

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
