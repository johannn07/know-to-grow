# Session notes

A running log of what changed and why, for picking work back up. `checklist.md`
is the build state; this is the narrative behind it. Newest session first.

---

## 2026-09-15/16 — Level 1 built end to end

**Where it got to:** the whole of Level 1 plays. Menu → hub → Stage 1 → 2 → 3 →
4 → back to the hub. Verified headless, not yet on a phone.

### What was built

- **Hub screen** (`scenes/ui/hub.tscn`) — the screen between the menu and a
  level. Greeting, star count, the plant's stage on a sign, and the play button.
  Star count and plant stage are Inspector placeholders; there is no `GameState`
  to persist them. The three bottom tabs (Lessons / Garden / Badges) are drawn
  but `disabled`, because they have nowhere to go.
- **Level 1, all four stages** — Dig the Hole, Drop the Seed, Water the Soil,
  Give Sunlight. Drag an item onto the soil; right or wrong; feedback card;
  Continue. No wording was written by hand anywhere: every word on screen is
  drawn into the artwork, straight from `Untitled.fig`.
- **`StageScreen`** (`scripts/levels/stage_screen.gd`) — the shared drag,
  feedback card, hotspot sizing and wrong-card rule that every stage extends.
- **`tools/verify_level_1.gd`** — walks the stage chain and plays each stage
  headlessly: a drop away from the target, a wrong answer, a right answer.

### Decisions taken (and who took them)

| Decision | Who |
|---|---|
| Hub sits between menu and level; its button names the level rather than repeating "Start Game" | owner |
| Options are separate draggable cards, tap-then-drag, per the design document | owner |
| The Figma prototype outranks `Know To Grow.pdf` when they disagree | owner |
| "Seed", not "Seed Packet" | follows from the above |
| Stage 4 reuses Level 2's "Correct Answer! / Sunlight" card | owner |
| Stage scenes are hand-owned, one folder per level | owner |
| A stage's garden never changes while the stage is on screen | owner |

### Things that turned out to be true about the artwork

These cost time to discover and are worth not rediscovering:

- **The garden backgrounds are independent drawings, not one scene in five
  states.** Diffing `bg_bed_empty` against `bg_bed_hole` lights up the entire
  frame — every cloud, tree and fence post moves, and they are different pixel
  sizes. They can never be cross-faded or swapped mid-stage. This is why the
  garden now only changes at a stage boundary.
- **The item cards carry thicker frames than the slots drawn into the tray, by
  different amounts per art family.** No scaling aligns them all. Hence a
  resting card draws nothing and the tray's own art shows through; the card
  appears only while dragged, and a tried option tints its slot instead.
- **Only three Level 1 "Correct Answer!" cards exist** — shovel, seed, watering
  can. There is none for Sun, and Level 2's cards carry no Continue button.
- **Two stages' wording differs between the artwork and the PDF** (Stage 2's
  prompt, Stage 4's fun-fact comma). Both transcripts were corrected to the art.
  Expect more; keep the list for the teaching-content owner.

### Corrections made to earlier work

- `OptionCard.return_home()` was leaving `top_level` without restoring the local
  position, so a returning card landed a screen-height below its row and looked
  deleted.
- The hub's `_ready()` aborted partway when a label was removed in the editor,
  which left the play button unconnected and the screen with no exit.
- Feedback hotspots are now padded to 160 px **in code** rather than by
  hand-tuned offsets, which is how How To Play's silently fell under the floor.

---

## Still in progress / next steps

Ordered by what unblocks the most.

1. **Play it on a phone.** Everything so far is verified headless. Headless
   cannot tell you whether a drag feels right or whether a five-year-old can
   hit the cards. This is the highest-value next action and nothing else
   substitutes for it.
2. **Level 1 completion beat.** Stage 4 currently returns to the hub. The art is
   drawn and unused: `[107]` "Level 1 Complete!", the `[116]` "Little Planter"
   badge, and `bg_bed_sprout.png` — which is the payoff of the level and is
   currently shown nowhere.
3. **How To Play's two failing checks.** `verify_menu_flow.gd` has failed since
   commit `3bc00a4`: `%LetsGoButton` is 510x154 and `%BackButton` 142x136,
   both under the 160 px floor. The offsets in that commit look like an
   accidental drag in the editor (`offset_top = 11.992004`). Two lines to fix,
   but it is someone's edit, so it has been left alone.
4. **Levels 2, 3 and 4.** The mechanic is built and the stage pattern is
   established, so these are mostly art extraction and wiring. Level 3 is
   multiple choice with no tray, and is the one level whose options can be
   shuffled.
5. **`GameState`.** Needed before the hub's star count or plant stage mean
   anything, and before "Start Game" can resume rather than restart.

## Open questions for the project owner

- The Oops card says *"That's not the right tool."* — but Stage 2's wrong
  answers are a rock and a leaf. One card is shared by all four stages.
- Stage 4's Correct card is visibly a different style from the other three, and
  Level 1 ends on a garden in a different framing (`bg_bed_sprout.png` is a
  close-up behind a white fence, not the raised bed). Both are art gaps, not
  bugs.
- The Correct cards carry a paragraph of explanation that exists nowhere in
  `content/*.tres`. The transcript model says every drawn word should be
  greppable and recordable; these are not. That would be a `correct_transcript`
  field.

## Housekeeping

- `CLAUDE.md`'s project layout still says `art/`; art and audio moved to
  `assets/` in `66c2429`. The Godot side survived the move — all UID references
  resolved and every suite still passes — but the doc is now wrong.
- `README.md` is stale in full: it describes the original starter kit and names
  `game_state.gd`, `audio_director.gd`, `drop_zone.gd` and `build_content.gd`,
  none of which have existed for some time.
- Music tracks are sitting untracked in `assets/audio/music/`. Nothing plays
  them yet — there is no `AudioDirector`.

## Verification state at the end of this session

| Check | Result |
|---|---|
| Project loads | clean |
| `verify_level_1.gd` | PASS |
| `verify_content.gd` | PASS — 19 challenges, 76 voice-over lines |
| `verify_menu_flow.gd` | **FAIL — 2**, both pre-existing (see step 3 above) |
