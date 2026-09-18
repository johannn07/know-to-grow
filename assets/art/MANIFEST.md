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
| `ui_tray_l1_s4.png` | 1000 x 462 | 535 KB |
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

Levels 3 and 4 therefore have **no stage select card yet**. Level 2's situation
select is `ui_situation_select_l2.png`. A drawn card per level, rows included,
is what those two need — not a blank one.

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

## Tool trays — delivered

| File | Size | Weight |
|---|---|---|
| `ui_tray_l1_s1.png` | 1000 x 476 | 522 KB |
| `ui_tray_l1_s2.png` | 1000 x 487 | 504 KB |
| `ui_tray_l1_s3.png` | 1000 x 470 | 549 KB |
| `ui_tray_l1_s4.png` | 1000 x 462 | 535 KB |

Each stage's "Choose a Tool" tray, with its three items **drawn into it**. The
draggable cards are anchored exactly over those drawn slots, so the tray reads
as one picture until a card is lifted — and then the drawn item underneath shows
through, which is what marks the slot the card came from.

Two things follow, and both are easy to break by accident:

- **The cards must stay in the same order as the items in the tray.** Stage 2's
  tray is Leaf / Seed / Rock, so its cards are in that order and not the order
  the content file happens to list them in. Reordering the cards in the editor
  would leave them sitting over the wrong labels. Each stage script says so at
  the top.
- **A resting card draws nothing.** The tray already has that item painted into
  it, at exactly the right size and place, so the card is only a hit area until
  it is picked up. Drawing both produced a rim inside a rim: the standalone
  cards carry thicker frames than the tray's drawn slots, and by different
  amounts per family — `icon_sun` and `icon_gloves` have noticeably chunkier
  frames than `icon_shovel` — so no single scaling lines them all up. Not
  double-drawing is exact by construction, and it holds for every stage.
  A card that has no artwork yet stays visible, so a missing asset is still a
  labelled blank rather than an invisible one.

A card becomes visible only while it is being dragged. An option that has been
tried and was wrong is marked by **tinting its slot** — a rounded translucent
panel at exactly the card's rect, which is the slot — rather than by putting the
greyed card back over it, which would reintroduce the same frame mismatch.

The slot rectangles are measured off each tray rather than estimated; the
measuring script lives beside the generated scenes' history in the commit that
introduced them, and the numbers are baked into the scenes as anchors.

Option shuffling is gone as a result: a card's position is fixed by the picture
behind it. That only ever mattered for Level 3, which is multiple choice and has
no tray.

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
| `ui_button_grow_now.png` | 1368 x 438 | 569 KB | "Grow Now" button, text drawn in |
| `ui_situation_select_l2.png` | 1535 x 2287 | 2.5 MB | Level 2 Monitoring card, Situation 1 unlocked, 2–5 locked |
| `ui_situation_row_1..5.png` | ~1110 x 330 | ~380 KB each | unlocked Situation rows, one colour each, three filled stars |
| `ui_level_intro_l2.png` | 1110 x 1373 | 1.4 MB | "Level 2 — Uh-oh! Your plant needs you!" |
| `ui_level_complete_l2.png` | 1122 x 1336 | 1.4 MB | "Level 2 Complete! You saved the plant!" |
| `ui_badge_plant_helper.png` | 1122 x 1388 | 1.8 MB | "Plant Helper" badge, Level 2's counterpart to Little Planter |
| `ui_level_complete_sign_l1.png` | 1072 x 1379 | 1.3 MB | signpost, "You Completed Level 1!" with a Grow Now button drawn in |
| `ui_header_l2_s1.png` | 900 x 314 | 298 KB | "Situation 1 — Hard and Dry Soil" |
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
  which all 19 prompts fit. `tools/verify_prompt_bubble.gd` enforces it.
- The Figma holds this bubble at **1774 x 887**, if it ever needs to be sharper.

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
- **Situations 2–5 have no header.**
- **The blank bubble is decided: it is the prompt for every stage, Levels 1–4**,
  with the words set as live text in Fredoka One. See `CLAUDE.md`.
- The situation rows are all drawn **unlocked with three filled stars**, and
  there are no locked versions except as they appear inside
  `ui_situation_select_l2.png`. Level 1 needed `tools/build_stage_rows.py` for
  the same gap.

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
