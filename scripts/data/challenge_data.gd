class_name ChallengeData
extends Resource

## One "turn" of the game. Every stage in all four levels fits this shape:
##   show a prompt -> learner picks/drags one of N options -> right or wrong.
## Levels differ only in presentation, not in logic.

enum Interaction {
	TAP,           ## Level 3: tap an answer card.
	DRAG_TO_ZONE,  ## Levels 1, 2, 4: drag an item onto a target area.
}

@export var id: StringName = &""
@export_multiline var prompt: String = ""
@export var interaction: Interaction = Interaction.DRAG_TO_ZONE

@export var options: Array[OptionData] = []
@export var correct_option_id: StringName = &""

## Extra answers that should also count as correct (e.g. Level 2 situation 3
## is fair to solve with either "Watering Can" or "Water").
@export var alternate_correct_ids: Array[StringName] = []

@export_multiline var fun_fact: String = ""

## Which drop zone accepts the answer: "soil", "plant", "roots", "stem"...
@export var zone_id: StringName = &"main"

## Which visual state the scene should show: "empty_bed", "hole_dug",
## "dry_soil", "brown_leaves", "highlight_roots"... The art team maps
## one image (or one animation) to each of these strings.
@export var scene_state: StringName = &""

## Optional: art/animation to play after a correct answer ("hole_dug",
## "seed_covered", "sprout"). Leave empty if the state change is enough.
@export var success_state: StringName = &""


func get_option(option_id: StringName) -> OptionData:
	for option in options:
		if option.id == option_id:
			return option
	return null


func is_correct(option_id: StringName) -> bool:
	return option_id == correct_option_id or option_id in alternate_correct_ids
