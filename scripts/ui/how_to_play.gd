extends SubScreen

## The How To Play screen is one drawn image with its controls painted into it
## (art/ui_how_to_play.png), so there is nothing to lay out here. The only
## interactive nodes are two invisible Buttons sitting exactly over the drawn
## controls: the X, which SubScreen handles as BackButton, and LET'S GO.
##
## Both are anchored over the button *art* that now sits on top of the painted
## controls, then grown to the touch floor by [method SubScreen.pad_to_touch_floor]
## — so the hit area always covers at least what the child can see, and never
## less than a thumb needs. Anchoring them by hand is what previously left them
## at 510x154 and 142x136, under the floor and narrower than the buttons drawn
## under them.

@export_file("*.tscn") var start_scene_path: String = "res://scenes/ui/hub.tscn"

@onready var _lets_go_button: Button = %LetsGoButton


func _ready() -> void:
	super()
	_lets_go_button.pressed.connect(_on_lets_go_pressed)
	pad_to_touch_floor(_lets_go_button)
	if _back_button != null:
		pad_to_touch_floor(_back_button)


func _on_lets_go_pressed() -> void:
	if start_scene_path.is_empty() or not ResourceLoader.exists(start_scene_path):
		push_warning("HowToPlay: start scene is unset or missing: '%s'" % start_scene_path)
		return
	get_tree().change_scene_to_file(start_scene_path)
