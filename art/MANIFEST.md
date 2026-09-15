# Art manifest — Know To Grow

Source of truth for the artwork: **`Untitled.fig`**, the Figma design. Assets are
extracted from the image blobs inside that file (a `.fig` is a ZIP containing
`canvas.fig` plus an `images/` directory of content-addressed PNGs), alpha-cropped
to remove the empty margins, and downscaled to the sizes below.

Until a file exists, an [`ArtSlot`](../scripts/ui/art_slot.gd) draws a labelled
colour block at the same size. **Dropping in real art is an Inspector action,
not a code change** — select the node, set its `texture`, done.

## Rules

- **Design resolution is 1080 x 1920.** Every pixel size below is at that scale.
- Assets are supplied at roughly **2x their on-screen size** so they stay sharp
  on 1440p-class phones, where `canvas_items` stretch scales the 1080 design up.
- **PNG, transparent background**, unless the row says otherwise.
- **`snake_case` filenames**, category prefix, no spaces, no version numbers.
- **Colour is never the only signal.** Roughly one boy in twelve has a colour
  vision deficiency, so shape and label always carry the meaning too.
- Backgrounds may bleed past their slot — they are drawn `KEEP_COVERED` and
  clipped, so a taller phone shows more scenery rather than a stretched image.

## Main menu — delivered

All seven are in the repo and wired into `scenes/ui/main_menu.tscn`.

| File | Size | Weight |
|---|---|---|
| `bg_sky.png` | 2160 x 1527 | 888 KB |
| `bg_ground.png` | 2160 x 490 | 238 KB |
| `logo.png` | 1400 x 968 | 585 KB |
| `mascot_sprout.png` | 660 x 832 | 446 KB |
| `mascot_flower.png` | 760 x 991 | 731 KB |
| `fx_leaves.png` | 1600 x 2166 | 336 KB |
| `ui_button_primary.png` | 576 x 210 | 11 KB |

Notes:

- `bg_sky.png` is the only opaque one; it carries the sky, framing trees, hills,
  fence and path in a single drawing, so the separate `bg_hills` slot in the
  scene is now empty and hidden. It is kept rather than deleted in case the
  background is ever split into parallax layers.
- `ui_button_primary.png` is cropped to the green plate only — the source image
  in Figma has loose decorative sparkles floating outside the button body, which
  must not be part of the 9-patch. It is applied as a `StyleBoxTexture` on the
  `PrimaryButton` theme variation, so every primary button in the game picks it
  up. The plate carries **no baked-in text**, which is what makes that possible.
- `fx_leaves.png` is a single static drawing of falling leaves, not a particle
  sprite. It replaced the `CPUParticles2D` stand-in. If the leaves should
  actually animate, the art needs to be one leaf, not a scattered group.

## Hub screen — delivered

All seven are in the repo and wired into `scenes/ui/hub.tscn`.

| File | Size | Weight | Slot |
|---|---|---|---|
| `bg_garden_stump.png` | 852 x 1846 | 2.0 MB | `Background` |
| `plant_seed_pot.png` | 650 x 750 | 404 KB | `Plant` |
| `ui_avatar.png` | 260 x 249 | 80 KB | `GreetingPill/Avatar` |
| `ui_star.png` | 180 x 183 | 36 KB | `StarPill/Star` |
| `ui_tab_lessons.png` | 260 x 203 | 68 KB | `BottomNav` |
| `ui_tab_garden.png` | 260 x 269 | 80 KB | `BottomNav` |
| `ui_tab_badges.png` | 260 x 275 | 72 KB | `BottomNav` |
| `bg_sign.png` | 1086 x 1448 | 1.0 MB | `BgSign` |

Notes:

- **The hub is composed, not baked.** Unlike How To Play — one drawn image with
  invisible buttons over it — every part of this screen is a separate asset with
  live text on top: the greeting, the star count, the plant stage and the play
  button. The pills, the card and the nav bar are `StyleBoxFlat`, not art.
