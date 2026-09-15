class_name StageSelect
extends SubScreen

## The list of stages inside one level, with an X back to the hub.
##
## The whole screen is one drawn picture — frame, header, and all four rows with
## their item icons, their "Stage N" labels and their stars already in it. The
## only interactive parts are invisible hotspots laid over the drawn rows, the
## same way How To Play works.
##
## **The row states are part of that picture**, not something this screen
## decides: Stage 1 is drawn unlocked and the other three drawn grey, and every
## star is drawn empty. That is the correct state today, because there is no
## GameState and nothing has ever been completed. It is also the reason
## [member unlocked_count] is a plain export rather than something read from
## progress — raising it past what the artwork shows would light up a row that
## still looks locked.
##
## The loose parts for building these rows out of components instead — both pill
## plates, all four item icons in locked and unlocked form, and both star states
## — are in the repo and listed in art/MANIFEST.md. Composing rows from them is
## the job to do alongside GameState, not before it.

## Where each drawn row sits, in fractions of the card image. Measured off the
## artwork, which is the only place they exist.
const ROW_RECTS: Array[Rect2] = [
	Rect2(0.1176, 0.2280, 0.7581, 0.1739),
	Rect2(0.1145, 0.4092, 0.7606, 0.1682),
	Rect2(0.1121, 0.5904, 0.7728, 0.1698),
	Rect2(0.1145, 0.7671, 0.7624, 0.1730),
]

## Where the X is drawn, in the same fractions. It is 126 x 115 on screen, under
## the touch floor, so its hotspot is grown past the drawn disc.
const CLOSE_RECT := Rect2(0.8500, 0.1164, 0.1316, 0.0799)

@export_group("Destinations")
## One scene per row, in the order they are drawn. A row with no path, or a row
## past [member unlocked_count], is left disabled.
@export var stage_scene_paths: Array[String] = [
	"res://scenes/levels/level_1/stage_1.tscn",
	"res://scenes/levels/level_1/stage_2.tscn",
	"res://scenes/levels/level_1/stage_3.tscn",
	"res://scenes/levels/level_1/stage_4.tscn",
]

@export_group("Placeholder state")
## How many rows are tappable, counted from the top. Placeholder until
## GameState exists: the artwork draws exactly one row unlocked, so raising this
## makes a row respond to a tap while still looking grey.
@export var unlocked_count: int = 1

@onready var _rows: Control = %Rows
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	super()
	place_hotspot(_close_button, CLOSE_RECT)
	_close_button.pressed.connect(go_back)

	for i in ROW_RECTS.size():
		var button := _row_button(i)
		if button == null:
			continue
		place_hotspot(button, ROW_RECTS[i])
		var path := stage_scene_paths[i] if i < stage_scene_paths.size() else ""
		# A row is live only if it is both reached and actually goes somewhere.
		var live := i < unlocked_count and not path.is_empty() and ResourceLoader.exists(path)
		button.disabled = not live
		if live:
			button.pressed.connect(_on_row_pressed.bind(path))


## The hotspot for one drawn row. The scene owns these, so a row that has been
## removed or renamed in the editor disables itself rather than breaking _ready.
func _row_button(index: int) -> Button:
	var button: Button = _rows.get_node_or_null("Row%d" % (index + 1)) as Button
	if button == null:
		push_warning("%s: no Row%d in this layout" % [name, index + 1])
	return button


func _on_row_pressed(path: String) -> void:
	get_tree().change_scene_to_file(path)
