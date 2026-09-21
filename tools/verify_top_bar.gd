extends SceneTree

## Checks the back / music / effects row on every stage.
##
##   godot --headless --path . -s res://tools/verify_top_bar.gd
##
## Every one of the 19 stages carries a [TopBar]. This walks them all and checks
## the things that break quietly: that the row is there and under the feedback
## overlay, that all three buttons clear 160 px and are wired, that the row sits
## above the header rather than on it, and that back leads to the stage's own
## level select rather than falling through to the main menu default.
##
## It then flips music and effects off and on and checks the audio buses, the
## saved file, and that a second row already on screen redraws itself.
##
## Toggling writes `user://settings.cfg`. Whatever was there before is put back
## at the end, so a run does not change the sound settings on this machine.

const TOUCH := 160.0
const SETTINGS := "user://settings.cfg"

## Where back leads from each level's stages.
const SELECT := {
	1: "res://scenes/ui/stage_select.tscn",
	2: "res://scenes/ui/stage_select_l2.tscn",
	3: "res://scenes/ui/stage_select_l3.tscn",
	4: "res://scenes/ui/stage_select_l4.tscn",
}
const STAGES := {1: 4, 2: 5, 3: 5, 4: 5}

var _failures := 0


func _initialize() -> void:
	await process_frame
	var saved: Variant = _read_settings()

	for level: int in STAGES:
		for stage_number in range(1, STAGES[level] + 1):
			await _check_stage(level, stage_number)
	await _check_toggles()

	_restore_settings(saved)
	print("%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


func _check_stage(level: int, stage_number: int) -> void:
	var path := "res://scenes/levels/level_%d/stage_%d.tscn" % [level, stage_number]
	var label := "L%d S%d" % [level, stage_number]
	var stage: StageScreen = (load(path) as PackedScene).instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame

	var bar := stage.get_node_or_null("%TopBar") as TopBar
	_expect(bar != null, "%s has a %%TopBar" % label)
	if bar == null:
		stage.queue_free()
		return

	var overlay: Control = stage.get_node("%Overlay")
	_expect(
		bar.get_index() < overlay.get_index(),
		"%s row is drawn under the feedback overlay" % label
	)
	_expect(
		stage.back_scene_path == SELECT[level],
		"%s back leads to its stage select (is '%s')" % [label, stage.back_scene_path]
	)
	_expect(
		bar.back_pressed.is_connected(stage.go_back),
		"%s back button is connected to the screen's back" % label
	)

	var lowest := 0.0
	for button_name in ["%BackButton", "%MusicButton", "%SfxButton"]:
		var button: ArtButton = bar.get_node(button_name)
		var rect := button.get_global_rect()
		lowest = maxf(lowest, rect.end.y)
		_expect(
			rect.size.x >= TOUCH and rect.size.y >= TOUCH,
			"%s %s clears 160 px (is %dx%d)" % [label, button_name, rect.size.x, rect.size.y]
		)
		_expect(
			button.pressed.get_connections().size() == 1,
			"%s %s is connected" % [label, button_name]
		)
		_expect(button.art != null, "%s %s has its art" % [label, button_name])

	var back: Rect2 = (bar.get_node("%BackButton") as Control).get_global_rect()
	var music: Rect2 = (bar.get_node("%MusicButton") as Control).get_global_rect()
	var sfx: Rect2 = (bar.get_node("%SfxButton") as Control).get_global_rect()
	_expect(
		is_equal_approx(back.position.y, music.position.y)
			and is_equal_approx(music.position.y, sfx.position.y),
		"%s all three buttons stand in one row" % label
	)
	_expect(
		back.end.x < stage.size.x * 0.5 and music.position.x > stage.size.x * 0.5
			and music.end.x <= sfx.position.x,
		"%s back is on the left, music then effects on the right" % label
	)

	# The header is whichever of the two a stage uses: Level 1 draws its own.
	var header := stage.get_node_or_null("%HeaderSign") as Control
	if header == null:
		header = stage.get_node_or_null("Header") as Control
	_expect(header != null, "%s has a header" % label)
	if header != null:
		_expect(
			header.get_global_rect().position.y >= lowest - 8.0,
			"%s header starts below the row (header %d, row ends %d)"
				% [label, header.get_global_rect().position.y, lowest]
		)

	stage.queue_free()
	await process_frame


func _check_toggles() -> void:
	print("--- music and effects ---")
	var audio := root.get_node_or_null("/root/AudioDirector") as AudioDirectorService
	_expect(audio != null, "AudioDirector is loaded")
	if audio == null:
		return
	audio.set_music_on(true)
	audio.set_sfx_on(true)

	var first: StageScreen = (load("res://scenes/levels/level_2/stage_1.tscn") as PackedScene).instantiate()
	var second: StageScreen = (load("res://scenes/levels/level_3/stage_1.tscn") as PackedScene).instantiate()
	root.add_child(first)
	root.add_child(second)
	await process_frame
	var bar: TopBar = first.get_node("%TopBar")
	var other: TopBar = second.get_node("%TopBar")
	var music_bus := AudioServer.get_bus_index(&"Music")
	var sfx_bus := AudioServer.get_bus_index(&"SFX")
	var vo_bus := AudioServer.get_bus_index(&"VO")

	_expect(not (bar.get_node("%MusicStrike") as Control).visible, "music starts on, unstruck")

	(bar.get_node("%MusicButton") as ArtButton).pressed.emit()
	_expect(not audio.is_music_on(), "music button switches music off")
	_expect(AudioServer.is_bus_mute(music_bus), "Music bus is muted")
	_expect(not AudioServer.is_bus_mute(sfx_bus), "effects are left alone")
	_expect((bar.get_node("%MusicStrike") as Control).visible, "music button shows it is off")
	_expect(
		(other.get_node("%MusicStrike") as Control).visible,
		"a second row on screen shows it too"
	)

	(bar.get_node("%SfxButton") as ArtButton).pressed.emit()
	_expect(not audio.is_sfx_on(), "effects button switches effects off")
	_expect(AudioServer.is_bus_mute(sfx_bus), "SFX bus is muted")
	_expect(not AudioServer.is_bus_mute(vo_bus), "voice-over is never muted by it")

	var file := ConfigFile.new()
	_expect(file.load(SETTINGS) == OK, "the choice is saved")
	_expect(
		file.get_value("sound", "music_on", true) == false
			and file.get_value("sound", "sfx_on", true) == false,
		"both are saved as off"
	)

	(bar.get_node("%MusicButton") as ArtButton).pressed.emit()
	(bar.get_node("%SfxButton") as ArtButton).pressed.emit()
	_expect(audio.is_music_on() and audio.is_sfx_on(), "pressing again switches both back on")
	_expect(
		not AudioServer.is_bus_mute(music_bus) and not AudioServer.is_bus_mute(sfx_bus),
		"both buses are heard again"
	)
	_expect(
		not (bar.get_node("%MusicStrike") as Control).visible
			and not (bar.get_node("%SfxStrike") as Control).visible,
		"neither button is struck through"
	)

	first.queue_free()
	second.queue_free()
	await process_frame


func _read_settings() -> Variant:
	if not FileAccess.file_exists(SETTINGS):
		return null
	return FileAccess.get_file_as_string(SETTINGS)


func _restore_settings(saved: Variant) -> void:
	if saved == null:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	else:
		var file := FileAccess.open(SETTINGS, FileAccess.WRITE)
		file.store_string(saved)
		file.close()
	# The running AudioDirector still holds the test's last choice; that dies
	# with this process, and the next start reads the file just restored.


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s" % label)
