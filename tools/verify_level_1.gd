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
# Prompt and fun fact must read at the same size on every stage. Their source
# images differ in aspect, so a fixed box would render each at its own width -
# stage 3's prompt came out a third narrower than stage 1's. Collected here and
# compared once every stage has been seen.
var _prompt_widths: Array[float] = []
var _fact_widths: Array[float] = []


func _initialize() -> void:
	await process_frame
	# Playing the stages records real progress, so this starts from nothing and
	# clears up after itself. Otherwise a run would leave stars behind and the
	# next screen that reads them would see a different game.
	var state: GameStateStore = root.get_node_or_null("/root/GameState") as GameStateStore
	if state != null:
		state.reset()
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
	_expect_same("prompt", _prompt_widths)
	_expect_same("fun fact", _fact_widths)
	await _check_quick_taps()
	if state != null:
		_expect(
			state.stars_for(&"level_1", 1) > 0,
			"playing stage 1 recorded progress (%d star(s))" % state.stars_for(&"level_1", 1)
		)
		state.reset()
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
	var bubble: PromptBubble = stage.get_node_or_null("%PromptBubble") as PromptBubble
	_expect(bubble != null, "%s has the shared prompt bubble" % label)
	if bubble != null:
		_expect(bubble.text == challenge.prompt_transcript,
			"%s bubble says its prompt_transcript" % label)
		_expect(bubble.text_fits(), "%s prompt fits its bubble" % label)
	_expect(stage.correct_card != null, "%s has a Correct card" % label)
	_expect(stage.wrong_card != null, "%s has an Oops card" % label)
	_expect(
		stage.get_node("%FunFact").texture != null,
		"%s has its fun fact strip" % label
	)
	var tray: ArtSlot = stage.get_node("%Cards").get_parent().get_node("TrayArt")
	_expect(tray.texture != null, "%s has its tool tray" % label)
	_expect(stage.blank_tray, "%s is on the blank tray" % label)
	_prompt_widths.append(stage.get_node("%PromptBubble").size.x)
	_fact_widths.append(stage.get_node("%FunFact").size.x)
	_expect(cards.size() >= 2, "%s has cards (%d)" % [label, cards.size()])
	for card in cards:
		_expect(card.icon != null, "%s card '%s' has its artwork" % [label, card.option_id])
		# The tray's slots are empty, so a resting card draws its own item.
		_expect(
			card.draw_at_rest and card.get_node("Art").visible,
			"%s card '%s' shows itself in its empty slot" % [label, card.option_id]
		)
		_expect(
			not card.get_node("Spent").visible,
			"%s card '%s' starts untried" % [label, card.option_id]
		)
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
	_expect(not stray.get_node("Spent").visible, "%s that card is not marked used" % label)
	_expect(stray.get_node("Art").visible, "%s that card is shown again in its slot" % label)
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
	await _check_feedback_press(stage, hotspot, label, "Choose Again", stage.wrong_art_rect)
	await _rest()
	_expect(is_instance_valid(wrong), "%s wrong card still exists" % label)
	_expect(
		wrong.position.distance_to(wrong_home) < 1.0,
		"%s wrong card is back in its slot" % label
	)
	# A retired option leaves its slot empty and darkened, not a greyed card.
	var tint: Panel = wrong.get_node("Spent")
	_expect(tint.visible, "%s wrong card's slot is tinted" % label)
	_expect(not wrong.get_node("Art").visible, "%s wrong card leaves its slot without an icon" % label)
	for card in cards:
		if card != wrong:
			_expect(card.get_node("Art").visible, "%s untried card '%s' is still shown" % [label, card.option_id])
	_expect(
		tint.size.is_equal_approx(wrong.size),
		"%s the tint covers the whole slot (%dx%d over %dx%d)"
			% [label, tint.size.x, tint.size.y, wrong.size.x, wrong.size.y]
	)
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
	# The garden must not change while the stage is on screen. The backgrounds
	# are independent drawings, so swapping one for the next jumps every cloud
	# and fence post, and it is very visible behind the feedback card. The
	# change belongs at the stage boundary.
	_expect(
		background.texture == opening,
		"%s garden is unchanged by a correct answer" % label
	)
	_expect(
		hotspot.size.x >= 160.0 and hotspot.size.y >= 160.0,
		"%s Continue clears 160 px (is %dx%d)" % [label, hotspot.size.x, hotspot.size.y]
	)
	await _check_feedback_press(stage, hotspot, label, "Continue", stage.correct_art_rect)
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