- That makes the hub the **first screen whose look depends on the display font**.
  Until a `.ttf` lands in `res://fonts/` it renders in Godot's default sans,
  which sits oddly against this art. See Fonts below — it is a one-line change.
- `bg_garden_stump.png` is the designer's native 852 x 1846, below the 2x rule
  and narrower than the 1080-wide design resolution, so `KEEP_COVERED` upscales
  it about 1.27x. Every portrait stage background in the `.fig` is this size, so
  this is the ceiling the artwork offers, not a downscaling choice.
- `plant_seed_pot.png` is the SEED stage. The `.fig` has the rest of the growth
  sequence (sprout, leafy, flowering, fruiting) at similar sizes — they drop into
  the same slot when the plant stage becomes real state rather than a
  placeholder.
- The three tab icons are wired but their buttons are `disabled`: Lessons,
  Garden and Badges have nowhere to go yet.

## Level 1 Stage 1 — delivered

Wired into `scenes/levels/level_1/stage_1.tscn`. Nothing on this screen is a
`Label`: every word the child reads is drawn into one of these files.

| File | Size | Weight |
|---|---|---|
| `bg_bed_empty.png` | 852 x 1846 | 1.7 MB |
| `bg_bed_hole.png` | 851 x 1849 | 1.7 MB |
| `ui_header_l1_s1.png` | 900 x 367 | 342 KB |
| `ui_prompt_l1_s1.png` | 1000 x 357 | 325 KB |
| `icon_shovel.png` | 300 x 354 | 120 KB |
| `icon_watering_can.png` | 300 x 334 | 121 KB |
| `icon_flower.png` | 300 x 362 | 122 KB |
| `ui_correct_l1_s1.png` | 800 x 1015 | 1.1 MB |
| `ui_oops_tool.png` | 800 x 521 | 443 KB |
| `ui_fact_l1_s1.png` | 900 x 295 | 275 KB |

Notes:

- **The two backgrounds are the same garden in two states.** A stage scene holds
  the one it opens on as its `Background` and the one it becomes as
  `success_background`, so consecutive stages name the same file — Stage 1's
  success garden is Stage 2's opening garden.
- **Two feedback cards carry their own buttons.** `ui_correct_l1_s1.png` has
  Continue drawn into it and `ui_oops_tool.png` has Choose Again. The screen
  lays an invisible `Button` over each, positioned in fractions of the image and
  then **padded out in code** until it clears the 160 px touch floor — the drawn
  Continue is only 105 px tall and Choose Again only 68 px. Hand-tuned offsets
  were how How To Play's hotspots silently fell under the floor; this cannot.
- **The Oops card is shared by all four stages**, each of which points its
  `wrong_card` at the same file. Its wording is about picking the wrong *tool*,
  which is true of Stages 1, 3 and 4 but not Stage 2 — see below.
- `ui_fact_l1_s1.png` sits at the bottom of the stage, visible the whole time
  rather than shown after an answer. The Correct card explains the answer; the
  fun fact is there to be read while the child is deciding.
- The item icons are the individually framed cards, each with its own name drawn
  on it, not the composed `Choose a Tool` tray. The tray exists ([49], [50],
  [51], [58] — one per stage) but a baked tray cannot be dragged, and the design
  document's Level 1 action is "tap the Shovel, drag it to the dirt".

## Level 1 Stage 2 — delivered

| File | Size | Weight |
|---|---|---|
| `bg_bed_seed.png` | 863 x 1822 | 1.8 MB |
| `ui_header_l1_s2.png` | 900 x 458 | 359 KB |
| `ui_prompt_l1_s2.png` | 1000 x 381 | 392 KB |
| `icon_seed.png` | 300 x 303 | 109 KB |
| `icon_rock.png` | 300 x 337 | 106 KB |
| `icon_leaf.png` | 300 x 329 | 109 KB |
| `ui_correct_l1_s2.png` | 800 x 1020 | 1.1 MB |
| `ui_fact_l1_s2.png` | 900 x 267 | 285 KB |

