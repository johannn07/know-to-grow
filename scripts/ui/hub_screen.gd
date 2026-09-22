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
## has grown through, and Badges every badge, the earned ones in colour. Level 1
## is also what earns the first badge, so Badges never opens on an empty grid.
##
## The star count and the plant come from [GameStateStore]. **The plant grows one
## stage for each level cleared, in order**: a seed in its pot at the start,
## the rooted seed once Level 1 is done. There is no separate "Click Me" beat
## before it — the completed-level sign's Grow Now leads straight here, and the
## hub simply shows what the plant has become.
##
## **When the plant has grown since the hub last showed it, it grows in on
## screen**: the plant it was fades back while the new one rises out of the soil
## behind a glowing, sparkling front, then gives a small bounce. Which stage the
## hub last showed is saved in [GameStateStore], so it happens once per stage,
## not on every visit — and a child who leaves mid-way sees it again next time.
##
## **The first time it shows the plant fully grown, it brings up the finished-game
## card by itself** — [member finished_overlay], over the garden, once the
## plant has finished growing in. That is where
## Grow Now after the last level lands. Whether it has come up is saved, so it
## does not return on every visit; New Game on it starts again from the seed.
##
## The text nodes are looked up leniently. This screen is still being laid out
## in the editor, and a card that gets moved or removed there should change how
## the hub looks, not stop it working — an unresolved %UniqueName aborts _ready()
## partway through, which previously left the play button unconnected. The play
## button itself is required, because without it the screen has no exit.

## Emitted when the plant has finished growing in.
signal grow_finished

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

## The glint that sweeps the play button every couple of seconds, pointing a
## child who cannot read yet at the next thing to do.
@export var next_step_material: ShaderMaterial = preload("res://shaders/next_step_glint.tres")

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
## Where Badges leads.
@export_file("*.tscn") var badges_scene_path: String = ""
## The Badges icon while the tabs are still locked.
@export var badges_icon_locked: Texture2D

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

## The material the plant draws with while it grows in: shaders/plant_grow.tres.
## Left empty, the plant just appears grown.
@export var grow_material: ShaderMaterial
## How long the new plant takes to rise out of the soil, in seconds.
@export var grow_seconds: float = 1.4

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
@onready var _badges_button: Button = %BadgesButton

## Each tab's icon as the scene draws it, put back once the tab opens.
var _lessons_icon: Texture2D = null
var _garden_icon: Texture2D = null
var _badges_icon: Texture2D = null

## The finished-game card while it is up, else null.
var _finished: GameCompleteOverlay = null

## The growing-in animation while it runs, else null.
var _grow_tween: Tween = null


func _ready() -> void:
	super()
	_set_label_text("%GreetingLabel", player_greeting)
	_play_button.pressed.connect(_on_play_pressed)
	_glint_play_button()
	_lessons_button.pressed.connect(_on_lessons_pressed)
	_garden_button.pressed.connect(_go_to.bind(garden_scene_path))
	_lessons_icon = _drawn_icon(_lessons_button)
	_garden_icon = _drawn_icon(_garden_button)
	_badges_button.pressed.connect(_go_to.bind(badges_scene_path))
	_badges_icon = _drawn_icon(_badges_button)
	_refresh()
	if _grow_if_new():
		await grow_finished
	if is_fully_grown() and progress != null and not progress.finished_shown():
		show_finished()


## Puts [member next_step_material] on the play button, in the button's own
## space: its plate is a stretched nine-patch and its words are live text, so
## the band has to cross the rect rather than any one texture.
func _glint_play_button() -> void:
	if next_step_material == null:
		return
	var glint := next_step_material.duplicate() as ShaderMaterial
	glint.set_shader_parameter(&"local_space", true)
	_play_button.material = glint
	var fit := func() -> void: glint.set_shader_parameter(&"box_size", _play_button.size)
	fit.call()
	_play_button.resized.connect(fit)


## Everything on the hub that follows from progress.
func _refresh() -> void:
	_set_label_text("%StarLabel", str(progress.total_stars() if progress != null else star_count))
	_show_plant()
	_play_button.text = level_label()
	_gate_tab(_lessons_button, _lessons_icon, lessons_icon_locked)
	_gate_tab(_garden_button, _garden_icon, garden_icon_locked)
	_gate_tab(_badges_button, _badges_icon, badges_icon_locked)


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


## True while the plant is growing in.
func is_growing() -> bool:
	return _grow_tween != null


## Grows the plant in if progress is ahead of what the hub last showed. Returns
## whether it started, so [method _ready] knows to wait before the finished card.
func _grow_if_new() -> bool:
	var stage := growth_stage()
	if progress == null:
		return false
	var shown := progress.plant_stage_shown()
	if stage <= shown:
		# A New Game, or nothing new: just catch the record up.
		if stage < shown:
			progress.mark_plant_stage_shown(stage)
		return false
	var plant: ArtSlot = get_node_or_null("%Plant") as ArtSlot
	if plant == null or grow_material == null or stage < 1 or stage > plant_stages.size() - 1:
		progress.mark_plant_stage_shown(stage)
		return false
	# Only ever the last step. A save from before this existed would otherwise
	# grow a seed straight into fruit.
	_grow_plant(plant, plant_stages[stage - 1], stage)
	return true


func _grow_plant(plant: ArtSlot, before_texture: Texture2D, stage: int) -> void:
	var resting_material := plant.material
	var grow := grow_material.duplicate() as ShaderMaterial
	grow.set_shader_parameter(&"reveal", 0.0)
	plant.material = grow

	# The plant as it was, drawn behind the new one and faded out. A copy of the
	# slot, so it sits and sways exactly where the plant does.
	var before := plant.duplicate(Node.DUPLICATE_SCRIPTS) as ArtSlot
	before.name = "PlantBefore"
	before.unique_name_in_owner = false
	before.texture = before_texture
	before.material = resting_material
	plant.add_sibling(before)
	plant.get_parent().move_child(before, plant.get_index())
	_grow_tween = create_tween()
	_grow_tween.tween_interval(0.35)
	_grow_tween.tween_callback(func() -> void:
		# Shrinks and bounces from the soil, not from the middle of the rect.
		# Set here rather than above, once the layout has settled.
		before.pivot_offset = Vector2(before.size.x * 0.5, before.size.y)
		plant.pivot_offset = Vector2(plant.size.x * 0.5, plant.size.y)
		if audio != null:
			audio.play_correct()
	)
	_grow_tween.tween_property(before, "modulate:a", 0.0, 0.6)
	_grow_tween.parallel().tween_property(before, "scale", Vector2(0.92, 0.92), 0.6)
	_grow_tween.parallel().tween_method(
		func(value: float) -> void: grow.set_shader_parameter(&"reveal", value),
		0.0, 1.0, grow_seconds
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_grow_tween.tween_property(plant, "scale", Vector2(1.06, 1.06), 0.14) 		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_grow_tween.tween_property(plant, "scale", Vector2.ONE, 0.3) 		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_grow_tween.tween_callback(func() -> void:
		plant.material = resting_material
		before.queue_free()
		_grow_tween = null
		if progress != null:
			progress.mark_plant_stage_shown(stage)
		grow_finished.emit()
	)


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
