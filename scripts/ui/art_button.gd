class_name ArtButton
extends Button

## An invisible hotspot over a button that is part of a drawing.
##
## Most buttons in the game show they were hit through the theme: PrimaryButton
## in ktg_theme.tres swaps in a pressed StyleBox that darkens the plate to 0.82.
## A button painted into a card cannot do that — this node draws nothing at all,
## and the thing the child can see is a separate [ArtSlot] underneath it. So the
## tint is applied to that art instead, with the same 0.82 the theme uses, and a
## button drawn into a picture feels like the ones that are not.
##
## It also bounces that art with [PressBounce], since the hotspot itself is
## invisible and scaling it would only move the hit area — unless
## [member bounce_art] is off, for art that cannot afford to shrink.
##
## Hover is a small lift on top of that. Only a mouse ever sees it: Android has
## no hover state, so on the device this ships to, pressed is the one that does
## the work.

## Matches PrimaryButton/styles/pressed in ktg_theme.tres. Keep them in step.
const PRESSED_TINT := Color(0.82, 0.82, 0.82, 1.0)

## Slightly brighter than untouched. The theme's primary button has no hover
## state to copy, since it was drawn for a phone.
const HOVER_TINT := Color(1.08, 1.08, 1.08, 1.0)

## Whether a press squashes the art as well as tinting it.
##
## Off for a drawing that is laid exactly over something else — a stage select
## row covers the row painted into the card at the same rect, so shrinking it
## uncovers the one underneath instead of reading as a press. The tint still
## fires, which is the part that survives a row not moving.
@export var bounce_art: bool = true

## The drawing this hotspot sits over, and the node that actually gets tinted.
## Left empty, the button still works and simply shows nothing on press.
##
## A path rather than a node reference because the scenes here are hand-edited:
## a typed node export is written by the editor as a NodePath that only the
## editor knows how to resolve, and typing one in by hand silently leaves the
## property null.
@export var art_path: NodePath

var art: CanvasItem = null

var _hovered := false
var _held := false


func _ready() -> void:
	if not art_path.is_empty():
		art = get_node_or_null(art_path) as CanvasItem
		if art == null:
			push_warning("%s: art_path does not resolve: '%s'" % [name, art_path])
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


## Drops any tint. Worth calling when the button is shown again, so a press cut
## short by the screen changing underneath it cannot leave the art stuck dark.
func clear_tint() -> void:
	_hovered = false
	_held = false
	_refresh()
	PressBounce.reset(art as Control)


func _on_mouse_entered() -> void:
	_hovered = true
	_refresh()


func _on_mouse_exited() -> void:
	_hovered = false
	_refresh()


func _on_button_down() -> void:
	_held = true
	_refresh()
	if bounce_art:
		PressBounce.press(art as Control)


func _on_button_up() -> void:
	# Fires whether or not the release landed inside the button, so a press
	# dragged off the edge cannot leave the art dark.
	_held = false
	_refresh()
	if bounce_art:
		PressBounce.release(art as Control)


func _refresh() -> void:
	if art == null:
		return
	if _held:
		art.modulate = PRESSED_TINT
	elif _hovered:
		art.modulate = HOVER_TINT
	else:
		art.modulate = Color.WHITE
