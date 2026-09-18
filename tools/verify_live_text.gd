extends SceneTree

## Checks every piece of live text laid over art: the prompt bubble and the
## header sign. That each component is built right, that every wording in
## content/ fits it, and that a stage fills both from its content file.
##
##   godot --headless --path . -s res://tools/verify_live_text.gd
##
## Live text is one fixed size per plate from the theme rather than shrunk to
## fit, so wording that is changed to something longer would be clipped at the
## edge of its art and nobody would notice until a child could not read it.
## This is where it is noticed: every transcript is laid out in its component at
## the width a stage gives it, and must not lose a line or a letter.

const BUBBLE := "res://scenes/components/prompt_bubble.tscn"
const HEADER := "res://scenes/components/header_sign.tscn"
const THEME := "res://themes/ktg_theme.tres"
const LEVELS: Array[String] = [
	"res://content/level_1_planting.tres",
	"res://content/level_2_monitoring.tres",
	"res://content/level_3_identifying.tres",
	"res://content/level_4_functions.tres",
]
## The widths Level 1's stages give their Prompt and Header slots, in design
## pixels. Later levels take their numbers from those, and the theme's sizes
## are chosen at these widths.
const BUBBLE_WIDTH := 964.0
const HEADER_WIDTH := 660.0
## A stage scene to put the components into, and a challenge that uses both.
const STAGE := "res://scenes/levels/level_1/stage_1.tscn"
const LIVE_CHALLENGE := &"l2_hard_soil"

var _failures := 0


func _initialize() -> void:
	await process_frame
	var bubble: PackedScene = load(BUBBLE)
	var header: PackedScene = load(HEADER)
	_expect(bubble != null, "prompt_bubble.tscn loads")
	_expect(header != null, "header_sign.tscn loads")
	if bubble == null or header == null:
		_finish()
		return

	print("\nPrompt bubble")
	await _check_component(bubble, BUBBLE_WIDTH, "bubble_art", ["%Text"])
	await _check_every_prompt_fits(bubble)
	print("\nHeader sign")
	await _check_component(header, HEADER_WIDTH, "sign_art", ["%Label", "%Title"])
	await _check_every_header_fits(header)
	print("\nStage")
	await _check_stage_fills_them(bubble, header)
	_finish()


