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

## Folders

Filenames are unique across the whole tree, so the tables below give the bare
name; this is where each one lives under `res://assets/art/`. A file keeps its
category prefix even though the folder says the same thing — the name alone
should still tell you what it is in a scene's `ext_resource` list.

| Folder | Holds |
|---|---|
| `backgrounds/` | `bg_*` — full-screen scenery, drawn `KEEP_COVERED` |
| `branding/` | `logo.png` |
| `characters/` | `mascot_*` |
| `effects/` | `fx_*` |
| `plants/` | `plant_*` — the hub's growth stages |
| `items/` | the draggable item cards (`icon_shovel`, `icon_seed`, ...), shared across stages |
| `ui/buttons/` | `ui_button_*` |
| `ui/common/` | art every level shares, such as the blank prompt bubble |
| `ui/hub/` | avatar, star and bottom-nav tab icons |
| `ui/screens/` | one-image screens and overlay cards: How To Play, level intro and complete, badges |
| `ui/stage_select/` | the stage select card (`ui_stage_select_l1`, rows drawn in), the rows laid over it and the star icons |
| `ui/stage_select/source/` | inputs to `tools/build_stage_rows.py` that no scene loads |
| `levels/level_N/` | art that belongs to one level: headers, prompts, trays, feedback and fact cards |

When a level's art arrives, give it a `levels/level_N/` folder. Anything a
second level reuses moves up to `items/` or `ui/` rather than being referenced
across level folders.

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
- That makes the hub the **first screen whose look depends on the display font**,
  which is Fredoka One — see Fonts below.
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

- **A stage's garden never changes while the stage is on screen.** The five bed
  pictures are *not* one garden in five states — they are independent drawings.
  Diffing `bg_bed_empty` against `bg_bed_hole` lights up the whole frame: every
  cloud, tree, fence post and flower sits slightly differently, and the two are
  even different pixel sizes (852 x 1846 against 851 x 1849). Swapping one for
  the next made the entire garden jump, which was glaring behind the feedback
  card. Each stage now keeps one background for its whole life and the change
  happens at the stage boundary, where a scene cut is expected anyway.
- `bg_bed_sprout.png` is **currently unused**. It was Stage 4's success garden,
  and with the swap gone there is no stage after it to show the sprout. That is
  the payoff of the whole level, so it belongs on the Level 1 completion screen
  when that gets built.
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

## Level 1 Stage 4 — delivered

| File | Size | Weight |
|---|---|---|
| `bg_bed_sprout.png` | 851 x 1849 | 2.2 MB |
| `ui_header_l1_s4.png` | 900 x 426 | 373 KB |
| `ui_prompt_l1_s4.png` | 1000 x 464 | 426 KB |
| `icon_cloud.png` | 300 x 372 | 112 KB |
| `icon_moon.png` | 300 x 353 | 114 KB |
| `ui_correct_l1_s4.png` | 800 x 665 | 434 KB |
| `ui_fact_l1_s4.png` | 900 x 270 | 300 KB |

Notes:

- **The Correct card is borrowed from Level 2**, by decision. The Figma file has
  exactly three "Correct Answer!" cards in the Level 1 frame — shovel, seed,
  watering can — and none for Sun. `ui_correct_l1_s4.png` is Level 2's
  "Correct Answer! / Sunlight". Two things come with it: it looks different from
  the other three (a green banner rather than the wooden frame), and **it has no
  Continue button drawn on it**, because Level 2's cards do not carry one. The
  stage sets `correct_button_rect` to the whole card so the child can tap
  anywhere on it. If a matching Level 1 card is ever drawn, swapping the texture
  and clearing that one property is the whole change.
- Its explanation is Level 2's wording — *"Sunlight provides the energy plants
  need to help make food"* — which happens to fit Level 1's question closely.
- `icon_sun.png` is reused from Stage 3, where Sun is a wrong answer. Since a
  resting card draws nothing, only the dragged card is ever seen, so the slight
  frame difference between its family and Cloud/Moon never shows.
- **The final garden changes framing.** `bg_bed_sprout.png` is a close-up of
  dark soil behind a white picket fence, not the raised bed in a lawn that the
  first four backgrounds use. The `.fig` has no sprout in the raised-bed
  framing, so Level 1 ends on a different-looking garden. Worth a look before
  it ships.
- One transcript corrected to match the art: the fun fact is drawn *"sunlight,
  water, and air"*, not *"sunlight, water and air"*. `SCRIPT.md` regenerated.

## Level flow overlays — in progress

The four screens between the hub and the stages, and between the stages and the
hub again. See `checklist.md` §3 for the sequence. Each is one drawn card on a
dimmed screen with a button under it, built on
[`CardOverlay`](../../scripts/ui/card_overlay.gd).

| File | Size | Weight | Screen |
|---|---|---|---|
| `ui_level_intro_l1.png` | 1106 x 1366 | 1.4 MB | `scenes/ui/level_intro.tscn` |
| `ui_level_complete_l1.png` | 1122 x 1385 | 1.4 MB | `scenes/ui/level_complete.tscn` |
| `ui_badge_little_planter.png` | 1122 x 1389 | 1.7 MB | `scenes/ui/badge_unlocked.tscn` |
| `ui_badge_unlock_banner.png` | 1698 x 808 | 1.2 MB | `scenes/ui/badge_unlocked.tscn` |

- **Supplied at 1.23x, not the usual 2x.** The card is drawn 900 x 1112 at the
  design resolution and the source is 1106 px wide. It is left at native size
  rather than upscaled, which would add weight without adding detail. Worth
  re-exporting larger from the `.fig` if it looks soft on a 1440p phone.
- **The Continue button sits below the card**, not on it — these cards have no
  button drawn into them. `CardOverlay.BUTTON_BELOW_CARD` is the shared rect,
  in fractions of the card, and the y past 1.0 is what puts it outside:

| Card | Button rect | Drawn |
|---|---|---|
| `ui_level_intro_l1` | `Rect2(0.265, 1.0405, 0.47, 0.1149)` | 423 x 128, 45 px under the card |
| `ui_level_complete_l1` | `Rect2(0.265, 1.0405, 0.47, 0.1149)` | 423 x 128, 45 px under the card |
| `ui_badge_little_planter` | `Rect2(0.2597, 1.0413, 0.4807, 0.1172)` | 423 x 128, 45 px under the card |

- **A banner can sit above the card the same way**, with a negative y. The badge
  screen stacks `BADGE UNLOCK!` over the badge it is unlocking:

| Banner | Banner rect | Drawn |
|---|---|---|
| `ui_badge_unlock_banner` | `Rect2(-0.0341, -0.429, 1.0682, 0.4106)` | 940 x 447, 20 px above the card, and wider than it — hence the x outside 0..1 |

