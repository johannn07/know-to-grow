extends SceneTree

## Checks the back / settings row on every stage, and the Settings card.
##
##   godot --headless --path . -s res://tools/verify_top_bar.gd
##
## Every one of the 19 stages carries a [TopBar]. This walks them all and checks
## the things that break quietly: that the row is there and under the feedback
## overlay, that both buttons clear 160 px and are wired, that the row sits
## above the header rather than on it, and that back leads to the stage's own
## level select rather than falling through to the main menu default.
##
## It then opens Settings and checks the card: every way of closing it, that
## Android's back closes it rather than leaving the stage, and that music and
## effects flip the audio buses, save, and darken their own art.
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
	await _check_hub()

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
	for button_name in ["%BackButton", "%SettingsButton"]:
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
	var settings: Rect2 = (bar.get_node("%SettingsButton") as Control).get_global_rect()
	_expect(
		is_equal_approx(back.position.y, settings.position.y),
		"%s both buttons stand in one row" % label
	)
	_expect(
		back.end.x < stage.size.x * 0.5 and settings.position.x > stage.size.x * 0.5,
		"%s back is on the left, settings on the right" % label
	)
	_expect(not bar.settings_open(), "%s settings starts closed" % label)

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
	print("--- the settings card ---")
	var audio := root.get_node_or_null("/root/AudioDirector") as AudioDirectorService
	_expect(audio != null, "AudioDirector is loaded")
	if audio == null:
		return
	audio.set_music_on(true)
	audio.set_sfx_on(true)

	var stage: StageScreen = (load("res://scenes/levels/level_2/stage_1.tscn") as PackedScene).instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame
	var bar: TopBar = stage.get_node("%TopBar")
	var card: SettingsOverlay = bar.get_node("%Settings")

	(bar.get_node("%SettingsButton") as ArtButton).pressed.emit()
	await process_frame
	_expect(bar.settings_open(), "settings button opens the card")
	_expect(
		card.get_global_rect().size.is_equal_approx(stage.get_viewport_rect().size),
		"the card's dim covers the whole screen (is %s)" % card.get_global_rect().size
	)
	for button_name in ["%CloseButton", "%MusicButton", "%SfxButton", "%MainMenuButton"]:
		var button: BaseButton = card.get_node(button_name)
		var rect := button.get_global_rect()
		_expect(
			rect.size.x >= TOUCH and rect.size.y >= TOUCH,
			"%s clears 160 px (is %dx%d)" % [button_name, rect.size.x, rect.size.y]
		)
		_expect(button.pressed.get_connections().size() >= 1, "%s is connected" % button_name)
	_expect(
		ResourceLoader.exists(card.main_menu_path),
		"Main Menu leads somewhere real ('%s')" % card.main_menu_path
	)
	var title: Label = card.get_node("%Title")
	_expect(title.text == "Settings", "the card is headed Settings")
	_expect(
		(card.get_node("%CardArt") as ArtSlot).texture != null,
		"the card has its art"
	)

	var music_art: ArtSlot = card.get_node("%MusicArt")
	var sfx_art: ArtSlot = card.get_node("%SfxArt")
	var music_bus := AudioServer.get_bus_index(&"Music")
	var sfx_bus := AudioServer.get_bus_index(&"SFX")
	var vo_bus := AudioServer.get_bus_index(&"VO")
	_expect(music_art.self_modulate == Color.WHITE, "music starts on, at full brightness")

	(card.get_node("%MusicButton") as ArtButton).pressed.emit()
	_expect(not audio.is_music_on(), "music button switches music off")
	_expect(AudioServer.is_bus_mute(music_bus), "Music bus is muted")
	_expect(not AudioServer.is_bus_mute(sfx_bus), "effects are left alone")
	_expect(music_art.self_modulate.v < 0.6, "music art is drawn darker")
	_expect(sfx_art.self_modulate == Color.WHITE, "effects art is not")

	(card.get_node("%SfxButton") as ArtButton).pressed.emit()
	_expect(not audio.is_sfx_on(), "effects button switches effects off")
	_expect(AudioServer.is_bus_mute(sfx_bus), "SFX bus is muted")
	_expect(not AudioServer.is_bus_mute(vo_bus), "voice-over is never muted by it")
	_expect(sfx_art.self_modulate.v < 0.6, "effects art is drawn darker")

	var file := ConfigFile.new()
	_expect(file.load(SETTINGS) == OK, "the choice is saved")
	_expect(
		file.get_value("sound", "music_on", true) == false
			and file.get_value("sound", "sfx_on", true) == false,
		"both are saved as off"
	)

	(card.get_node("%MusicButton") as ArtButton).pressed.emit()
	(card.get_node("%SfxButton") as ArtButton).pressed.emit()
	_expect(audio.is_music_on() and audio.is_sfx_on(), "pressing again switches both back on")
	_expect(
		not AudioServer.is_bus_mute(music_bus) and not AudioServer.is_bus_mute(sfx_bus),
		"both buses are heard again"
	)
	_expect(
		music_art.self_modulate == Color.WHITE and sfx_art.self_modulate == Color.WHITE,
		"both are back at full brightness"
	)

	# Three ways out, none of which leaves the stage.
	(card.get_node("%CloseButton") as ArtButton).pressed.emit()
	_expect(not bar.settings_open(), "the X closes the card")

	bar.open_settings()
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	(card.get_node("%Dim") as ColorRect).gui_input.emit(release)
	_expect(not bar.settings_open(), "a tap on the dim closes the card")

	bar.open_settings()
	stage.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await process_frame
	_expect(not bar.settings_open(), "Android back closes the card")
	_expect(
		stage.is_inside_tree() and get_current_scene_path() != stage.back_scene_path,
		"and stays on the stage rather than going back"
	)

	stage.queue_free()
	await process_frame


func _check_hub() -> void:
	print("--- the hub ---")
	var hub: Control = (load("res://scenes/ui/hub.tscn") as PackedScene).instantiate()
	root.add_child(hub)
	await process_frame
	await process_frame
	var bar := hub.get_node_or_null("%TopBar") as TopBar
	_expect(bar != null, "hub has a %TopBar")
	if bar == null:
		hub.queue_free()
		return
	_expect(not (bar.get_node("%BackButton") as Control).visible, "hub shows no back button")
	_expect(not (bar.get_node("%BackArt") as Control).visible, "hub shows no back arrow")
	var settings: Control = bar.get_node("%SettingsButton")
	var rect := settings.get_global_rect()
	_expect(
		rect.size.x >= TOUCH and rect.size.y >= TOUCH,
		"hub settings clears 160 px (is %dx%d)" % [rect.size.x, rect.size.y]
	)
	_expect(rect.end.x > hub.size.x * 0.5, "hub settings is on the right")
	for pill_name in ["GreetingPill", "StarPill"]:
		var pill: Control = hub.get_node(pill_name)
		_expect(
			not pill.get_global_rect().intersects(rect),
			"hub settings does not cover the %s" % pill_name
		)
	var bar_is_last := bar.get_index() == hub.get_child_count() - 1
	_expect(bar_is_last, "hub row draws over the rest of the hub")

	(settings as ArtButton).pressed.emit()
	await process_frame
	_expect(bar.settings_open(), "hub settings opens the card")
	hub.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await process_frame
	_expect(not bar.settings_open(), "Android back closes the card on the hub")
	_expect(hub.is_inside_tree(), "and stays on the hub")

	hub.queue_free()
	await process_frame


func get_current_scene_path() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


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
