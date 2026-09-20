class_name OptionCard
extends Control

## One draggable item card: the shovel, the watering can, the flower.
##
## The artwork carries the item's name in its own pixels, so this draws nothing
## itself — it is a hit area with a picture in it and a drag behaviour.
##
## Where the card rests depends on the tray behind it, set by [member
## draw_at_rest]:
##
## - **A drawn tray** (Level 1's) has each item already painted into the picture,
##   at exactly the right size and position, so a resting card draws **nothing
##   at all**. Drawing the card on top of it too only ever produced a rim inside
##   a rim, because the standalone cards carry thicker frames than the tray's
##   drawn slots — and by different amounts, so no single scaling lines them all
##   up. The card's own art appears only while it is being dragged.
## - **A blank tray** has empty slots, so the card draws itself at rest, over its
##   slot.
##
## Either way a tried-and-wrong option ends the same: its art gone and its slot
## tinted — see [method mark_spent]. A card with no tray behind it at all keeps
## its art and is darkened in place instead; see [member keep_art_when_spent].
##
## How the card is *chosen* depends on [member draggable]: carried to a target
## on Levels 1, 2 and 4, or tapped where it stands on Level 3, which has no
## tray and no drop zone.
##
## The art keeps its own shape, centred in the card's rect, rather than being
## stretched to it. The item cards are not one shape — from 0.83 wide for the
## flower to 1.06 for the sun — and the slots are square, so stretching squashed
## them by up to 15%.
##
## Dragging sets [member Control.top_level] so the card escapes the container
## that laid it out, while the container keeps reserving its slot. That way a
## card that snaps back lands exactly where it started without the row reflowing
## underneath it.

## Emitted on release. The screen decides whether the drop counts; the card only
## reports where it was let go.
signal dropped(card: OptionCard, at_global: Vector2)

## Emitted when a tap-to-answer card is pressed and released on itself. A stage
## with no tray at all uses this in place of [signal dropped]: there is nowhere
## to carry the card to, so choosing it *is* the answer. A press that slides off
## the card before it is let go is not a tap, the same way a drag let go away
## from the target is not a drop.
signal tapped(card: OptionCard)

## How long a rejected card takes to slide home, in seconds. Short enough not to
## make a child wait, long enough to read as "that went back" rather than a
## glitch.
const RETURN_TIME := 0.25

## Matches an OptionData id in content/*.tres. The stage compares this against
## its own correct answer; the .tres keeps the item's name and hint as
## transcripts for review and voice-over.
@export var option_id: StringName = &"":
	set(value):
		option_id = value
		_apply()

## The item card, with its name already drawn on it. Set per stage in the
## stage's scene, so a card can be seen and moved in the editor.
@export var icon: Texture2D:
	set(value):
		icon = value
		_apply()

## Whether this card is picked up and carried to a target. On for Levels 1, 2
## and 4, which have a tray and a drop zone; off for Level 3, where the card is
## tapped where it stands. A stage sets it for all its cards from
## [member StageScreen.tap_to_answer].
@export var draggable: bool = true

## What a spent card leaves behind.
##
## Over a tray slot the card's art goes and the slot is tinted instead, because
## the slot is still drawn underneath it. A card sitting loose on the garden has
## nothing underneath, so it keeps its art and is darkened where it stands —
## hiding it would leave a dark rectangle floating on the grass. A stage sets it
## from [member StageScreen.tap_to_answer].
@export var keep_art_when_spent: bool = false

## Whether the card shows its own art while sitting in its slot. On for a blank
## tray, whose slots are empty; off for a drawn tray, which already shows the
## item. A stage sets it for all its cards from [member StageScreen.blank_tray].
@export var draw_at_rest: bool = false:
	set(value):
		draw_at_rest = value
		if is_node_ready():
			_rest()

var _dragging := false
## Held down, for a tap-to-answer card. The release may well arrive outside the
## card's own rect, so it is watched for in [method _input] rather than left to
## [method _gui_input], which would never see it and leave the card dark.
var _held := false
## The slide home currently running, if any. Kept so a tap that lands during the
## slide can finish it first rather than race it: see [method _begin_drag].
var _return_tween: Tween = null
var _grab_offset := Vector2.ZERO
var _home_local := Vector2.ZERO
var _home_global := Vector2.ZERO

@onready var _art: ArtSlot = $Art
@onready var _spent_tint: Panel = $Spent


var _spent := false


func _ready() -> void:
	_apply()
	_rest()


