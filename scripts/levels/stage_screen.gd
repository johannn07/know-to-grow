class_name StageScreen
extends SubScreen

## Shared behaviour for one stage of a level: drag an item onto the target, get
## it right or wrong, move on.
##
## This holds only the parts that would otherwise be copied into all nineteen
## stages — the drag handling, the feedback overlay, the hotspot sizing and the
## rule about what a wrong card does. Everything a stage *shows* lives in that
## stage's own scene, and anything a stage does differently belongs in its own
## script, which extends this one.
##
## A stage's garden never changes while the stage is on screen. The backgrounds
## are independent drawings rather than one scene with a hole added to it — every
## cloud, tree and fence post sits slightly differently — so swapping one for the
## next made the whole garden jump, which was very visible behind the feedback
## card. The change now happens at the stage boundary, where a cut is expected.
##
## A stage scene is expected to have: %Background, %Cards holding [OptionCard]
## children, and %Overlay / %OverlayAspect / %OverlayArt / %OverlayButton for
## the feedback card. A drag stage also has a %DropZone; a tap stage does not —
## see [member tap_to_answer].
##
## No wording is set here or in any stage scene. The header, the prompt, the
## item names and both feedback cards carry their text in their own pixels, and
## content/*.tres records that wording as a transcript for review and
## voice-over. See art/MANIFEST.md.

## Where the drawn button sits on the Level 1 feedback cards, as fractions of
## the card's own image. Measured off the art, which is the only place these
## exist. A card with no button drawn on it uses [constant WHOLE_CARD] instead.
const CONTINUE_RECT := Rect2(0.20, 0.785, 0.59, 0.115)
const CHOOSE_AGAIN_RECT := Rect2(0.315, 0.71, 0.41, 0.145)

## For a feedback card that carries no drawn button: the whole card is the
## target. Stage 4's Correct card is borrowed from Level 2, whose cards have no
## Continue on them.
##
## Doubles as the card's own extent, for deciding whether a button's artwork
## lands on the card or below it. See [method _show_feedback].
const WHOLE_CARD := Rect2(0.0, 0.0, 1.0, 1.0)

## Where the button *artwork* sits on the Level 1 feedback cards. These are not
## the hotspot rects above: a hotspot is padded out to reach the touch floor,
## while the art has to land exactly on the button already drawn into the card,
## or the child sees two buttons. Measured by aligning the new button's body to
## the painted one's, so the new art covers the old completely.
const CONTINUE_ART_RECT := Rect2(0.1818, 0.7705, 0.6105, 0.1532)
const CHOOSE_AGAIN_ART_RECT := Rect2(0.2736, 0.6849, 0.5130, 0.2345)

## A card with no Continue painted on it gets one drawn just below it instead,
## which is where the y past 1.0 comes from — these are fractions of the card,
## and the button sits outside its bottom edge. Stage 4's borrowed Level 2 card
## is the one that needs this.
const CONTINUE_BELOW_CARD_RECT := Rect2(0.265, 1.06, 0.47, 0.1707)

@export_group("Answer")
## Which level this stage belongs to, matching the `id` in content/*.tres. With
## [member stage_number] it is how progress is filed against this stage.
@export var level_id: StringName = &""
## Where this stage sits in its level, counting from 1. It decides which stage
## select row this is, so it has to match the order the rows are drawn in.
@export var stage_number: int = 0
## Matches a ChallengeData in content/*.tres. The smoke test checks this scene
## against it, and a stage with a %PromptBubble reads its prompt from it.
@export var challenge_id: StringName = &""
## The level's reviewed content file. Only a stage with a %PromptBubble or a
## %HeaderSign needs it: their words are that challenge's transcripts, read here
## at runtime so the reviewed transcript is the only copy of them.
@export var level_content: LevelData
## The [member OptionCard.option_id] that is correct here.
@export var correct_option_id: StringName = &""
## Answers that also count, for a stage with more than one good answer.
@export var alternate_correct_ids: Array[StringName] = []

