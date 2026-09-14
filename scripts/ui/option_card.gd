class_name OptionCard
extends Control

## A single option the learner can tap or drag.
##
## Builds its own children in code so you do not need a .tscn or a single PNG
## to start playing. When art arrives, set OptionData.icon and the placeholder
## block disappears on its own.

signal tapped(option_id: StringName)

const CARD_SIZE := Vector2(240, 260)
const ICON_SIZE := Vector2(180, 180)

var data: OptionData
var draggable: bool = true

var _panel: PanelContainer
var _icon: TextureRect
var _label: Label


func setup(option: OptionData, can_drag: bool) -> void:
	data = option
	draggable = can_drag
	custom_minimum_size = CARD_SIZE
	# Must be STOP, or neither the tap nor the drag will ever reach this node.
	mouse_filter = Control.MOUSE_FILTER_STOP
	if is_node_ready():
		_build()


func _ready() -> void:
	if data != null and _panel == null:
		_build()


func _build() -> void:
	pivot_offset = custom_minimum_size * 0.5
	resized.connect(func() -> void: pivot_offset = size * 0.5)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)

	_icon = TextureRect.new()
	_icon.custom_minimum_size = ICON_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_icon)

	_label = Label.new()
	_label.text = data.label
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_label)

	_refresh_icon()


func _refresh_icon() -> void:
	if data.icon != null:
		_icon.texture = data.icon
		_icon.modulate = Color.WHITE
		return
	# --- placeholder mode ---
	var placeholder := PlaceholderTexture2D.new()
	placeholder.size = ICON_SIZE
	_icon.texture = placeholder
	_icon.modulate = data.placeholder_color


# --- input -------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			AudioDirector.play_vo(data.vo_key)
			_press_tween(0.94)
		else:
			_press_tween(1.0)
			if not draggable:
				tapped.emit(data.id)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable:
		return null
	AudioDirector.play_sfx(&"pickup")

	var preview := TextureRect.new()
	preview.texture = _icon.texture
	preview.modulate = _icon.modulate
	preview.custom_minimum_size = ICON_SIZE
	preview.size = ICON_SIZE
	preview.pivot_offset = ICON_SIZE * 0.5
	# Centre the preview under the finger instead of the top-left corner.
	var wrapper := Control.new()
	wrapper.add_child(preview)
	preview.position = -ICON_SIZE * 0.5
	set_drag_preview(wrapper)

	modulate.a = 0.5
	return {"option_id": data.id, "source": self}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0  # free "snap back": the card never actually moved.


# --- feedback ----------------------------------------------------------------

func _press_tween(target: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * target, 0.08)


func shake() -> void:
	var start := position
	var tween := create_tween()
	tween.tween_property(self, "position", start + Vector2(14, 0), 0.05)
	tween.tween_property(self, "position", start - Vector2(14, 0), 0.05)
	tween.tween_property(self, "position", start, 0.05)


func celebrate() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.15, 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
