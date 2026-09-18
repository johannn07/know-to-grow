# Know To Grow — locked decisions

The settled questions, so they stay settled. If something here is being
re-argued, either the argument is new information — in which case change this
file in the same commit as the code — or it is a question that was already
answered.

**This file is not the plan.** `checklist.md` is the build state,
`SESSION_NOTES.md` is the narrative, and `CLAUDE.md` is how to work in the repo.
Anything still undecided lives in those, under **⚠**, and deliberately not here.

Last reviewed 2026-09-18.

---

## What it is

An educational mobile game for ages ~5–9 about planting, caring for and naming
the parts of a plant. Android first. Offline. Free of accounts, ads and
analytics.

**Four levels, 19 stages, one mechanic.** Show a prompt, the learner picks one
of N options, it is right or it is wrong.

| Level | Theme | Stages | What is settled about how it plays |
|---|---|---|---|
| 1 | Planting | 4 | drag an item from the blank tray onto the soil, cards shuffled; fixed stage order |
| 2 | Monitoring | 5 | the blank tray, cards shuffled, and a `Score: 0/5` that only goes up |
| 3 | Identifying | 5 | multiple choice, no tray, options shuffled |
| 4 | Functions | 5 | matching a plant part to its function; needs more than one drop zone |

## Platform and presentation

| Decision | Value | Enforced in |
|---|---|---|
| Design resolution | 1080 × 1920 | `project.godot` `display/window/size` |
| Orientation | portrait, locked | `handheld/orientation=1` |
| Stretch | `canvas_items` + `expand` | `display/window/stretch` |
| Renderer | Mobile | `renderer/rendering_method="mobile"` |
| Window resizable | no | `window/size/resizable=false` |
| Package name | `com.johannn.ktg` | `export_presets.cfg` |
| Architecture | `arm64-v8a` only | `export_presets.cfg` |
| Android SDK | `min_sdk` 24, `target_sdk` 34 | `export_presets.cfg` |
| Engine | Godot 4.7.2 | `config/features` |

`expand` means the extra room on a tall phone or a 4:3 tablet is real screen,
not letterboxing, so a layout has to stay harmless at both ends.

## Privacy and data

- **No accounts.** Nothing to sign into, nothing to name, nothing to recover.
- **No analytics, no ads, no telemetry, no crash reporting.**
- **No network.** `permissions/custom_permissions` is empty and no Android
  permission is enabled, so the app cannot reach the internet even by accident.
  The game is fully playable offline because it is only ever offline.
- **Progress is one local file:** `user://progress.cfg`, a plain-text
  `ConfigFile` holding one number per stage — the stars earned, `0` for never
  finished. Nothing else is stored, and nothing leaves the device.
  (`scripts/core/game_state.gd`)

Everything the game knows is derived from those numbers: whether a stage is
unlocked, whether a level is done, what the hub counts.

## Progression

- **Play always opens the stage select** and the child picks a stage. Not
  resume, not restart. Resume falls out of it, since cleared rows stay
  unlocked.
- **A stage unlocks when the stage before it is cleared.**
- **Stars are scored by attempts** — three for right first time, two on the
  second, one after that. *Owner's decision, and it sits against the design
  document's "no penalties" for Level 1; the teaching-content owner has not yet
  signed it off.*
- **Stars are never taken away.** A replay can only raise them.
- **Badges are fixed per level, not earned by performance.** Level 1 always
  unlocks *Little Planter*.
- **Level 1 plays in fixed order** — planting is a real-world sequence. The
  cards within a stage are shuffled every play, on Levels 1 and 2 alike.

### The sequence a level runs through

```
Hub → Level overlay → Stage select → Stages 1-4 → Level Complete overlay
    → Badge Unlocked overlay → "You completed Level N" overlay
    → Hub, "Click Me" on the plant → Hub, plant grown
```

## Handling a wrong answer

From the design document, stated for both Level 1 and Level 4:

- **No penalties and no "Wrong" label.** A wrong choice bounces gently back with
  a friendly hint and the child retries.
- A wrong card **greys out rather than disappearing**, so the tray never empties.
- A friendly line on a wrong answer — "Oops, let's try again!" The document says
  "voice/text", so audio is permitted here, not mandated.

## Text and language

- **English only. Filipino is not shipping.** The artwork carries English text
  drawn into the pixels, so translating would mean re-rendering every banner.
  Revisit only as a deliberate, costed project.
- **The artwork carries the words.** Prompt banners, stage headers, feedback
  cards and several buttons have their wording drawn in. That is the design.
- **`content/*.tres` holds transcripts, not display strings** —
  `prompt_transcript`, `fun_fact_transcript` and the rest. They exist so the
  wording stays greppable, diffable and reviewable, and so it can be recorded as
  voice-over. They are never drawn on screen.
- **One exception: the prompt.** Every prompt, Levels 1–4, is live text laid over
  the blank shared bubble `assets/art/ui/common/ui_prompt_bubble.png`, so a
  prompt can change without re-rendering art. `prompt_transcript` is the one
  transcript that is rendered.
- **Art that already has words drawn in stays as it is.** Do not rebuild an
  existing image as live text.
- **Fredoka One is the only typeface**, set once as `default_font` in
  `themes/ktg_theme.tres`. SIL Open Font License; keep `OFL.txt` beside it.
- **Voice-over is planned** — every spoken line has a `*_vo_key`, and audio will
  live at `res://assets/audio/vo/en/<key>.ogg`.

## Audio

Three buses, defined in `default_bus_layout.tres` and routed by the
`AudioDirector` autoload: **Music**, **SFX**, **VO**.

Music is per-context and continuous across scene changes — one track outside a
level, one per level — so walking hub → level overlay → stage select does not
restart it.

## Sources of truth

1. **`Untitled.fig` is the prototype and it wins.** Where a prompt, an item name
   or a fun fact is worded differently in the artwork, the artwork is right and
   the transcript is updated to match, in the same change.
2. `Know To Grow.pdf` is the earlier teaching brief. It still owns the teaching
   intent — level structure, what each stage teaches, the no-penalties rule.
3. This file, for anything neither of them says.

Correcting a transcript to match art is bookkeeping, not a design change,
because transcripts are never rendered. Changing *wording* is a design change:
it means re-rendering art and re-recording a line.

## Build-time constraints that shape the code

- **Art arrives after the screen is built.** Every image position is an
  `ArtSlot`, which draws a labelled colour block at the final size until a
  texture is assigned. Sizes come from the layout, never from the image, so real
  art can never shift a finished screen. No stock or CC0 art in the repo as a
  stand-in.
- **Stages are hand-built scenes**, one `.tscn` and one script each, so a stage
  can be opened in the editor and rearranged. Shared behaviour — the drag, the
  feedback card, the hotspot sizing, the wrong-card rule — lives once in
  `StageScreen`.
- **The garden backgrounds are five independent drawings, not one scene in five
  states.** They cannot be cross-faded or swapped mid-stage, which is why a
  stage's garden only changes at a stage boundary.
