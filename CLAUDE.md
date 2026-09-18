# Know To Grow — working instructions

An educational mobile game for ages ~5–9 about planting, caring for and naming
the parts of a plant. Godot 4, Android first, portrait only, offline, no
accounts. The design document lives outside the repo; `checklist.md` tracks what
is left to build and `assets/art/MANIFEST.md` is the asset contract.

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
│   ├── levels/     stage_screen.gd, then level_N/stage_M.gd per stage
│   └── ui/         screens and reusable UI pieces
├── scenes/
│   ├── ui/         main menu, hub, how to play
│   ├── levels/     level_N/stage_M.tscn — one scene per stage
│   └── components/ option card, drop zone, feedback popup
├── themes/         ktg_theme.tres — all button and label styling
└── assets/
    ├── art/        MANIFEST.md is the asset contract; images sorted by category
    │   ├── backgrounds/  branding/  characters/  effects/  plants/
    │   ├── items/        draggable item cards shared across stages
    │   ├── ui/           buttons/, common/, hub/, screens/, stage_select/ (+ source/)
    │   └── levels/       level_N/ — art that belongs to one level
    ├── audio/      music/, sfx/, vo/en/
    ├── fonts/      fredoka_one/ — the only typeface
    └── video/
```

`assets/art/MANIFEST.md` says which folder each kind of image goes in. Keep the
category prefix on filenames (`bg_`, `icon_`, `ui_`) even inside a folder that
says the same thing.

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
- Never hardcode a `res://assets/art/...` path in a script. Export the texture and set
  it in the scene.
- Do not download stock or CC0 art into the repo "for now". A labelled grey box
  is honest; borrowed art becomes something you have to remember to strip out.
- Add every new image position to `assets/art/MANIFEST.md` with its exact pixel size in
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

## Stages are hand-built scenes

Every stage is its own scene and its own script — `scenes/levels/level_1/
stage_2.tscn` with `scripts/levels/level_1/stage_2.gd` — so a stage can be
opened in the editor and rearranged without touching code. The art, the item
cards and the answer all live in the scene.

Shared behaviour lives in [`StageScreen`](scripts/levels/stage_screen.gd), which
every stage script extends: the drag, the feedback card, the 160 px hotspot
sizing, and the rule that a wrong card greys out rather than disappearing. That
is the part worth **not** copying nineteen times — every one of those was a bug
at some point, and a fix should land once. Put anything a stage does differently
in its own script; `on_correct` and `on_wrong` exist to be overridden.

A stage on a **blank tray** — empty slots, Level 2 onwards — sets `blank_tray`,
and its cards draw themselves at rest. On Level 1's drawn trays it stays off and
a resting card draws nothing, because the picture already shows the item. A
wrong card ends the same on both: no icon, slot darkened.

A blank tray also **shuffles**: each play deals the cards into the scene's slots
in a new order. The scene still lists its cards in the content file's order,
which is what erify_level_* compares. A drawn tray cannot shuffle, since a
card moved off its own painting would sit on another item's picture.

**The stage scenes are yours, not generated.** They were first written by a
script, but they are hand-owned now: sizes and positions get nudged in the
editor, and regenerating a scene wholesale throws that away. To make a change
consistent across stages, edit each scene in place and take the numbers from the
stage that is already right, rather than rebuilding them all from a template.

`content/*.tres` no longer holds the stage art. It keeps the logic and the
transcripts, which is what a teaching-content reviewer reads and what the
voice-over is recorded from. `tools/verify_level_1.gd` checks the two have not
drifted apart — that each scene's answer and its set of item cards still match
the content file.

## When the Figma and the PDF disagree, the Figma wins — decided

`Untitled.fig` is the actual prototype, so it takes precedence over
`Know To Grow.pdf`. The PDF is the earlier teaching brief; where a prompt, an
item name or a fun fact is worded differently in the artwork, **the artwork is
right and the transcript gets updated to match** in the same change.

Two have come up so far, both in Level 1 Stage 2: the prompt bubble, and *Seed*
rather than *Seed Packet*. Expect more. Correcting one is bookkeeping, not a
design change, because transcripts are never rendered — but re-run
`tools/export_vo_script.gd` afterwards, and keep a note in `checklist.md` so the
teaching-content owner sees the whole list before voice-over is recorded.

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

