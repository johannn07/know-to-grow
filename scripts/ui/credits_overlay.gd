class_name CreditsOverlay
extends Control

## The credits card, opened from Credits on the finished-game card.
##
## The words are in the scene, on `%Text`, so they can be corrected in the
## Inspector without touching code. Lines still waiting on the project owner say
## "To be confirmed" rather than guessing a name — see checklist §9.
##
## It closes the way the Settings card does: the round back arrow, or a tap on
## the dim around it.

@onready var _dim: ColorRect = %Dim
@onready var _close_button: ArtButton = %CloseButton
@onready var _scroll: ScrollContainer = %Scroll


func _ready() -> void:
	_close_button.pressed.connect(close)
	_dim.gui_input.connect(_on_dim_input)
	hide()


func open() -> void:
	_scroll.scroll_vertical = 0
	show()


func close() -> void:
	_close_button.clear_tint()
	hide()


func is_open() -> bool:
	return visible


func _on_dim_input(event: InputEvent) -> void:
	# Release rather than press, so the same touch cannot land on the card
	# underneath once this one has gone.
	var touch := event as InputEventScreenTouch
	var click := event as InputEventMouseButton
	if (touch != null and not touch.pressed) or (
		click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed
	):
		close()
