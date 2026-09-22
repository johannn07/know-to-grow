extends SceneTree

## Checks the tap-to-answer path through [StageScreen] and [OptionCard].
##
##   godot --headless --path . -s res://tools/verify_tap_answer.gd
##
## Level 3 answers by tapping a card where it stands rather than carrying it to
## a target, so a second route runs through the shared stage code: no %DropZone,
## no slide home, a card that draws itself with no tray behind it, and a wrong
## card darkened in place instead of leaving an empty slot.
##
## That is shared behaviour, so it is checked on its own rather than through one
## level's scenes. A Level 2 stage is borrowed as the rig — it has the full
## %Cards / %Overlay wiring — and [member StageScreen.tap_to_answer] is flipped
## on before it enters the tree. The same walk over Level 3's own scenes belongs
## in `verify_level_3`; this one keeps working if those scenes are rearranged.
##
## The drag path is re-checked here too, from the same scene untouched, so a
## change made for Level 3 cannot quietly break Levels 1, 2 and 4.
##
## Playing records real progress, so this **writes to `user://progress.cfg`**
## and resets it to empty afterwards, as `verify_game_state` does.

const RIG := "res://scenes/levels/level_2/stage_1.tscn"

var _failures := 0
var _state: GameStateStore


func _initialize() -> void:
	await process_frame
	_state = root.get_node_or_null("/root/GameState") as GameStateStore
	if _state != null:
		_state.reset()

	await _check_tap_stage()
	await _check_kept_order()
	await _check_drag_stage_is_unchanged()

	if _state != null:
		_state.reset()
	print("%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


func _check_tap_stage() -> void:
	print("--- tap stage ---")
	var stage := await _rig(true)
	var cards := stage.cards()
	var overlay: Control = stage.get_node("%Overlay")
	var hotspot: ArtButton = stage.get_node("%OverlayButton")

	for card in cards:
		_expect(not card.draggable, "card '%s' cannot be dragged" % card.option_id)
		_expect(card.draw_at_rest, "card '%s' draws itself, with no tray behind it" % card.option_id)
		_expect(card.keep_art_when_spent, "card '%s' will be darkened in place" % card.option_id)
		_expect(
			card.size.x >= 160.0 and card.size.y >= 160.0,
			"card '%s' clears 160 px (is %dx%d)" % [card.option_id, card.size.x, card.size.y]
		)

	# --- a press that slides off the card is not a tap ---
	var stray: OptionCard = cards[0]
	stray._press()
	_expect(stray.get_node("Art").modulate != Color.WHITE, "a press darkens the card")
	stray._release(Vector2(-500.0, -500.0))
	await _settle()
	_expect(not overlay.visible, "a press let go off the card is not an answer")
	_expect(stray.get_node("Art").modulate == Color.WHITE, "letting go clears the darken")
	_expect(not stray.get_node("Spent").visible, "that card is still pickable")

	# --- a wrong tap ---
	var wrong: OptionCard = null
	for card in cards:
		if not stage.is_correct(card.option_id):
			wrong = card
			break
	_tap(wrong)
	await _settle()
	_expect(overlay.visible, "a wrong tap shows the Oops card")
	_expect(stage.find_children("*", "SparkleBurst", false, false).is_empty(),
		"a wrong tap fires no sparkles")
	_expect(
		wrong.get_node("Art").visible and wrong.get_node("Spent").visible,
		"the wrong card stays on screen, darkened where it stands"
	)
	_expect(wrong.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the wrong card stops answering")
	hotspot.pressed.emit()
	await _settle()
	_expect(not overlay.visible, "Choose Again dismisses the Oops card")

	# --- the right tap ---
	var right: OptionCard = null
	for card in cards:
		if card.option_id == stage.correct_option_id:
			right = card
	_tap(right)
	await _settle()
	_expect(overlay.visible, "the right tap shows the Correct card")
	var bursts := stage.find_children("*", "SparkleBurst", false, false)
	_expect(bursts.size() == 1, "the right tap fires one sparkle burst")
	if bursts.size() == 1:
		var burst := bursts[0] as SparkleBurst
		_expect(burst.layer > 0, "the burst draws above the Correct card")
		_expect(burst.is_bursting(), "the burst is in flight")
		await create_timer(2.0).timeout
		_expect(not is_instance_valid(burst), "the burst frees itself afterwards")
	if _state != null:
		_expect(
			_state.stars_for(stage.level_id, stage.stage_number) > 0,
			"the tap recorded progress (%d star(s))"
				% _state.stars_for(stage.level_id, stage.stage_number)
		)
	# One wrong attempt was made, so this is not a three-star clear.
	if _state != null:
		_expect(
			_state.stars_for(stage.level_id, stage.stage_number) < 3,
			"the wrong tap counted as an attempt"
		)
	stage.queue_free()
	await process_frame


## Nothing above may change how a dragged stage behaves.
func _check_drag_stage_is_unchanged() -> void:
	print("--- drag stage ---")
	if _state != null:
		_state.reset()
	var stage := await _rig(false)
	var cards := stage.cards()
	var overlay: Control = stage.get_node("%Overlay")
	var centre: Vector2 = stage.get_node("%DropZone").get_global_rect().get_center()

	for card in cards:
		_expect(card.draggable, "card '%s' is still dragged" % card.option_id)
		_expect(not card.keep_art_when_spent, "card '%s' still leaves its slot" % card.option_id)

	# A tap on a draggable card starts a drag, not an answer.
	var first: OptionCard = cards[0]
	first._gui_input(_click(first.get_global_rect().get_center()))
	await _settle()
	_expect(not overlay.visible, "pressing a draggable card is not an answer on its own")
	first._end_drag(first.get_global_rect().get_center())
	await _settle()
	await _rest()

	var wrong: OptionCard = null
	for card in cards:
		if not stage.is_correct(card.option_id):
			wrong = card
			break
	wrong._begin_drag(wrong.global_position + Vector2(20.0, 20.0))
	wrong._end_drag(centre)
	await _settle()
	_expect(overlay.visible, "a wrong drop still shows the Oops card")
	await _rest()
	_expect(
		not wrong.get_node("Art").visible and wrong.get_node("Spent").visible,
		"the wrong card still leaves a darkened empty slot"
	)
	stage.queue_free()
	await process_frame


## Level 4 taps but must not shuffle: its Correct cards name the answer by a
## drawn letter. With keep_card_order on, every play leaves each card in the
## place the scene gave it. Thirty plays, since a shuffle of three leaves the
## order unchanged one time in six.
func _check_kept_order() -> void:
	print("--- tap stage keeping its card order ---")
	var authored: StageScreen = (load(RIG) as PackedScene).instantiate()
	var placed: Array = []
	for card in authored.get_node("%Cards").get_children():
		placed.append(_place_of(card))
	authored.free()

	var kept := true
	for i in 30:
		var stage := await _rig(true, true)
		var dealt: Array = []
		for card in stage.cards():
			dealt.append(_place_of(card))
		kept = kept and dealt == placed
		stage.queue_free()
		await process_frame
	_expect(kept, "over 30 plays every card stayed in the place the scene gave it")


func _place_of(card: Control) -> String:
	return "%.1f,%.1f,%.1f,%.1f" % [card.anchor_left, card.anchor_top, card.offset_left, card.offset_top]


func _rig(tap: bool, keep_order: bool = false) -> StageScreen:
	var stage: StageScreen = (load(RIG) as PackedScene).instantiate()
	stage.tap_to_answer = tap
	stage.keep_card_order = keep_order
	root.add_child(stage)
	stage.set_deferred("size", Vector2(1080.0, 1920.0))
	await _settle()
	return stage


func _tap(card: OptionCard) -> void:
	card._press()
	card._release(card.get_global_rect().get_center())


func _click(at: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.global_position = at
	event.position = at
	return event


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