- **Never render a `*_transcript` field** — with one exception, the prompt
  (below). Otherwise, if a screen needs to show words, it shows the art that
  has them. Any other transcript in a `Label` is a bug.
- **A transcript must match its artwork exactly.** If the art is re-rendered
  with different wording, update the transcript in the same change.
- **Voice-over is planned**, so every spoken line has a `*_vo_key` and audio
  lives at `res://assets/audio/vo/en/<key>.ogg`.
- `assets/audio/vo/en/SCRIPT.md` is **generated**, not written. Re-run
  `tools/export_vo_script.gd` after any content change.
- Changing wording now means re-rendering art *and* re-recording a line. Get the
  teaching-content reviewer through all 19 stages before commissioning voice-over.

## Headers are live text on a blank sign, Level 2 — decided

Level 2's five situation headers are the blank sign with two plates, and the
words laid over it:

- the small **wooden plaque** carries `header_label_transcript` — "Situation 1"
  — in white with a dark outline;
- the **cream banner** under it carries `header_title_transcript` — "Hard and
  Dry Soil" — in dark brown.

Both are on `ChallengeData`, both are **rendered**, and they join the prompt as
exceptions to the never-render-a-transcript rule. Set both or neither;
`verify_content` enforces that.

It is the `HeaderSign` component: a stage that holds a `%HeaderSign` has it
filled from its challenge by `StageScreen`, the same way a `%PromptBubble` is.

Level 1's four headers keep their drawn wording and leave both fields empty.
Levels 3 and 4 are undecided.

## Fun facts are Level 1's alone — decided

Only Level 1 has a fun fact strip. Levels 2-4 have no `fun_fact_transcript` and
no `fun_fact_vo_key`, `verify_content` requires them for Level 1 and forbids
them elsewhere, and `export_vo_script.gd` skips the row rather than writing an
empty one. This is why Level 1's stage layout is taller than every other
level's.

## Prompts are live text on one shared bubble — decided

Every stage prompt, **Level 1 through Level 4**, is drawn on the same blank
speech bubble, `assets/art/ui/common/ui_prompt_bubble.png`, with the words laid
over it as live text. The bubble has no words in it, so it is never re-rendered
when a prompt changes.

- **The prompt's text is `prompt_transcript`.** This is the one transcript that
  is rendered. It still has to be reviewed, and it is still the voice-over line.
- **Art that already has words drawn in stays as it is.** Do not rebuild an
  existing image as live text: headers, feedback cards, fact strips, buttons and
  overlay cards keep their drawn wording.
- New prompts do not need their own drawn artwork, so a missing prompt image is
  never a blocker for building a stage.

## Fredoka One is the only typeface — decided

All live text uses **Fredoka One**, `assets/fonts/fredoka_one/
fredoka_one_regular.ttf`. It is set once as `default_font` in
`themes/ktg_theme.tres`, and every scene uses that theme, so nothing else needs
setting.

- Do not add a font override to a single node; change the theme's sizes and
  variations instead.
- The font is under the SIL Open Font License. Keep `OFL.txt` next to it.

## Stage select — decided

Each level's stage select is an overlay on that level's **card with its rows
already drawn in** — `assets/art/ui/stage_select/ui_stage_select_l1.png` for
Level 1. The row art is laid over the rows in the picture, at the same rects, so
the drawn ones are covered exactly.

The blank `ui_stage_select_bg_l1..l4.png` cards were **removed, and should not
be brought back**. At 377 x 732 for a ~960 px slot they were a quarter of the
drawn card's resolution. Levels 3 and 4 need a *drawn* card each, rows included,
not a blank one.

- **The scene sets how many rows there are.** `row_rects`, `close_rect`,
  `row_art` and `row_art_locked` are measured off that level's card and live in
  its scene, one entry per row, with a `%Rows/RowN` hotspot and a
  `%RowsArt/RowNArt` holding three star slots for each. `verify_menu_flow`
  fails if any of them disagree.
- **A row's press does not bounce**, per the rule below. The four row hotspots
  set `bounce_art = false` on [`ArtButton`](scripts/ui/art_button.gd).