- The badge screen's stack is 1729 px of the 1920 available, so it is centred by
  an uneven margin (top 395, bottom 100) rather than by the card alone. Change
  any of the three sizes and that margin has to be recomputed with it.
- Backgrounds: the level intro uses the hub's own `bg_garden_stump.png`, so it
  reads as sitting on top of the hub the child just left. The badge screen uses
  **`bg_bed_sprout.png`** — the sprout the level was spent growing, and which
  had been left unused since stages stopped swapping their gardens.

## Stage select — delivered

### Level cards — one drawn card per level

| File | Size | Weight |
|---|---|---|
| `ui_stage_select_l1.png` | 1633 x 2456 | ~0.2 MB |

The card with its four rows already drawn into it, which is what
`stage_select.tscn` uses. The row art is laid over the rows in the picture at
the same rects, so the drawn ones are covered exactly.

**The blank `ui_stage_select_bg_l1..l4.png` cards were removed.** They were cut
from one sheet, `Level 1-4 Stage select.png`, at 377 x 732 — a quarter of the
resolution of the drawn card they would have replaced, for the same ~960 px
slot. Using them meant a visibly softer card and a fresh measurement of every
row and star rect. The owner's decision is to keep the drawn card instead.

**Level 4 therefore has no stage select card yet.** Level 2's situation select
is `ui_situation_select_l2.png` and Level 3's is `ui_stage_select_l3.png`, both
drawn cards with their rows in them. A drawn card, rows included, is what
Level 4 still needs — not a blank one.

- **They are low resolution.** The drawn card is ~960 px wide on screen and
  these are ~377, so they display at about 2.5x and will look soft. Ask for a
  larger export before this ships.
- Unlike `ui_stage_select_l1.png` they have **no rows baked in**, so row rects
  are free to be chosen rather than measured off the art.

### Level 1 card — wired

| File | Size | Weight |
|---|---|---|
| `ui_stage_select_l1.png` | 1633 x 2456 | 2.7 MB |

Drawn 960 x 1444 at the design resolution, over the hub's garden dimmed to 45%.

- **The whole screen is one picture** — frame, header, close, and all four rows
  with their icons, labels and stars already in it. The interactive parts are
  invisible hotspots over the drawn rows, the same as How To Play.

| Target | Rect2 on the card | Drawn |
|---|---|---|
| Row 1 | `Rect2(0.1176, 0.2280, 0.7581, 0.1739)` | 727 x 251, live |
| Row 2 | `Rect2(0.1145, 0.4092, 0.7606, 0.1682)` | 730 x 243, locked |
| Row 3 | `Rect2(0.1121, 0.5904, 0.7728, 0.1698)` | 741 x 245, locked |
| Row 4 | `Rect2(0.1145, 0.7671, 0.7624, 0.1730)` | 731 x 249, locked |
| Close | `Rect2(0.8500, 0.1164, 0.1316, 0.0799)` | 126 x 115, grown to 160 x 160 |

- **The stars are live.** Each row's three stars are drawn over the empty ones in
  the picture from what `GameState` recorded, and they cover them exactly — the
  delivered star is 248 x 236 against the drawn 153 x 145, a ratio of 1.051
  against 1.055, within half a percent. Which rows can be tapped is live too: a
  row opens when the stage before it is cleared.

| Star | Rect2 on the card | Drawn |
|---|---|---|
| Row 1, stars 1-3 | `L0.4838 / L0.5860 / L0.6938`, `T0.3217 B0.3807` | 90 x 85 each |
| Row 2, stars 1-3 | `L0.4819 / L0.5845 / L0.6926`, `T0.4998 B0.5569` | 90 x 82 each |
| Row 3, stars 1-3 | `L0.4854 / L0.5896 / L0.6995`, `T0.6819 B0.7395` | 92 x 83 each |
| Row 4, stars 1-3 | `L0.4827 / L0.5856 / L0.6940`, `T0.8603 B0.9190` | 90 x 85 each |

### Rows

| File | Size | Weight | Made by |
|---|---|---|---|
| `ui_stage_row_1..4.png` | ~1240 x 420 | ~0.8 MB each | drawn: green, orange, blue, yellow |
| `ui_stage_row_1..4_locked.png` | ~1240 x 420 | ~0.4 MB each | composited by `tools/build_stage_rows.py` |

**The four unlocked rows are drawn art**, delivered as `l1_stage1..4.png`. Each
is cropped to its capsule and stretched to the rect of the row it covers, which
is 12-19% larger and within 4% of the same shape. The drawn rows came with three
filled stars; those are **covered with `icon_star_empty.png`** in the file, so
the row always starts empty and `GameState` fills stars on top. The star slots
in `stage_select.tscn` were moved to sit on the new stars — the per-row star
table below describes the old composited rows and no longer applies to the
unlocked ones. Checked in a real render with all twelve stars filled.

Each row is drawn over the one baked into the card, at the same rect, so the
drawn one is covered exactly. Which of the pair is used comes from `GameState`.

- **The locked rows are still composited** — the notes below are about those.
  The drawn rows share no palette with them, so a locked Stage 2 is grey where
  the unlocked one is orange. Drawn locked rows would fix that; drop them in
  under the same names.
- **Originally only four of the eight were illustrated.** The card has Stage 1 on a
  green plate and Stages 2-4 on grey. The other four — Stage 1 locked, Stages
  2-4 unlocked — were **composited by `tools/build_stage_rows.py`**:
  the row is cut out of the card, its plate and its "Stage N" label recoloured
  into the other state, then the right item icon and clean empty stars laid on
  top. The recolour matches luminance rank to rank against the opposite row's
  palette, so shading and the leaf pattern survive and only the hue moves.
- **Plate and label are recoloured separately.** Matched together, the label
  loses its contrast against the plate and nearly disappears.
- **The composited greens are slightly paler than the drawn Stage 1** and their
  label pill a little lighter. They read as one set, but Stage 1 is the only
  green anyone drew, and a close eye will see it. Replacing the four composited
  files with drawn ones needs no code change — same names, same rects.
- The script now writes **only the locked four**, so re-running it cannot
  overwrite the drawn rows.

### Row parts — cut from the delivered sheets

The item icons and both stars are used, by the row builder and by the screen.
The label pill and its blank plate are **not**: they are ratio ~5.2 against the
3.12 the card draws, so they cannot stand in for the label already there.

