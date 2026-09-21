class_name HoldButton
extends Button

## A button that has to be held down, not just tapped, before it acts.
##
## For anything that throws away a child's progress. New Game over an existing
## save is the case it was made for, decided by the project owner: one stray tap
## must not wipe a garden someone spent four levels growing, and a hold is the
## lightest gate that stops it — the parent-gate idea in CLAUDE.md, at its
## smallest.
##
## Connect to [signal held], not `pressed`. While the thumb is down a pale fill
## runs across the plate, so the wait reads as progress rather than as the
## button ignoring the child; let go early and it drains away and
## [signal hold_cancelled] fires, which a screen can use to say "keep holding".
##
## With [member require_hold] off it is an ordinary button that emits
## [signal held] on a normal press, so the same control serves the main menu's
## New Game both with and without a save behind it.

## The hold finished. This is the one to act on.
signal held
## Let go before the hold finished.
signal hold_cancelled

## How long the thumb has to stay down, in seconds.
@export var hold_seconds: float = 1.5
## Off, and a plain tap is enough — for when there is nothing to lose.
@export var require_hold: bool = true:
	set(value):
		require_hold = value
		_stop()

## Colour of the fill that runs across while holding. Pale, over the green plate.
@export var fill_color: Color = Color(1.0, 1.0, 1.0, 0.35)

var _holding := false
var _elapsed := 0.0
var _fill: Panel


func _ready() -> void:
	_fill = Panel.new()
	_fill.name = "HoldFill"
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.set_corner_radius_all(64)
	_fill.add_theme_stylebox_override("panel", style)
	add_child(_fill, false, Node.INTERNAL_MODE_FRONT)
	_fill.hide()
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(_on_pressed)
	set_process(false)


## How far through the hold, 0 to 1. For tests and for anything drawing its own
## progress.
func progress() -> float:
	return clampf(_elapsed / maxf(hold_seconds, 0.01), 0.0, 1.0)


func _on_down() -> void:
	if not require_hold:
		return
	_holding = true
	_elapsed = 0.0
	set_process(true)
	_show_fill()


func _on_up() -> void:
	if _holding:
		_stop()
		hold_cancelled.emit()


func _on_pressed() -> void:
	if not require_hold:
		held.emit()


func _process(delta: float) -> void:
	if not _holding:
		return
	_elapsed += delta
	_show_fill()
	if _elapsed >= hold_seconds:
		# Finished under the thumb: act now rather than on release, so the child
		# sees it happen while still holding.
		_stop()
		held.emit()


func _show_fill() -> void:
	# Inset from the plate's rim so the fill stays on the green face.
	var inset := Vector2(18.0, 16.0)
	var full := size - inset * 2.0
	_fill.position = inset
	_fill.size = Vector2(full.x * progress(), full.y)
	_fill.visible = _holding and _fill.size.x > 1.0


func _stop() -> void:
	_holding = false
	_elapsed = 0.0
	set_process(false)
	if _fill != null:
		_fill.hide()
