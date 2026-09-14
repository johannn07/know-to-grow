class_name DropZone
extends Control

## A target the learner drags an OptionCard onto: the soil, the whole plant,
## or one highlighted plant part. Put one of these over each interactive area
## of the artwork once the art exists.

signal option_dropped(option_id: StringName, zone_id: StringName)

@export var zone_id: StringName = &"main"

## Minimum comfortable touch target for small hands. Do not go below this.
const MIN_TOUCH_SIZE := Vector2(160, 160)

var _highlighted: bool = false


func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(MIN_TOUCH_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok: bool = data is Dictionary and data.has("option_id")
	_set_highlight(ok)
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_set_highlight(false)
	option_dropped.emit(StringName(data["option_id"]), zone_id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_highlight(false)


func _set_highlight(on: bool) -> void:
	if on == _highlighted:
		return
	_highlighted = on
	modulate = Color(1.15, 1.15, 1.0) if on else Color.WHITE
