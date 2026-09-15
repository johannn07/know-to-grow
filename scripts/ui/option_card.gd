class_name OptionCard
extends Control

## One draggable item card: the shovel, the watering can, the flower.
##
## The artwork carries the item's name in its own pixels, so this draws nothing
## itself — it is a hit area with a picture in it and a drag behaviour.
##
## Dragging sets [member Control.top_level] so the card escapes the container
## that laid it out, while the container keeps reserving its slot. That way a
## card that snaps back lands exactly where it started without the row reflowing
## underneath it.

## Emitted on release. The screen decides whether the drop counts; the card only
## reports where it was let go.
signal dropped(card: OptionCard, at_global: Vector2)

## How long a rejected card takes to slide home, in seconds. Short enough not to
## make a child wait, long enough to read as "that went back" rather than a
## glitch.
const RETURN_TIME := 0.25

## Tint for a card that has been tried and was wrong. It stays on screen, greyed
## out, so the child can see what they have already ruled out.
const SPENT_MODULATE := Color(0.52, 0.52, 0.58, 1.0)

## Matches an OptionData id in content/*.tres. The stage compares this against
## its own correct answer; the .tres keeps the item's name and hint as
## transcripts for review and voice-over.
@export var option_id: StringName = &"":
	set(value):
		option_id = value
		_apply()

## The item card, with its name already drawn on it. Set per stage in the
## stage's scene, so a card can be seen and moved in the editor.
@export var icon: Texture2D:
	set(value):
		icon = value
		_apply()

var _dragging := false
var _grab_offset := Vector2.ZERO
var _home_local := Vector2.ZERO
var _home_global := Vector2.ZERO

@onready var _art: ArtSlot = $Art


func _ready() -> void:
	_apply()


func _apply() -> void:
	if _art == null:
		return
	_art.texture = icon
	_art.slot_name = String(option_id)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _dragging:
			_begin_drag(event.global_position)
			accept_event()


func _input(event: InputEvent) -> void:
	# Motion and release are handled here rather than in _gui_input because a
	# dragged card spends most of its time outside its own rect, where
	# _gui_input no longer receives anything.
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		global_position = event.global_position - _grab_offset
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		_end_drag(event.global_position)


func _begin_drag(at_global: Vector2) -> void:
	_dragging = true
	_home_local = position
	_home_global = global_position
	_grab_offset = at_global - global_position
	top_level = true
	global_position = _home_global
	z_index = 10


func _end_drag(at_global: Vector2) -> void:
	_dragging = false
	z_index = 0
	dropped.emit(self, at_global)


## Slides the card back to where the drag started. Called by the screen when a
## drop is rejected, so the card does not decide its own fate.
func return_home() -> void:
	# The home position is only meaningful once a drag has actually begun.
	# Without this a card that never moved would be tweened to the origin and
	# fly to the corner of the screen.
	if not top_level:
		return
	z_index = 0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", _home_global, RETURN_TIME)
	await tween.finished
	# Dropping out of top_level makes Godot read `position` as parent-relative
	# again. It currently holds global coordinates, so it has to be restored by
	# hand — otherwise the card lands a screen-height below its row and looks
	# like it was deleted.
	top_level = false
	position = _home_local


## Stops this card responding to touch, for when the stage has been answered.
func freeze() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(false)


## Greys the card out and retires it. Used for an option that was tried on the
## target and was wrong: removing it would erase the child's own attempt, and
## leaving it live invites the same wrong answer again.
func mark_spent() -> void:
	modulate = SPENT_MODULATE
	freeze()
