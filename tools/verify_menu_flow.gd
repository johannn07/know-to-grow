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
		"res://scenes/ui/stage_select_l2.tscn",
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
			for i in select.row_count():
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
			# On a fresh start only the first row is reached, and it opens only if
			# its stage has been built.
			var first_built := ResourceLoader.exists(select.stage_scene_paths[0])
			_expect(
				live == (1 if first_built else 0),
				"%s opens exactly the reached, built rows on a fresh start (got %d)"
					% [path.get_file(), live]
			)
			# How many rows there are is set by the scene, so everything the scene
			# holds for them has to agree: one rect, one drawing each way, one
			# hotspot and one row art with three star slots per row.
			var n := select.row_count()
			_expect(n > 0, "stage_select has rows (%d)" % n)
			_expect(
				select.row_art.size() == n and select.row_art_locked.size() == n,
				"stage_select has a drawing each way for all %d rows (%d unlocked, %d locked)"
					% [n, select.row_art.size(), select.row_art_locked.size()]
			)
			_expect(
				select.get_node("%Rows").get_child_count() == n,
				"stage_select has one hotspot per row (%d for %d)"
					% [select.get_node("%Rows").get_child_count(), n]
			)
			for i in n:
				var art: Node = select.get_node("%RowsArt").get_node_or_null("Row%dArt" % (i + 1))
				_expect(
					art != null and art.get_child_count() == 3,
					"stage_select Row%dArt exists with three star slots" % (i + 1)
				)
			_expect(select.close_rect.has_area(), "stage_select close_rect is set")
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
	await _check_press_bounce()
	if state != null:
		await _check_progress_reaches_the_rows(state, "res://scenes/ui/stage_select.tscn", &"level_1")
		await _check_progress_reaches_the_rows(state, "res://scenes/ui/stage_select_l2.tscn", &"level_2")
		state.reset()
	print("\n%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


## A press should squash what the child can see and let it spring back. A themed
## button bounces itself; a hotspot bounces the art under it, never itself,
## since scaling an invisible hotspot only moves where the tap lands.
##
## This covers the buttons with **nothing behind them**. The ones laid over art
## already painted into a card must not squash, and are checked by
## [method _check_art_over_art_darkens_only].
func _check_press_bounce() -> void:
	# Every one of these has nothing painted behind the art it moves: the menu
	# button is themed and is its own art, and the three overlay cards put their
	# Continue *below* the card, over the dim.
	var cases: Array = [
		["res://scenes/ui/main_menu.tscn", "%StartButton", ""],
		["res://scenes/ui/level_intro.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/level_complete.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/badge_unlocked.tscn", "%ActionButton", "../ButtonArt"],
	]
	for case: Array in cases:
		var screen: Node = await _instantiate(case[0])
		if screen == null:
			continue
		var button: BaseButton = screen.get_node(case[1])
		var face: Control = button if case[2] == "" else button.get_node(case[2])
		var label := "%s %s" % [String(case[0]).get_file(), face.name]

		button.button_down.emit()
		await create_timer(PressBounce.PRESS_SECONDS + 0.05).timeout
		_expect(face.scale.x < 0.99, "%s squashes on press (scale %.2f)" % [label, face.scale.x])
		if face != button:
			_expect(
				(button as Control).scale == Vector2.ONE,
				"%s: the hotspot itself does not move" % label
			)
		_expect(
			face.pivot_offset.is_equal_approx(face.size * 0.5),
			"%s squashes about its centre" % label
		)

		button.button_up.emit()
		await create_timer(PressBounce.RELEASE_SECONDS + 0.1).timeout
		_expect(
			face.scale.is_equal_approx(Vector2.ONE),
			"%s springs back to full size (scale %.2f)" % [label, face.scale.x]
		)
		screen.queue_free()
		await process_frame

	# The stage select close button has no separate art — its X is part of the
	# card — so a press must neither move the hotspot nor fail.
	var select: Node = await _instantiate("res://scenes/ui/stage_select.tscn")
	if select != null:
		var close: ArtButton = select.get_node("%CloseButton")
		close.button_down.emit()
		await create_timer(PressBounce.PRESS_SECONDS + 0.05).timeout
		_expect(close.scale == Vector2.ONE, "stage_select close hotspot stays put when pressed")
		close.button_up.emit()
		select.queue_free()
		await process_frame

	await _check_art_over_art_darkens_only()


## The presses that must *not* squash: a drawing laid exactly over one already
## painted into a card. Shrinking it uncovers the painted version around its
## edges instead of reading as a press — the stage select rows over the rows in
## the card, and How To Play's X and LET'S GO over the controls painted into
## that screen. The darken has to survive, since with the bounce gone it is the
## only thing left that answers the tap.
##
## The feedback cards obey the same rule, derived from their art rect; that is
## checked by verify_level_1, which is where a stage gets played.
func _check_art_over_art_darkens_only() -> void:
	# The art is read off the button's own resolved reference rather than by
	# path, so this checks the very node the button tints.
	var cases: Array = [
		["res://scenes/ui/stage_select.tscn", "%Rows/Row1"],
		["res://scenes/ui/stage_select.tscn", "%Rows/Row2"],
		["res://scenes/ui/stage_select.tscn", "%Rows/Row3"],
		["res://scenes/ui/stage_select.tscn", "%Rows/Row4"],
		["res://scenes/ui/stage_select_l2.tscn", "%Rows/Row1"],
		["res://scenes/ui/stage_select_l2.tscn", "%Rows/Row2"],
		["res://scenes/ui/stage_select_l2.tscn", "%Rows/Row3"],
		["res://scenes/ui/stage_select_l2.tscn", "%Rows/Row4"],
		["res://scenes/ui/stage_select_l2.tscn", "%Rows/Row5"],
		["res://scenes/ui/how_to_play.tscn", "%BackButton"],
		["res://scenes/ui/how_to_play.tscn", "%LetsGoButton"],
	]
	for case: Array in cases:
		var screen: Node = await _instantiate(case[0])
		if screen == null:
			continue
		var label := "%s %s" % [String(case[0]).get_file(), String(case[1]).get_file()]
		var button: ArtButton = screen.get_node_or_null(case[1]) as ArtButton
		var art: Control = null if button == null else button.art as Control
		if button == null or art == null:
			_expect(false, "%s has a hotspot with art under it" % label)
			screen.queue_free()
			await process_frame
			continue
		_expect(not button.bounce_art, "%s opts out of the bounce" % label)

		button.button_down.emit()
		await create_timer(PressBounce.PRESS_SECONDS + 0.05).timeout
		_expect(
			art.scale.is_equal_approx(Vector2.ONE),
			"%s art does not squash (scale %.2f)" % [label, art.scale.x]
		)
		_expect(
			art.modulate.is_equal_approx(ArtButton.PRESSED_TINT),
			"%s art darkens on press" % label
		)

		button.button_up.emit()
		await process_frame
		_expect(
			art.modulate.is_equal_approx(Color.WHITE),
			"%s art lifts its tint on release" % label
		)
		screen.queue_free()
		await process_frame


## The stage select is the only screen that reads progress, and opening it on a
## fresh game proves nothing. This clears two stages of a level and checks the
## rows and the stars actually moved, on each level's card.
func _check_progress_reaches_the_rows(
	state: GameStateStore, path: String, level_id: StringName
) -> void:
	state.reset()
	state.record_stage_cleared(level_id, 1, 0)  # first try, three stars
	state.record_stage_cleared(level_id, 2, 1)  # one wrong, two stars
	var label := path.get_file()

	var screen: StageSelect = await _instantiate(path) as StageSelect
	if screen == null:
		_expect(false, "%s reopens with progress" % label)
		return
	var rows: Control = screen.get_node("%Rows")
	var rows_art: Control = screen.get_node("%RowsArt")
	for stage_number in range(1, screen.row_count() + 1):
		var reached: bool = stage_number <= 3
		# A reached row opens only if its stage has been built. Level 2's rows
		# are drawn before its stages exist, and must not lead nowhere.
		var built := ResourceLoader.exists(screen.stage_scene_paths[stage_number - 1])
		var open := not (rows.get_node("Row%d" % stage_number) as Button).disabled
		_expect(
			open == (reached and built),
			"%s Row%d is %s (reached %s, built %s)"
				% [label, stage_number, "open" if open else "closed", reached, built]
		)
		# A reached row must be drawn in its unlocked state, not just be
		# tappable. A locked row with no drawing of its own draws nothing, so
		# the locked row painted into the card shows through instead.
		var slot: ArtSlot = rows_art.get_node("Row%dArt" % stage_number)
		var art := screen._row_art(stage_number, reached)
		_expect(
			slot.texture == art and (art != null or slot.hide_when_empty),
			"%s Row%d is drawn %s" % [
				label, stage_number,
				"unlocked" if reached else ("locked" if art != null else "as the card paints it")
			]
		)
		var want := 3 if stage_number == 1 else (2 if stage_number == 2 else 0)
		var filled := 0
		for slot_number in 3:
			var star: ArtSlot = rows_art.get_node(
				"Row%dArt/Row%dStar%d" % [stage_number, stage_number, slot_number + 1]
			)
			if screen.star_filled != null and star.texture == screen.star_filled:
				filled += 1
		_expect(
			filled == want,
			"%s Row%d shows %d filled star(s) (got %d)" % [label, stage_number, want, filled]
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
