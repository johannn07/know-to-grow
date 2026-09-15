extends SceneTree

## Content validation for res://content/level_*.tres. Run headless before any
## commit that touches the level data:
##
##   godot --headless --path . -s res://tools/verify_content.gd
##
## Checks the things that silently break a level: a correct_option_id that no
## option actually has, a duplicate or missing voice-over key, an empty
## transcript (which would leave the voice-over script with a hole in it).

const LEVELS := [
	"res://content/level_1_planting.tres",
	"res://content/level_2_monitoring.tres",
	"res://content/level_3_identifying.tres",
	"res://content/level_4_functions.tres",
]

var _failures := 0
var _vo_keys := {}


func _initialize() -> void:
	var total_challenges := 0
	for path in LEVELS:
		var level: LevelData = load(path) as LevelData
		if level == null:
			_fail("%s loads as LevelData" % path)
			continue
		print("\n%s  (%d challenges)" % [level.title, level.challenges.size()])
		_expect(not level.id.is_empty(), "  level id set")
		_expect(not level.instruction_transcript.is_empty(), "  instruction transcript present")
		_expect(not level.completion_transcript.is_empty(), "  completion transcript present")
		_claim_vo(level.instruction_vo_key, "%s instruction" % level.id)
		_claim_vo(level.completion_vo_key, "%s completion" % level.id)
		if not level.final_fun_fact_transcript.is_empty():
			_claim_vo(level.final_fun_fact_vo_key, "%s final fun fact" % level.id)

		for c in level.challenges:
			total_challenges += 1
			var ids: Array[StringName] = []
			for o in c.options:
				ids.append(o.id)
				_expect(not o.label.is_empty(), "  %s: option '%s' has a label" % [c.id, o.id])
				_claim_vo(o.vo_key, "item %s" % o.id, true)
			_expect(c.correct_option_id in ids,
				"  %s: correct answer '%s' is one of the options" % [c.id, c.correct_option_id])
			for alt in c.alternate_correct_ids:
				_expect(alt in ids, "  %s: alternate '%s' is one of the options" % [c.id, alt])
			_expect(not c.prompt_transcript.is_empty(), "  %s: prompt transcript present" % c.id)
			_expect(not c.fun_fact_transcript.is_empty(), "  %s: fun fact transcript present" % c.id)
			_claim_vo(c.prompt_vo_key, "%s prompt" % c.id)
			_claim_vo(c.fun_fact_vo_key, "%s fun fact" % c.id)

	print("\n%d challenges, %d distinct voice-over lines to record" % [total_challenges, _vo_keys.size()])
	print("%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


## Item names are deliberately shared between levels, so those may repeat.
func _claim_vo(key: StringName, who: String, shared: bool = false) -> void:
	if key.is_empty():
		_fail("  %s: missing voice-over key" % who)
		return
	if _vo_keys.has(key) and not shared:
		_fail("  %s: voice-over key '%s' already used by %s" % [who, key, _vo_keys[key]])
		return
	_vo_keys[key] = who


func _expect(ok: bool, label: String) -> void:
	if ok:
		print("  ok  %s" % label.strip_edges())
	else:
		_fail(label)


func _fail(label: String) -> void:
	_failures += 1
	print("  FAIL  %s" % label.strip_edges())
