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

	# --- a card dropped outside the soil just goes home ---
	var stray: OptionCard = _card(cards, challenge.correct_option_id)
	stray.dropped.emit(stray, Vector2(40.0, 40.0))
	await _settle()
	_expect(not overlay.visible, "a drop outside the soil shows no feedback")

	# --- wrong answer ---
	var wrong: OptionCard = _wrong_card(cards, challenge)
	wrong.dropped.emit(wrong, centre)
	await _settle()
	_expect(overlay.visible, "wrong answer shows the Oops card")
	_expect(
		screen.get_node("%OverlayArt").texture == level.wrong_art,
		"the Oops card is the level's wrong_art"
	)
	_expect(
		screen.get_node("%Background").texture == level.scene_art[challenge.scene_state],
		"a wrong answer does not change the garden"
	)
	_expect(
		hotspot.size.x >= 160.0 and hotspot.size.y >= 160.0,
		"Choose Again hotspot clears 160 px (is %dx%d)" % [hotspot.size.x, hotspot.size.y]
	)

	hotspot.pressed.emit()
	await _settle()
	_expect(not overlay.visible, "Choose Again dismisses the Oops card")
	_expect(not screen._answered, "a wrong answer does not end the stage")

	# --- right answer ---
	var right: OptionCard = _card(cards, challenge.correct_option_id)
	right.dropped.emit(right, centre)
	await _settle()
	_expect(overlay.visible, "correct answer shows the Correct card")
	_expect(
		screen.get_node("%OverlayArt").texture == challenge.correct_art,
		"the Correct card is this stage's own correct_art"
	)
	_expect(
		screen.get_node("%Background").texture == level.scene_art[challenge.success_state],
		"the garden advances to '%s'" % challenge.success_state
	)
	_expect(
		hotspot.size.x >= 160.0 and hotspot.size.y >= 160.0,
		"Continue hotspot clears 160 px (is %dx%d)" % [hotspot.size.x, hotspot.size.y]
	)
	_expect(screen._answered, "the stage is marked answered")

	print("\n%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


func _settle() -> void:
	# _place_hotspot waits a frame before padding the hit area out to 160 px.
	for i in 4:
		await process_frame


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
