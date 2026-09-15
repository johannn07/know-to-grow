extends SceneTree

## Walks Level 1's stage scenes and plays each one: drop a wrong item, dismiss
## the Oops card, drop the right one, check the garden changed, then follow
## next_stage_path to the stage after it.
##
##   godot --headless --path . -s res://tools/verify_level_1.gd
##
## The stages are hand-built scenes now, so two kinds of thing can go wrong and
## neither shows up in a screenshot. One is behaviour — whether a drop was
## accepted, whether a wrong answer was penalised, whether a hotspot is big
## enough for a thumb. The other is drift: a scene's answer or its item cards
## quietly disagreeing with content/level_1_planting.tres, which is the copy a
## teaching-content reviewer reads and the voice-over is recorded from. This
## checks both.

const FIRST_STAGE := "res://scenes/levels/level_1/stage_1.tscn"
const CONTENT := "res://content/level_1_planting.tres"

var _failures := 0
var _level: LevelData


func _initialize() -> void:
	await process_frame
	_level = load(CONTENT)
	_expect(_level != null, "level content loads")

	var path := FIRST_STAGE
	var seen := 0
	while not path.is_empty():
		if not ResourceLoader.exists(path):
			_expect(false, "stage scene exists: %s" % path)
			break
		path = await _play(path)
		seen += 1
		if seen > 20:
			_expect(false, "stage chain does not loop forever")
			break

	print("\n%d stage(s) played" % seen)
	_expect(seen > 0, "at least one stage was played")
	print("%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


## Plays one stage scene and returns the path of the next, or "" at the end.
func _play(scene_path: String) -> String:
	var stage: StageScreen = (load(scene_path) as PackedScene).instantiate()
	root.add_child(stage)
	root.get_viewport().size = Vector2i(1080, 1920)
	stage.set_deferred("size", Vector2(1080, 1920))
	await _settle()

	var label := scene_path.get_file().get_basename()
	print("--- %s ---" % label)

	var cards := stage.cards()
	var overlay: Control = stage.get_node("%Overlay")
	var hotspot: Button = stage.get_node("%OverlayButton")
	var background: ArtSlot = stage.get_node("%Background")
	var opening: Texture2D = background.texture

	# --- the scene must still agree with the reviewed content ---
	var challenge := _challenge(stage.challenge_id)
	_expect(challenge != null, "%s challenge_id '%s' is in the content" % [label, stage.challenge_id])
	if challenge != null:
		_expect(
			challenge.correct_option_id == stage.correct_option_id,
			"%s answer '%s' matches the content's '%s'"
				% [label, stage.correct_option_id, challenge.correct_option_id]
		)
		var scene_ids: Array[StringName] = []
		for card in cards:
			scene_ids.append(card.option_id)
		var content_ids: Array[StringName] = []
		for option in challenge.options:
			content_ids.append(option.id)
		scene_ids.sort()
		content_ids.sort()
		_expect(
			scene_ids == content_ids,
			"%s cards %s match the content's %s" % [label, scene_ids, content_ids]
		)

	# --- the stage is dressed ---
	_expect(background.texture != null, "%s has a garden" % label)
	_expect(stage.get_node("%Header").texture != null, "%s has its header" % label)
	_expect(stage.get_node("%Prompt").texture != null, "%s has its prompt" % label)
	_expect(stage.correct_card != null, "%s has a Correct card" % label)
	_expect(stage.wrong_card != null, "%s has an Oops card" % label)
	_expect(stage.success_background != null, "%s has a garden to change to" % label)
	_expect(cards.size() >= 2, "%s has cards (%d)" % [label, cards.size()])
	for card in cards:
		_expect(card.icon != null, "%s card '%s' has its artwork" % [label, card.option_id])
		_expect(
			card.size.x >= 160.0 and card.size.y >= 160.0,
			"%s card '%s' clears 160 px" % [label, card.option_id]
		)

	var centre: Vector2 = stage.get_node("%DropZone").get_global_rect().get_center()

	# --- let go away from the target: not an answer, stays pickable ---
	var stray: OptionCard = cards[0]
	var stray_home: Vector2 = stray.position
	stray._begin_drag(stray.global_position + Vector2(20.0, 20.0))
	stray._end_drag(Vector2(40.0, 40.0))
	await _settle()
	_expect(not overlay.visible, "%s a drop away from the target is not an answer" % label)
	await _rest()
	_expect(
		stray.position.distance_to(stray_home) < 1.0,
		"%s that card is back in its slot" % label
	)
	_expect(stray.modulate == Color.WHITE, "%s that card is not greyed out" % label)
	_expect(
		stray.mouse_filter != Control.MOUSE_FILTER_IGNORE,
		"%s that card can still be picked up" % label
	)

	# --- wrong item on the target ---
	var wrong: OptionCard = _wrong(cards, stage)
	var wrong_home: Vector2 = wrong.position
	wrong._begin_drag(wrong.global_position + Vector2(20.0, 20.0))
	wrong._end_drag(centre)
	await _settle()
	_expect(overlay.visible, "%s wrong answer shows the Oops card" % label)
	_expect(background.texture == opening, "%s wrong answer leaves the garden alone" % label)
	_expect(
		hotspot.size.x >= 160.0 and hotspot.size.y >= 160.0,
		"%s Choose Again clears 160 px (is %dx%d)" % [label, hotspot.size.x, hotspot.size.y]
	)
	await _rest()
	_expect(is_instance_valid(wrong), "%s wrong card still exists" % label)
	_expect(
		wrong.position.distance_to(wrong_home) < 1.0,
		"%s wrong card is back in its slot" % label
	)
	_expect(wrong.modulate != Color.WHITE, "%s wrong card is greyed out" % label)
	_expect(
		wrong.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"%s wrong card cannot be picked again" % label
	)
	hotspot.pressed.emit()
	await _settle()
	_expect(not overlay.visible, "%s Choose Again dismisses the Oops card" % label)

	# --- right item ---
	var right: OptionCard = _card(cards, stage.correct_option_id)
	_expect(right != null, "%s has its correct card '%s'" % [label, stage.correct_option_id])
	right._begin_drag(right.global_position + Vector2(20.0, 20.0))
	right._end_drag(centre)
	await _settle()
	_expect(overlay.visible, "%s correct answer shows the Correct card" % label)
	_expect(
		background.texture == stage.success_background,
		"%s garden changes after a correct answer" % label
	)
	_expect(
		hotspot.size.x >= 160.0 and hotspot.size.y >= 160.0,
		"%s Continue clears 160 px (is %dx%d)" % [label, hotspot.size.x, hotspot.size.y]
	)
	# A dragged card leaves its container's transform behind, so tree order no
	# longer keeps the feedback card above it.
	_expect(overlay.z_index > right.z_index, "%s Correct card draws over the dropped card" % label)

	var next := stage.next_stage_path
	if not next.is_empty():
		_expect(ResourceLoader.exists(next), "%s next stage exists: %s" % [label, next])
	else:
		_expect(
			ResourceLoader.exists(stage.done_scene_path),
			"%s is last, and its done scene exists" % label
		)
	stage.queue_free()
	await process_frame
	return next


func _challenge(id: StringName) -> ChallengeData:
	for challenge in _level.challenges:
		if challenge.id == id:
			return challenge
	return null


func _settle() -> void:
	# _place_hotspot waits a frame before padding the hit area out to 160 px.
	for i in 4:
		await process_frame


## Waits out the slide home. That is a real timed tween, so frames alone will
## not finish it.
func _rest() -> void:
	await create_timer(OptionCard.RETURN_TIME + 0.2).timeout


func _card(cards: Array[OptionCard], option_id: StringName) -> OptionCard:
	for card in cards:
		if card.option_id == option_id:
			return card
	return null


func _wrong(cards: Array[OptionCard], stage: StageScreen) -> OptionCard:
	for card in cards:
		if not stage.is_correct(card.option_id):
			return card
	return null


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s" % label)
