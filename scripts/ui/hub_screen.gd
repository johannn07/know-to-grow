extends SubScreen

## The hub: the screen between the main menu and a level.
##
## It shows who is playing, what their plant has grown into so far, and the one
## level that is next.
##
## **The tabs along the bottom open once Level 1 is cleared**, and until then
## are drawn in grey and do not answer — the same grey the locked stage rows use.
## Lessons goes to the stage select of the level the plant is waiting on, which
## can then be paged left and right. Garden shows the plant at each stage it
## has grown through. Badges has nowhere to go yet, so its button stays
## disabled.
##
## The star count and the plant come from [GameStateStore]. **The plant grows one
## stage for each level cleared, in order**: a seed in its pot at the start,
## the rooted seed once Level 1 is done. There is no separate "Click Me" beat
## before it — the completed-level sign's Grow Now leads straight here, and the
## hub simply shows what the plant has become.
##
## **The first time it shows the plant fully grown, it brings up the finished-game
## card by itself** — [member finished_overlay], over the garden. That is where
## Grow Now after the last level lands. Whether it has come up is saved, so it
## does not return on every visit; New Game on it starts again from the seed.
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

@export_group("Tabs")
## Where Lessons leads at each stage of the plant, same order as [member
## plant_stages]: the stage select of the level that stage is waiting on. Past
## the last entry it keeps leading to the last one.
@export var lesson_scene_paths: Array[String] = []
## The Lessons icon while the tabs are still locked.
@export var lessons_icon_locked: Texture2D
## Where Garden leads.
@export_file("*.tscn") var garden_scene_path: String = ""
## The Garden icon while the tabs are still locked.
@export var garden_icon_locked: Texture2D

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

@export_group("Finished game")
## The "Hooray! You did it!" card, laid over the hub the first time every level
## in [member growth_levels] is cleared. See [GameCompleteOverlay].
@export var finished_overlay: PackedScene
## What plays while it is up. The hub's own track comes back when it closes.
@export var finished_music: AudioDirectorService.Track = AudioDirectorService.Track.LEVEL_5

## A locked tab's name, lighter than the theme's brown the way the locked rows'
## lettering is.
const LOCKED_LABEL_COLOR := Color(0.55, 0.55, 0.55, 1.0)

@onready var _play_button: Button = %PlayButton
@onready var _lessons_button: Button = %LessonsButton
@onready var _garden_button: Button = %GardenButton

## Each tab's icon as the scene draws it, put back once the tab opens.
var _lessons_icon: Texture2D = null
var _garden_icon: Texture2D = null

## The finished-game card while it is up, else null.
var _finished: GameCompleteOverlay = null


func _ready() -> void:
	super()
	_set_label_text("%GreetingLabel", player_greeting)
	_play_button.pressed.connect(_on_play_pressed)
	_lessons_button.pressed.connect(_on_lessons_pressed)
	_garden_button.pressed.connect(_go_to.bind(garden_scene_path))
	_lessons_icon = _drawn_icon(_lessons_button)
	_garden_icon = _drawn_icon(_garden_button)
	_refresh()
	if is_fully_grown() and progress != null and not progress.finished_shown():
		show_finished()


## Everything on the hub that follows from progress.
func _refresh() -> void:
	_set_label_text("%StarLabel", str(progress.total_stars() if progress != null else star_count))
	_show_plant()
	_play_button.text = level_label()
	_gate_tab(_lessons_button, _lessons_icon, lessons_icon_locked)
	_gate_tab(_garden_button, _garden_icon, garden_icon_locked)


## True once every level that grows the plant is cleared.
func is_fully_grown() -> bool:
	return not growth_levels.is_empty() and growth_stage() >= growth_levels.size()


## Brings up the finished-game card and records that it has been seen.
func show_finished() -> void:
	if finished_overlay == null or _finished != null:
		return
	_finished = finished_overlay.instantiate() as GameCompleteOverlay
	if _finished == null:
		push_warning("Hub: finished_overlay is not a GameCompleteOverlay")
		return
	add_child(_finished)
	# The card arrives after _ready dressed the hub's own buttons.
	dress_every_button(_finished)
	_finished.continue_playing.connect(_close_finished)
	_finished.new_game.connect(_on_new_game)
	if progress != null:
		progress.mark_finished_shown()
	if audio != null:
		audio.play_music(finished_music)


## The finished-game card, while it is up.
func finished_card() -> GameCompleteOverlay:
	return _finished


func _close_finished() -> void:
	if _finished != null:
		_finished.queue_free()
		_finished = null
	if audio != null:
		audio.play_music(music_track)


## Starts again from the seed, here on the hub: progress is wiped and the hub
## redraws, which is the same thing a reload would show without the flash.
func _on_new_game() -> void:
	if progress != null:
		progress.reset()
	_close_finished()
	_refresh()


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
	return 0 if progress == null else progress.levels_cleared_in_order(growth_levels)


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


## True once Level 1 is cleared, which is what opens the tabs.
func tabs_unlocked() -> bool:
	return growth_stage() >= 1


## Where Lessons leads now.
func lesson_scene_path() -> String:
	return _for_stage(lesson_scene_paths)


## Opens a tab or locks it, and draws it to match: its own icon and the theme's
## lettering when open, the grey drawing and grey lettering when not.
func _gate_tab(button: Button, icon_open: Texture2D, icon_locked: Texture2D) -> void:
	var open := tabs_unlocked()
	button.disabled = not open
	var icon := _tab_icon(button)
	if icon != null and icon_open != null and icon_locked != null:
		icon.texture = icon_open if open else icon_locked
	var label: Label = button.get_parent().get_node_or_null("Content/TabLabel") as Label
	if label == null:
		return
	if open:
		label.remove_theme_color_override(&"font_color")
	else:
		label.add_theme_color_override(&"font_color", LOCKED_LABEL_COLOR)


## A tab's icon: the ArtSlot drawn beside its hotspot. Looked up leniently, like
## the hub's labels, since the nav is still being arranged in the editor.
func _tab_icon(button: Button) -> ArtSlot:
	return button.get_parent().get_node_or_null("Content/Icon") as ArtSlot


## What a tab's icon shows in the scene, before any locking.
func _drawn_icon(button: Button) -> Texture2D:
	var icon := _tab_icon(button)
	return null if icon == null else icon.texture


func _on_lessons_pressed() -> void:
	_go_to(lesson_scene_path())


func _go_to(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("Hub: tab scene is unset or missing: '%s'" % path)
		return
	get_tree().change_scene_to_file(path)