## Shape, theme styling, and that nothing in it swallows a drag.
func _check_component(
	scene: PackedScene, width: float, art_property: String, labels: Array
) -> void:
	var host := await _host(scene, width)
	var root_node: AspectRatioContainer = host.get_child(0) as AspectRatioContainer
	var name := root_node.name
	var art: Texture2D = root_node.get(art_property)
	_expect(art != null, "%s: art is assigned in the scene" % name)
	if art != null:
		_expect(
			is_equal_approx(root_node.ratio, float(art.get_width()) / float(art.get_height())),
			"%s keeps the art's shape (ratio %.4f)" % [name, root_node.ratio]
		)
	for path: String in labels:
		var label: Label = root_node.get_node(path)
		_expect(
			not String(label.theme_type_variation).is_empty()
				and label.get_theme_font_size("font_size") > 0,
			"%s %s uses %s at %d px"
				% [name, label.name, label.theme_type_variation,
					label.get_theme_font_size("font_size")]
		)
	# Both sit over the stage, and a stage's cards are dragged across them.
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is Control:
			_expect(
				(node as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"%s/%s lets drags through" % [name, node.name]
			)
	host.queue_free()
	await process_frame


func _check_every_prompt_fits(scene: PackedScene) -> void:
	var host := await _host(scene, BUBBLE_WIDTH)
	var bubble: PromptBubble = host.get_child(0) as PromptBubble
	var text: Label = bubble.get_node("%Text")
	print("  text box %dx%d in a %d px wide bubble" % [text.size.x, text.size.y, BUBBLE_WIDTH])
	var most_lines := 0
	var checked := 0
	for challenge in _challenges():
		bubble.text = challenge.prompt_transcript
		await process_frame
		checked += 1
		most_lines = maxi(most_lines, text.get_line_count())
		_expect(
			bubble.text_fits(),
			"%s prompt fits (%d of %d lines shown)"
				% [challenge.id, text.get_visible_line_count(), text.get_line_count()]
		)
	print("  %d prompts checked; the longest takes %d lines" % [checked, most_lines])
	_expect(checked == 19, "all 19 prompts were checked (%d)" % checked)
	host.queue_free()
	await process_frame


func _check_every_header_fits(scene: PackedScene) -> void:
	var host := await _host(scene, HEADER_WIDTH)
	var sign: HeaderSign = host.get_child(0) as HeaderSign
	var plaque: Label = sign.get_node("%Label")
	var banner: Label = sign.get_node("%Title")
	print("  plaque box %dx%d, banner box %dx%d in a %d px wide sign"
		% [plaque.size.x, plaque.size.y, banner.size.x, banner.size.y, HEADER_WIDTH])
	var checked := 0
	for challenge in _challenges():
		if challenge.header_label_transcript.is_empty():
			continue
		sign.label_text = challenge.header_label_transcript
		sign.title_text = challenge.header_title_transcript
		await process_frame
		checked += 1
		_expect(
			sign.text_fits(),
			"%s header fits on one line each: \"%s\" / \"%s\""
				% [challenge.id, challenge.header_label_transcript,
					challenge.header_title_transcript]
		)
	print("  %d live headers checked" % checked)
	_expect(checked == 5, "all 5 of Level 2's headers were checked (%d)" % checked)
	host.queue_free()
	await process_frame


## A stage reads its words from its content file, so the reviewed transcripts
## are the only copy of them. No stage holds these components yet, so both are
## put into a stage scene the way one would hold them, pointed at a Level 2
## challenge that uses both.
func _check_stage_fills_them(bubble_scene: PackedScene, header_scene: PackedScene) -> void:
	var stage: StageScreen = (load(STAGE) as PackedScene).instantiate() as StageScreen
	var bubble: PromptBubble = _adopt(stage, bubble_scene, "PromptBubble") as PromptBubble
	var header: HeaderSign = _adopt(stage, header_scene, "HeaderSign") as HeaderSign
	var level: LevelData = load(LEVELS[1])
	stage.level_content = level
	stage.challenge_id = LIVE_CHALLENGE
	root.add_child(stage)
	await process_frame

	var challenge: ChallengeData = level.get_challenge(LIVE_CHALLENGE)
	_expect(bubble.text == challenge.prompt_transcript,
		"stage fills its bubble from %s's prompt_transcript" % LIVE_CHALLENGE)
	_expect(header.label_text == challenge.header_label_transcript,
		"stage fills the plaque: \"%s\"" % header.label_text)
	_expect(header.title_text == challenge.header_title_transcript,
		"stage fills the banner: \"%s\"" % header.title_text)
	stage.queue_free()
	await process_frame


## Puts a component into a stage as a %UniqueName, the way a stage scene holds it.
func _adopt(stage: Node, scene: PackedScene, node_name: String) -> Node:
	var node: Node = scene.instantiate()
	node.name = node_name
	stage.add_child(node)
	node.owner = stage
	node.unique_name_in_owner = true
	return node


func _challenges() -> Array[ChallengeData]:
	var all: Array[ChallengeData] = []
	for path in LEVELS:
		var level: LevelData = load(path) as LevelData
		if level == null:
			_expect(false, "%s loads" % path)
			continue
		all.append_array(level.challenges)
	return all


## A component at a stage's width, under the game's theme.
func _host(scene: PackedScene, width: float) -> Control:
	var host := Control.new()
	host.theme = load(THEME)
	var node: AspectRatioContainer = scene.instantiate()
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	host.add_child(node)
	root.add_child(host)
	node.size = Vector2(width, width / node.ratio)
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
