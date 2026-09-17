extends SceneTree

## Generates assets/audio/vo/en/SCRIPT.md from the transcripts in res://content/.
##
##   godot --headless --path . -s res://tools/export_vo_script.gd
##
## This is the whole point of keeping transcripts alongside the artwork: the
## words are drawn into the art, but they stay greppable here, so the recording
## script is generated rather than retyped. Re-run it whenever content changes.

const LEVELS := [
	"res://content/level_1_planting.tres",
	"res://content/level_2_monitoring.tres",
	"res://content/level_3_identifying.tres",
	"res://content/level_4_functions.tres",
]
const OUT := "res://assets/audio/vo/en/SCRIPT.md"


func _initialize() -> void:
	var lines := PackedStringArray()
	lines.append("# Voice-over script — English")
	lines.append("")
	lines.append("Generated from `content/level_*.tres` by `tools/export_vo_script.gd`.")
	lines.append("Do not edit by hand — edit the transcripts and re-run it.")
	lines.append("")
	lines.append("Each line is recorded as `res://assets/audio/vo/en/<key>.ogg`. The wording must")
	lines.append("match the artwork exactly, because the art is what the child sees.")
	lines.append("")

	var items := {}
	var total := 0

	for path in LEVELS:
		var level: LevelData = load(path) as LevelData
		lines.append("## %s" % level.title)
		lines.append("")
		lines.append("| Key | Line |")
		lines.append("|---|---|")
		lines.append("| `%s` | %s |" % [level.instruction_vo_key, _clean(level.instruction_transcript)])
		total += 1
		for c in level.challenges:
			lines.append("| `%s` | %s |" % [c.prompt_vo_key, _clean(c.prompt_transcript)])
			total += 1
			# Fun facts are Level 1's alone, so everywhere else there is no line
			# to record and the row would come out empty.
			if not c.fun_fact_transcript.is_empty():
				lines.append("| `%s` | %s |" % [c.fun_fact_vo_key, _clean(c.fun_fact_transcript)])
				total += 1
			for o in c.options:
				items[o.vo_key] = o.label
		lines.append("| `%s` | %s |" % [level.completion_vo_key, _clean(level.completion_transcript)])
		total += 1
		if not level.final_fun_fact_transcript.is_empty():
			lines.append("| `%s` | %s |" % [level.final_fun_fact_vo_key, _clean(level.final_fun_fact_transcript)])
			total += 1
		lines.append("")

	lines.append("## Item names")
	lines.append("")
	lines.append("Spoken when a child taps an item. Shared across levels, so each is recorded once.")
	lines.append("")
	lines.append("| Key | Line |")
	lines.append("|---|---|")
	var keys := items.keys()
	keys.sort()
	for k in keys:
		lines.append("| `%s` | %s |" % [k, _clean(items[k])])
	total += keys.size()

	lines.append("")
	lines.append("**%d lines to record.**" % total)
	lines.append("")

	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	print("wrote %s — %d lines" % [OUT, total])
	quit()


func _clean(s: String) -> String:
	return s.replace("\n", " ").replace("|", "\\|").strip_edges()
