extends SceneTree

## Plays Level 1 Stage 1 headlessly: drops a wrong card, dismisses the Oops
## card, then drops the right one and checks the garden changed.
##
##   godot --headless --path . -s res://tools/verify_level_1.gd
##
## A screenshot cannot tell you whether a drop was accepted, whether the wrong
## answer was penalised, or whether the Continue hotspot is big enough for a
## thumb. This can.

var _failures := 0


func _initialize() -> void:
	await process_frame
	var screen: Node = (load("res://scenes/levels/challenge_screen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	root.get_viewport().size = Vector2i(1080, 1920)
	screen.set_deferred("size", Vector2(1080, 1920))
	await _settle()

	var level: LevelData = screen.level
	var challenge: ChallengeData = level.challenges[0]

	_expect(challenge.id == &"l1_dig", "stage 1 is l1_dig (is %s)" % challenge.id)
	_expect(screen.get_node("%Header").texture != null, "stage header art is wired")
	_expect(screen.get_node("%Prompt").texture != null, "stage prompt art is wired")
	_expect(
		screen.get_node("%Background").texture == level.scene_art[challenge.scene_state],
		"garden starts in the '%s' state" % challenge.scene_state
	)

	var cards: Array = screen.get_node("%Cards").get_children()
	_expect(cards.size() == 3, "three option cards (got %d)" % cards.size())
	for card in cards:
		_expect(card.data.icon != null, "card '%s' has its artwork" % card.data.id)
		_expect(
			card.size.x >= 160.0 and card.size.y >= 160.0,
			"card '%s' clears 160 px (is %dx%d)" % [card.data.id, card.size.x, card.size.y]
		)

	var zone: Control = screen.get_node("%DropZone")
	var centre: Vector2 = zone.get_global_rect().get_center()
	var overlay: Control = screen.get_node("%Overlay")
	var hotspot: Button = screen.get_node("%OverlayButton")

	# Dragging is simulated through the card's own begin/end so the home
	# position is recorded exactly as it is in play. Emitting `dropped` directly
	# would skip that and quietly not test the way back.

	# --- let go away from the soil: not an answer, stays pickable ---
	var stray: OptionCard = _card(cards, challenge.correct_option_id)
	var stray_home: Vector2 = stray.position
	stray._begin_drag(stray.global_position + Vector2(20.0, 20.0))
	stray._end_drag(Vector2(40.0, 40.0))
	await _settle()
	_expect(not overlay.visible, "a drop away from the soil shows no feedback")
	await _rest()
	_expect(stray.position.distance_to(stray_home) < 1.0,
		"that card is back in its slot (off by %.1f px)" % stray.position.distance_to(stray_home))
	_expect(not stray.top_level, "that card rejoined the row")
	_expect(stray.modulate == Color.WHITE, "that card is not greyed out")
	_expect(stray.mouse_filter != Control.MOUSE_FILTER_IGNORE,
		"that card can still be picked up")

	# --- wrong answer on the soil: returns, greyed out, retired ---
	var wrong: OptionCard = _wrong_card(cards, challenge)
	var wrong_home: Vector2 = wrong.position
	wrong._begin_drag(wrong.global_position + Vector2(20.0, 20.0))
	wrong._end_drag(centre)
	await _settle()
	_expect(overlay.visible, "wrong answer shows the Oops card")
	_expect(screen.get_node("%OverlayArt").texture == level.wrong_art,
		"the Oops card is the level's wrong_art")
	_expect(screen.get_node("%Background").texture == level.scene_art[challenge.scene_state],
		"a wrong answer does not change the garden")
	_expect(hotspot.size.x >= 160.0 and hotspot.size.y >= 160.0,
		"Choose Again hotspot clears 160 px (is %dx%d)" % [hotspot.size.x, hotspot.size.y])
	await _rest()
	_expect(is_instance_valid(wrong), "the wrong card still exists")
	_expect(wrong.position.distance_to(wrong_home) < 1.0,
		"the wrong card is back in its slot (off by %.1f px)" % wrong.position.distance_to(wrong_home))
	_expect(wrong.modulate != Color.WHITE, "the wrong card is greyed out")
	_expect(wrong.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"the wrong card cannot be picked again")

	hotspot.pressed.emit()
	await _settle()
	_expect(not overlay.visible, "Choose Again dismisses the Oops card")
	_expect(not screen._answered, "a wrong answer does not end the stage")

	# --- right answer ---
	var right: OptionCard = _card(cards, challenge.correct_option_id)
	right._begin_drag(right.global_position + Vector2(20.0, 20.0))
	right._end_drag(centre)
	await _settle()
	_expect(overlay.visible, "correct answer shows the Correct card")
	_expect(screen.get_node("%OverlayArt").texture == challenge.correct_art,
		"the Correct card is this stage's own correct_art")
	_expect(screen.get_node("%Background").texture == level.scene_art[challenge.success_state],
		"the garden advances to '%s'" % challenge.success_state)
	_expect(hotspot.size.x >= 160.0 and hotspot.size.y >= 160.0,
		"Continue hotspot clears 160 px (is %dx%d)" % [hotspot.size.x, hotspot.size.y])
	_expect(screen._answered, "the stage is marked answered")
	# A dragged card leaves the container's transform behind, so ordinary tree
	# order no longer keeps the overlay on top of it.
	_expect(overlay.z_index > right.z_index,
		"the Correct card draws over the dropped card (%d vs %d)" % [overlay.z_index, right.z_index])


	# --- Continue advances to Stage 2 ---
	hotspot.pressed.emit()
	await _settle()
	_expect(screen.challenge_index == 1, "Continue moves on to stage 2 (index %d)" % screen.challenge_index)

	var s2: ChallengeData = level.challenges[1]
	_expect(s2.id == &"l1_seed", "stage 2 is l1_seed (is %s)" % s2.id)
	_expect(screen.get_node("%Header").texture == s2.header_art, "stage 2 shows its own header")
	_expect(screen.get_node("%Prompt").texture == s2.prompt_art, "stage 2 shows its own prompt")
	_expect(screen.get_node("%Background").texture == level.scene_art[s2.scene_state],
		"stage 2 opens on the '%s' garden it was left in" % s2.scene_state)
	_expect(not screen._answered, "stage 2 starts unanswered")

	var cards2: Array = []
	for c in screen.get_node("%Cards").get_children():
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			cards2.append(c)
	_expect(cards2.size() == 3, "stage 2 has three cards (got %d)" % cards2.size())
	for card in cards2:
		_expect(card.data.icon != null, "stage 2 card '%s' has its artwork" % card.data.id)
		_expect(card.modulate == Color.WHITE, "stage 2 card '%s' starts fresh" % card.data.id)

	var wrong2: OptionCard = _wrong_card(cards2, s2)
	wrong2._begin_drag(wrong2.global_position + Vector2(20.0, 20.0))
	wrong2._end_drag(centre)
	await _settle()
	_expect(overlay.visible, "stage 2 wrong answer shows the Oops card")
	await _rest()
	_expect(wrong2.modulate != Color.WHITE, "stage 2 wrong card is greyed out")
	hotspot.pressed.emit()
	await _settle()

	var right2: OptionCard = _card(cards2, s2.correct_option_id)
	_expect(right2 != null, "stage 2 has its correct card '%s'" % s2.correct_option_id)
	right2._begin_drag(right2.global_position + Vector2(20.0, 20.0))
	right2._end_drag(centre)
	await _settle()
	_expect(screen.get_node("%OverlayArt").texture == s2.correct_art,
		"stage 2 shows its own Correct card")
	_expect(screen.get_node("%Background").texture == level.scene_art[s2.success_state],
		"the garden advances to '%s'" % s2.success_state)

	# --- transcripts still describe the artwork ---
	_expect(s2.prompt_transcript == "What goes inside the hole to start growing our plant?",
		"stage 2 prompt transcript matches the speech bubble")
	_expect(s2.get_option(&"seed_packet").label == "Seed",
		"the seed card's transcript matches the word drawn on it")


	print("\n%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


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
