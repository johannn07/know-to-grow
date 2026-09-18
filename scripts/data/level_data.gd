class_name LevelData
extends Resource

## A whole level: framing plus an ordered list of challenges. One .tres file per
## level lives in res://content/.
##
## As with [ChallengeData], the text fields here are transcripts of what the
## artwork says, not strings the game draws.

@export var id: StringName = &""

## The level's name as drawn on its art. Transcript only.
@export var title: String = ""

@export var challenges: Array[ChallengeData] = []

## Randomise challenge order on each play. Keep this false for Level 1 —
## planting is a real-world sequence and must stay in order.
@export var shuffle_challenges: bool = false

## Randomise where the options appear. Keep this TRUE for Level 3, whose
## scripted answers sit at B, A, C, A, B; children memorise positions faster
## than they learn content.
@export var shuffle_options: bool = true

## Scene to load after this level — a video screen, the next level, the map.
@export_file("*.tscn") var next_scene_path: String = ""

@export_group("Art")
@export var title_art: Texture2D
@export var completion_art: Texture2D

@export_group("Transcript")
## Never rendered. See [member ChallengeData.prompt_transcript].
@export_multiline var instruction_transcript: String = ""
@export_multiline var completion_transcript: String = "Great job!"
@export_multiline var final_fun_fact_transcript: String = ""

@export_group("Voice-over")
@export var instruction_vo_key: StringName = &""
@export var completion_vo_key: StringName = &""
@export var final_fun_fact_vo_key: StringName = &""


## The challenge with this id, or null. A stage uses it to find its own
## transcripts by its [member StageScreen.challenge_id].
func get_challenge(challenge_id: StringName) -> ChallengeData:
	for challenge in challenges:
		if challenge.id == challenge_id:
			return challenge
	return null
