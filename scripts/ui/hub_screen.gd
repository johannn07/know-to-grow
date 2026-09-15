extends SubScreen

## The hub: the screen between the main menu and a level.
##
## It shows who is playing, what their plant has grown into so far, and the one
## level that is next. The three tabs along the bottom are part of the drawn
## design but have nowhere to go yet, so they are visibly disabled rather than
## silently dead — a button that does nothing when tapped teaches a child that
## tapping does not work.
##
## Everything shown here is a placeholder value set in the Inspector. Nothing is
## persisted: there is no GameState yet, so the star count and the plant stage
## cannot survive a restart. Wiring them up is a separate task.

@export_group("Destination")
@export_file("*.tscn") var level_scene_path: String = "res://scenes/ui/level_select_stub.tscn"

@export_group("Placeholder state")
## Greeting above the garden. The child is never asked to type a name.
@export var player_greeting: String = "Hello, Little Gardener!"
## Stars collected so far. Placeholder until GameState exists.
@export var star_count: int = 0
## What the plant has grown into, shown on the My Plant card.
@export var plant_stage_label: String = "SEED"
## Wording on the play button. Names the level rather than repeating "Start
## Game", which the main menu already says.
@export var level_label: String = "Level 1: Grow a Seed"

@onready var _greeting_label: Label = %GreetingLabel
@onready var _star_label: Label = %StarLabel
@onready var _plant_stage_label: Label = %PlantStageLabel
@onready var _play_button: Button = %PlayButton


func _ready() -> void:
	super()
	_greeting_label.text = player_greeting
	_star_label.text = str(star_count)
	_plant_stage_label.text = plant_stage_label
	_play_button.text = level_label
	_play_button.pressed.connect(_on_play_pressed)


func _on_play_pressed() -> void:
	if level_scene_path.is_empty() or not ResourceLoader.exists(level_scene_path):
		push_warning("Hub: level scene is unset or missing: '%s'" % level_scene_path)
		return
	get_tree().change_scene_to_file(level_scene_path)
