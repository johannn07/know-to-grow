extends SubScreen

## The hub: the screen between the main menu and a level.
##
## It shows who is playing, what their plant has grown into so far, and the one
## level that is next. The three tabs along the bottom are part of the drawn
## design but have nowhere to go yet, so their buttons stay disabled.
##
## The star count and the plant come from [GameStateStore]. **The plant grows one
## stage for each level cleared, in order**: a seed in its pot at the start,
## the rooted seed once Level 1 is done. There is no separate "Click Me" beat
## before it — the completed-level sign's Grow Now leads straight here, and the
## hub simply shows what the plant has become.
##
## The text nodes are looked up leniently. This screen is still being laid out
## in the editor, and a card that gets moved or removed there should change how
## the hub looks, not stop it working — an unresolved %UniqueName aborts _ready()
## partway through, which previously left the play button unconnected. The play
## button itself is required, because without it the screen has no exit.

@export_group("Destination")
## Where the play button leads at each stage of the plant, in the same order as
## [member plant_stages]: Level 1's overlay before anything is cleared, Level 2's
## once Level 1 is. It is the level overlay, which names the level and hands off
## to it — Play never goes straight into a stage: see checklist.md §3. Past the
## last entry the button keeps leading to the last one.
@export var level_scene_paths: Array[String] = ["res://scenes/ui/level_intro.tscn"]
## What the play button says at each stage, same order. It names the level
## rather than repeating "Start Game", which the main menu already says.
@export var level_labels: Array[String] = ["Level 1: Grow a Seed"]

@export_group("Placeholder state")
## Greeting above the garden. The child is never asked to type a name.
@export var player_greeting: String = "Hello, Little Gardener!"
## Stars collected so far. Read from [GameState]; the export is only what shows
## in the editor, where no autoload has run.
@export var star_count: int = 0
## What the plant has grown into, when there is no progress to read — only the
## editor sees this. Shown only while the scene has a label for it.
@export var plant_stage_label: String = "SEED"

@export_group("Plant")
## The plant at each stage, in order: before any level is cleared, then after
## each one. One more entry than [member growth_levels] covers the whole game.
@export var plant_stages: Array[Texture2D] = []
## What the sign calls each stage, in the same order — "SEED", "ROOT".
@export var plant_stage_names: Array[String] = []
## The levels that grow the plant, in order. Each cleared one moves it on a
## stage; a level only counts once every level before it is cleared.
@export var growth_levels: Array[LevelData] = []

@onready var _play_button: Button = %PlayButton


func _ready() -> void:
	super()
	_set_label_text("%GreetingLabel", player_greeting)
	_set_label_text("%StarLabel", str(progress.total_stars() if progress != null else star_count))
	_show_plant()
	_play_button.text = level_label()
	_play_button.pressed.connect(_on_play_pressed)


## Shows the plant at the stage progress has reached, and names it on the sign.
func _show_plant() -> void:
	var stage := growth_stage()
	var plant: ArtSlot = get_node_or_null("%Plant") as ArtSlot
	if plant != null and stage < plant_stages.size():
		plant.texture = plant_stages[stage]
	var label := plant_stage_label
	if stage < plant_stage_names.size():
		label = plant_stage_names[stage]
	_set_label_text("%PlantStageLabel", label)


## How many of [member growth_levels] are cleared, counting from the first and
## stopping at the first that is not. 0 is the seed.
func growth_stage() -> int:
	var stage := 0
	if progress == null:
		return stage
	for level in growth_levels:
		if level == null or not progress.is_level_cleared(level.id, level.challenges.size()):
			break
		stage += 1
	return stage


## Fills a label if the scene still has one under that name, and says so quietly
## if it does not. Never raises: see the note at the top of the class.
func _set_label_text(unique_name: String, value: String) -> void:
	var label: Label = get_node_or_null(unique_name) as Label
	if label == null:
		print_verbose("Hub: no %s in this layout, skipping" % unique_name)
		return
	label.text = value


func _on_play_pressed() -> void:
	var path := level_scene_path()
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("Hub: level scene is unset or missing: '%s'" % path)
		return
	get_tree().change_scene_to_file(path)


## The level the play button leads to now: the next one the plant is waiting on.
func level_scene_path() -> String:
	return _for_stage(level_scene_paths)


## What the play button says now.
func level_label() -> String:
	return _for_stage(level_labels)


## The entry for the plant's current stage, or the last one past the end.
func _for_stage(entries: Array[String]) -> String:
	if entries.is_empty():
		return ""
	return entries[mini(growth_stage(), entries.size() - 1)]