| File | Size | Purpose |
|---|---|---|
| `ui_stage_label_plate.png` | 1932 x 347 | blank label pill, unlocked — **unused** |
| `ui_stage_label_plate_locked.png` | 1923 x 349 | blank label pill, locked — **unused** |
| `ui_stage_label_1..4.png` | ~362 x 71 | "Stage N", unlocked — **unused** |
| `ui_stage_label_1..4_locked.png` | ~362 x 71 | "Stage N", locked — **unused** |
| `icon_stage_shovel/seed/water/sun.png` | ~303 x 302 | the row's item, unlocked |
| `icon_stage_*_locked.png` | ~303 x 302 | the same four, greyed |
| `icon_star_filled.png` | 248 x 236 | earned star |
| `icon_star_empty.png` | 249 x 233 | unearned star |

These are separate from the stage item icons already in the game
(`icon_shovel.png` and friends): those are the draggable cards, drawn without a
disc behind them. These carry the coloured disc the stage select rows use.

## Buttons — delivered

| File | Size | Weight | Drawn over |
|---|---|---|---|
| `ui_button_back.png` | 332 x 299 | 121 KB | the X on `ui_how_to_play` |
| `ui_button_lets_go.png` | 1368 x 436 | 460 KB | LET'S GO on `ui_how_to_play` |
| `ui_button_continue.png` | 1100 x 332 | 318 KB | Continue on `ui_correct_l1_s1/2/3` |
| `ui_button_choose_again.png` | 924 x 297 | 214 KB | Choose Again on `ui_oops_tool` |

These are the four buttons as their own drawings, dressed with the leaves and
flowers the painted-in versions do not have.

- **Each one is laid over the button already drawn into the card**, not next to
  it. The cards were rendered with a plain button baked in, and re-rendering
  them is not on the table, so the only way to use these is to cover the old
  one. Every rect below was found by aligning the new button's body to the
  painted one's bounding box, which is why they are not round numbers.

| Button | Rect2 on its card, in fractions |
|---|---|
| Back / X | `Rect2(0.8055, 0.0574, 0.1628, 0.1276)` |
| LET'S GO | `Rect2(0.1442, 0.8009, 0.6705, 0.1824)` |
| Continue | `Rect2(0.1818, 0.7705, 0.6105, 0.1532)` |
| Continue, Stage 4 | `Rect2(0.265, 1.06, 0.47, 0.1707)` |
| Choose Again | `Rect2(0.2736, 0.6849, 0.5130, 0.2345)` |

- **They are drawn `STRETCH`, not `KEEP_ASPECT`.** Covering the painted button
  completely matters more than holding the source aspect exactly, and the two
  disagree by 4-8% depending on the button. At these sizes that is invisible; a
  sliver of the old button showing around the edge would not be.
- The two feedback buttons are placed in code by `StageScreen`, from
  `CONTINUE_ART_RECT` and `CHOOSE_AGAIN_ART_RECT`, because the card underneath
  changes per stage. The two on How To Play are anchored in the scene.
- **Stage 4's Continue sits below its card, not on it** — which is where the y
  past 1.0 comes from: the rects are fractions of the card, and this one starts
  past its bottom edge. Its Correct card is Level 2's and has no Continue
  painted on it to cover, so the button is drawn as its own thing, 45 px under
  the card and 128 px tall at the design resolution, with 413 px still clear
  below it. That card is also the only one where the whole card used to be the
  tap target; the target is now the button, like everywhere else.
- The hotspot rects are **not** these rects. A hotspot is padded out to clear
  the 160 px touch floor; the art is not, or it would no longer line up. Stage
  4's Continue is drawn 423 x 128 and tapped at 423 x 160.
- **Pressing one tints the art, not the button.** These hotspots draw nothing,
  so they cannot use the theme's pressed StyleBox the way the menu buttons do.
  [`ArtButton`](../../scripts/ui/art_button.gd) darkens the art underneath to
  `0.82` while held, the same value `PrimaryButton` uses in `ktg_theme.tres`,
  and lifts it to `1.08` on hover — which only a mouse ever sees, since Android
  has no hover state. Change one and change the other.

## Tool trays — the four drawn ones are deleted

`ui_tray_l1_s1..4.png` were Level 1's trays with each stage's three items
**drawn into them**, at 1000 x ~470. They are **gone from the repo**: Level 1
moved to `ui_tray_blank.png` (below) so that its cards could be shuffled, which
a drawn tray cannot do — a card moved off its own painting would sit on another
item's picture. Recover them from git history if a drawn tray is ever wanted
again.

Two rules died with them, both of which shaped the code:

- **A resting card drew nothing**, because the tray already had that item
  painted in at the right size and place. Drawing both produced a rim inside a
  rim: standalone cards carry thicker frames than the drawn slots did, by
  different amounts per family. On the blank tray the card draws itself instead
  — that is what `blank_tray` switches, and both halves are still in
  `OptionCard`.
- **The cards had to stay in the tray's order**, or they sat over the wrong
  drawn labels. Now the order is the content file's, and where each card lands
  is dealt afresh every play.

What survives unchanged: a wrong option is marked by **tinting its slot** — a
rounded translucent panel at exactly the card's rect — rather than by putting a
greyed card back over it.

## Prompt and fun fact are drawn at a fixed width

The four prompt bubbles and the four fun-fact strips are not the same shape:
the bubbles grow taller with longer wording, and the strips a little shorter.
Fitting each into one shared box made the box's height the limit, so each
rendered at its own width — stage 3's prompt came out 468 px against stage 1's
686, a third smaller, and its text with it.

So every stage draws its prompt and its fun fact at the width **stage 1 uses**,
with the box height following the image's own aspect. Stage 1 is the reference
and is set by hand in the editor; the other three are matched to it. The
compositions are consistent enough for width to be the right measure: exported
at a common width, the mascot in the four bubbles agrees to within 9%.
`tools/verify_level_1.gd` checks all four stages still match, whatever the
reference is changed to.

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

## Level 2 and hub extras — imported, not wired

Imported from a hand-exported `Know To Grow Assets` folder (hub, level select,
Level 2 situation select and situations). Every file is in the repo and
imported, but **no scene uses them yet**. Cropped to their content and scaled to
the width of their Level 1 sibling where one exists; the rest are at source size.

