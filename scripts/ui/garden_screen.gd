class_name GardenScreen
extends SubScreen

## The Garden: the plant at every stage it has grown through so far, one at a
## time, in the middle of the hub's garden.
##
## It opens on the plant as it is now. A swipe to the right, or the left arrow,
## steps back a stage towards the seed; the other way steps forward again. **It
## stops at the stage the plant has reached** — the plant grows one stage for
## each level cleared, in order, exactly as the hub counts it — so a stage not
## yet grown is never shown ahead of time, the same way Lessons stops at the
## level the child has reached.
##
## The plant stands alone and centred here, where the hub puts it to one side of
## its sign, because the plant is the whole point of this screen. Its name is on
## the header sign above: "My Plant" on the plaque, the stage on the banner.
##
## Paging stays in the one scene. Only the plant slides; the garden behind it
## and the sign stay put, and the sign changes its word as the next plant
## arrives.

## Matches the hub's `plant_stages`: the plant before any level is
## cleared, then after each one. verify_menu_flow checks the two agree.
@export var plant_stages: Array[Texture2D] = []
## What the sign calls each stage, in the same order — "SEED", "ROOT".
@export var plant_stage_names: Array[String] = []
## The levels that grow the plant, in order, as on the hub.
@export var growth_levels: Array[LevelData] = []
## The plaque over the stage's name.
@export var sign_label: String = "My Plant"

## How long the plant takes to slide out, and the next one to slide in.
const PAGE_SECONDS := 0.2

var _shown := 0
var _paging := false
var _swipe := SwipeTracker.new()

@onready var _slide: Control = %Slide
@onready var _plant: ArtSlot = %Plant
@onready var _sign: HeaderSign = %HeaderSign
@onready var _previous_button: Button = %PreviousButton
@onready var _next_button: Button = %NextButton
@onready var _previous_art: CanvasItem = %PreviousArt
@onready var _next_art: CanvasItem = %NextArt


func _ready() -> void:
	super()
	if plant_stages.size() != plant_stage_names.size():
		push_warning("Garden: %d plants but %d names" % [plant_stages.size(), plant_stage_names.size()])
	_previous_button.pressed.connect(turn_page.bind(-1))
	_next_button.pressed.connect(turn_page.bind(1))
	_sign.label_text = sign_label
	_shown = grown_stage()
	_show_stage()


## The furthest stage the plant has reached, which is also where the Garden
## opens. 0 is the seed.
func grown_stage() -> int:
	var grown := 0 if progress == null else progress.levels_cleared_in_order(growth_levels)
	return clampi(grown, 0, maxi(plant_stages.size() - 1, 0))


## The stage on screen now.
func shown_stage() -> int:
	return _shown


## Whether there is a grown stage that way: -1 back towards the seed, 1 on.
func has_page(direction: int) -> bool:
	var target := _shown + direction
	return target >= 0 and target <= grown_stage()


## True while a plant is sliding.
func is_paging() -> bool:
	return _paging


## Slides the plant out, swaps it for the stage that way, and slides that one
## in from the other side. Ignored while a slide is running, so a double tap on
## an arrow cannot skip a stage.
func turn_page(direction: int) -> void:
	if _paging or not has_page(direction):
		return
	_paging = true
	var width := get_viewport_rect().size.x
	var tween := create_tween()
	tween.tween_property(_slide, "position:x", -direction * width, PAGE_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_arrive.bind(direction, width))
	tween.tween_property(_slide, "position:x", 0.0, PAGE_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_settle)


func _arrive(direction: int, width: float) -> void:
	_shown += direction
	_show_stage()
	_slide.position.x = direction * width


func _settle() -> void:
	_paging = false


## Draws the stage in [member _shown]: its plant, its name, and an arrow each
## way there is somewhere to go.
func _show_stage() -> void:
	if _shown < plant_stages.size():
		_plant.texture = plant_stages[_shown]
	_sign.title_text = plant_stage_names[_shown] if _shown < plant_stage_names.size() else ""
	for direction: int in [-1, 1]:
		var offered := has_page(direction)
		var button := _previous_button if direction < 0 else _next_button
		button.visible = offered
		button.disabled = not offered
		(_previous_art if direction < 0 else _next_art).visible = offered


## A release that turns out to be a swipe is swallowed, so nothing under the
## finger answers it as a tap. See [SwipeTracker].
func _input(event: InputEvent) -> void:
	var direction := _swipe.feed(event)
	if direction != 0 and has_page(direction):
		get_viewport().set_input_as_handled()
		turn_page(direction)
