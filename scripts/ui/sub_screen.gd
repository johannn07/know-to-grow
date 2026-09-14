extends Control

## Shared behaviour for any screen reached from the main menu: one way back,
## reachable both from an on-screen button and from Android's back gesture.
##
## Attach this to the root of a screen that has a Button named BackButton with
## "Access as Unique Name" enabled.

@export_file("*.tscn") var back_scene_path: String = "res://scenes/ui/main_menu.tscn"

@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(go_back)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func go_back() -> void:
	if back_scene_path.is_empty() or not ResourceLoader.exists(back_scene_path):
		push_warning("SubScreen: back scene is unset or missing: '%s'" % back_scene_path)
		return
	get_tree().change_scene_to_file(back_scene_path)