| File | Size | Weight | What it is |
|---|---|---|---|
| `bg_soil_cracked.png` | 863 x 1822 | 1.9 MB | sprout in cracked dry soil — Situation 1, hard and dry soil |
| `bg_bed_sprout.png` | 851 x 1849 | 2.2 MB | sprout with dead brown leaves — Situation 2 (already here, see below) |
| `bg_soil_dry.png` | 852 x 1846 | 1.8 MB | sprout wilting in dry soil — Situation 3, needs a drink |
| `bg_plant_shade.png` | 852 x 1846 | 1.7 MB | sprout in deep shade, grey sky — Situation 4, needs light |
| `bg_plant_yellow_leaves.png` | 852 x 1846 | 1.9 MB | pale yellow sprout in rich soil — Situation 5, needs nutrients |
| `plant_sprout.png` | 650 x 726 | 307 KB | seed with a root and a shoot — the hub's next growth stage after `plant_seed_pot` |
| `icon_fertilizer.png` | 300 x 302 | 122 KB | item card, "Fertilizer" |
| `icon_water.png` | 300 x 300 | 96 KB | item card, "Water" |
| `icon_pruning_shears.png` | 300 x 285 | 112 KB | item card, "Pruning Shears" |
| `ui_button_click_me.png` | 1368 x 447 | 560 KB | "Click Me" button, text drawn in |
| `ui_button_grow_now.png` | 1368 x 438 | 569 KB | "Grow Now" button, text drawn in — a wooden plank, **not** the green one on the sign; unused |
| `ui_button_grow_now_sign.png` | 720 x 227 | 185 KB | the green Grow Now pill **cut from** `ui_level_complete_sign_l1.png`, masked to its stadium shape, laid back over itself at `(0.1707, 0.8057, 0.6716, 0.1646)` of the sign so a press can darken it |
| `ui_situation_select_l2.png` | 1535 x 2287 | 2.5 MB | Level 2 Monitoring card, Situation 1 unlocked, 2–5 locked |
| `ui_situation_row_1..5.png` | ~1110 x 330 | ~380 KB each | unlocked Situation rows, one colour each, **stars covered with the empty star** |
| `ui_level_intro_l2.png` | 1110 x 1373 | 1.4 MB | "Level 2 — Uh-oh! Your plant needs you!" |
| `ui_level_complete_l2.png` | 1122 x 1336 | 1.4 MB | "Level 2 Complete! You saved the plant!" |
| `ui_badge_plant_helper.png` | 1122 x 1388 | 1.8 MB | "Plant Helper" badge, Level 2's counterpart to Little Planter |
| `ui_level_complete_sign_l1.png` | 1072 x 1379 | 1.3 MB | signpost, "You Completed Level 1!" with a Grow Now button drawn in |
| `ui_badge_green_thumb.png` | 1122 x 1402 | 1.8 MB | "Green Thumb — You know how to care for plants!", Level 2's second badge, after Plant Helper |
| `ui_level_complete_sign_l2.png` | 1086 x 1404 | 1.3 MB | signpost, "You Completed Level 2!" with a Grow Now button drawn in; top 44 px of transparent margin cropped |
| `ui_button_grow_now_sign_l2.png` | 720 x 227 | 195 KB | the Grow Now pill **cut from** `ui_level_complete_sign_l2.png` with `ui_button_grow_now_sign.png`'s stadium mask, laid back over itself at `(0.1685, 0.7927, 0.663, 0.1617)` of the sign. Not the Level 1 pill: the two are drawn slightly differently |
| `ui_level_intro_l3.png` | 1122 x 1402 | 1.4 MB | "Level 3 — Detective time! Read each clue and find which plant part it describes." |
| `plant_leafy.png` | 650 x 735 | 434 KB | leafy sprout with roots in a mound of soil — the hub's plant once Level 2 is cleared, "SPROUT"; cropped to alpha and scaled to 650 wide like `plant_sprout` |
| `ui_correct_l2_s1.png` | 800 x 547 | 349 KB | Correct Answer, Shovel |
| `ui_correct_l2_s2.png` | 800 x 622 | 447 KB | Correct Answer, Pruning Shears |
| `ui_correct_l2_s3.png` | 800 x 588 | 394 KB | Correct Answer, Water |
| `ui_correct_l2_s5.png` | 800 x 570 | 389 KB | Correct Answer, Fertilizer |
| `ui_prompt_bubble.png` | 1000 x 474 | 364 KB | the sprout's speech bubble with **no text in it** — every prompt, Levels 1-4 |

Notes:

**`ui_prompt_bubble.png` is wired** as `scenes/components/prompt_bubble.tscn`,
the `PromptBubble` component. The prompt is live text over the cream box:

- **Cream box** measured at 340-914 x 151-356 px of the 1000 x 474 image. The
  text is inset 24 px horizontally and 12 px vertically, so its rect is
  `(0.364, 0.3439) - (0.890, 0.7257)` in fractions of the image.
- **At a stage's 964 px wide slot** the bubble is 964 x 457 and the text box is
  507 x 174, which holds three lines of 34 px `PromptText` — the largest size at
  which all 19 prompts fit. `tools/verify_live_text.gd` enforces it.
- The Figma holds this bubble at **1774 x 887**, if it ever needs to be sharper.

**`ui_tray_blank.png`**, 1000 x 443, 424 KB, in `ui/common/` — the empty
"Choose a Tool" tray, three blank square slots. A newly drawn asset, not a Figma
export; cropped to alpha > 16 and scaled to 1000 wide like the other trays.
Used by Levels 1 and 2.

- **Slots**, outline to outline, in fractions of the tray: `(0.083, 0.2912) -
  (0.351, 0.9007)`, `(0.364, 0.2912) - (0.636, 0.9007)`, `(0.648, 0.2912) -
  (0.916, 0.9007)` — 268-272 x 270 px of the 1000 x 443 image. A card is
  anchored over the whole slot and draws its art at its own shape inside it.

**`ui_header_blank.png`**, 900 x 307, 274 KB, in `ui/common/` — the blank
wooden stage header, wired as `scenes/components/header_sign.tscn`, the
`HeaderSign` component. Cut from Figma image `e54af65e3603` (1672 x 941) by
cropping to alpha > 16 — the source's height was mostly faint padding — then
downscaled to 900 wide, the drawn header's width.

- **Plaque** text rect `(0.2556, 0.0847) - (0.7389, 0.4463)`: the wooden plank
  at y 26-137, between its two nails. 58 px `HeaderLabel`, white outlined in the
  prompts' dark brown.
- **Banner** text rect `(0.0789, 0.4691) - (0.9189, 0.8567)`: the cream at
  x 47-851, y 144-263, inset 24 px. 51 px `HeaderTitle`, the largest at which
  "Needs Extra Nutrients" still fits on one line.
- Sizes are chosen at a **660 px wide** header, Level 1's header slot, where
  the sign is 660 x 225. `tools/verify_live_text.gd` enforces both.

- **Thirteen files in the folder were already here** and were skipped: the
  hub's trophy, star, book, sprout pot, seed pot and sign; the green button
  plate (the uncropped source of `ui_button_primary.png`); the Sun and Watering
  Can and Shovel cards; `bg_bed_sprout`; the Badge Unlock banner; and
  "Correct Answer / Sunlight", which is `ui_correct_l1_s4.png`. That last one
  is Level 2 art to begin with, so **Situation 4's Correct card is
  `ui_correct_l1_s4.png`** — point the scene at it rather than copying it.