@export_group("Interaction")
## On when the answer is **tapped** rather than dragged — Level 3, which has no
## tray and no target to carry a card to.
##
## It is set in the scene rather than read from the challenge's `interaction`
## because a tap stage is built differently: it has no %DropZone, and reading it
## from an optional resource would mean a stage with no level_content silently
## became a drag stage with nothing to drag to. `verify_level_3` checks the two
## still agree.
##
## A tap stage has no tray at all, so its cards always draw themselves and are
## always dealt afresh — the two things [member blank_tray] turns on for a stage
## that does have one — and a spent card is darkened where it stands rather than
## leaving an empty slot behind.
@export var tap_to_answer: bool = false
## On to keep the cards where the scene puts them instead of dealing them afresh
## each play. Level 4's Correct cards name the answer by a drawn letter,
## "Correct Match: B", so its cards must stay in their drawn A/B/C order or the
## letter points at the wrong one. Only matters to a stage whose cards would
## otherwise be shuffled: see [member tap_to_answer] and [member blank_tray].
@export var keep_card_order: bool = false

@export_group("Art")
## On when this stage's tray has empty slots rather than its items painted in, so
## every card draws itself at rest over its slot. Off for Level 1's drawn trays,
## where the picture already shows each item. See [member OptionCard.draw_at_rest].
@export var blank_tray: bool = false
## The "Correct Answer!" card for this stage, with Continue drawn into it.
@export var correct_card: Texture2D
## The "Oops!" card, with Choose Again drawn into it.
@export var wrong_card: Texture2D

## The Continue button, drawn over the one painted into [member correct_card].
@export var continue_art: Texture2D
## Choose Again, drawn over the one painted into [member wrong_card].
@export var choose_again_art: Texture2D

@export_group("Feedback hotspots")
## Where the Continue button is drawn on [member correct_card], in fractions of
## that image. Use [constant WHOLE_CARD] when the card has no button drawn on it.
@export var correct_button_rect: Rect2 = CONTINUE_RECT
## Where Choose Again is drawn on [member wrong_card].
@export var wrong_button_rect: Rect2 = CHOOSE_AGAIN_RECT
## Where [member continue_art] is drawn. Use [constant CONTINUE_BELOW_CARD_RECT]
## for a card with no Continue painted on it; a zero-sized rect hides it.
@export var correct_art_rect: Rect2 = CONTINUE_ART_RECT
## Where [member choose_again_art] is drawn.
@export var wrong_art_rect: Rect2 = CHOOSE_AGAIN_ART_RECT

@export_group("Celebration")
## Stars bursting out of the right card, over the Correct card. Every stage has
## it by default, so none of the nineteen scenes needs to set it; clear it on a
## stage that should not. See [SparkleBurst].
@export var correct_burst: PackedScene = preload("res://scenes/components/sparkle_burst.tscn")

@export_group("Flow")
## The next stage. Empty means this is the last one built.
@export_file("*.tscn") var next_stage_path: String = ""
## Where to go when there is no next stage.
@export_file("*.tscn") var done_scene_path: String = "res://scenes/ui/hub.tscn"

var _answered := false

## Wrong answers actually dropped on the target before the right one. Drops that
## missed the target are not attempts — the child changed their mind. This is
## what the stars are worked out from.
var _wrong_attempts := 0

## The target a card is carried to. A tap stage has none: see
## [member tap_to_answer].
@onready var _drop_zone: Control = get_node_or_null("%DropZone") as Control
@onready var _cards: Control = %Cards
@onready var _overlay: Control = %Overlay
@onready var _overlay_aspect: AspectRatioContainer = %OverlayAspect
@onready var _overlay_art: ArtSlot = %OverlayArt
@onready var _overlay_button_art: ArtSlot = %OverlayButtonArt
@onready var _overlay_button: ArtButton = %OverlayButton


