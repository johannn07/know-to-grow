extends SceneTree

## Plays Level 2's stage scenes: drop an item off target, drop a wrong one, drop
## the right one, and follow the stage on.
##
##   godot --headless --path . -s res://tools/verify_level_2.gd
##
## Level 2 is built differently from Level 1, so it has its own walk. Its prompt
## and header are live text read from content at runtime, it has no fun fact,
## its cards draw themselves on a blank tray, and its Correct cards have their
## Continue below the card. Each of those is checked here on every stage, along
## with the drift check Level 1 has: that a scene's answer and its cards still
## agree with content/level_2_monitoring.tres.

const FIRST_STAGE := "res://scenes/levels/level_2/stage_1.tscn"
const CONTENT := "res://content/level_2_monitoring.tres"

var _failures := 0
var _level: LevelData


func _initialize() -> void:
	await process_frame
	# Playing records real progress, so start from nothing and clear up after.
	var state: GameStateStore = root.get_node_or_null("/root/GameState") as GameStateStore
	if state != null:
		state.reset()
	_level = load(CONTENT)
	_expect(_level != null, "level content loads")

	var path := FIRST_STAGE
	var seen := 0
	while not path.is_empty() and path.begins_with("res://scenes/levels/level_2/"):
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
			state.stars_for(&"level_2", 1) > 0,
			"playing Situation 1 recorded progress (%d star(s))" % state.stars_for(&"level_2", 1)
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
	print("--- level_2 %s ---" % label)

	var cards := stage.cards()
	var overlay: Control = stage.get_node("%Overlay")
	var hotspot: ArtButton = stage.get_node("%OverlayButton")

	# --- the scene still agrees with the reviewed content ---
	var challenge := _level.get_challenge(stage.challenge_id)
	_expect(challenge != null, "%s challenge '%s' is in the content" % [label, stage.challenge_id])
	if challenge == null:
		stage.queue_free()
		return ""
	_expect(stage.level_id == &"level_2", "%s files its progress under level_2" % label)
	_expect(stage.level_content == _level, "%s reads the Level 2 content file" % label)
	_expect(
		challenge.correct_option_id == stage.correct_option_id,
		"%s answer '%s' matches the content" % [label, stage.correct_option_id]
	)
	# Order matters as well as membership: each card sits over one slot, and the
	# content lists them left to right.
	var scene_ids: Array[StringName] = []
	for card in cards:
		scene_ids.append(card.option_id)
	var content_ids: Array[StringName] = []
	for option in challenge.options:
		content_ids.append(option.id)
	_expect(scene_ids == content_ids, "%s cards %s match the content, in order" % [label, scene_ids])

	# --- Level 2's own dressing ---
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
	_expect(stage.get_node_or_null("%FunFact") == null, "%s has no fun fact strip" % label)
	_expect((stage.get_node("%Background") as ArtSlot).texture != null, "%s has its garden" % label)
	_expect(stage.blank_tray, "%s is on the blank tray" % label)
	for card in cards:
		_expect(
			card.icon != null and card.get_node("Art").visible,
			"%s card '%s' shows itself in its slot" % [label, card.option_id]
		)
		_expect(
			card.size.x >= 160.0 and card.size.y >= 160.0,
			"%s card '%s' clears 160 px (is %dx%d)" % [label, card.option_id, card.size.x, card.size.y]
		)

	var centre: Vector2 = stage.get_node("%DropZone").get_global_rect().get_center()

	# --- off target: not an answer ---
	var stray: OptionCard = cards[0]
	stray._begin_drag(stray.global_position + Vector2(20.0, 20.0))
	stray._end_drag(Vector2(20.0, 20.0))
	await _settle()
	await _rest()
	_expect(not overlay.visible, "%s a drop off the target is not an answer" % label)
	_expect(stray.get_node("Art").visible, "%s that card is shown back in its slot" % label)

	# --- wrong answer ---
	var wrong: OptionCard = null
	for card in cards:
		if not stage.is_correct(card.option_id):
			wrong = card
			break
	wrong._begin_drag(wrong.global_position + Vector2(20.0, 20.0))
	wrong._end_drag(centre)
	await _settle()
	_expect(overlay.visible, "%s a wrong answer shows the Oops card" % label)
	_expect(not hotspot.bounce_art, "%s Choose Again, on the card, does not bounce" % label)
	_expect(
		hotspot.size.x >= 160.0 and hotspot.size.y >= 160.0,
		"%s Choose Again clears 160 px" % label
	)
	await _rest()
	_expect(
		not wrong.get_node("Art").visible and wrong.get_node("Spent").visible,
		"%s the wrong card leaves a darkened empty slot" % label
	)
	hotspot.pressed.emit()
	await _settle()
	_expect(not overlay.visible, "%s Choose Again dismisses the Oops card" % label)

	# --- right answer ---
	var right: OptionCard = null
	for card in cards:
		if card.option_id == stage.correct_option_id:
			right = card
	right._begin_drag(right.global_position + Vector2(20.0, 20.0))
	right._end_drag(centre)
	await _settle()
	_expect(overlay.visible, "%s the right answer shows the Correct card" % label)
	# Level 2's Correct cards have no Continue drawn on them, so it sits below
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


func _settle() -> void:
	for i in 4:
		await process_frame


## Waits out a card's slide home, which is a real timed tween.
func _rest() -> void:
	await create_timer(OptionCard.RETURN_TIME + 0.2).timeout


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s" % label)