- **The situation mapping comes from the delivered file names**
  (`Situation N_bg.png`, `situationN_correct_answer.png`). Situation 2's
  background is pixel-identical to **`bg_bed_sprout.png`**, which Level
  Complete and Badge Unlocked already use, so it is not copied — the Situation 2
  scene points at `bg_bed_sprout.png`. Situation 4's Correct card is
  `ui_correct_l1_s4.png` the same way.
- **No situation has a drawn header any more.** `ui_header_l2_s1.png` was
  removed so all five match: every Level 2 header is the blank sign below with
  live text on it, which is what the Figma already did for Situations 2–5.
- **The blank bubble is decided: it is the prompt for every stage, Levels 1–4**,
  with the words set as live text in Fredoka One. See `CLAUDE.md`.
- **Wired as `scenes/ui/stage_select_l2.tscn`.** The situation rows arrived
  drawn unlocked with three filled stars; each star was covered with
  `icon_star_empty.png` in the image itself, as Level 1's were. Every star was
  found by its yellow and covered at the same outline margin, measured on
  rows 1, 3 and 5 (strict-yellow box −8 / −10 / +10 / +15 px).
- **No locked row art is needed.** The card already paints Situations 2–5
  locked, with empty stars, so a locked row draws nothing and the card shows
  through. `row_art_locked` is five nulls, and `build_stage_rows.py` is not
  involved.
- **Placement was found by edge matching**, since the card's rows are grey and
  the row art is coloured. Rows 2–5 sit on the card at 1.00 scale, row 1 at
  **0.97**, which is why its rect is narrower. Rects in fractions of the card:
  `(0.1492, 0.2038, 0.7140, 0.1373)`, `(0.1427, 0.3389, 0.7257, 0.1482)`,
  `(0.1420, 0.4880, 0.7264, 0.1447)`, `(0.1459, 0.6231, 0.7205, 0.1478)`,
  `(0.1446, 0.7731, 0.7173, 0.1443)`. The X disc is `(0.8534, 0.1128, 0.1283,
  0.0870)`, 197 x 199 px.
- Stars checked in a real render with all fifteen earned: every filled star
  sits on its drawn empty one.

## Level 3 — imported, not wired

Imported from the hand-exported `Know To Grow Assets/Level 3` folder. All 25
files are in the repo and imported, but **no scene uses them yet**. The badge
and Level 4 folders in that same export are deliberately left out; they belong
to later steps.

Level 3's question is carried by the **background**, not by a separate diagram:
each `bg_stage_N_l3.png` draws the whole plant with one part in colour and
glowing and the rest desaturated to grey. That part is the answer, and the five
match the `scene_state` values already in `content/level_3_identifying.tres` —
`highlight_leaves`, `highlight_stem`, `highlight_roots`, `highlight_flower`,
`highlight_fruit`, in stage order.

### Backgrounds

| File | Size | Weight | Highlights |
|---|---|---|---|
| `bg_stage_1_l3.png` | 852 x 1846 | 1.9 MB | leaves |
| `bg_stage_2_l3.png` | 1024 x 1536 | 1.8 MB | stem |
| `bg_stage_3_l3.png` | 852 x 1846 | 1.9 MB | roots |
| `bg_stage_4_l3.png` | 941 x 1672 | 1.8 MB | flower |
| `bg_stage_5_l3.png` | 851 x 1849 | 1.8 MB | fruit |

Four of the five are the same shape as the `bg_bed_*` family already in the
repo, so they were taken in at source size with no crop — they are opaque edge
to edge and there is no alpha margin to remove.

- **`bg_stage_2_l3.png` is the odd one at 1024 x 1536**, a 0.667 aspect against
  the screen's 0.5625. Drawn `KEEP_COVERED` it scales to 1920 tall and loses
  about 840 px off the sides, far more than the others lose. Check in a real
  render that the glowing stem survives the crop before Stage 2 is signed off.

### Answer cards — `levels/level_3/`

Tap targets, one per plant part, with the part's name drawn into the card.
Cropped to alpha, then scaled to **640 wide**, which is the manifest's 2x rule
against a ~320 px card slot; at source they were ~3.5x and 1.3 MB each.

| File | Size | Weight |
|---|---|---|
| `icon_roots_l3.png` | 640 x 733 | 526 KB |
| `icon_stem_l3.png` | 640 x 750 | 471 KB |
| `icon_leaves_l3.png` | 640 x 781 | 421 KB |
| `icon_flower_l3.png` | 640 x 730 | 473 KB |
| `icon_fruit_l3.png` | 640 x 739 | 458 KB |

- **They live in `levels/level_3/`, not `items/`.** `items/` holds the
  *draggable* cards shared across stages; these are tap-only and Level 3's
  alone, and Level 4 ships its own `icon_stage_N_cM_l4` set rather than reusing
  them.
- **`icon_leaves_l3` is the odd one.** It came at 1231 x 1593 where the other
  four are 1122 x 1402, and with a hard alpha edge where theirs feather out, so
  after cropping it is about 6% taller in proportion. `OptionCard` centres art
  in its rect keeping the art's own shape, so it will sit slightly larger than
  its neighbours. Check it against the other two cards in Stage 1.

### Feedback cards — `levels/level_3/`

Cropped to alpha. Each carries the answer's name and a **Reinforcement Fact**,
both drawn in, and — like Level 2's — **no Continue button drawn on them**, so
Continue is drawn below the card as `CONTINUE_BELOW_CARD_RECT`.

| File | Size | Weight | Says |
|---|---|---|---|
| `ui_correct_l3_s1.png` | 1122 x 1232 | 1.2 MB | Correct Choice: Leaves — "Leaves capture sunlight and help the plant make food!" |
| `ui_correct_l3_s2.png` | 1024 x 1293 | 1.3 MB | Correct Choice: Stem — "The stem helps hold the plant upright and carries water to other parts of the plant!" |
| `ui_correct_l3_s3.png` | 1024 x 1386 | 1.4 MB | Correct Choice: Roots — "Roots hold the plant firmly in the soil and absorb water and nutrients!" |
| `ui_correct_l3_s4.png` | 1024 x 1396 | 1.4 MB | Correct Choice: Flower — "Flowers help plants reproduce by helping them make seeds!" |
| `ui_correct_l3_s5.png` | 1024 x 1428 | 1.4 MB | Correct Choice: Fruit — "Fruits protect the seeds and help them develop into new plants!" |

- **The Reinforcement Fact is not a fun fact.** Fun facts are Level 1's alone by
  decision, and these are drawn into the Correct card rather than shown on a
  strip of their own. They stay drawn art with no transcript field, which means
  `verify_content` still requires `fun_fact_transcript` to be empty on Level 3 —
  but it also means these five sentences have no voice-over line and no
  reviewer sign-off. Raise with the teaching-content owner before recording.
