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
	# The stage select reads progress, so start from a known empty game and
	# leave it that way. Otherwise a previous run decides how many rows open.
	var state: GameStateStore = root.get_node_or_null("/root/GameState") as GameStateStore
	if state != null:
		state.reset()

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
		"res://scenes/ui/level_intro.tscn",
		"res://scenes/ui/badge_unlocked.tscn",
		"res://scenes/ui/level_complete.tscn",
		"res://scenes/ui/stage_select.tscn",
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
				var bare: String = label_name.substr(1)
				if not screen.has_node(label_name):
					# A label that is in the scene but not reachable by its unique
					# name is the dangerous case: the lenient lookup skips it in
					# silence, so the node keeps whatever text was typed into the
					# editor and the exported value never reaches the screen.
					_expect(
						_find_by_name(screen, bare) == null,
						"hub '%s' exists but has no Access as Unique Name, so nothing wires it" % bare
					)
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

		# A CardOverlay is one drawn card with its button placed in fractions of
		# that card, in code. Nothing about that is visible in the scene file, so
		# a rect that stopped covering its art would break quietly.
		if screen is CardOverlay:
			var overlay: CardOverlay = screen
			_expect(overlay.card_art != null, "%s has its card art" % path.get_file())
			_expect_scene(overlay.next_scene_path, "%s next_scene_path" % path.get_file())
			var action: ArtButton = overlay.get_node("%ActionButton")
			_expect(
				action.pressed.get_connections().size() == 1,
				"%s %%ActionButton is connected" % path.get_file()
			)
			_expect(
				action.size.x >= 160.0 and action.size.y >= 160.0,
				"%s %%ActionButton clears 160 px (is %dx%d)"
					% [path.get_file(), action.size.x, action.size.y]
			)
			if overlay.button_art != null:
				var button_art: ArtSlot = overlay.get_node("%ButtonArt")
				_expect(
					action.art == button_art,
					"%s %%ActionButton tints its own art" % path.get_file()
				)

		# The stage select's rows are hotspots over rows drawn into one picture.
		# A rect that drifted off its row would still look fine and still fail.
		if screen is StageSelect:
			var select: StageSelect = screen
			var live := 0
			for i in StageSelect.ROW_RECTS.size():
				var row: Button = select.get_node("%Rows").get_node("Row%d" % (i + 1))
				_expect(
					row.size.x >= 160.0 and row.size.y >= 160.0,
					"stage_select Row%d clears 160 px (is %dx%d)" % [i + 1, row.size.x, row.size.y]
				)
				if not row.disabled:
					live += 1
					_expect(
						row.pressed.get_connections().size() == 1,
						"stage_select Row%d is connected" % (i + 1)
					)
			_expect(
				live == 1,
				"stage_select opens exactly the one reached row on a fresh start (got %d)" % live
			)
			var close: Button = select.get_node("%CloseButton")
			_expect(close.pressed.get_connections().size() == 1, "stage_select %CloseButton is connected")
			_expect(
				close.size.x >= 160.0 and close.size.y >= 160.0,
				"stage_select %%CloseButton clears 160 px (is %dx%d)" % [close.size.x, close.size.y]
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
	if state != null:
		await _check_progress_reaches_the_rows(state)
		state.reset()
	print("\n%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


## The stage select is the only screen that reads progress, and opening it on a
## fresh game proves nothing. This clears two stages and checks the rows and the
## stars actually moved.
func _check_progress_reaches_the_rows(state: GameStateStore) -> void:
	state.reset()
	state.record_stage_cleared(&"level_1", 1, 0)  # first try, three stars
	state.record_stage_cleared(&"level_1", 2, 1)  # one wrong, two stars

	var screen: StageSelect = await _instantiate("res://scenes/ui/stage_select.tscn") as StageSelect
	if screen == null:
		_expect(false, "stage select reopens with progress")
		return
	var rows: Control = screen.get_node("%Rows")
	for stage_number in [1, 2, 3]:
		_expect(
			not (rows.get_node("Row%d" % stage_number) as Button).disabled,
			"with stages 1 and 2 cleared, Row%d is open" % stage_number
		)
	_expect(
		(rows.get_node("Row4") as Button).disabled,
		"Row4 stays closed while stage 3 is unfinished"
	)

	var stars: Control = screen.get_node("%Stars")
	for expected: Array in [[1, 3], [2, 2], [3, 0], [4, 0]]:
		var stage_number: int = expected[0]
		var filled := 0
		for slot_number in 3:
			var slot: ArtSlot = stars.get_node("Row%dStar%d" % [stage_number, slot_number + 1])
			if screen.star_filled != null and slot.texture == screen.star_filled:
				filled += 1
		_expect(
			filled == expected[1],
			"Row%d shows %d filled star(s) (got %d)" % [stage_number, expected[1], filled]
		)
	screen.queue_free()
	await process_frame


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


## Depth-first search by node name, ignoring unique-name registration. Used to
## tell "this label was deleted" apart from "this label is there but unreachable".
func _find_by_name(from: Node, node_name: String) -> Node:
	for child in from.get_children():
		if child.name == node_name:
			return child
		var found: Node = _find_by_name(child, node_name)
		if found != null:
			return found
	return null


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