func _ready() -> void:
	super()
	_overlay.hide()
	_overlay_button.pressed.connect(_on_overlay_pressed)
	# Loose: the card draws itself and its place is dealt rather than painted.
	# True of a blank tray's slots, and of a tap stage, which has no tray.
	var loose := blank_tray or tap_to_answer
	for card in cards():
		card.draggable = not tap_to_answer
		card.draw_at_rest = loose
		card.keep_art_when_spent = tap_to_answer
		if tap_to_answer:
			card.tapped.connect(_on_card_tapped)
		else:
			card.dropped.connect(_on_card_dropped)
	if loose and not keep_card_order:
		shuffle_cards()
	if not tap_to_answer and _drop_zone == null:
		push_warning("%s: no %%DropZone, so a dragged card has nowhere to land" % name)
	_show_prompt()
	_show_header()


## The stage's option cards, in scene order — which is the content file's order,
## not necessarily where they sit on screen. See [method shuffle_cards].
func cards() -> Array[OptionCard]:
	var found: Array[OptionCard] = []
	for child in _cards.get_children():
		if child is OptionCard:
			found.append(child)
	return found


## Deals the cards into the tray's slots in a new order, so the answer is not
## always in the same place when a stage is played again. Only a blank tray can
## do this: on Level 1's drawn trays each item is painted into its slot, and a
## card moved off its own painting would pick up the wrong item.
##
## The slots are the cards' own anchors and offsets as the scene places them, so
## the set of places is unchanged and only who stands where moves.
func shuffle_cards() -> void:
	var dealt: Array[OptionCard] = cards()
	var slots: Array = []
	for card in dealt:
		slots.append(_slot_of(card))
	slots.shuffle()
	for i in dealt.size():
		_put_in_slot(dealt[i], slots[i])


func _slot_of(card: Control) -> Array[float]:
	var slot: Array[float] = []
	for side in 4:
		slot.append(card.get_anchor(side))
	for side in 4:
		slot.append(card.get_offset(side))
	return slot


func _put_in_slot(card: Control, slot: Array[float]) -> void:
	for side in 4:
		card.set_anchor(side, slot[side])
	for side in 4:
		card.set_offset(side, slot[4 + side])


func is_correct(option_id: StringName) -> bool:
	return option_id == correct_option_id or option_id in alternate_correct_ids


func _on_card_dropped(card: OptionCard, at_global: Vector2) -> void:
	if _answered:
		return
	if _drop_zone == null or not _drop_zone.get_global_rect().has_point(at_global):
		# Let go somewhere that is not the target. That is not an answer — the
		# child changed their mind or missed — so the card goes back and stays
		# every bit as pickable as before.
		card.return_home()
		return
	_answer(card)


## A tap stage has nowhere to carry a card to, so choosing one is the whole
## attempt. There is no drop to miss and nothing to slide home.
func _on_card_tapped(card: OptionCard) -> void:
	if _answered:
		return
	_answer(card)


## One wrong-or-right, however the child got here. [method OptionCard.return_home]
## does nothing for a card that never left its place, so a tap takes this path
## unchanged.
func _answer(card: OptionCard) -> void:
	if is_correct(card.option_id):
		_answered = true
		card.freeze()
		if audio != null:
			audio.play_correct()
		if progress != null:
			progress.record_stage_cleared(level_id, stage_number, _wrong_attempts)
		else:
			push_warning("%s: no GameState, so this stage was not recorded" % name)
		on_correct(card)
		_burst_from(card)
		_show_feedback(correct_card, correct_button_rect, continue_art, correct_art_rect)
	else:
		# Actually chosen, and wrong. The card goes back greyed out: still
		# visible, so the attempt is not erased, but no longer pickable, so the
		# same wrong answer cannot be repeated.
		card.return_home()
		card.mark_spent()
		_wrong_attempts += 1
		if audio != null:
			audio.play_wrong()
		on_wrong(card)
		_show_feedback(wrong_card, wrong_button_rect, choose_again_art, wrong_art_rect)


