class_name StageSelect
extends SubScreen

## The list of stages inside one level, with an X back to the hub.
##
## The whole screen is one drawn picture — frame, header, and every row with
## its item icon, its "Stage N" label and its stars already in it. The
## only interactive parts are invisible hotspots laid over the drawn rows, the
## same way How To Play works.
##
## **Which rows can be tapped, and how each is drawn, comes from
## [GameStateStore].** A row opens when the stage before it is cleared; its row
## art switches between the locked and unlocked drawing; its three stars fill
## with what was earned. The row art covers the row baked into the card at the
## same rect, and the stars are children of that row art.
##
## Each row hotspot is an [ArtButton] pointed at its row art, so a press tints
## the whole row — stars included, since they are its children. It does not
## bounce: the row art covers a row painted into the card, and shrinking it would
## uncover that one (see CLAUDE.md). The close button is an ArtButton with no
## art: its X is part of the card, so there is nothing separate to move.

## **How many rows a level has is set by its scene**, not here. Each level's card
## is drawn differently — Level 1 has four stages, Level 2 five situations — so
## the measurements belong with the card they were taken from. For every entry
## in [member row_rects] the scene holds a %Rows/RowN hotspot and a
## %RowsArt/RowNArt with three RowNStarM star slots in it.

@export_group("Layout")
## Where each drawn row sits on the card, top to bottom, in fractions of the card
## image. Measured off the artwork, which is the only place they exist.
@export var row_rects: Array[Rect2] = []
## Where the card's X is drawn, in the same fractions. On Level 1's card it is
## 126 x 115 on screen, under the touch floor, so its hotspot is grown past the
## drawn disc.
@export var close_rect: Rect2 = Rect2()

@export_group("Destinations")
## One scene per row, in the order they are drawn. A row with no path, or one
## whose stage has not been reached yet, is left disabled.
@export var stage_scene_paths: Array[String] = [
	"res://scenes/levels/level_1/stage_1.tscn",
	"res://scenes/levels/level_1/stage_2.tscn",
	"res://scenes/levels/level_1/stage_3.tscn",
	"res://scenes/levels/level_1/stage_4.tscn",
]

## Which level's progress this screen shows, matching the `id` in content/*.tres
## and the `level_id` on each stage scene.
@export var level_id: StringName = &"level_1"

@export_group("Art")
## Each row as it looks once reached, top to bottom, one per [member row_rects]
## entry. Drawn over the row baked into the card: same capsule, same place, so
## the one underneath is covered exactly.
@export var row_art: Array[Texture2D] = []
## Each row as it looks before it is reached, in the same order.
@export var row_art_locked: Array[Texture2D] = []
## Drawn over a row's empty star for each one earned.
@export var star_filled: Texture2D
## Drawn over the rest. Usually left empty, since the row art already has them.
@export var star_empty: Texture2D

@onready var _rows: Control = %Rows
@onready var _rows_art: Control = %RowsArt
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	super()
	if not close_rect.has_area():
		push_warning("%s: close_rect is not set, so the X has no hotspot" % name)
	place_hotspot(_close_button, close_rect)
	_close_button.pressed.connect(go_back)
	if row_art.size() != row_rects.size() or row_art_locked.size() != row_rects.size():
		push_warning("%s: %d rows but %d unlocked and %d locked row drawings"
			% [name, row_rects.size(), row_art.size(), row_art_locked.size()])

	for i in row_rects.size():
		var button := _row_button(i)
		if button == null:
			continue
		place_hotspot(button, row_rects[i])
		var stage_number := i + 1
		var path := stage_scene_paths[i] if i < stage_scene_paths.size() else ""
		# A row is live only if it has been reached and goes somewhere real.
		var reached := progress == null or progress.is_stage_unlocked(level_id, stage_number)
		var live := reached and not path.is_empty() and ResourceLoader.exists(path)
		button.disabled = not live
		if live:
			button.pressed.connect(_on_row_pressed.bind(path))
		_show_row(stage_number, reached)
		_show_stars(stage_number)


## Draws the row in the state it has actually reached, over the one baked into
## the card. Same capsule at the same place, so the drawn one is covered.
func _show_row(stage_number: int, unlocked: bool) -> void:
	var slot: ArtSlot = _rows_art.get_node_or_null("Row%dArt" % stage_number) as ArtSlot
	if slot == null:
		push_warning("%s: no Row%dArt in this layout" % [name, stage_number])
		return
	slot.texture = _row_art(stage_number, unlocked)


func _row_art(stage_number: int, unlocked: bool) -> Texture2D:
	var art: Array[Texture2D] = row_art if unlocked else row_art_locked
	var i := stage_number - 1
	return art[i] if i >= 0 and i < art.size() else null


## How many rows this level's card has.
func row_count() -> int:
	return row_rects.size()


## Fills a row's three stars with what that stage earned. Nothing is drawn for
## an unearned one unless [member star_empty] is set — the picture underneath
## already has an empty star there.
func _show_stars(stage_number: int) -> void:
	var earned := 0 if progress == null else progress.stars_for(level_id, stage_number)
	for slot_number in 3:
		# Stars are children of their row, so they tint with it.
		var slot: ArtSlot = _rows_art.get_node_or_null(
			"Row%dArt/Row%dStar%d" % [stage_number, stage_number, slot_number + 1]
		) as ArtSlot
		if slot == null:
			push_warning("%s: no Row%dStar%d in this layout" % [name, stage_number, slot_number + 1])
			continue
		slot.texture = star_filled if slot_number < earned else star_empty


## The hotspot for one drawn row. The scene owns these, so a row that has been
## removed or renamed in the editor disables itself rather than breaking _ready.
func _row_button(index: int) -> Button:
	var button: Button = _rows.get_node_or_null("Row%d" % (index + 1)) as Button
	if button == null:
		push_warning("%s: no Row%d in this layout" % [name, index + 1])
	return button


func _on_row_pressed(path: String) -> void:
	get_tree().change_scene_to_file(path)
