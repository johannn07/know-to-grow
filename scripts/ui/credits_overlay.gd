class_name CreditsOverlay
extends Control

## The credits, opened from Credits on the finished-game card: plain text that
## rolls up the screen over a dark dim, film-style, and closes itself once the
## last line has gone off the top.
##
## The words are in the scene, one Label per line under `%Lines`, so they can be
## corrected in the Inspector without touching code. Headings use the
## `HeaderLabel` style, the rest the theme's plain Label.
##
## A tap anywhere closes it early. Credits are something a parent might want
## and a child might not, so nothing waits on them.

## How fast the text rises, in design pixels a second. Slow enough to read a
## line aloud as it passes.
@export var scroll_speed: float = 110.0

var _tween: Tween

@onready var _dim: ColorRect = %Dim
@onready var _lines: VBoxContainer = %Lines


func _ready() -> void:
	_dim.gui_input.connect(_on_dim_input)
	hide()


func open() -> void:
	show()
	# The column's height is only known once it has been laid out.
	await get_tree().process_frame
	var start := size.y
	var finish := -_lines.size.y
	_lines.position.y = start
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_lines, "position:y", finish, (start - finish) / scroll_speed)
	_tween.finished.connect(close)


func close() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	hide()


func is_open() -> bool:
	return visible


func _on_dim_input(event: InputEvent) -> void:
	# Release rather than press, so the same touch cannot land on the card
	# underneath once this has gone.
	var touch := event as InputEventScreenTouch
	var click := event as InputEventMouseButton
	if (touch != null and not touch.pressed) or (
		click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed
	):
		close()
