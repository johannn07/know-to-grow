extends SubScreen

## The hub: the screen between the main menu and a level.
##
## It shows who is playing, what their plant has grown into so far, and the one
## level that is next. The three tabs along the bottom are part of the drawn
## design but have nowhere to go yet, so their buttons stay disabled.
##
## Everything shown here is a placeholder value set in the Inspector. Nothing is
## persisted: there is no GameState yet, so the star count and the plant stage
## cannot survive a restart. Wiring them up is a separate task.
##
## The text nodes are looked up leniently. This screen is still being laid out
## in the editor, and a card that gets moved or removed there should change how
## the hub looks, not stop it working — an unresolved %UniqueName aborts _ready()
## partway through, which previously left the play button unconnected. The play
## button itself is required, because without it the screen has no exit.

@export_group("Destination")
@export_file("*.tscn") var level_scene_path: String = "res://scenes/levels/challenge_screen.tscn"

@export_group("Placeholder state")
## Greeting above the garden. The child is never asked to type a name.
@export var player_greeting: String = "Hello, Little Gardener!"
## Stars collected so far. Placeholder until GameState exists.
@export var star_count: int = 0
## What the plant has grown into. Shown only while the scene has a label for it;
## it also decides which plant art belongs in the Plant slot.
@export var plant_stage_label: String = "SEED"
## Wording on the play button. Names the level rather than repeating "Start
## Game", which the main menu already says.
@export var level_label: String = "Level 1: Grow a Seed"

@onready var _play_button: Button = %PlayButton


func _ready() -> void:
	super()
	_set_label_text("%GreetingLabel", player_greeting)
	_set_label_text("%StarLabel", str(star_count))
	_set_label_text("%PlantStageLabel", plant_stage_label)
	_play_button.text = level_label
	_play_button.pressed.connect(_on_play_pressed)


## Fills a label if the scene still has one under that name, and says so quietly
## if it does not. Never raises: see the note at the top of the class.
func _set_label_text(unique_name: String, value: String) -> void:
	var label: Label = get_node_or_null(unique_name) as Label
	if label == null:
		print_verbose("Hub: no %s in this layout, skipping" % unique_name)
		return
	label.text = value


func _on_play_pressed() -> void:
	if level_scene_path.is_empty() or not ResourceLoader.exists(level_scene_path):
		push_warning("Hub: level scene is unset or missing: '%s'" % level_scene_path)
		return
	get_tree().change_scene_to_file(level_scene_path)
