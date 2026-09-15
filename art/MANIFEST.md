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

Wired into `content/level_1_planting.tres` and played by
`scenes/levels/challenge_screen.tscn`. Nothing on this screen is a `Label`:
every word the child reads is drawn into one of these files.

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

- **The two backgrounds are the same garden in two states.** They are keyed by
  name in `LevelData.scene_art` (`empty_bed`, `hole_dug`) rather than attached to
  a challenge, because one stage's `success_state` is the next stage's
  `scene_state` — the pictures are shared, so the level owns them.
- **Two feedback cards carry their own buttons.** `ui_correct_l1_s1.png` has
  Continue drawn into it and `ui_oops_tool.png` has Choose Again. The screen
  lays an invisible `Button` over each, positioned in fractions of the image and
  then **padded out in code** until it clears the 160 px touch floor — the drawn
  Continue is only 105 px tall and Choose Again only 68 px. Hand-tuned offsets
  were how How To Play's hotspots silently fell under the floor; this cannot.
- **The Oops card belongs to the level, not the stage.** Its wording is about
  picking the wrong *tool*, which is true of all four Level 1 stages.
- `ui_fact_l1_s1.png` is **wired but not yet displayed.** `ui_correct_l1_s1.png`
  already explains why the shovel is right, and showing a second card would add
  another tap. Whether Level 1 wants the Fun Fact strip as well is an open
  question for the project owner.
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