- There is **no Oops card for Level 3.** `ui_oops_tool.png` is reused, wording
  and all, on the owner's decision.

### Header and instruction — `levels/level_3/`

| File | Size | Weight |
|---|---|---|
| `ui_header_blank_l3.png` | 1755 x 876 | 1.2 MB |
| `ui_tap_the_correct_answer.png` | 1903 x 289 | 429 KB |

- **`ui_header_blank_l3.png` is a second `HeaderSign` shape**, not the one in
  `ui/common/`. The brown plaque sits *on top of* the cream banner here rather
  than above it, so its two plate rects were measured off this image rather than
  taken from `header_sign.tscn`. Its plaque carries "Stage N" and its banner
  "Identify the Plant Part" on all five stages — decided, so the answer is never
  in the header.
- **Wired** as `scenes/components/header_sign_l3.tscn`, the same `HeaderSign`
  script as Level 2's with its own art and plate rects:

  | Plate | On the 1755 x 876 image | In fractions |
  |---|---|---|
  | plaque, `%Label` | 360-1490 x 210-455 | `(0.2051, 0.2397) - (0.8490, 0.5194)` |
  | banner, `%Title` | 110-1650 x 580-770 | `(0.0627, 0.6621) - (0.9402, 0.8790)` |

  The plaque wood runs 300-1555 x 115-545 and the cream banner 70-1690 x
  567-800; both boxes are inset from those so the text stays off the curved
  ends and the dark outline.

- **Level 3's sign is given 760 px, not Level 2's 660.** "Identify the Plant
  Part" is 557 px wide at the theme's 51 px `HeaderTitle`, against a banner that
  is only 0.8775 of the image wide — 554 px at 660, which does not fit. Widening
  the sign keeps the type the same size as Level 2's rather than shrinking Level
  3's words, and at 760 the sign is 379 px tall and the banner box 666 x 82.
  `tools/verify_live_text.gd` now checks each level's headers against its own
  sign at its own width, and a Level 3 stage scene must give the sign 760 px or
  that check stops describing what ships.
- It is in `levels/level_3/`, not `ui/common/`, because `ui/common/` is art
  *every* level shares and Level 4 ships its own `ui_header_blank_l4.png`.
- **`ui_tap_the_correct_answer.png` replaces the tray's drawn "Choose a Tool".**
  Level 3 has no tray, so this wooden plank is the instruction. Level 4 has its
  own `ui_tap_the_correct_function_card.png`, so it is Level 3's alone despite
  the name carrying no `_l3` suffix.

### How a Level 3 stage is laid out

Measured against `scenes/levels/level_3/stage_1.tscn`, which the other four
copy. At the 1080 x 1920 design resolution:

| Piece | Rect | Notes |
|---|---|---|
| `%Background` | full screen | `KEEP_COVERED`, clipped |
| `%HeaderSign` | 160-920 x 20-399 | 760 wide, the width its banner was fitted at |
| `%PromptBubble` | 58-1022 x **1000-1457** | 964 wide, Level 1's width; **y varies per stage** |
| `TapBanner` | 140-940 x 1478-1600 | 800 wide |
| three cards | y 1610-1900, 260 x 290 | x 90 / 410 / 730, 60 apart |

**The bubble's y is each stage's own decision, and the only thing that moves.**
The glowing part is drawn into each background at a different height, and a
964-wide bubble across it hides the answer. Checked in a full-resolution
composite of all five:

| Stage | Glowing part sits at | Bubble |
|---|---|---|
| 1 leaves | y 450-990 | **low**, y 1000 |
| 2 stem | y 790-1180 | **high**, y 420 |
| 3 roots | y 1080-1400 | **high**, y 420 |
| 4 flower | y 440-600 | **low**, y 1000 |
| 5 fruit | y 790-950 | **low**, y 1000 |

At the low position the bubble sits over the soil beside the sprout mascot,
which reads as the mascot speaking rather than as a panel dropped on the
garden. There is no third position: high and low are the only two, and the
header, banner and cards never move.

### Stage select — `ui/stage_select/`

| File | Size | Weight |
|---|---|---|
| `ui_stage_select_l3.png` | 1609 x 2412 | 2.6 MB |
| `ui_stage_row_1_l3.png` | 1163 x 350 | 381 KB |
| `ui_stage_row_2_l3.png` | 1163 x 344 | 424 KB |
| `ui_stage_row_3_l3.png` | 1181 x 347 | 413 KB |
| `ui_stage_row_4_l3.png` | 1166 x 372 | 402 KB |
| `ui_stage_row_5_l3.png` | 1180 x 356 | 393 KB |

The drawn card with all **five** rows in it, Stage 1 unlocked and 2-5 grey, in
the Level 2 pattern. Its five row drawings are laid over it.

- **These six are the only Level 3 files not cropped to alpha**, and that is
  what made them measurable. Each row's rect is found by matching the row
  against the card; cropping each one by its own alpha — which differs by up to
  18 px between them — would have moved them relative to the card by different
  amounts. They keep the export frames Figma gave them, and **all five matched
  at scale 1.00**, so the rows were exported at the card's own scale.
- The rects were found by **normalised cross-correlation of each row's gradient
  magnitude against the card's**, which ignores the colour difference between a
  coloured row and the grey one painted underneath it. Checked by compositing
  each row back onto the card at its rect: no grey shows anywhere.

  | Row | Rect on the card, in fractions |
  |---|---|
  | 1 | `(0.1361, 0.2090, 0.7228, 0.1451)` |
  | 2 | `(0.1374, 0.3487, 0.7228, 0.1426)` |
  | 3 | `(0.1268, 0.4851, 0.7340, 0.1439)` |
  | 4 | `(0.1355, 0.6177, 0.7247, 0.1542)` |
  | 5 | `(0.1311, 0.7720, 0.7334, 0.1476)` |

  The close disc is `(0.8191, 0.1186, 0.1342, 0.0813)` — 129 x 117 px at a
  960-wide card, under the touch floor, so its hotspot is grown past the drawn
  circle as Level 1's is.

- **The rows' three filled stars have been covered** with `icon_star_empty.png`,
  in the images themselves, so a row starts empty and earned stars are drawn on
  top. Each star's gold core was found, grown by 1.132 x 1.146 — the ratio of
  `icon_star_filled.png`'s full extent to its own gold core, which is how much
  the dark outline adds — and the empty star composited over it. The same rects
  are the scene's `RowNStarM` slots, so a filled star lands exactly where the
  covered one is. Verified in a full-resolution render of the card with all
  fifteen stars filled.
