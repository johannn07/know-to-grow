# Art manifest — Know To Grow

Every image the game expects, with the exact size it will be drawn at. This is
the brief for the artist and the checklist for whoever drops the files in.

Until a file exists, an [`ArtSlot`](../scripts/ui/art_slot.gd) draws a labelled
colour block at the same size. **Dropping in real art is an Inspector action,
not a code change** — select the node, set its `texture`, done. Nothing resizes,
nothing moves.

## Rules

- **Design resolution is 1080 × 1920.** Every pixel size below is at that scale.
- **PNG, transparent background**, unless the row says otherwise.
- **`snake_case` filenames**, category prefix, no spaces, no version numbers.
  `item_shovel.png`, not `Shovel v2 FINAL.png`.
- **Colour is never the only signal.** Roughly one boy in twelve has a colour
  vision deficiency, so shape and label always carry the meaning too.
- Backgrounds may bleed past their slot — they are drawn `KEEP_COVERED` and
  clipped, so a taller phone shows more scenery rather than a stretched image.

## Main menu — `scenes/ui/main_menu.tscn`

| Slot name | File | Size | Notes |
|---|---|---|---|
| `bg_sky` | `bg_sky.png` | 1080 × 1920 | Opaque. Drawn behind everything; safe to crop top and bottom. |
| `bg_hills` | `bg_hills.png` | 1080 × 1180 | Bottom-anchored. Foliage and fence line. |
| `bg_ground` | `bg_ground.png` | 1080 × 300 | Bottom-anchored. Grass and soil strip. |
| `logo` | `logo.png` | 940 × 470 | The "Know To Grow" wordmark. Transparent. |
| `mascot_sprout` | `mascot_sprout.png` | 330 × 390 | Bottom-left potted sprout. |
| `mascot_flower` | `mascot_flower.png` | 380 × 450 | Bottom-right flowering plant. |
| — | `fx_leaf.png` | 64 × 64 | Falling leaf. Goes on the `LeafParticles` node's `texture`, not an ArtSlot. |

Shared by `how_to_play.tscn` and `level_select_stub.tscn`: both reuse `bg_sky`.

## Still to be specified

The screens below do not exist yet, so their slots are not final. The counts
come from the design document and are good enough to brief an artist against;
confirm the exact sizes when the screens are built.

| Group | Items | Count |
|---|---|---|
| Item icons (512 × 512) | shovel, watering can, pruning shears, gloves, seed packet, seed, flower, sunlight, water, fertilizer, sun, cloud, moon, rock, leaf | 15 |
| Level 1 stages (1080 × ~1300) | empty bed, hole dug, seed covered, soil watered, sprout | 5 |
| Level 2 stages (1080 × ~1300) | hard/dry soil, brown leaves, thirsty, low light, undernourished | 5 |
| Hero plant (layered) | one plant showing roots, stem, leaves, flower and fruit at once | 1 |
| Part highlights | a glow/outline overlay per part | 5 |
| UI | card frame (4 states), button frame (3 states), popup frame, score chip, star, arrow hint, sparkle, confetti, home/sound/back icons | ~15 |

Two notes worth settling early:

1. **The sun appears twice** — as a sky object in Level 1 and as a "basic need"
   card in Level 2. Decide whether that is one drawing or two.
2. **The hero plant carries Levels 3 and 4 on its own.** Ask for it as a layered
   file so the parts can be highlighted and animated separately.

## Fonts

The game currently uses Godot's default font. The reference art uses a chunky
rounded display face for the logo and buttons. Drop a licensed `.ttf` in
`res://fonts/` and set it once in `themes/ktg_theme.tres` — every screen follows.
