class_name PromptBubble
extends AspectRatioContainer

## The sprout's speech bubble with a stage's question written into it as live
## text.
##
## Every prompt shares one blank bubble, ui_prompt_bubble.png, so a change of
## wording never means re-rendering art. The words are [member text], which a
## stage fills from its challenge's `prompt_transcript` — the one transcript
## that is rendered. See CLAUDE.md.
##
## The root keeps the bubble's own shape, so %Text, anchored in fractions of the
## image over its cream box, stays on the box at any size the stage gives it.
##
## The text is one fixed size from the theme's PromptText variation rather than
## shrunk to fit. A prompt that no longer fits is clipped, and
## tools/verify_live_text.gd fails on it — a loud test beats text that
## quietly gets smaller from one stage to the next.
##
## When a stage opens, [method pulse] pops the bubble in and lets it breathe
## twice, so the eye goes to the question before the answers. It is the whole
## bubble that moves — this control, around the middle of the drawn card —
## because an [AspectRatioContainer] resets its children's scale whenever it
## lays them out. Only scale and brightness change, never size, so the text is
## laid out exactly as [method text_fits] measured it.

## The blank bubble. Its pixel ratio sets the shape of this control.
@export var bubble_art: Texture2D:
	set(value):
		bubble_art = value
		if is_node_ready():
			_show_art()

## What the sprout is saying. Set by the stage; left empty, the bubble is blank.
@export_multiline var text: String = "":
	set(value):
		text = value
		if is_node_ready():
			_text.text = text

## How much brighter the bubble gets at the top of each breath.
const BREATH_GLOW := Color(1.12, 1.12, 1.12, 1.0)

@onready var _bubble: ArtSlot = %Bubble
@onready var _text: Label = %Text

var _pulse: Tween = null


func _ready() -> void:
	_show_art()
	_text.text = text


## Pops the bubble in from small, then two gentle breaths, about two seconds in
## all, and it is still. Called by [StageScreen] when a stage opens.
func pulse() -> void:
	if _pulse != null:
		_pulse.kill()
	# Hidden until the stage has been laid out, so the pivot can be found and
	# the full-size bubble never flashes up first.
	modulate.a = 0.0
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var card := _bubble.get_parent() as Control
	pivot_offset = card.position + card.size * 0.5
	scale = Vector2(0.6, 0.6)
	_pulse = create_tween()
	_pulse.tween_property(self, "modulate:a", 1.0, 0.18)
	_pulse.parallel().tween_property(self, "scale", Vector2(1.06, 1.06), 0.3) 		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_pulse.tween_property(self, "scale", Vector2.ONE, 0.16) 		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	for breath in 2:
		_pulse.tween_interval(0.15)
		_pulse.tween_property(self, "scale", Vector2(1.035, 1.035), 0.35) 			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_pulse.parallel().tween_property(self, "modulate", BREATH_GLOW, 0.35)
		_pulse.tween_property(self, "scale", Vector2.ONE, 0.35) 			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		_pulse.parallel().tween_property(self, "modulate", Color.WHITE, 0.35)
	_pulse.tween_callback(func() -> void: _pulse = null)


## True while [method pulse] is still moving the bubble.
func is_pulsing() -> bool:
	return _pulse != null or modulate.a < 1.0


## True when every line of the prompt is inside the cream box. Nothing at
## runtime depends on it; it is what the verify tool asks.
func text_fits() -> bool:
	return _text.get_visible_line_count() >= _text.get_line_count()


func _show_art() -> void:
	_bubble.texture = bubble_art
	if bubble_art != null:
		ratio = float(bubble_art.get_width()) / float(bubble_art.get_height())
