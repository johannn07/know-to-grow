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
## tools/verify_prompt_bubble.gd fails on it — a loud test beats text that
## quietly gets smaller from one stage to the next.

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

@onready var _bubble: ArtSlot = %Bubble
@onready var _text: Label = %Text


func _ready() -> void:
	_show_art()
	_text.text = text


## True when every line of the prompt is inside the cream box. Nothing at
## runtime depends on it; it is what the verify tool asks.
func text_fits() -> bool:
	return _text.get_visible_line_count() >= _text.get_line_count()


func _show_art() -> void:
	_bubble.texture = bubble_art
	if bubble_art != null:
		ratio = float(bubble_art.get_width()) / float(bubble_art.get_height())
