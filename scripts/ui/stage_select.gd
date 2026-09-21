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
## uncover that one (see CLAUDE.md). The close button works the same way: its
## X is painted into the card, so %CloseArt is that disc cut out of the card and
## laid back over it, there only to be darkened on a press.
##
## **The four levels' stage selects are pages of one strip.** A swipe to the
## left, or the arrow on the right, slides this card out and the next level's in;
## the other way goes back a level. The next level is only offered once this one
## is cleared, which is when it opens — so the strip ends at the level the child
## has reached, and never shows one whose first row it has no drawing to lock.
## The arrows sit in the gutters either side of the card, over nothing, so they
## bounce as normal, and each one hides where there is no page to go to.

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

@export_group("Paging")
## The stage select for the level before this one: the left arrow, or a swipe to
## the right. Empty on the first level.
@export_file("*.tscn") var previous_page_path: String = ""
## The next level's: the right arrow, or a swipe to the left. Offered only once
## this level is cleared. Empty on the last level.
@export_file("*.tscn") var next_page_path: String = ""

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

## How long the card takes to slide out, and the next one to slide in.
const PAGE_SECONDS := 0.2

## Which side the next stage select slides in from: 1 the right, -1 the left,
## 0 not at all. Static because it has to outlive the scene change that asks
## for it.
static var _arrive_from: int = 0

var _swipe := SwipeTracker.new()
var _paging := false

@onready var _center: Control = %Center
@onready var _previous_button: Button = %PreviousButton
@onready var _next_button: Button = %NextButton
@onready var _previous_art: CanvasItem = %PreviousArt
@onready var _next_art: CanvasItem = %NextArt
@onready var _rows: Control = %Rows
@onready var _rows_art: Control = %RowsArt
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	super()
	if not close_rect.has_area():
		push_warning("%s: close_rect is not set, so the X has no hotspot" % name)
	place_hotspot(_close_button, close_rect)
	_close_button.pressed.connect(go_back)
	_previous_button.pressed.connect(turn_page.bind(-1))
	_next_button.pressed.connect(turn_page.bind(1))
	for direction: int in [-1, 1]:
		var offered := has_page(direction)
		var button := _previous_button if direction < 0 else _next_button
		button.visible = offered
		button.disabled = not offered
		(_previous_art if direction < 0 else _next_art).visible = offered
	if _arrive_from != 0:
		_slide_in(_arrive_from)
		_arrive_from = 0
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


## The page one level along: -1 the level before, 1 the level after.
func page_path(direction: int) -> String:
	return previous_page_path if direction < 0 else next_page_path


## Whether there is a page that way the child is allowed to see. Going back is
## always open — this level was reached, so the one before it was cleared.
func has_page(direction: int) -> bool:
	var path := page_path(direction)
	if path.is_empty() or not ResourceLoader.exists(path):
		return false
	if direction > 0:
		return progress != null and progress.is_level_cleared(level_id, row_count())
	return true


## True from the moment a page is asked for until the scene changes.
func is_paging() -> bool:
	return _paging


## Slides this card out and changes to the page that way. Does nothing if there
## is no such page, or one is already on its way, so a double tap on an arrow
## cannot skip a level.
func turn_page(direction: int) -> void:
	if _paging or not has_page(direction):
		return
	_paging = true
	_arrive_from = direction
	var width := get_viewport_rect().size.x
	var tween := create_tween()
	tween.tween_method(_set_slide, 0.0, -direction * width, PAGE_SECONDS) 		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(get_tree().change_scene_to_file.bind(page_path(direction)))


## The arriving card starts a screen away on the side it came from and slides to
## rest. Set before the first frame is drawn, so it never flashes in place.
func _slide_in(from_side: int) -> void:
	var width := get_viewport_rect().size.x
	_set_slide(from_side * width)
	create_tween().tween_method(_set_slide, from_side * width, 0.0, PAGE_SECONDS) 		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Moves the card sideways without resizing it: both edges by the same amount.
func _set_slide(x: float) -> void:
	_center.offset_left = x
	_center.offset_right = x


## A release that turns out to be a swipe is swallowed, so the row it started
## on is not opened as well. See [SwipeTracker].
func _input(event: InputEvent) -> void:
	var direction := _swipe.feed(event)
	if direction != 0 and has_page(direction):
		get_viewport().set_input_as_handled()
		turn_page(direction)