## Fires [member correct_burst] from the middle of the card that was right —
## where it was dropped, or where it stands on a tap stage.
func _burst_from(card: Control) -> void:
	if correct_burst == null:
		return
	var burst := correct_burst.instantiate() as SparkleBurst
	if burst == null:
		push_warning("%s: correct_burst is not a SparkleBurst" % name)
		return
	add_child(burst)
	burst.burst_at(card.get_global_rect().get_center())


## Writes this stage's question into its speech bubble. A stage without a
## %PromptBubble has its prompt drawn into the art instead — Level 1's four do —
## and there is nothing to fill.
func _show_prompt() -> void:
	var bubble: PromptBubble = get_node_or_null("%PromptBubble") as PromptBubble
	if bubble == null:
		return
	var challenge: ChallengeData = _challenge("bubble")
	if challenge != null:
		bubble.text = challenge.prompt_transcript


## Writes the plaque and banner onto a blank header sign. A stage without a
## %HeaderSign has its header drawn into the art — Level 1's four do.
func _show_header() -> void:
	var header: HeaderSign = get_node_or_null("%HeaderSign") as HeaderSign
	if header == null:
		return
	var challenge: ChallengeData = _challenge("header")
	if challenge != null:
		header.label_text = challenge.header_label_transcript
		header.title_text = challenge.header_title_transcript


## This stage's challenge in [member level_content], or null with a warning
## naming what is left blank because of it.
func _challenge(left_blank: String) -> ChallengeData:
	var challenge: ChallengeData = null
	if level_content != null:
		challenge = level_content.get_challenge(challenge_id)
	if challenge == null:
		push_warning("%s: no challenge '%s' in level_content, so the %s is blank"
			% [name, challenge_id, left_blank])
	return challenge


## Hooks for a stage that needs to do something of its own. Override in the
## stage's script; there is no need to call super().
func on_correct(_card: OptionCard) -> void:
	pass


func on_wrong(_card: OptionCard) -> void:
	pass


func _show_feedback(
	art: Texture2D, button_rect: Rect2, button_art: Texture2D, art_rect: Rect2
) -> void:
	if art == null:
		push_warning("%s: no feedback art assigned in the scene" % name)
		return
	_overlay_art.texture = art
	# The hotspot is placed in fractions of the image, so the node it sits in
	# has to be exactly the image's shape — no letterboxing.
	_overlay_aspect.ratio = float(art.get_width()) / float(art.get_height())
	# The button art covers the one painted into the card, so it is only shown
	# where there is one to cover — Stage 4's borrowed card has none.
	_overlay_button_art.texture = button_art
	_overlay_button_art.visible = button_art != null and art_rect.has_area()
	if _overlay_button_art.visible:
		# The art is anchored but never padded: it has to stay exactly on the
		# button painted into the card, while the hotspot over it does not.
		anchor_to(_overlay_button_art, art_rect)
	# A button drawn *on* the card covers one painted into it, exactly, so a
	# squash would uncover the painted one rather than read as a press — the
	# same reason the stage select rows do not bounce. A button drawn below the
	# card has nothing underneath, so it bounces as every other button does.
	_overlay_button.bounce_art = not WHOLE_CARD.intersects(art_rect)
	# Both cards share one hotspot and one art node, so a tint left over from the
	# last answer would otherwise still be on them when the next card appears.
	_overlay_button.clear_tint()
	_overlay.show()
	place_hotspot(_overlay_button, button_rect)


func _on_overlay_pressed() -> void:
	_overlay.hide()
	if not _answered:
		# "Choose Again" — the card has already slid back, so there is nothing
		# to undo. No penalty, no score, no "Wrong" label.
		return
	advance()


func advance() -> void:
	var target := next_stage_path if not next_stage_path.is_empty() else done_scene_path
	if target.is_empty() or not ResourceLoader.exists(target):
		push_warning("%s: nowhere to go — '%s' is unset or missing" % [name, target])
		return
	get_tree().change_scene_to_file(target)
