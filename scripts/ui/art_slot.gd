@tool
class_name ArtSlot
extends Control

## A single piece of art that does not exist yet.
##
## While [member texture] is null this draws a labelled colour block filling the
## node's own rect, so screens can be laid out, exported and playtested before a
## single asset arrives. Assign a texture in the Inspector and the placeholder
## disappears — no node types change, no scene surgery, no code edit.
##
## Sizes come from [member Control.custom_minimum_size] / the anchors, never from
## the texture, so real art cannot shift a finished layout. Every filename and
## pixel size this project expects is listed in res://art/MANIFEST.md.

## How a real texture fills the slot. Ignored while [member texture] is null.
enum Fit {
	STRETCH, ## Fill the rect, ignoring the source aspect ratio.
	KEEP_ASPECT, ## Fit inside the rect, leaving empty margins if needed.
	KEEP_COVERED, ## Fill the rect and let the overflow spill; set clip_contents.
}

## Thickness of the placeholder's outline, in design pixels.
const BORDER_WIDTH := 4.0

## Gap between the placeholder's caption and the left/right edges.
const LABEL_MARGIN := 12.0

## Caption size is derived from the slot height, then clamped to this range so
## a full-screen background and a small icon stay equally readable.
const MIN_LABEL_SIZE := 18
const MAX_LABEL_SIZE := 56

## Slots taller than this get their caption near the top edge instead of dead
## centre, so a full-bleed background's label does not sit on top of the buttons.
const TALL_SLOT_HEIGHT := 700.0

@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()

@export var fit: Fit = Fit.KEEP_ASPECT:
	set(value):
		fit = value
		queue_redraw()

## Caption drawn on the placeholder. Use the MANIFEST filename stem ("logo",
## "bg_sky", "mascot_left") so a playtester can name the thing they are pointing
## at. Falls back to the node name when left empty.
@export var slot_name: String = "":
	set(value):
		slot_name = value
		queue_redraw()

@export var placeholder_color: Color = Color(0.45, 0.62, 0.35):
	set(value):
		placeholder_color = value
		queue_redraw()

## Draw nothing at all while the texture is missing. Use it for decoration that
## would only clutter the grey-box build — flourishes, sparkles, extra foliage.
@export var hide_when_empty: bool = false:
	set(value):
		hide_when_empty = value
		queue_redraw()


func _init() -> void:
	# Slots are decorative. Without this an ArtSlot layered over a button would
	# swallow the tap. Scene files can still override it for a slot that needs
	# input of its own.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if texture != null:
		_draw_texture()
	elif not hide_when_empty:
		_draw_placeholder()


func _draw_texture() -> void:
	match fit:
		Fit.STRETCH:
			draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
		Fit.KEEP_COVERED:
			draw_texture_rect(texture, _scaled_rect(true), false)
		_:
			draw_texture_rect(texture, _scaled_rect(false), false)


## Centres the texture in the slot, scaled to fit inside it (or to cover it).
func _scaled_rect(cover: bool) -> Rect2:
	var source := texture.get_size()
	if source.x <= 0.0 or source.y <= 0.0:
		return Rect2(Vector2.ZERO, size)

	var axis_scale := size / source
	var factor := maxf(axis_scale.x, axis_scale.y) if cover else minf(axis_scale.x, axis_scale.y)
	var drawn := source * factor
	return Rect2((size - drawn) * 0.5, drawn)


func _draw_placeholder() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, placeholder_color, true)
	draw_rect(rect, placeholder_color.darkened(0.35), false, BORDER_WIDTH)

	var font := get_theme_default_font()
	if font == null:
		return

	var caption := slot_name if not slot_name.is_empty() else String(name)
	var available := size.x - LABEL_MARGIN * 2.0
	if available <= 0.0:
		return

	var font_size := clampi(int(size.y / 6.0), MIN_LABEL_SIZE, MAX_LABEL_SIZE)
	# Shrink rather than truncate — a clipped caption ("mascot_flow…") is worse
	# than a small one when the whole point is to name the missing asset.
	var measured := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if measured > available:
		font_size = maxi(MIN_LABEL_SIZE, int(font_size * available / measured))

	# Dark text on pale blocks, pale text on dark ones, so the caption stays
	# readable whatever colour the slot was given.
	var is_pale := placeholder_color.get_luminance() > 0.5
	var text_color := Color(0.0, 0.0, 0.0, 0.7) if is_pale else Color(1.0, 1.0, 1.0, 0.9)

	var ascent := font.get_ascent(font_size)
	var baseline := (size.y + ascent - font.get_descent(font_size)) * 0.5
	if size.y > TALL_SLOT_HEIGHT:
		baseline = LABEL_MARGIN + ascent

	draw_string(
		font,
		Vector2(LABEL_MARGIN, baseline),
		caption,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x - LABEL_MARGIN * 2.0,
		font_size,
		text_color
	)