func _apply() -> void:
	if _art == null:
		return
	_art.texture = icon
	_art.slot_name = String(option_id)


## Shows the card at rest over a blank tray, or hides it so a drawn tray's slot
## shows through. A card with no artwork yet stays visible either way, so a
## missing asset is still a labelled blank rather than an invisible one. A spent
## card stays hidden: its slot is tinted instead.
func _rest() -> void:
	if _art != null and not _spent:
		_art.visible = draw_at_rest or icon == null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not draggable:
			if event.pressed and not _held:
				_press()
				accept_event()
			return
		if event.pressed and not _dragging:
			_begin_drag(event.global_position)
			accept_event()


func _input(event: InputEvent) -> void:
	# Motion and release are handled here rather than in _gui_input because a
	# dragged card spends most of its time outside its own rect, and a held tap
	# can be let go anywhere on the screen — in both cases _gui_input no longer
	# receives anything.
	if _held:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT 				and not event.pressed:
			_release(event.global_position)
		return
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		global_position = event.global_position - _grab_offset
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		_end_drag(event.global_position)


## A tap-to-answer card under a thumb: the same darken and squash every other
## button in the game does, applied to the card's art rather than to the card,
## so the hit area does not move out from under the finger. Level 3's cards sit
## loose on the garden with nothing painted behind them, so they are free to
## squash — see the art-over-art rule in CLAUDE.md.
func _press() -> void:
	_held = true
	if _art != null:
		_art.modulate = ArtButton.PRESSED_TINT
		PressBounce.press(_art)


func _release(at_global: Vector2) -> void:
	_held = false
	_clear_press()
	if get_global_rect().has_point(at_global):
		tapped.emit(self)


func _clear_press() -> void:
	if _art == null:
		return
	_art.modulate = Color.WHITE
	PressBounce.release(_art)


func _begin_drag(at_global: Vector2) -> void:
	# A tap while the card is still sliding home would otherwise take its
	# half-way point as home, in global coordinates, and the two slides would
	# race until it came to rest off the screen, where no one can tap it again.
	# Land it first, so home is always the real slot.
	if _return_tween != null:
		_return_tween.kill()
		_arrive_home()
	_dragging = true
	_home_local = position
	_home_global = global_position
	_grab_offset = at_global - global_position
	top_level = true
	global_position = _home_global
	z_index = 10
	if _art != null:
		_art.show()


func _end_drag(at_global: Vector2) -> void:
	_dragging = false
	z_index = 0
	dropped.emit(self, at_global)


## Slides the card back to where the drag started. Called by the screen when a
## drop is rejected, so the card does not decide its own fate.
func return_home() -> void:
	# The home position is only meaningful once a drag has actually begun.
	# Without this a card that never moved would be tweened to the origin and
	# fly to the corner of the screen.
	if not top_level:
		return
	z_index = 0
	_return_tween = create_tween()
	_return_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_return_tween.tween_property(self, "global_position", _home_global, RETURN_TIME)
	_return_tween.finished.connect(_arrive_home)


## Settles the card back into its slot, at the end of a slide or cut short by a
## new tap.
func _arrive_home() -> void:
	_return_tween = null
	# Dropping out of top_level makes Godot read `position` as parent-relative
	# again. It currently holds global coordinates, so it has to be restored by
	# hand — otherwise the card lands a screen-height below its row and looks
	# like it was deleted.
	top_level = false
	position = _home_local
	_rest()


## Stops this card responding to touch, for when the stage has been answered.
func freeze() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(false)


## Retires this option: the slot it came from is tinted and stops responding.
##
## The tint is a rounded panel sized to the card's own rect, which is the tray's
## slot, so it dims that slot and nothing else. On a drawn tray, showing the
## greyed card art instead would put its thicker frame back over the slot, which
## is the mismatch this whole arrangement exists to avoid. On a blank tray the
## slot is left empty and darkened: the card's icon goes, since it can never be
## picked up again anyway.
##
## The option is dimmed rather than deleted: removing it would erase the child's
## own attempt, and leaving it live invites the same wrong answer again.
func mark_spent() -> void:
	_spent = true
	if _art != null:
		# A loose card has no slot behind it to fall back to, so it stays and
		# takes the tint itself. Any press still on it is dropped outright
		# rather than sprung back, since it is not a control any more.
		_art.modulate = Color.WHITE
		PressBounce.reset(_art)
		_art.visible = keep_art_when_spent
	if _spent_tint != null:
		_spent_tint.show()
	freeze()
