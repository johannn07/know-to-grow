class_name ChallengeData
extends Resource

## One "turn" of the game. Every stage in all four levels fits this shape:
## show a prompt, the learner picks or drags one of N options, it is right or
## wrong. The levels differ in presentation, not in logic.
##
## Wording lives here only as a transcript. The prompt the learner actually
## reads is drawn into [member prompt_art]; see art/MANIFEST.md.

enum Interaction {
	TAP, ## Level 3: tap an answer card.
	DRAG_TO_ZONE, ## Levels 1, 2 and 4: drag an item onto a target area.
}

@export var id: StringName = &""
@export var interaction: Interaction = Interaction.DRAG_TO_ZONE

@export_group("Logic")
@export var options: Array[OptionData] = []
@export var correct_option_id: StringName = &""

## Extra answers that also count. Level 2's "the soil is dry and the plant needs
## a drink" is solved equally well by the watering can or by water, and both are
## on screen.
@export var alternate_correct_ids: Array[StringName] = []

## Which drop zone accepts the answer: "soil", "plant", "roots", "stem"...
@export var zone_id: StringName = &"main"

## Which visual state the scene should show before the answer: "empty_bed",
## "hole_dug", "dry_soil", "highlight_roots"...
@export var scene_state: StringName = &""

## Optional state to play after a correct answer. Leave empty when advancing to
## the next challenge's [member scene_state] is enough.
@export var success_state: StringName = &""

@export_group("Art")
## The "Stage 1 — Dig the Hole" style header.
@export var header_art: Texture2D
## The prompt banner, with the question already drawn on it.
@export var prompt_art: Texture2D
## The fun-fact banner shown after a correct answer.
@export var fun_fact_art: Texture2D

@export_group("Transcript")
## What [member prompt_art] says. NEVER RENDERED — this is the voice-over script
## and the text a content reviewer signs off on.
@export_multiline var prompt_transcript: String = ""
## What [member fun_fact_art] says. Never rendered.
@export_multiline var fun_fact_transcript: String = ""

@export_group("Voice-over")
@export var prompt_vo_key: StringName = &""
@export var fun_fact_vo_key: StringName = &""


func get_option(option_id: StringName) -> OptionData:
	for option in options:
		if option.id == option_id:
			return option
	return null


func is_correct(option_id: StringName) -> bool:
	return option_id == correct_option_id or option_id in alternate_correct_ids
