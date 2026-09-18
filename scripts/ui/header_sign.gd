class_name HeaderSign
extends AspectRatioContainer

## The blank wooden stage header with its words written on as live text.
##
## The sign has two plates: the small wooden plaque on top, which carries
## [member label_text] — "Situation 1" — in white with a dark outline, and the
## cream banner under it, which carries [member title_text] — "Hard and Dry
## Soil" — in dark brown. A stage fills them from its challenge's
## `header_label_transcript` and `header_title_transcript`. See CLAUDE.md.
##
## The root keeps the sign's own shape, so %Label and %Title, anchored in
## fractions of the image over their plates, stay on them at any size.
##
## Each plate has one fixed size from the theme — HeaderLabel and HeaderTitle —
## chosen so the longest wording in the game fits on one line, rather than each
## stage's words being shrunk to fit. A header whose words no longer fit is
## clipped, and tools/verify_live_text.gd fails on it.

## The blank sign. Its pixel ratio sets the shape of this control.
@export var sign_art: Texture2D:
	set(value):
		sign_art = value
		if is_node_ready():
			_show_art()

## The plaque — "Situation 1".
@export var label_text: String = "":
	set(value):
		label_text = value
		if is_node_ready():
			_label.text = label_text

## The banner — "Hard and Dry Soil".
@export var title_text: String = "":
	set(value):
		title_text = value
		if is_node_ready():
			_title.text = title_text

@onready var _sign: ArtSlot = %Sign
@onready var _label: Label = %Label
@onready var _title: Label = %Title


func _ready() -> void:
	_show_art()
	_label.text = label_text
	_title.text = title_text


## True when both plates show their whole wording on one line. Nothing at
## runtime depends on it; it is what the verify tool asks.
func text_fits() -> bool:
	return _fits_one_line(_label) and _fits_one_line(_title)


func _fits_one_line(label: Label) -> bool:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	var outline: int = label.get_theme_constant("outline_size")
	var width: float = font.get_string_size(
		label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	).x + outline
	return width <= label.size.x and font.get_height(font_size) <= label.size.y


func _show_art() -> void:
	_sign.texture = sign_art
	if sign_art != null:
		ratio = float(sign_art.get_width()) / float(sign_art.get_height())
