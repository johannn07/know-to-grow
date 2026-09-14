# Know to Grow — starter kit

Drop these into a fresh Godot 4 project. Everything runs with **zero art assets**.

```
res://
├── scripts/
│   ├── data/    option_data.gd  challenge_data.gd  level_data.gd
│   ├── core/    game_state.gd  audio_director.gd
│   └── ui/      option_card.gd  drop_zone.gd  challenge_screen.gd
└── tools/       build_content.gd
```

## 5-minute setup

1. Copy the `scripts/` and `tools/` folders into your project.
2. **Project → Project Settings → Globals → Autoload**, add in this order:
   - `res://scripts/core/game_state.gd` → node name `GameState`
   - `res://scripts/core/audio_director.gd` → node name `AudioDirector`
3. Open `tools/build_content.gd` in the script editor and press **File → Run**
   (`Ctrl+Shift+X`). It writes `res://content/level_1..4.tres`.
4. New scene → root node `Control` → attach `scripts/ui/challenge_screen.gd`.
   In the Inspector, set **Level** to `res://content/level_1_planting.tres`.
5. Save as `res://scenes/challenge_screen.tscn`, press F5, pick it as the main
   scene. You now have a playable grey-box of Level 1. Swap the `Level` property
   to play levels 2, 3 and 4 — no other change needed.

`.gitignore` and `.gitattributes` in this folder go at the repo root.

## What to change when art arrives

| Then | Do this |
|---|---|
| Item icons | Set `icon` on each `OptionData` in the `.tres`. Placeholders vanish automatically. |
| Illustrated stages | Replace `ChallengeScreen._build_stage_area()` with a real scene; place a `DropZone` over each interactive area and set its `zone_id`. |
| Audio | Drop files into `res://audio/sfx/<key>.ogg` and `res://audio/vo/en/<key>.ogg`. `AudioDirector` picks them up with no code change. |

Nothing in `game_state.gd`, `challenge_data.gd` or the answer-checking logic
should need to change because of art.