Notes:

- **Two transcripts were corrected to match the artwork**, per the rule above.
  The speech bubble reads *"What goes inside the hole to start growing our
  plant?"*, not the design document's *"Now, put one tiny seed into the hole.
  What goes inside?"*; and the item card is drawn **Seed**, not *Seed Packet*.
  Nothing a child sees changed — transcripts are never rendered — but the
  voice-over script did, so `audio/vo/en/SCRIPT.md` was regenerated. This also
  settles the open "Seed or Seed Packet" question in favour of the art.
  The option's `id` stays `seed_packet`: ids are internal and renaming one
  churns its `vo_key` for nothing.
- **The Oops card still says "That's not the right tool."** In this stage the
  wrong answers are a rock and a leaf, which are not tools. It is the only Oops
  card in the file and it is wired level-wide, so the wording is off by one
  stage. Worth a re-render if the project owner wants it exact.
- The bed states now run `empty_bed` -> `hole_dug` -> `seed_covered`. The
  remaining two, `soil_watered` and `sprout`, are already drawn — the same bed
  wet ([152]) and with a sprout in it ([166]).

## Level 1 Stage 3 — delivered

| File | Size | Weight |
|---|---|---|
| `bg_bed_watered.png` | 941 x 1672 | 1.8 MB |
| `ui_header_l1_s3.png` | 900 x 442 | 365 KB |
| `ui_prompt_l1_s3.png` | 1000 x 523 | 428 KB |
| `icon_sun.png` | 300 x 284 | 113 KB |
| `icon_gloves.png` | 300 x 315 | 114 KB |
| `ui_correct_l1_s3.png` | 800 x 1016 | 1.1 MB |
| `ui_fact_l1_s3.png` | 900 x 273 | 287 KB |

Notes:

- **No transcript needed correcting here.** The speech bubble and the fun-fact
  strip both match the design document word for word. The Stage 2 divergence
  looks like an exception rather than the rule.
- `icon_watering_can.png` is reused, not re-extracted: it is a wrong answer in
  Stage 1 and the right one here, and both stages already point at the same
  `OptionData`.
- **Stage 4 has no Correct Answer card.** The Figma file holds exactly three in
  the Level 1 frame — shovel, seed and watering can ([117], [111], [125]). There
  is nothing for "Sun". The `.fig` does have "Correct Answer! / Sunlight" ([85]),
  but that is a Level 2 asset in a different frame, and its explanation is about
  Level 2's *"the plant looks sad and needs light"*, not Level 1's *"plants need
  light to help make food"*. Stage 4 needs either a new card rendered to match
  the other three, or a decision to reuse [85] and accept the mismatch.

## Tool trays — delivered

| File | Size | Weight |
|---|---|---|
| `ui_tray_l1_s1.png` | 1000 x 476 | 522 KB |
| `ui_tray_l1_s2.png` | 1000 x 487 | 504 KB |
| `ui_tray_l1_s3.png` | 1000 x 470 | 549 KB |

Each stage's "Choose a Tool" tray, with its three items **drawn into it**. The
draggable cards are anchored exactly over those drawn slots, so the tray reads
as one picture until a card is lifted — and then the drawn item underneath shows
through, which is what marks the slot the card came from.

Two things follow, and both are easy to break by accident:

- **The cards must stay in the same order as the items in the tray.** Stage 2's
  tray is Leaf / Seed / Rock, so its cards are in that order and not the order
  the content file happens to list them in. Reordering the cards in the editor
  would leave them covering the wrong labels. Each stage script says so at the
  top.
- **Card art fills its slot rather than fitting inside it.** The standalone card
  and the tray's drawn panel are the same design exported on different canvases,
  so fitting left the tray's own label pill peeking out below the card. Filling
  covers it exactly; the small aspect difference is the export's, not a
  distortion of the drawing.

