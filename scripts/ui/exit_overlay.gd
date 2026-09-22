class_name ExitOverlay
extends Control

## "Are you sure you want to exit?" — the card between the title screen's Exit
## and the app actually closing.
##
## Yes leaves; No, a tap on the dim, or Android's back gesture keep playing.
## The question is drawn into the card; the two buttons are the menu's own
## themed plates with live words, laid on the card's blank lower half. No is the
## big green one, since staying is the answer a child tapping by accident wants.
##
## It does not quit by itself. It emits [signal exit_confirmed] and the screen
## that owns it decides what leaving means, which also lets the smoke test press
## Yes without closing the test run.

## Yes was pressed.
signal exit_confirmed

@onready var _dim: ColorRect = %Dim
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton


func _ready() -> void:
	_yes_button.pressed.connect(_on_yes_pressed)
	_no_button.pressed.connect(close)
	_dim.gui_input.connect(_on_dim_input)
	hide()


func open() -> void:
	show()


func close() -> void:
	hide()


func is_open() -> bool:
	return visible


func _on_yes_pressed() -> void:
	exit_confirmed.emit()


func _on_dim_input(event: InputEvent) -> void:
	# Release rather than press, so the same touch cannot also land on a button
	# underneath after the overlay has gone.
	var touch := event as InputEventScreenTouch
	var click := event as InputEventMouseButton
	if (touch != null and not touch.pressed) or (
		click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed
	):
		close()
