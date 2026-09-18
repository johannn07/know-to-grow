extends SceneTree

## Checks the live-text prompt: the bubble component, that every prompt in the
## game fits it, and that a stage fills it from its content file.
##
##   godot --headless --path . -s res://tools/verify_prompt_bubble.gd
##
## Prompts are one fixed size from the theme rather than shrunk to fit, so a
## prompt that is reworded longer would be clipped at the bottom of the bubble
## and nobody would notice until a child could not read it. This is where it is
## noticed: every prompt_transcript in content/ is laid out in the bubble at the
## width a stage gives it, and must not lose a line.

const BUBBLE := "res://scenes/components/prompt_bubble.tscn"
const THEME := "res://themes/ktg_theme.tres"
const LEVELS: Array[String] = [
	"res://content/level_1_planting.tres",
	"res://content/level_2_monitoring.tres",
	"res://content/level_3_identifying.tres",
	"res://content/level_4_functions.tres",
]
## The Prompt slot in Level 1's stages is 964 design pixels wide, and later
## levels take their numbers from those. The bubble's height follows from its
## own shape.
const STAGE_WIDTH := 964.0
const STAGE := "res://scenes/levels/level_1/stage_1.tscn"

var _failures := 0


func _initialize() -> void:
	await process_frame
	var scene: PackedScene = load(BUBBLE)
	_expect(scene != null, "prompt_bubble.tscn loads")
	if scene == null:
		_finish()
		return

	await _check_component(scene)
	await _check_every_prompt_fits(scene)
	await _check_stage_fills_it(scene)
	_finish()


func _check_component(scene: PackedScene) -> void:
	var host := await _host(scene)
	var bubble: PromptBubble = host.get_child(0) as PromptBubble
	_expect(bubble != null, "the root is a PromptBubble")
	if bubble == null:
		return
	var art := bubble.bubble_art
	_expect(art != null, "bubble art is assigned in the scene")
	if art != null:
		_expect(
			is_equal_approx(bubble.ratio, float(art.get_width()) / float(art.get_height())),
			"bubble keeps the art's shape (ratio %.4f)" % bubble.ratio
		)
	var text: Label = bubble.get_node("%Text")
	_expect(text.theme_type_variation == &"PromptText", "text uses the PromptText variation")
	_expect(
		text.get_theme_font_size("font_size") > 0,
		"PromptText has a size in the theme (%d)" % text.get_theme_font_size("font_size")
	)
	# The bubble sits over the garden, and a stage's cards are dragged across it.
	for node: Control in [bubble, bubble.get_node("Card"), bubble.get_node("%Bubble"), text]:
		_expect(
			node.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"%s lets drags through" % node.name
		)
	host.queue_free()
	await process_frame


func _check_every_prompt_fits(scene: PackedScene) -> void:
	var host := await _host(scene)
	var bubble: PromptBubble = host.get_child(0) as PromptBubble
	var text: Label = bubble.get_node("%Text")
	print("\n  text box %dx%d at a %d px wide bubble, %d px type"
		% [text.size.x, text.size.y, STAGE_WIDTH, text.get_theme_font_size("font_size")])
	var most_lines := 0
	var checked := 0
	for path in LEVELS:
		var level: LevelData = load(path) as LevelData
		if level == null:
			_expect(false, "%s loads" % path)
			continue
		for challenge in level.challenges:
			bubble.text = challenge.prompt_transcript
			await process_frame
			checked += 1
			most_lines = maxi(most_lines, text.get_line_count())
			_expect(
				bubble.text_fits(),
				"%s fits (%d of %d lines shown)"
					% [challenge.id, text.get_visible_line_count(), text.get_line_count()]
			)
	print("  %d prompts checked; the longest takes %d lines" % [checked, most_lines])
	_expect(checked == 19, "all 19 prompts were checked (%d)" % checked)
	host.queue_free()
	await process_frame


## A stage with a %PromptBubble reads its words from its content file, so the
## reviewed transcript is the only copy of them. No stage has a bubble yet, so
## one is put into Level 1 Stage 1 the way a stage scene would hold it.
func _check_stage_fills_it(scene: PackedScene) -> void:
	var stage: StageScreen = (load(STAGE) as PackedScene).instantiate() as StageScreen
	var bubble: PromptBubble = scene.instantiate() as PromptBubble
	bubble.name = "PromptBubble"
	stage.add_child(bubble)
	bubble.owner = stage
	bubble.unique_name_in_owner = true
	var level: LevelData = load(LEVELS[0])
	stage.level_content = level
	root.add_child(stage)
	await process_frame

	var expected: String = level.get_challenge(stage.challenge_id).prompt_transcript
	_expect(
		bubble.text == expected,
		"stage fills its bubble from %s's prompt_transcript" % stage.challenge_id
	)
	stage.queue_free()
	await process_frame


## The bubble at a stage's width, under the game's theme.
func _host(scene: PackedScene) -> Control:
	var host := Control.new()
	host.theme = load(THEME)
	host.size = Vector2(STAGE_WIDTH, STAGE_WIDTH)
	var bubble: Control = scene.instantiate()
	bubble.set_anchors_preset(Control.PRESET_TOP_LEFT)
	host.add_child(bubble)
	root.add_child(host)
	bubble.size = Vector2(STAGE_WIDTH, STAGE_WIDTH / (bubble as AspectRatioContainer).ratio)
	for i in 3:
		await process_frame
	return host


func _finish() -> void:
	print("%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s" % label)
