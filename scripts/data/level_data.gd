class_name LevelData
extends Resource

## A whole level: framing text plus an ordered list of challenges.
## One .tres file per level lives in res://content/.

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var instruction: String = ""

@export var challenges: Array[ChallengeData] = []

## Randomise challenge order on each play (keep false for Level 1 - planting
## is a real-world sequence and must stay in order).
@export var shuffle_challenges: bool = false

## Randomise the on-screen position of the options. Keep this TRUE for Level 3,
## where the scripted answers sit at B, A, C, A, B - children memorise
## positions faster than they learn content.
@export var shuffle_options: bool = true

@export_multiline var completion_message: String = "Great job!"
@export_multiline var final_fun_fact: String = ""

## Scene to load after this level (a video screen, the next level, the map).
@export_file("*.tscn") var next_scene_path: String = ""
