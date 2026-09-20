extends SceneTree

## Plays Level 3's stage scenes: press a card and slide off it, tap a wrong one,
## tap the right one, and follow the stage on.
##
##   godot --headless --path . -s res://tools/verify_level_3.gd
##
## Level 3 is built differently again. It is **tapped, not dragged**: there is no
## tray, no drop zone and nothing to carry, so a card is chosen where it stands
## and a wrong one is darkened in place. Its header is its own sign at 760 px
## rather than Level 2's at 660. Each of those is checked here on every stage,
## along with the drift check the other levels have: that a scene's answer, its
## cards and its interaction still agree with content/level_3_identifying.tres.
##
## It walks the chain from Stage 1, so stages added later are picked up without
## this file changing.
##
## Playing records real progress, so this **writes to `user://progress.cfg`** and
## resets it to empty afterwards.

const FIRST_STAGE := "res://scenes/levels/level_3/stage_1.tscn"
const CONTENT := "res://content/level_3_identifying.tres"
const STAGE_DIR := "res://scenes/levels/level_3/"
## What a Level 3 stage gives its header sign. See tools/verify_live_text.gd.
const HEADER_WIDTH := 760.0

var _failures := 0
var _level: LevelData


func _initialize() -> void:
	await process_frame
	var state: GameStateStore = root.get_node_or_null("/root/GameState") as GameStateStore
	if state != null:
		state.reset()
	_level = load(CONTENT)
	_expect(_level != null, "level content loads")

	await _check_shuffle()

	var path := FIRST_STAGE
	var seen := 0
	while not path.is_empty() and path.begins_with(STAGE_DIR):
		if not ResourceLoader.exists(path):
			_expect(false, "stage scene exists: %s" % path)
			break
		path = await _play(path)
		seen += 1
		if seen > 10:
			_expect(false, "stage chain does not loop forever")
			break

	print("\n%d stage(s) played" % seen)
	_expect(seen > 0, "at least one stage was played")
	if state != null:
		_expect(
			state.stars_for(&"level_3", 1) > 0,
			"playing Stage 1 recorded progress (%d star(s))" % state.stars_for(&"level_3", 1)
		)
		state.reset()
	print("%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


## Plays one stage and returns the scene it leads to.
func _play(scene_path: String) -> String:
	var stage: StageScreen = (load(scene_path) as PackedScene).instantiate()
	root.add_child(stage)
	stage.set_deferred("size", Vector2(1080, 1920))
	await _settle()
	var label := scene_path.get_file().get_basename()
	print("--- level_3 %s ---" % label)

	var cards := stage.cards()
	var overlay: Control = stage.get_node("%Overlay")
	var hotspot: ArtButton = stage.get_node("%OverlayButton")

	# --- the scene still agrees with the reviewed content ---
	var challenge := _level.get_challenge(stage.challenge_id)
	_expect(challenge != null, "%s challenge '%s' is in the content" % [label, stage.challenge_id])
	if challenge == null:
		stage.queue_free()
		return ""
	_expect(stage.level_id == &"level_3", "%s files its progress under level_3" % label)
	_expect(stage.level_content == _level, "%s reads the Level 3 content file" % label)
	_expect(
		challenge.correct_option_id == stage.correct_option_id,
		"%s answer '%s' matches the content" % [label, stage.correct_option_id]
	)
	# tap_to_answer is set in the scene, since a tap stage is built without a
	# %DropZone. This is the check that keeps it in step with the content.
	_expect(
		stage.tap_to_answer and challenge.interaction == ChallengeData.Interaction.TAP,
		"%s is tapped, and the content says so too" % label
	)
	var scene_ids: Array[StringName] = []
	for card in cards:
		scene_ids.append(card.option_id)
	var content_ids: Array[StringName] = []
	for option in challenge.options:
		content_ids.append(option.id)
	_expect(scene_ids == content_ids, "%s cards %s match the content, in order" % [label, scene_ids])

	# --- Level 3's own dressing ---
	_expect(stage.get_node_or_null("%DropZone") == null, "%s has no drop zone" % label)
	_expect(stage.get_node_or_null("%FunFact") == null, "%s has no fun fact strip" % label)
	_expect((stage.get_node("%Background") as ArtSlot).texture != null, "%s has its garden" % label)
	var bubble: PromptBubble = stage.get_node_or_null("%PromptBubble") as PromptBubble
	var header: HeaderSign = stage.get_node_or_null("%HeaderSign") as HeaderSign
	_expect(
		bubble != null and bubble.text == challenge.prompt_transcript,
		"%s bubble says the reviewed prompt" % label
	)
	_expect(
		header != null and header.label_text == challenge.header_label_transcript
			and header.title_text == challenge.header_title_transcript,
		"%s header says \"%s\" / \"%s\""
			% [label, challenge.header_label_transcript, challenge.header_title_transcript]
	)
	_expect(
		header != null and is_equal_approx(header.size.x, HEADER_WIDTH),
		"%s gives its header %d px, the width its wording was fitted at (is %d)"
			% [label, HEADER_WIDTH, 0 if header == null else header.size.x]
	)
	for card in cards:
		_expect(
			card.icon != null and card.get_node("Art").visible,
			"%s card '%s' draws itself" % [label, card.option_id]
		)
		_expect(not card.draggable, "%s card '%s' is tapped, not dragged" % [label, card.option_id])
		_expect(
			card.size.x >= 160.0 and card.size.y >= 160.0,
			"%s card '%s' clears 160 px (is %dx%d)" % [label, card.option_id, card.size.x, card.size.y]
		)

	# --- a press that slides off the card is not an answer ---
	var stray: OptionCard = cards[0]
	stray._press()
	stray._release(Vector2(-500.0, -500.0))
	await _settle()
	_expect(not overlay.visible, "%s a press let go off a card is not an answer" % label)
	_expect(not stray.get_node("Spent").visible, "%s that card is still tappable" % label)

	# --- a wrong tap ---
	var wrong: OptionCard = null
	for card in cards:
		if not stage.is_correct(card.option_id):
			wrong = card
			break
	_tap(wrong)
	await _settle()
	_expect(overlay.visible, "%s a wrong tap shows the Oops card" % label)
	_expect(not hotspot.bounce_art, "%s Choose Again, on the card, does not bounce" % label)
	_expect(
		hotspot.size.x >= 160.0 and hotspot.size.y >= 160.0,
		"%s Choose Again clears 160 px" % label
	)
	_expect(
		wrong.get_node("Art").visible and wrong.get_node("Spent").visible,
		"%s the wrong card stays on screen, darkened where it stands" % label
	)
	hotspot.pressed.emit()
	await _settle()
	_expect(not overlay.visible, "%s Choose Again dismisses the Oops card" % label)

	# --- the right tap ---
	var right: OptionCard = null
	for card in cards:
		if card.option_id == stage.correct_option_id:
			right = card
	_tap(right)
	await _settle()
	_expect(overlay.visible, "%s the right tap shows the Correct card" % label)
	# Level 3's Correct cards have no Continue drawn on them, so it sits below
	# the card with nothing behind it, and bounces.
	_expect(hotspot.bounce_art, "%s Continue, below the card, bounces" % label)
	_expect(
		hotspot.size.x >= 160.0 and hotspot.size.y >= 160.0,
		"%s Continue clears 160 px" % label
	)

	var next := stage.next_stage_path if not stage.next_stage_path.is_empty() else stage.done_scene_path
	_expect(ResourceLoader.exists(next), "%s leads on to %s" % [label, next.get_file()])
	stage.queue_free()
	await process_frame
	return next


## Every play deals the cards into the stage's three places afresh. The places
## themselves never move — only which card is in which.
func _check_shuffle() -> void:
	print("--- shuffle ---")
	var scene: PackedScene = load(FIRST_STAGE)
	var authored: StageScreen = scene.instantiate()
	var slots: Array = []
	# Read before _ready, which is where the deal happens.
	for card in authored.get_node("%Cards").get_children():
		slots.append(_slot_key(card))
	slots.sort()
	authored.free()

	var answer_slots := {}
	var same_slots := true
	for i in 30:
		var stage: StageScreen = scene.instantiate()
		root.add_child(stage)
		var dealt: Array = []
		for card in stage.cards():
			dealt.append(_slot_key(card))
			if card.option_id == stage.correct_option_id:
				answer_slots[_slot_key(card)] = true
		dealt.sort()
		same_slots = same_slots and dealt == slots
		stage.free()
	_expect(same_slots, "every deal uses exactly the scene's three places")
	_expect(
		answer_slots.size() > 1,
		"over 30 plays the answer sat in %d different places" % answer_slots.size()
	)


func _slot_key(card: Control) -> String:
	return "%.1f,%.1f,%.1f,%.1f" % [card.offset_left, card.offset_top, card.offset_right, card.offset_bottom]


func _tap(card: OptionCard) -> void:
	card._press()
	card._release(card.get_global_rect().get_center())


func _settle() -> void:
	for i in 4:
		await process_frame


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s" % label)