Option shuffling is gone as a result: a card's position is fixed by the picture
behind it. That only ever mattered for Level 3, which is multiple choice and has
no tray.

## Where the stage art is wired

**In the stage scenes, not in `content/*.tres`.** Each stage is a hand-built
scene — `scenes/levels/level_1/stage_1.tscn` and so on — that holds its own
background, header, prompt, item cards and both feedback cards, so all of it can
be seen and moved in the editor.

`content/*.tres` keeps the logic and the transcripts. Its `header_art`,
`prompt_art`, `fun_fact_art` and `OptionData.icon` fields are left empty for
Level 1; they remain in the schema for any screen that is driven from data
instead. `tools/verify_level_1.gd` checks each scene's answer and item cards
still match the content file, so the two cannot drift.

## Still in the Figma file, not yet extracted

The `.fig` contains roughly **170 unique full-resolution assets** — effectively
the whole game. Spot-checked groups:

| Group | Examples | Approx. size |
|---|---|---|
| Item icons | shovel, watering can, pruning shears, gloves, seed, rock, leaf, flower, fertilizer, sun, cloud, moon, water, roots, stem, fruit | 1254 x 1254 |
| Stage backgrounds | empty bed, dug hole, seed planted, watered, sprout, cracked dry soil, tree stump, potted plant | 852 x 1846 |
| Hero plants | sprout with roots, flowering plant with roots, plant with tomato | ~1500-2300 tall |
| Level select plates | Level 1-4, locked and unlocked, with per-stage star rows | 4096 x 2896 |
| Feedback cards | "Correct Answer!", "Oops! That's not the right tool", reinforcement facts | 1122 x 1402 |
| Completion badges | Level 1-4 complete, Green Thumb, Super Grower, Mystery Solver, Plant Power-Up, Badge Unlock | 1122 x 1402 |
| Headers and banners | "Stage 1 — Dig the Hole", "Situation 1 — Hard and Dry Soil", fun-fact strips | 1774 x 887, 2172 x 724 |
| Buttons | Continue, Grow Now, Let's Go, Click Me, Choose Again | 2172 x 724 |
| Tool trays | "Choose a Tool" with three item slots, four variants | 1672 x 941 |

### These carry their own text — and that is the agreed design

**Most of them have their English text baked into the pixels.** A fun-fact
banner is not a frame plus a string — it is one flat drawing with the sentence
already rendered in it. The same is true of the stage headers, the feedback
cards and several buttons.

Decided: **keep it.** English only, no Filipino. The typography was checked at
the 1080-wide design resolution first — the smallest body text lands around 30px
cap height, comfortably readable for a five-to-nine-year-old — and rebuilding
those curved, outlined, frame-fitted headings as live `Label` nodes would look
worse for real work.

What follows from that:

- **The art is the display layer.** `content/*.tres` holds `*_transcript`
  fields that record what each asset says. They are never rendered. Rendering
  one in a `Label` is a bug.
- **A transcript must match its artwork exactly.** Re-render a banner with new
  wording, update the transcript in the same change, and re-run
  `tools/verify_content.gd`.
- **Voice-over is planned.** Every spoken line has a `*_vo_key`, and
  `audio/vo/en/SCRIPT.md` — 76 lines — is generated from the transcripts by
  `tools/export_vo_script.gd`. Never hand-edit it.
- **Wording changes are now expensive**: a re-render plus a re-record. Lock the
  teaching content before commissioning voice-over.

When wiring the level art, each `ChallengeData` has `header_art`, `prompt_art`
and `fun_fact_art` slots waiting, and each `OptionData` has `icon`.

## Fonts

The game currently uses Godot's default font. The Figma artwork uses a chunky
rounded display face. Drop a licensed `.ttf` in `res://fonts/` and set it once in
`themes/ktg_theme.tres` — every screen follows.