## A child taps a card again and again. Each tap is a tiny drag that lets go on
## the card itself, so the card slides home — and the next tap lands mid-slide.
## That once made the card take its half-way point as home, and the two slides
## raced until it came to rest ~1300 px away, off the screen, where it could
## never be tapped again. A double-tap did it at any speed; more taps only
## sometimes put the card back by accident, so this tries two and three taps at
## three speeds and every one has to end in the slot.
func _check_quick_taps() -> void:
	print("--- quick taps, on stage_1 ---")
	for gap in [0.05, 0.08, 0.15]:
		for taps in [2, 3]:
			var stage: StageScreen = (load(FIRST_STAGE) as PackedScene).instantiate()
			root.add_child(stage)
			stage.set_deferred("size", Vector2(1080, 1920))
			await _settle()
			var card: OptionCard = stage.cards()[1]
			var home := card.global_position
			for tap in taps:
				var at := card.global_position + Vector2(20.0, 20.0)
				card._begin_drag(at)
				card._end_drag(at)
				await create_timer(gap).timeout
			await _rest()
			_expect(
				card.global_position.distance_to(home) < 1.0 and not card.top_level
					and card.mouse_filter != Control.MOUSE_FILTER_IGNORE,
				"%d taps %.2fs apart leave the card in its slot, pickable (off by %.0f px)"
					% [taps, gap, card.global_position.distance_to(home)]
			)
			stage.queue_free()
			await process_frame


## Every stage should draw this element at the same width, so it reads at the
## same size whatever the wording is.
func _expect_same(what: String, widths: Array[float]) -> void:
	if widths.is_empty():
		return
	var lo: float = widths[0]
	var hi: float = widths[0]
	for w in widths:
		lo = minf(lo, w)
		hi = maxf(hi, w)
	_expect(hi - lo < 1.0, "every stage draws its %s at the same width (%d..%d)" % [what, lo, hi])


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


## A feedback button drawn *on* its card covers a button painted into the card,
## exactly, so squashing it uncovers the painted one rather than reading as a
## press — the same reason a stage select row does not bounce. A button drawn
## *below* the card has nothing underneath and must still bounce, since for
## Stage 4's borrowed Level 2 card that is the only Continue there is.
##
## Either way the darken has to fire, because on an on-card button it is the
## whole of the feedback.
func _check_feedback_press(
	stage: StageScreen, hotspot: Button, label: String, what: String, art_rect: Rect2
) -> void:
	var art: Control = stage.get_node_or_null("%OverlayButtonArt") as Control
	if art == null:
		_expect(false, "%s has an OverlayButtonArt to press" % label)
		return
	var on_card := StageScreen.WHOLE_CARD.intersects(art_rect)
	_expect(
		(hotspot as ArtButton).bounce_art != on_card,
		"%s %s %s" % [
			label, what, "on the card does not bounce" if on_card else "below the card bounces"
		]
	)

	hotspot.button_down.emit()
	await create_timer(PressBounce.PRESS_SECONDS + 0.05).timeout
	if on_card:
		_expect(
			art.scale.is_equal_approx(Vector2.ONE),
			"%s %s art stays put under a press (scale %.2f)" % [label, what, art.scale.x]
		)
	else:
		_expect(
			art.scale.x < 0.99,
			"%s %s art squashes under a press (scale %.2f)" % [label, what, art.scale.x]
		)
	_expect(
		art.modulate.is_equal_approx(ArtButton.PRESSED_TINT),
		"%s %s art darkens under a press" % [label, what]
	)

	hotspot.button_up.emit()
	await create_timer(PressBounce.RELEASE_SECONDS + 0.1).timeout
	_expect(
		art.scale.is_equal_approx(Vector2.ONE),
		"%s %s art is back at full size (scale %.2f)" % [label, what, art.scale.x]
	)
	_expect(
		art.modulate.is_equal_approx(Color.WHITE),
		"%s %s art lifts its tint on release" % [label, what]
	)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s" % label)
