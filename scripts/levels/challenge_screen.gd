extends SubScreen

## Plays one challenge — one "stage" — from a [LevelData].
##
## Every stage in the game is the same turn: show a prompt, the learner picks or
## drags one of N options, it is right or it is wrong. So this screen is driven
## entirely by data. Nothing here knows it is Level 1 Stage 1; swapping the
## resource and the index plays a different stage.
##
## No wording is written here. The header, the prompt, the feedback cards and
## the item names are all drawn into their artwork, and the matching strings in
## the .tres are transcripts that are never rendered. See art/MANIFEST.md.

## Touch floor at the 1080-wide design resolution. Both feedback cards have
## their button drawn smaller than this, so the hotspot laid over one is grown
## to reach it — generous invisible targets cost nothing and a small thumb
## needs them.
const MIN_TOUCH := 160.0

## Where each feedback card's drawn button sits, as fractions of that card's own
## image. Measured off the art; the art is the only place these exist.
const CONTINUE_RECT := Rect2(0.20, 0.785, 0.59, 0.115)
const CHOOSE_AGAIN_RECT := Rect2(0.315, 0.71, 0.41, 0.145)

@export var level: LevelData
@export var challenge_index: int = 0
@export var option_card_scene: PackedScene
## Where to go when the level runs out of stages that have art wired up.
@export_file("*.tscn") var done_scene_path: String = "res://scenes/ui/hub.tscn"

var _challenge: ChallengeData
var _answered := false

@onready var _background: ArtSlot = %Background
@onready var _header: ArtSlot = %Header
@onready var _prompt: ArtSlot = %Prompt
@onready var _drop_zone: Control = %DropZone
@onready var _cards: HBoxContainer = %Cards
@onready var _overlay: Control = %Overlay
@onready var _overlay_aspect: AspectRatioContainer = %OverlayAspect
@onready var _overlay_art: ArtSlot = %OverlayArt
@onready var _overlay_button: Button = %OverlayButton


func _ready() -> void:
	super()
	_overlay.hide()
	_overlay_button.pressed.connect(_on_overlay_pressed)
	_show_challenge()


func _show_challenge() -> void:
	if level == null or challenge_index >= level.challenges.size():
		push_warning("ChallengeScreen: no challenge at index %d" % challenge_index)
		return
	_challenge = level.challenges[challenge_index]
	_answered = false
	_set_state(_challenge.scene_state)
	_header.texture = _challenge.header_art
	_prompt.texture = _challenge.prompt_art
	_build_cards()


## Swaps the background to a named garden state. The names come from the
## challenge data ("empty_bed", "hole_dug"); the pictures come from the level.
func _set_state(state: StringName) -> void:
	if level.scene_art.has(state):
		_background.texture = level.scene_art[state]


func _build_cards() -> void:
	for child in _cards.get_children():
		child.queue_free()
	var options := _challenge.options.duplicate()
	if level.shuffle_options:
		options.shuffle()
	for option in options:
		var card: OptionCard = option_card_scene.instantiate()
		_cards.add_child(card)
		card.data = option
		card.dropped.connect(_on_card_dropped)


func _on_card_dropped(card: OptionCard, at_global: Vector2) -> void:
	if _answered:
		return
	if not _drop_zone.get_global_rect().has_point(at_global):
		# Let go somewhere that is not the target. That is not an answer — the
		# child changed their mind or missed — so the card goes back and stays
		# every bit as pickable as before.
		card.return_home()
		return
	if _challenge.is_correct(card.data.id):
		_answered = true
		card.freeze()
		_set_state(_challenge.success_state)
		_show_feedback(_challenge.correct_art, CONTINUE_RECT)
	else:
		# Actually tried on the target and wrong. The card returns to its slot
		# greyed out: still visible, so the attempt is not erased, but no longer
		# pickable, so the same wrong answer cannot be repeated.
		card.return_home()
		card.mark_spent()
		_show_feedback(level.wrong_art, CHOOSE_AGAIN_RECT)


func _show_feedback(art: Texture2D, button_rect: Rect2) -> void:
	if art == null:
		push_warning("ChallengeScreen: no feedback art for '%s'" % _challenge.id)
		return
	_overlay_art.texture = art
	# The hotspot is positioned in fractions of the image, so the node it sits
	# in has to be exactly the image's shape — no letterboxing.
	_overlay_aspect.ratio = float(art.get_width()) / float(art.get_height())
	_overlay.show()
	_place_hotspot(_overlay_button, button_rect)


## Anchors a hotspot over a button that is drawn into the artwork, then pads it
## out until it clears [constant MIN_TOUCH] in both directions.
func _place_hotspot(button: Button, frac: Rect2) -> void:
	button.anchor_left = frac.position.x
	button.anchor_top = frac.position.y
	button.anchor_right = frac.end.x
	button.anchor_bottom = frac.end.y
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0
	await get_tree().process_frame
	var pad_x: float = maxf(0.0, (MIN_TOUCH - button.size.x) * 0.5)
	var pad_y: float = maxf(0.0, (MIN_TOUCH - button.size.y) * 0.5)
	button.offset_left = -pad_x
	button.offset_right = pad_x
	button.offset_top = -pad_y
	button.offset_bottom = pad_y


func _on_overlay_pressed() -> void:
	_overlay.hide()
	if not _answered:
		# "Choose Again" — the card has already slid back, so there is nothing
		# to undo. No penalty, no score, no "Wrong" label.
		return
	_advance()


func _advance() -> void:
	var next := challenge_index + 1
	# Stages are being built one at a time. A stage with no prompt art is one
	# that has not been made yet, so stop rather than show a screen of
	# placeholders.
	if next < level.challenges.size() and level.challenges[next].prompt_art != null:
		challenge_index = next
		_show_challenge()
		return
	if done_scene_path.is_empty() or not ResourceLoader.exists(done_scene_path):
		push_warning("ChallengeScreen: done scene is unset or missing")
		return
	get_tree().change_scene_to_file(done_scene_path)