- **Rows are drawn art with their stars covered.** The drawn rows come with
  three filled stars. Before import, each one is covered with
  `icon_star_empty.png` in the image itself, so a row always starts empty.
- **Earned stars are drawn on top** with `icon_star_filled.png`, from
  `GameState`. Each row's three star slots in the scene have to sit exactly on
  that row's drawn stars, so moving or replacing a row means re-measuring its
  star slots. Check it in a real render with all stars filled, not headless.
- Level 1's unlocked rows are the drawn `ui_stage_row_1..4.png`. The locked rows
  still come from `tools/build_stage_rows.py`, which now writes only those four.
- Level 2's is `stage_select_l2.tscn`. Its card paints Situations 2–5 locked,
  so `row_art_locked` is empty and a locked row shows the card's painting. A
  reached row stays closed until its stage scene exists.

## Art laid over art does not bounce — decided

`PressBounce` squashes a control to 0.93 so a tap feels answered. That only
works when there is nothing behind the thing being squashed.

Several buttons here are a new drawing laid **exactly over** one already painted
into a card. Shrinking one of those uncovers the painted version around its
edges — a ring of the old button around the new one — so the press reads as the
card showing through rather than as a button moving.

**The rule:** art that covers other art keeps the 0.82 darken and drops the
squash. Art with nothing behind it bounces as normal.

`ArtButton.bounce_art` is the switch. It defaults to `true`, so a new button
bounces unless it says otherwise.

| Button | Sits on | Press | Set where |
|---|---|---|---|
| Stage select rows ×4 | the row painted into the card | darken | the scene |
| How To Play's X and LET'S GO | the controls painted into the screen | darken | the scene |
| Continue / Choose Again on a feedback card | the button painted into the card | darken | derived |
| Stage 4's Continue | below the card, nothing behind | darken + squash | derived |
| Completed-level sign's Grow Now | the button painted into the sign | darken | derived |
| Level intro / complete / badge Continue | below the card, over the dim | darken + squash | derived |
| Main menu buttons | their own themed plate | darken + squash | default |

- The feedback cards **derive it** in `StageScreen._show_feedback`, from whether
  the art rect falls on the card: `not WHOLE_CARD.intersects(art_rect)`. A new
  stage gets the right behaviour from its rects without anyone remembering this.
  `CardOverlay` derives it the same way from its `button_rect`: the three
  overlays with their button below the card bounce, the completed-level sign,
  whose Grow Now is painted on it, does not.
- **Check the art, not the comment.** Whether something is painted underneath is
  a fact about the PNG. Crop the card at the button's rect and look.
- When the darken is the only feedback left, it is doing real work. Do not
  quietly drop it.

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
| Progress rules | `godot --headless --path . -s res://tools/verify_game_state.gd` |
| Audio wiring | `godot --headless --path . -s res://tools/verify_audio.gd` |
| Level 2 stages play through | `godot --headless --path . -s res://tools/verify_level_2.gd` |
| Live text fits its art (prompts, headers) | `godot --headless --path . -s res://tools/verify_live_text.gd` |

`verify_game_state.gd` **writes to `user://progress.cfg`**, so running it clears
whatever progress is on the machine. It resets to empty afterwards.
So does `verify_audio.gd`, which plays a stage to check the answer stings.

**Once music has played, every run ends with `1 resources still in use at exit`.**
That is the audio server's playback object outliving the scene tree, not a leak
in this project: stopping the players, clearing their streams and nulling the
exports all leave it, and the same run with music never started exits clean.
Ignore that one line; treat anything else on `--quit` as real.

Note that a `-s` tool script is compiled **before autoloads are registered**, so
`GameState` as a bare identifier will not compile in one. Reach progress through
`SubScreen.progress`, which is typed by `GameStateStore` and works in both.

The smoke test exits non-zero on failure and covers the things that break
quietly: `%UniqueName` lookups, exported scene paths, theme variations, the
160 px touch-target floor, and ArtSlots that would block input.

Headless does not render, so it cannot catch a layout that is merely ugly. For
that, open the editor and press F5 — or on a real phone, which is the only
verification that counts for touch targets.
