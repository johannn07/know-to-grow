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

### The open problem with these

**Most of them have their English text baked into the pixels.** A fun-fact
banner is not a frame plus a string — it is one flat drawing with the sentence
already rendered in it. The same is true of the stage headers, the feedback
cards and several buttons.

That collides with the data-driven design in `content/*.tres`, where every
prompt, hint and fun fact lives as editable text — two sources of truth for the
same sentence, which will drift.

It would also rule out Filipino localisation and complicate spoken prompts. Note
that neither of those is a stated requirement: the design document says nothing
about translation or spoken instructions beyond one "friendly voice/text" line on
wrong answers. Both come from the setup guide as proposals. How much they matter
is the project owner's call, not an assumption to build on.

This needs a decision before any of the level art is wired up. See `checklist.md`.

## Fonts

The game currently uses Godot's default font. The Figma artwork uses a chunky
rounded display face. Drop a licensed `.ttf` in `res://fonts/` and set it once in
`themes/ktg_theme.tres` — every screen follows.