- **Each row is its own colour**, not one colour for unlocked and another for
  locked: green, tan, blue, yellow, purple, top to bottom. The card paints
  Stages 2-5 grey, so `row_art_locked` is empty and a locked row shows the
  card's own painting, as Level 2's does.

### Ending — `ui/screens/`

| File | Size | Weight |
|---|---|---|
| `ui_level_complete_l3.png` | 1121 x 1289 | 1.4 MB |
| `ui_badge_mystery_solver.png` | 1122 x 1389 | 1.8 MB |
| `ui_level_complete_sign_l3.png` | 1056 x 1418 | 1.3 MB |
| `ui_button_grow_now_sign_l3.png` | 777 x 201 | 190 KB |

Cropped to alpha. The sequence is Level 1's with Level 2's numbers: Stage 5 →
`level_complete_l3.tscn` → `badge_unlocked_l3.tscn` →
`level_complete_sign_l3.tscn` → the hub.

- **The badge is decided by its own artwork.** The seven badges in the export
  each name what they are for, so which level gets which is not a choice:
  *Mystery Solver* reads "You found all the parts of a plant!", so it is Level
  3's. *Plant Power-Up* ("the functions of plant parts") and *Super Grower* are
  Level 4's, and *Know to Grow Star* ("You finished the game") is the final
  screen's. Level 3 gets **one** badge, where Level 2 got two.
- **`ui_button_grow_now_sign_l3.png` is cut from the sign**, the same treatment
  as Level 1's and Level 2's pills: the green stadium was found by colour in the
  lower third of `ui_level_complete_sign_l3.png`, cropped at
  `(0.1430, 0.8244, 0.7358, 0.1417)` of the image and masked to its own stadium
  so the leaves behind it are not taken too. Laid back over itself at that same
  rect, so it looks exactly as drawn and only darkens on press — `CardOverlay`
  derives `bounce_art = false` from the rect falling on the card.
- **The Correct card and the badge put their Continue below**, over the dim, so
  those two bounce. The rects are Level 2's scaled by the ratio difference, so
  the button is the same 423 px wide on screen in all of them.
- **All three sit over `bg_stage_5_l3.png`**, the fruiting plant — the thing the
  child has just finished naming. Level 1's ending uses its payoff garden the
  same way; Level 2's uses its intro's instead.

## Level 4 — imported, not wired

Imported from the hand-exported `Know To Grow Assets/Level 4` folder: all 39
files, and **no scene uses them yet**. The badges (*Plant Power-Up*, *Super
Grower*, *Know to Grow Star*) are in the export's `Badges` folder and are left
for the ending, as Level 3's were.

Level 4 is tapped like Level 3, and its question is again carried by the
**background**: the same potted plant each time, with the part being asked
about glowing. The five run roots, stem, leaves, flower, fruit — the stage
order already in `content/level_4_functions.tres`.

### Backgrounds — `backgrounds/`

| File | Size | Weight | Highlights |
|---|---|---|---|
| `bg_stage_1_l4.png` | 852 x 1846 | 2.2 MB | roots, drawn through the pot |
| `bg_stage_2_l4.png` | 852 x 1846 | 1.9 MB | stem |
| `bg_stage_3_l4.png` | 851 x 1849 | 2.0 MB | leaves |
| `bg_stage_4_l4.png` | 852 x 1846 | 2.1 MB | flower |
| `bg_stage_5_l4.png` | 851 x 1849 | 2.1 MB | fruit |

Byte copies, opaque, no crop. All five are the `bg_bed_*` shape, so none has
Level 3 Stage 2's side-crop problem.

### Answer cards — `levels/level_4/`

Fifteen: **three per stage, drawn per stage**, `icon_stage_N_cM_l4` where `cM`
is the card's position A/B/C. Wide function strips — an icon and a sentence —
rather than Level 3's square part cards. Cropped to the drawn card and **kept at source
resolution**: the card slot is not laid out yet, and at ~2120 px they are only
about 2.2x a full-width slot, so there was nothing to gain by guessing one.

| File | Size | Weight | Says |
|---|---|---|---|
| `icon_stage_1_c1_l4.png` | 1982 x 395 | 534 KB | Make food using sunlight. |
| `icon_stage_1_c2_l4.png` | 2032 x 402 | 655 KB | Absorb water and nutrients and hold the plant in the soil. |
| `icon_stage_1_c3_l4.png` | 2012 x 400 | 558 KB | Protect the seeds. |
| `icon_stage_2_c1_l4.png` | 2109 x 417 | 749 KB | Support the plant and carry water and nutrients. |
| `icon_stage_2_c2_l4.png` | 2105 x 418 | 725 KB | Protect the seeds. (apple icon) |
| `icon_stage_2_c3_l4.png` | 2108 x 420 | 766 KB | Make food using sunlight. |
| `icon_stage_3_c1_l4.png` | 2111 x 420 | 769 KB | Hold the plant firmly in the soil. |
| `icon_stage_3_c2_l4.png` | 2107 x 420 | 741 KB | Help make food using sunlight. |
| `icon_stage_3_c3_l4.png` | 2105 x 421 | 718 KB | Protect the seeds. |
| `icon_stage_4_c1_l4.png` | 2106 x 419 | 760 KB | Absorb water from the soil. |
| `icon_stage_4_c2_l4.png` | 2132 x 421 | 745 KB | Help the plant reproduce and make seeds. |
| `icon_stage_4_c3_l4.png` | 2117 x 421 | 813 KB | Carry water to the leaves |
| `icon_stage_5_c1_l4.png` | 2107 x 420 | 741 KB | Help make food using sunlight. |
| `icon_stage_5_c2_l4.png` | 2105 x 421 | 718 KB | Protect the seeds. |
| `icon_stage_5_c3_l4.png` | 2106 x 419 | 760 KB | Absorb water from the soil. |

- **All fifteen are the same 5:1 shape.** Stages 2-5 were exported with
  100-170 px of near-invisible haze (alpha under 32) around the card, which a
  plain alpha crop kept, so they looked 3.3:1 and drew a third smaller than
  Stage 1's in the same slot. They are cropped at alpha 32, to the drawn edge,
  as the header was.
- **Stage 5's cards are Stage 3's and Stage 4's files again**, byte for byte
  (`s5_c1` = `s3_c2`, `s5_c2` = `s3_c3`, `s5_c3` = `s4_c1`).
  Kept as separate files so each stage owns its three, as the export names them.
- **Every card's text and order agree with the content file, except two.**
  The option `fn_make_food` is drawn *"Make food using sunlight."* on Stages 1
  and 2 but *"Help make food using sunlight."* on 3 and 5, while the content
  has one shared label, "Help make food…". And Stage 4's *"Carry water to the
  leaves"* has no full stop. Both are transcript bookkeeping for when the
  stages are built, under the Figma-wins rule — the first one means splitting
  a shared option.

