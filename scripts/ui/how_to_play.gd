extends SubScreen

## The How To Play screen is one drawn image with its controls painted into it
## (art/ui_how_to_play.png), so there is nothing to lay out here. The only
## interactive nodes are two invisible Buttons sitting exactly over the drawn
## controls: the X, which SubScreen handles as BackButton, and LET'S GO.
##
## Their hit areas are deliberately larger than the drawn controls — the art's
## button is 104 px tall at the design resolution, short of the 160 px a small
## thumb needs, and an invisible button can be generous without looking wrong.

@export_file("*.tscn") var start_scene_path: String = "res://scenes/ui/hub.tscn"

@onready var _lets_go_button: Button = %LetsGoButton


func _ready() -> void:
	super()
	_lets_go_button.pressed.connect(_on_lets_go_pressed)


func _on_lets_go_pressed() -> void:
	if start_scene_path.is_empty() or not ResourceLoader.exists(start_scene_path):
		push_warning("HowToPlay: start scene is unset or missing: '%s'" % start_scene_path)
		return
	get_tree().change_scene_to_file(start_scene_path)
