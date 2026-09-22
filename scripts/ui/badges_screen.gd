class_name BadgesScreen
extends SubScreen

## Badges: every badge in the game, the ones earned in colour — the first six on
## a 3 x 2 grid, and the last, Know to Grow Star, on its own under it.
##
## **Badges are fixed per level**, so a badge is earned exactly when the level
## that awards it is cleared — [member badge_levels] says which. An earned badge
## can be tapped to see it large, the way it looked when it was unlocked but
## without the BADGE UNLOCK! banner and Continue: just "Tap to close" under it,
## and a tap anywhere does. One not yet earned is drawn in the locked rows' grey
## and does not answer.
##
## **The last badge stands apart — decided.** Know to Grow Star is for finishing
## the game, so it is centred under the grid and drawn larger than the rest.
## Every cell is a %BadgeN with a BadgeNArt inside, wherever it sits: six in
## %Grid, the seventh on its own, so moving one does not touch the code.
##
## Android's back closes an open badge rather than leaving, the same as the
## Settings card.

## Each badge as it was unlocked, in grid order. One per cell that has a badge.
@export var badges: Array[Texture2D] = []
## The same badges in grey, for the ones not earned yet. Same order.
@export var badges_locked: Array[Texture2D] = []
## The level that awards each badge, same order. Level 2 and Level 4 appear more
## than once because they award more than one.
@export var badge_levels: Array[LevelData] = []
## The plaque over the count.
@export var sign_label: String = "My Badges"
## The glint that sweeps across an earned badge, and across the one opened
## large. Locked badges stay matte, so the difference shows at a glance.
@export var shine_material: Material = preload("res://shaders/shine.tres")

@onready var _sign: HeaderSign = %HeaderSign
@onready var _view: Control = %BadgeView
@onready var _view_art: ArtSlot = %BadgeViewArt


func _ready() -> void:
	super()
	if badges.size() != badges_locked.size() or badges.size() != badge_levels.size():
		push_warning("Badges: %d badges, %d grey, %d levels"
			% [badges.size(), badges_locked.size(), badge_levels.size()])
	_view.hide()
	_view.gui_input.connect(_on_view_input)
	for i in cell_count():
		var cell := _cell(i)
		if cell == null:
			continue
		var earned := is_earned(i)
		var art: ArtSlot = cell.get_node_or_null("Badge%dArt" % (i + 1)) as ArtSlot
		if art != null:
			art.texture = _badge_art(i, earned)
			art.material = shine_material if earned else null
		cell.disabled = not earned
		if earned:
			cell.pressed.connect(open_badge.bind(i))
	_sign.label_text = sign_label
	_sign.title_text = "%d of %d" % [earned_count(), badges.size()]


## How many badge cells the screen has.
func cell_count() -> int:
	return badges.size()


## Whether the badge in cell [param index] has been earned. A cell with no
## badge never is.
func is_earned(index: int) -> bool:
	if index < 0 or index >= badges.size() or index >= badge_levels.size():
		return false
	var level := badge_levels[index]
	return progress != null and level != null \
		and progress.is_level_cleared(level.id, level.challenges.size())


func earned_count() -> int:
	var count := 0
	for i in badges.size():
		if is_earned(i):
			count += 1
	return count


## Shows one earned badge large, over the grid.
func open_badge(index: int) -> void:
	if not is_earned(index):
		return
	_view_art.texture = badges[index]
	_view_art.material = shine_material
	_view.show()


func close_badge() -> void:
	_view.hide()


func badge_open() -> bool:
	return _view.visible


func _badge_art(index: int, earned: bool) -> Texture2D:
	var art: Array[Texture2D] = badges if earned else badges_locked
	return art[index] if index < art.size() else null


func _cell(index: int) -> Button:
	var cell: Button = get_node_or_null("%%Badge%d" % (index + 1)) as Button
	if cell == null:
		push_warning("Badges: no %%Badge%d in this layout" % (index + 1))
	return cell


func _on_view_input(event: InputEvent) -> void:
	# Release rather than press, so the same touch cannot land on a badge in
	# the grid once the view has gone.
	var touch := event as InputEventScreenTouch
	var click := event as InputEventMouseButton
	if (touch != null and not touch.pressed) or (
		click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed
	):
		accept_event()
		close_badge()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and badge_open():
		close_badge()
		return
	super(what)
