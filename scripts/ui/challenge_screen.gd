class_name ChallengeScreen
extends Control

## The one screen that plays Level 1, 2, 3 and 4.
##
## It builds a grey-box UI in code so you can play the whole game today.
## When art arrives you replace `_build_stage_area()` with a real scene
## (background sprite + DropZone nodes placed over the artwork) and leave
## everything below this line alone.

@export var level: LevelData
@export var auto_advance_delay: float = 0.0  ## 0 = wait for the Next button.

var _title: Label
var _score: Label
var _prompt: Label
var _stage_box: Control
var _stage_label: Label
var _zone: DropZone
var _options: HBoxContainer
var _feedback: Label
var _fact_panel: PanelContainer
var _fact_label: Label
var _next_button: Button

var _locked: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

	GameState.score_changed.connect(_on_score_changed)
	GameState.challenge_changed.connect(_on_challenge_changed)
	GameState.level_completed.connect(_on_level_completed)

	if level == null:
		push_error("ChallengeScreen has no LevelData assigned.")
		return
	GameState.start_level(level)


# --- construction ------------------------------------------------------------

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	_apply_safe_area(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 24)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	_title = Label.new()
	_title.text = level.title if level else ""
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)

	_score = Label.new()
	header.add_child(_score)

	_prompt = Label.new()
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 42)
	root.add_child(_prompt)

	_stage_box = _build_stage_area()
	_stage_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_stage_box)

	_feedback = Label.new()
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.custom_minimum_size.y = 90
	root.add_child(_feedback)

	_options = HBoxContainer.new()
	_options.alignment = BoxContainer.ALIGNMENT_CENTER
	_options.add_theme_constant_override("separation", 32)
	root.add_child(_options)

	_build_fact_panel()


## GREY-BOX ONLY. Replace with the real illustrated stage later.
func _build_stage_area() -> Control:
	_zone = DropZone.new()
	_zone.zone_id = &"main"
	_zone.custom_minimum_size = Vector2(600, 500)
	_zone.option_dropped.connect(_on_option_dropped)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zone.add_child(panel)

	_stage_label = Label.new()
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_stage_label)

	return _zone


func _build_fact_panel() -> void:
	_fact_panel = PanelContainer.new()
	_fact_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_fact_panel.custom_minimum_size = Vector2(800, 400)
	_fact_panel.visible = false
	add_child(_fact_panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_fact_panel.add_child(box)

	_fact_label = Label.new()
	_fact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fact_label.add_theme_font_size_override("font_size", 38)
	box.add_child(_fact_label)

	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.custom_minimum_size = Vector2(280, 120)
	_next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next_button.pressed.connect(_on_next_pressed)
	box.add_child(_next_button)


# --- flow --------------------------------------------------------------------

func _on_challenge_changed(challenge: ChallengeData, _index: int, _total: int) -> void:
	_locked = false
	_feedback.text = ""
	_fact_panel.visible = false
	_prompt.text = challenge.prompt
	_stage_label.text = "[%s]" % challenge.scene_state  # grey-box stand-in for art
	_zone.zone_id = challenge.zone_id
	AudioDirector.play_vo(StringName("prompt_%s" % challenge.id))
	_rebuild_options(challenge)


func _rebuild_options(challenge: ChallengeData) -> void:
	for child in _options.get_children():
		child.queue_free()

	var list := challenge.options.duplicate()
	if level.shuffle_options:
		list.shuffle()

	var can_drag := challenge.interaction == ChallengeData.Interaction.DRAG_TO_ZONE
	for option: OptionData in list:
		var card := OptionCard.new()
		card.setup(option, can_drag)
		if not can_drag:
			card.tapped.connect(_on_option_chosen)
		_options.add_child(card)


func _on_option_dropped(option_id: StringName, _zone_id: StringName) -> void:
	_on_option_chosen(option_id)


func _on_option_chosen(option_id: StringName) -> void:
	if _locked:
		return
	var challenge := GameState.current_challenge()
	if challenge == null:
		return

	if challenge.is_correct(option_id):
		_locked = true
		AudioDirector.play_sfx(&"correct")
		GameState.register_correct()
		_card_for(option_id, func(c: OptionCard) -> void: c.celebrate())
		if challenge.success_state != &"":
			_stage_label.text = "[%s]" % challenge.success_state
		_show_fact(challenge.fun_fact)
	else:
		AudioDirector.play_sfx(&"wrong")
		GameState.register_miss(option_id)
		var option := challenge.get_option(option_id)
		_feedback.text = option.wrong_hint if option else "Oops, let's try again!"
		_card_for(option_id, func(c: OptionCard) -> void: c.shake())
		# No penalty, no lock: the learner simply tries again.


func _show_fact(text: String) -> void:
	_fact_label.text = text
	_fact_panel.visible = true
	if auto_advance_delay > 0.0:
		_next_button.visible = false
		await get_tree().create_timer(auto_advance_delay).timeout
		if _fact_panel.visible:
			_on_next_pressed()


func _on_next_pressed() -> void:
	_fact_panel.visible = false
	GameState.advance()


func _on_score_changed(score: int, total: int) -> void:
	_score.text = "Score: %d/%d" % [score, total]


func _on_level_completed(_level_id: StringName, _score: int, _total: int) -> void:
	_prompt.text = level.completion_message
	_fact_label.text = level.final_fun_fact
	_fact_panel.visible = true
	_next_button.text = "Continue"
	for child in _options.get_children():
		child.queue_free()
	if level.next_scene_path != "":
		_next_button.pressed.connect(
			func() -> void: get_tree().change_scene_to_file(level.next_scene_path),
			CONNECT_ONE_SHOT
		)


# --- helpers -----------------------------------------------------------------

func _card_for(option_id: StringName, action: Callable) -> void:
	for child in _options.get_children():
		var card := child as OptionCard
		if card != null and card.data.id == option_id:
			action.call(card)
			return


func _apply_safe_area(margin: MarginContainer) -> void:
	var base := 48
	margin.add_theme_constant_override("margin_left", base)
	margin.add_theme_constant_override("margin_right", base)
	margin.add_theme_constant_override("margin_top", base)
	margin.add_theme_constant_override("margin_bottom", base)

	var screen := DisplayServer.window_get_size()
	if screen.x == 0 or screen.y == 0:
		return
	var safe := DisplayServer.get_display_safe_area()
	var vp := get_viewport_rect().size
	var sx := vp.x / float(screen.x)
	var sy := vp.y / float(screen.y)
	margin.add_theme_constant_override("margin_left", maxi(base, int(safe.position.x * sx)))
	margin.add_theme_constant_override("margin_top", maxi(base, int(safe.position.y * sy)))
	margin.add_theme_constant_override("margin_right", maxi(base, int((screen.x - safe.end.x) * sx)))
	margin.add_theme_constant_override("margin_bottom", maxi(base, int((screen.y - safe.end.y) * sy)))
