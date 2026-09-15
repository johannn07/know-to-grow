extends SceneTree

## Plays Level 1 headlessly, stage by stage: for each stage that has its art
## wired, drop a wrong item, dismiss the Oops card, drop the right one, and
## check the garden changed. Then press Continue and do the next one.
##
##   godot --headless --path . -s res://tools/verify_level_1.gd
##
## A screenshot cannot tell you whether a drop was accepted, whether a wrong
## answer was penalised, whether the garden carried over between stages, or
## whether a hotspot is big enough for a thumb. This can.

var _failures := 0
var _screen: Node
var _level: LevelData
var _centre: Vector2
var _overlay: Control
var _hotspot: Button


func _initialize() -> void:
	await process_frame
	_screen = (load("res://scenes/levels/challenge_screen.tscn") as PackedScene).instantiate()
	root.add_child(_screen)
	root.get_viewport().size = Vector2i(1080, 1920)
	_screen.set_deferred("size", Vector2(1080, 1920))
	await _settle()

	_level = _screen.level
	_overlay = _screen.get_node("%Overlay")
	_hotspot = _screen.get_node("%OverlayButton")
	_centre = _screen.get_node("%DropZone").get_global_rect().get_center()

	# Stages are built one at a time. Only play the ones that have art.
	var wired := 0
	for challenge in _level.challenges:
		if challenge.prompt_art != null:
			wired += 1
	print("Level 1: %d of %d stages wired\n" % [wired, _level.challenges.size()])
	_expect(wired > 0, "at least one stage is wired")

	await _check_screen_mechanics()

	for i in wired:
		await _play_stage(i)
		if i < wired - 1:
			# Continue on the last wired stage leaves for the hub, which would
			# tear the screen down mid-test.
			_hotspot.pressed.emit()
			await _settle()
			_expect(_screen.challenge_index == i + 1, "Continue moves on to stage %d" % (i + 2))

	print("\n%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


## Things that belong to the screen rather than to any one stage, so they are
## worth checking once: that a card let go away from the target is not treated
## as an answer, and that it stays exactly as pickable as it was.
func _check_screen_mechanics() -> void:
	var cards := _cards()
	var card: OptionCard = cards[0]
	var home: Vector2 = card.position
	# Driven through the card's own begin/end so the way home is really
	# exercised. Emitting `dropped` skips it, which is how a fault got through.
	card._begin_drag(card.global_position + Vector2(20.0, 20.0))
	card._end_drag(Vector2(40.0, 40.0))
	await _settle()
	_expect(not _overlay.visible, "a drop away from the target is not an answer")
	await _rest()
	_expect(
		card.position.distance_to(home) < 1.0,
		"that card is back in its slot (off by %.1f px)" % card.position.distance_to(home)
	)
	_expect(not card.top_level, "that card rejoined the row")
	_expect(card.modulate == Color.WHITE, "that card is not greyed out")
	_expect(card.mouse_filter != Control.MOUSE_FILTER_IGNORE, "that card can still be picked up")


func _play_stage(index: int) -> void:
	var challenge: ChallengeData = _level.challenges[index]
	var name := "stage %d (%s)" % [index + 1, challenge.id]
	print("--- %s ---" % name)

	_expect(_screen.challenge_index == index, "%s is the one on screen" % name)
	_expect(_screen.get_node("%Header").texture == challenge.header_art, "%s header" % name)
	_expect(_screen.get_node("%Prompt").texture == challenge.prompt_art, "%s prompt" % name)
	_expect(
		_level.scene_art.has(challenge.scene_state),
		"%s has a garden for '%s'" % [name, challenge.scene_state]
	)
	_expect(
		_screen.get_node("%Background").texture == _level.scene_art[challenge.scene_state],
		"%s opens on the '%s' garden" % [name, challenge.scene_state]
	)
	_expect(not _screen._answered, "%s starts unanswered" % name)

	var cards := _cards()
	_expect(cards.size() == challenge.options.size(), "%s has %d cards" % [name, cards.size()])
	for card in cards:
		_expect(card.data.icon != null, "%s card '%s' has its artwork" % [name, card.data.id])
		_expect(card.modulate == Color.WHITE, "%s card '%s' starts fresh" % [name, card.data.id])
		_expect(
			card.size.x >= 160.0 and card.size.y >= 160.0,
			"%s card '%s' clears 160 px" % [name, card.data.id]
		)

	# --- wrong item on the target: greys out, changes nothing, costs nothing ---
	var wrong: OptionCard = _wrong_card(cards, challenge)
	var wrong_home: Vector2 = wrong.position
	wrong._begin_drag(wrong.global_position + Vector2(20.0, 20.0))
	wrong._end_drag(_centre)
	await _settle()
	_expect(_overlay.visible, "%s wrong answer shows the Oops card" % name)
	_expect(
		_screen.get_node("%OverlayArt").texture == _level.wrong_art,
		"%s Oops card is the level's wrong_art" % name
	)
	_expect(
		_screen.get_node("%Background").texture == _level.scene_art[challenge.scene_state],
		"%s wrong answer leaves the garden alone" % name
	)
	_expect(
		_hotspot.size.x >= 160.0 and _hotspot.size.y >= 160.0,
		"%s Choose Again clears 160 px (is %dx%d)" % [name, _hotspot.size.x, _hotspot.size.y]
	)
	await _rest()
	_expect(is_instance_valid(wrong), "%s wrong card still exists" % name)
	_expect(
		wrong.position.distance_to(wrong_home) < 1.0,
		"%s wrong card is back in its slot" % name
	)
	_expect(wrong.modulate != Color.WHITE, "%s wrong card is greyed out" % name)
	_expect(
		wrong.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"%s wrong card cannot be picked again" % name
	)

	_hotspot.pressed.emit()
	await _settle()
	_expect(not _overlay.visible, "%s Choose Again dismisses the Oops card" % name)
	_expect(not _screen._answered, "%s a wrong answer does not end the stage" % name)

	# --- right item ---
	var right: OptionCard = _card(cards, challenge.correct_option_id)
	_expect(right != null, "%s has its correct card '%s'" % [name, challenge.correct_option_id])
	right._begin_drag(right.global_position + Vector2(20.0, 20.0))
	right._end_drag(_centre)
	await _settle()
	_expect(_overlay.visible, "%s correct answer shows the Correct card" % name)
	_expect(
		_screen.get_node("%OverlayArt").texture == challenge.correct_art,
		"%s Correct card is this stage's own correct_art" % name
	)
	_expect(
		_level.scene_art.has(challenge.success_state),
		"%s has a garden for '%s'" % [name, challenge.success_state]
	)
	_expect(
		_screen.get_node("%Background").texture == _level.scene_art[challenge.success_state],
		"%s garden advances to '%s'" % [name, challenge.success_state]
	)
	_expect(
		_hotspot.size.x >= 160.0 and _hotspot.size.y >= 160.0,
		"%s Continue clears 160 px (is %dx%d)" % [name, _hotspot.size.x, _hotspot.size.y]
	)
	_expect(_screen._answered, "%s is marked answered" % name)
	# A dragged card leaves its container's transform behind, so tree order no
	# longer keeps the feedback card above it.
	_expect(
		_overlay.z_index > right.z_index,
		"%s Correct card draws over the dropped card" % name
	)


func _cards() -> Array:
	var live: Array = []
	for child in _screen.get_node("%Cards").get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			live.append(child)
	return live


func _settle() -> void:
	# _place_hotspot waits a frame before padding the hit area out to 160 px.
	for i in 4:
		await process_frame


## Waits out the slide home. That is a real timed tween, so frames alone will
## not finish it.
func _rest() -> void:
	await create_timer(OptionCard.RETURN_TIME + 0.2).timeout


func _card(cards: Array, option_id: StringName) -> OptionCard:
	for card in cards:
		if card.data.id == option_id:
			return card
	return null


func _wrong_card(cards: Array, challenge: ChallengeData) -> OptionCard:
	for card in cards:
		if not challenge.is_correct(card.data.id):
			return card
	return null


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s" % label)
