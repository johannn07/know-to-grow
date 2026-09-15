extends SceneTree

## Headless smoke test for the menu flow. Takes about two seconds and exits
## non-zero on failure, so it is worth running before every commit that touches
## a screen:
##
##   godot --headless --path . -s res://tools/verify_menu_flow.gd
##
## It checks the things that break silently: unique node names that no longer
## resolve, exported scene paths pointing at nothing, theme variations that were
## renamed, touch targets that shrank below the 160 px floor, and ArtSlots that
## would swallow a tap meant for a button.

var _failures := 0


func _initialize() -> void:
	await process_frame

	var menu: Node = await _instantiate("res://scenes/ui/main_menu.tscn")
	if menu != null:
		_expect(menu.has_node("%StartButton"), "menu has %StartButton")
		_expect(menu.has_node("%HowToPlayButton"), "menu has %HowToPlayButton")
		_expect_scene(menu.start_scene_path, "menu.start_scene_path")
		_expect_scene(menu.how_to_play_scene_path, "menu.how_to_play_scene_path")

		var start: Button = menu.get_node("%StartButton")
		_expect(start.pressed.get_connections().size() == 1, "StartButton is connected")
		_expect(
			start.has_theme_stylebox("normal", "PrimaryButton"),
			"PrimaryButton variation resolves in the theme"
		)
		_expect(start.size.y >= 160.0, "StartButton is >= 160 px tall (is %d)" % start.size.y)

		var how: Button = menu.get_node("%HowToPlayButton")
		_expect(how.size.y >= 160.0, "HowToPlayButton is >= 160 px tall (is %d)" % how.size.y)

		# An ArtSlot must never swallow a tap meant for a button underneath it.
		for slot in _find_art_slots(menu):
			_expect(
				slot.mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"ArtSlot '%s' ignores input" % slot.name
			)
		menu.queue_free()

	for path in [
		"res://scenes/ui/hub.tscn",
		"res://scenes/ui/how_to_play.tscn",
		"res://scenes/ui/level_select_stub.tscn",
	]:
		var screen: Node = await _instantiate(path)
		if screen == null:
			continue
		# Every SubScreen has a way back, but only some draw a button for it —
		# the hub relies on the Android gesture alone, by design.
		if screen.has_node("%BackButton"):
			var back: Button = screen.get_node("%BackButton")
			_expect(
				back.pressed.get_connections().size() == 1,
				"%s %%BackButton is connected" % path.get_file()
			)
		_expect_scene(screen.back_scene_path, "%s back_scene_path" % path.get_file())

		for slot in _find_art_slots(screen):
			_expect(
				slot.mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"%s ArtSlot '%s' ignores input" % [path.get_file(), slot.name]
			)

		# The hub is composed from separate art with live text over it, so the
		# things that break quietly are the label lookups and the play target.
		if screen.has_node("%PlayButton"):
			_expect_scene(screen.level_scene_path, "hub level_scene_path")
			# The hub's text nodes are optional — the layout is still moving, and
			# cards get added and removed in the editor. So do not demand a
			# particular set of labels; demand that the ones the scene does have
			# received their exported value, which is what a mistyped unique name
			# would break.
			var expected := {
				"%GreetingLabel": screen.player_greeting,
				"%StarLabel": str(screen.star_count),
				"%PlantStageLabel": screen.plant_stage_label,
			}
			var wired := 0
			for label_name in expected:
				if not screen.has_node(label_name):
					continue
				var label: Label = screen.get_node(label_name)
				_expect(
					label.text == expected[label_name],
					"hub %s shows its exported value ('%s')" % [label_name, label.text]
				)
				wired += 1
			_expect(wired > 0, "hub wires at least one label (%d found)" % wired)
			var play: Button = screen.get_node("%PlayButton")
			_expect(play.pressed.get_connections().size() == 1, "hub %PlayButton is connected")
			_expect(
				play.size.y >= 160.0, "hub %%PlayButton is >= 160 px tall (is %d)" % play.size.y
			)
			# The three tabs are drawn but have nowhere to go yet. They must stay
			# disabled: a tab that looks live and does nothing teaches a child
			# that tapping does not work.
			for tab_name in ["%LessonsButton", "%GardenButton", "%BadgesButton"]:
				var tab: Button = screen.get_node(tab_name)
				_expect(tab.disabled, "hub %s is disabled until it has a destination" % tab_name)
				_expect(
					tab.size.x >= 160.0 and tab.size.y >= 160.0,
					"hub %s clears 160 px (is %dx%d)" % [tab_name, tab.size.x, tab.size.y]
				)

		# How To Play is a single drawn image; its controls are invisible Buttons
		# sitting over the painted ones, so their placement is only verifiable here.
		if screen.has_node("%LetsGoButton"):
			_expect_scene(screen.start_scene_path, "how_to_play start_scene_path")
			for name in ["%LetsGoButton", "%BackButton"]:
				var b: Button = screen.get_node(name)
				_expect(b.pressed.get_connections().size() == 1, "%s is connected" % name)
				_expect(
					b.size.x >= 160.0 and b.size.y >= 160.0,
					"%s hit area clears 160 px (is %dx%d)" % [name, b.size.x, b.size.y]
				)
		screen.queue_free()

	await process_frame
	print("\n%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


func _instantiate(path: String) -> Node:
	var packed: PackedScene = load(path)
	if packed == null:
		_expect(false, "%s loads" % path)
		return null
	var node := packed.instantiate()
	root.add_child(node)
	# Containers need a layout pass before sizes mean anything.
	root.get_viewport().size = Vector2i(1080, 1920)
	node.set_deferred("size", Vector2(1080, 1920))
	await process_frame
	await process_frame
	return node


func _find_art_slots(from: Node) -> Array[ArtSlot]:
	var found: Array[ArtSlot] = []
	for child in from.get_children():
		if child is ArtSlot:
			found.append(child)
		found.append_array(_find_art_slots(child))
	return found


func _expect_scene(path: String, label: String) -> void:
	_expect(not path.is_empty() and ResourceLoader.exists(path), "%s -> '%s'" % [label, path])


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s" % label)