### Feedback cards — `levels/level_4/`

Cropped to alpha. Each names its match by letter and carries a Reinforcement
Fact, both drawn in, with **no Continue drawn on the card** — Level 3's
pattern, so Continue goes below it.

| File | Size | Weight | Says |
|---|---|---|---|
| `ui_correct_l4_s1.png` | 1106 x 1291 | 1.4 MB | Correct Match: B — "Roots hold the plant in the soil and absorb water and nutrients." |
| `ui_correct_l4_s2.png` | 1106 x 1341 | 1.4 MB | Correct Match: A — "The stem supports the plant and helps move water and nutrients to different parts." |
| `ui_correct_l4_s3.png` | 1106 x 1341 | 1.4 MB | Correct Match: B — "Leaves use sunlight to help the plant make its own food." |
| `ui_correct_l4_s4.png` | 1106 x 1341 | 1.4 MB | Correct Match: B — "Flowers help plants reproduce and produce seeds for new plants." |
| `ui_correct_l4_s5.png` | 1106 x 1351 | 1.3 MB | Correct Match: B — "Fruits protect the seeds inside and help them develop." |

- **The letters are drawn in, so the cards cannot be shuffled.** A Level 4
  stage must keep its cards in A/B/C order, or "Correct Match: B" points at the
  wrong card. That is the one thing that does not carry over from Level 3,
  whose cards are always shuffled. The letters do match the `cM` positions and
  each challenge's `correct_option_id`.
- No Oops card; `ui_oops_tool.png` is reused, as for Level 3.

### Header and instruction — `levels/level_4/`

| File | Size | Weight |
|---|---|---|
| `ui_tap_the_correct_function_card.png` | 2066 x 241 | 426 KB |

- **Level 4's blank header was removed: it is `ui/common/ui_header_blank.png`.**
  Delivered as `ui_header_blank_l4.png`, 1672 x 890, but only y 169-732 is sign;
  the rest was an alpha-under-32 haze the import's crop kept. Cropped to the
  sign and scaled to 900 wide, it matches the shared blank pixel for pixel, so
  Level 4 uses `header_sign.tscn` at Level 2's 660 px with no plate rects of its
  own. Its wording, "Stage N" / the part, is in the content file and checked
  by `verify_live_text`.
- The plank reads "Tap the correct function card." and replaces Level 3's
  "Tap the correct answer."

### How a Level 4 stage is laid out

Measured against `scenes/levels/level_4/stage_1.tscn`, which the other four
copy, and checked first in a full-resolution composite of all five. At the
1080 x 1920 design resolution:

| Piece | Rect | Notes |
|---|---|---|
| `%Background` | full screen | `KEEP_COVERED`, clipped |
| `%HeaderSign` | 210-870 x 20-245 | Level 2's sign at its 660 px |
| `TapBanner` | 90-990 x 255-360 | straight under the header |
| `%PromptBubble` | 58-1022 x **370-827** or **885-1342** | 964 wide; **y varies per stage** |
| three cards | 90-990 x 1350-1525 / 1540-1715 / 1730-1905 | A, B, C; never shuffled |

**The plank is under the header, not above the cards** as in Level 3. Three
stacked 5:1 cards at 900 wide need the bottom 560 px, and Stage 1's roots are
drawn inside the pot down to y 1305, so nothing else fits between them.

| Stage | Glowing part sits at | Bubble |
|---|---|---|
| 1 roots | y 960-1305, in the pot | **high**, y 370 |
| 2 stem | y 360-900 | **low**, y 885 |
| 3 leaves | y 420-900 | **low**, y 885 |
| 4 flower | y 300-570 | **low**, y 885 |
| 5 fruit | y 315-555 | **low**, y 885 |

The Correct cards are 1106 wide and about 0.86 in shape, so at the overlay's
900 px a card is ~1050 tall and Continue is `Rect2(0.265, 1.06, 0.47, 0.1606)`
— the same 423 x 169 px on screen as Level 3's.

### Stage select — `ui/stage_select/`

| File | Size | Weight |
|---|---|---|
| `ui_stage_select_l4.png` | 1656 x 2481 | 4.3 MB |
| `ui_stage_row_1_l4.png` | 1244 x 397 | 717 KB |
| `ui_stage_row_2_l4.png` | 1202 x 356 | 691 KB |
| `ui_stage_row_3_l4.png` | 1225 x 416 | 754 KB |
| `ui_stage_row_4_l4.png` | 1202 x 381 | 737 KB |
| `ui_stage_row_5_l4.png` | 1247 x 400 | 710 KB |

"Level 4 / Functions", Stage 1 green, 2-5 painted grey — the Level 2 and 3
pattern, so `row_art_locked` will be empty. **Byte copies, not cropped**, so the
rows can be matched against the card the way Level 3's were. Their drawn stars
are not covered yet; that happens with the stage select, not here.

### Hub plants — `plants/`

| File | Size | Weight |
|---|---|---|
| `plant_leafy_with_flower.png` | 1317 x 1746 | 1.6 MB |
| `plant_leafy_with_flower_and_fruit.png` | 1320 x 1722 | 1.8 MB |

The hub's fourth and fifth plant states: flowering, then flowering with a
tomato. Cropped to alpha. **`plant_leafy_with_flower` is wired** as the hub's
fourth `plant_stages` entry, "FLOWER", shown once Level 3 is cleared. It is
taller in proportion than the sprout (0.75 against 0.88), so in the hub's
`KEEP_ASPECT` slot it draws at the same height and about 70 px narrower.

### Ending and game completion — `ui/screens/`

| File | Size | Weight |
|---|---|---|
| `ui_level_intro_l4.png` | 1109 x 1325 | 1.4 MB |
| `ui_level_complete_l4.png` | 1121 x 1266 | 1.5 MB |
| `ui_level_complete_sign_l4.png` | 1037 x 1416 | 1.5 MB |
| `ui_game_completion.png` | 1087 x 1330 | 1.7 MB |

Cropped to alpha. The intro reads "Level 4 / Plant power time!", and is
**wired** as `scenes/ui/level_intro_l4.tscn` at its own card ratio, 0.837; Level 4
Complete "Plant powers unlocked!"; the sign "You Completed Level 4!" with Grow
Now painted on it, which will need its pill cut as Levels 1-3's were. The game
completion card, "Hooray! You did it!", is the finished-game screen and is
not Level 4's alone.

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

**Fredoka One** is the game's only typeface: `res://assets/fonts/fredoka_one/
fredoka_one_regular.ttf`, set as `default_font` in `themes/ktg_theme.tres`, so
every `Label` and `Button` in every scene uses it. SIL Open Font License 1.1 —
`OFL.txt` sits beside the font and must ship with it.
