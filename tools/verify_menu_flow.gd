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
		_expect(menu.has_node("%ContinueButton"), "menu has %ContinueButton")
		_expect(menu.has_node("%NewGameButton"), "menu has %NewGameButton")
		_expect(menu.has_node("%HowToPlayButton"), "menu has %HowToPlayButton")
		_expect_scene(menu.start_scene_path, "menu.start_scene_path")
		_expect_scene(menu.how_to_play_scene_path, "menu.how_to_play_scene_path")

		var new_game: HoldButton = menu.get_node("%NewGameButton")
		var continue_button: Button = menu.get_node("%ContinueButton")
		_expect(new_game.held.get_connections().size() == 1, "NewGameButton's hold is connected")
		_expect(continue_button.pressed.get_connections().size() == 1, "ContinueButton is connected")
		_expect(
			new_game.has_theme_stylebox("normal", "PrimaryButton"),
			"PrimaryButton variation resolves in the theme"
		)
		_expect(new_game.text == "New Game", "the first button reads New Game (is '%s')" % new_game.text)
		_expect(new_game.size.y >= 160.0, "NewGameButton is >= 160 px tall (is %d)" % new_game.size.y)
		_expect(continue_button.size.y >= 160.0,
			"ContinueButton is >= 160 px tall (is %d)" % continue_button.size.y)

		var how: Button = menu.get_node("%HowToPlayButton")
		_expect(how.size.y >= 160.0, "HowToPlayButton is >= 160 px tall (is %d)" % how.size.y)

		# An ArtSlot must never swallow a tap meant for a button underneath it.
		for slot in _find_art_slots(menu):
			_expect(
				slot.mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"ArtSlot '%s' ignores input" % slot.name
			)

		# --- With no save: no Continue, and New Game is a plain tap ---
		_expect(not continue_button.visible, "no save: Continue is hidden")
		_expect(not new_game.require_hold, "no save: New Game is a plain tap")
		_expect(not (menu.get_node("%HoldHint") as Control).visible, "no save: no hold hint")
		menu.queue_free()
		await process_frame

	if state != null:
		await _check_menu_with_a_save(state)

	for path in [
		"res://scenes/ui/hub.tscn",
		"res://scenes/ui/garden.tscn",
		"res://scenes/ui/badges.tscn",
		"res://scenes/ui/how_to_play.tscn",
		"res://scenes/ui/level_select_stub.tscn",
		"res://scenes/ui/level_intro.tscn",
		"res://scenes/ui/level_intro_l2.tscn",
		"res://scenes/ui/badge_unlocked.tscn",
		"res://scenes/ui/level_complete_sign.tscn",
		"res://scenes/ui/level_complete.tscn",
		"res://scenes/ui/level_complete_l2.tscn",
		"res://scenes/ui/badge_unlocked_l2.tscn",
		"res://scenes/ui/badge_unlocked_l2_green_thumb.tscn",
		"res://scenes/ui/level_complete_sign_l2.tscn",
		"res://scenes/ui/level_intro_l3.tscn",
		"res://scenes/ui/stage_select.tscn",
		"res://scenes/ui/stage_select_l2.tscn",
		"res://scenes/ui/stage_select_l3.tscn",
		"res://scenes/ui/level_complete_l3.tscn",
		"res://scenes/ui/badge_unlocked_l3.tscn",
		"res://scenes/ui/level_complete_sign_l3.tscn",
		"res://scenes/ui/level_intro_l4.tscn",
		"res://scenes/ui/stage_select_l4.tscn",
		"res://scenes/ui/level_complete_l4.tscn",
		"res://scenes/ui/badge_unlocked_l4.tscn",
		"res://scenes/ui/badge_unlocked_l4_super_grower.tscn",
		"res://scenes/ui/badge_unlocked_l4_know_to_grow_star.tscn",
		"res://scenes/ui/level_complete_sign_l4.tscn",
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
			_expect(
				screen.level_scene_paths.size() == screen.level_labels.size()
					and screen.level_scene_paths.size() == screen.plant_stages.size(),
				"hub has a destination and a label for every plant stage"
			)
			for i in screen.level_scene_paths.size():
				_expect_scene(screen.level_scene_paths[i], "hub level_scene_paths[%d]" % i)
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
			# Whether a tab is open depends on progress, so that is checked in
			# _check_lessons_and_pages, _check_garden and _check_badges.
			for tab_name in ["%LessonsButton", "%GardenButton", "%BadgesButton"]:
				var tab: Button = screen.get_node(tab_name)
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
	_check_ending(&"level_2", [
		"res://scenes/levels/level_2/stage_5.tscn",
		"res://scenes/ui/level_complete_l2.tscn",
		"res://scenes/ui/badge_unlocked_l2.tscn",
		"res://scenes/ui/badge_unlocked_l2_green_thumb.tscn",
		"res://scenes/ui/level_complete_sign_l2.tscn",
		"res://scenes/ui/hub.tscn",
	])
	_check_ending(&"level_3", [
		"res://scenes/levels/level_3/stage_5.tscn",
		"res://scenes/ui/level_complete_l3.tscn",
		"res://scenes/ui/badge_unlocked_l3.tscn",
		"res://scenes/ui/level_complete_sign_l3.tscn",
		"res://scenes/ui/hub.tscn",
	])
	_check_ending(&"level_4", [
		"res://scenes/levels/level_4/stage_5.tscn",
		"res://scenes/ui/level_complete_l4.tscn",
		"res://scenes/ui/badge_unlocked_l4.tscn",
		"res://scenes/ui/badge_unlocked_l4_super_grower.tscn",
		"res://scenes/ui/badge_unlocked_l4_know_to_grow_star.tscn",
		"res://scenes/ui/level_complete_sign_l4.tscn",
		"res://scenes/ui/hub.tscn",
	])
	if state != null:
		await _check_hub_grows_the_plant(state)
		await _check_finished_game(state)
		await _check_progress_reaches_the_rows(state, "res://scenes/ui/stage_select.tscn", &"level_1")
		await _check_progress_reaches_the_rows(state, "res://scenes/ui/stage_select_l2.tscn", &"level_2")
		await _check_progress_reaches_the_rows(state, "res://scenes/ui/stage_select_l3.tscn", &"level_3")
		await _check_progress_reaches_the_rows(state, "res://scenes/ui/stage_select_l4.tscn", &"level_4")
		await _check_lessons_and_pages(state)
		await _check_garden(state)
		await _check_badges(state)
		state.reset()
	print("\n%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(_failures)


## Every level ends the same shape: its last stage leads to Level Complete,
## then one badge or two, then its sign, whose Grow Now goes to the hub where
## the plant has grown. Each screen has to name the next, and a chain that
## forks anywhere leaves a child stranded on a card with nowhere to go.
func _check_ending(level_id: StringName, chain: Array) -> void:
	for i in chain.size() - 1:
		var node: Node = (load(chain[i]) as PackedScene).instantiate()
		var next: String = node.get("done_scene_path") if node is StageScreen 			else node.get("next_scene_path")
		_expect(
			next == chain[i + 1],
			"%s ending: %s leads on to %s"
				% [level_id, chain[i].get_file(), chain[i + 1].get_file()]
		)
		node.free()


## A save changes the title screen: Continue appears above New Game, and New
## Game has to be held so a stray tap cannot wipe the garden. Leaves progress
## empty, as it found it.
func _check_menu_with_a_save(state: GameStateStore) -> void:
	state.record_stage_cleared(&"level_1", 1, 0)
	var menu: Node = await _instantiate("res://scenes/ui/main_menu.tscn")
	if menu == null:
		state.reset()
		return
	var continue_button: Button = menu.get_node("%ContinueButton")
	var new_game: HoldButton = menu.get_node("%NewGameButton")
	var hint: Label = menu.get_node("%HoldHint")
	_expect(continue_button.visible, "save: Continue is shown")
	_expect(continue_button.position.y < new_game.position.y, "save: Continue sits above New Game")
	_expect(new_game.require_hold, "save: New Game has to be held")
	_expect(hint.visible, "save: the hold hint is shown")
	_expect(hint.position.y > new_game.position.y, "save: the hint sits under New Game")

	# Nowhere to go, so the handlers can run without changing the scene.
	menu.start_scene_path = ""
	new_game.pressed.emit()
	_expect(state.has_progress(), "save: a plain tap on New Game keeps the save")
	new_game.held.emit()
	_expect(not state.has_progress(), "save: holding New Game wipes the save")
	menu.queue_free()
	await process_frame
	state.reset()


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
		["res://scenes/ui/main_menu.tscn", "%NewGameButton", ""],
		["res://scenes/ui/level_intro.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/level_intro_l2.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/level_complete.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/badge_unlocked.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/level_complete_l2.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/badge_unlocked_l2.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/badge_unlocked_l2_green_thumb.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/level_intro_l3.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/level_complete_l3.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/badge_unlocked_l3.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/level_intro_l4.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/level_complete_l4.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/badge_unlocked_l4.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/badge_unlocked_l4_super_grower.tscn", "%ActionButton", "../ButtonArt"],
		["res://scenes/ui/badge_unlocked_l4_know_to_grow_star.tscn", "%ActionButton", "../ButtonArt"],
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
		["res://scenes/ui/stage_select_l3.tscn", "%Rows/Row1"],
		["res://scenes/ui/stage_select_l3.tscn", "%Rows/Row2"],
		["res://scenes/ui/stage_select_l3.tscn", "%Rows/Row3"],
		["res://scenes/ui/stage_select_l3.tscn", "%Rows/Row4"],
		["res://scenes/ui/stage_select_l3.tscn", "%Rows/Row5"],
		["res://scenes/ui/stage_select_l4.tscn", "%Rows/Row1"],
		["res://scenes/ui/stage_select_l4.tscn", "%Rows/Row2"],
		["res://scenes/ui/stage_select_l4.tscn", "%Rows/Row3"],
		["res://scenes/ui/stage_select_l4.tscn", "%Rows/Row4"],
		["res://scenes/ui/stage_select_l4.tscn", "%Rows/Row5"],
		["res://scenes/ui/stage_select.tscn", "%CloseButton"],
		["res://scenes/ui/stage_select_l2.tscn", "%CloseButton"],
		["res://scenes/ui/stage_select_l3.tscn", "%CloseButton"],
		["res://scenes/ui/stage_select_l4.tscn", "%CloseButton"],
		["res://scenes/ui/level_complete_sign.tscn", "%ActionButton"],
		["res://scenes/ui/level_complete_sign_l2.tscn", "%ActionButton"],
		["res://scenes/ui/level_complete_sign_l3.tscn", "%ActionButton"],
		["res://scenes/ui/level_complete_sign_l4.tscn", "%ActionButton"],
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


## Lessons is locked, and drawn grey, until Level 1 is cleared, then leads to
## the stage select of the level the plant is waiting on. The four stage selects
## are pages of one strip: each links to its neighbours both ways, offers the
## next only once its own level is cleared, and turns on a sideways swipe.
func _check_lessons_and_pages(state: GameStateStore) -> void:
	var pages: Array[String] = [
		"res://scenes/ui/stage_select.tscn",
		"res://scenes/ui/stage_select_l2.tscn",
		"res://scenes/ui/stage_select_l3.tscn",
		"res://scenes/ui/stage_select_l4.tscn",
	]

	# --- the hub's Lessons tab ---
	state.reset()
	var hub: Node = await _instantiate("res://scenes/ui/hub.tscn")
	if hub != null:
		var lessons: Button = hub.get_node("%LessonsButton")
		var icon: ArtSlot = lessons.get_parent().get_node("Content/Icon")
		var label: Label = lessons.get_parent().get_node("Content/TabLabel")
		_expect(lessons.disabled, "lessons: locked before Level 1 is cleared")
		_expect(
			hub.lessons_icon_locked != null and icon.texture == hub.lessons_icon_locked,
			"lessons: drawn grey while locked"
		)
		_expect(label.has_theme_color_override(&"font_color"), "lessons: its name is grey while locked")
		_expect(lessons.pressed.get_connections().size() == 1, "lessons: %LessonsButton is connected")
		_expect(
			hub.lesson_scene_paths.size() == hub.plant_stages.size(),
			"lessons: a destination for every plant stage"
		)
		for i in hub.lesson_scene_paths.size():
			_expect_scene(hub.lesson_scene_paths[i], "hub lesson_scene_paths[%d]" % i)
		hub.queue_free()
		await process_frame
	for stage_number in range(1, 5):
		state.record_stage_cleared(&"level_1", stage_number, 0)
	hub = await _instantiate("res://scenes/ui/hub.tscn")
	if hub != null:
		var lessons: Button = hub.get_node("%LessonsButton")
		var icon: ArtSlot = lessons.get_parent().get_node("Content/Icon")
		var label: Label = lessons.get_parent().get_node("Content/TabLabel")
		_expect(not lessons.disabled, "lessons: open once Level 1 is cleared")
		_expect(
			icon.texture != null and icon.texture != hub.lessons_icon_locked,
			"lessons: drawn in colour once open"
		)
		_expect(not label.has_theme_color_override(&"font_color"), "lessons: its name is brown once open")
		_expect(hub.lesson_scene_path() == pages[1], "lessons: after Level 1 it opens Level 2's stages")
		hub.queue_free()
		await process_frame

	# --- the strip is linked both ways; Level 1 cleared, so it is Levels 1-2 ---
	for i in pages.size():
		var select: StageSelect = await _instantiate(pages[i]) as StageSelect
		if select == null:
			continue
		var label := pages[i].get_file()
		var want_previous := pages[i - 1] if i > 0 else ""
		var want_next := pages[i + 1] if i + 1 < pages.size() else ""
		_expect(select.previous_page_path == want_previous, "%s: left goes to '%s'" % [label, want_previous])
		_expect(select.next_page_path == want_next, "%s: right goes to '%s'" % [label, want_next])
		var card: Control = select.get_node("%CardArt")
		for side in ["Previous", "Next"]:
			var button: Button = select.get_node("%" + side + "Button")
			var art: ArtSlot = select.get_node("%" + side + "Art") as ArtSlot
			_expect(button.pressed.get_connections().size() == 1, "%s %sButton is connected" % [label, side])
			_expect(
				button.size.x >= 160.0 and button.size.y >= 160.0,
				"%s %sButton clears 160 px (is %dx%d)" % [label, side, button.size.x, button.size.y]
			)
			_expect(art != null and art.texture != null, "%s %sArt has its arrow" % [label, side])
			# The arrows live in the gutters, so they cannot hide a row or the X.
			if art != null:
				_expect(
					not art.get_global_rect().intersects(card.get_global_rect()),
					"%s %sArt stays clear of the card" % [label, side]
				)
		var want_left := i > 0
		var want_right := i == 0
		_expect(
			(select.get_node("%PreviousButton") as Button).visible == want_left,
			"%s: left arrow %s" % [label, "shown" if want_left else "hidden"]
		)
		_expect(
			(select.get_node("%NextButton") as Button).visible == want_right
				and (select.get_node("%NextArt") as CanvasItem).visible == want_right,
			"%s: right arrow %s with Level 1 cleared" % [label, "shown" if want_right else "hidden"]
		)
		select.queue_free()
		await process_frame

	# --- a swipe turns the page, and the next one slides in ---
	_expect(SwipeTracker.direction(Vector2(-300, 20)) == 1, "swipe: left moves on a level")
	_expect(SwipeTracker.direction(Vector2(300, -20)) == -1, "swipe: right goes back one")
	_expect(SwipeTracker.direction(Vector2(-60, 0)) == 0, "swipe: a short drag is a tap")
	_expect(SwipeTracker.direction(Vector2(-200, 400)) == 0, "swipe: a steep drag is not a swipe")
	var first: StageSelect = await _instantiate(pages[0]) as StageSelect
	if first != null:
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = Vector2(800, 900)
		first._input(press)
		var lift := press.duplicate() as InputEventMouseButton
		lift.pressed = false
		lift.position = Vector2(400, 920)
		first._input(lift)
		_expect(first.is_paging(), "swipe: dragging Level 1's card left turns the page")
		# Freed before its tween ends, so the scene never actually changes here.
		first.queue_free()
		await process_frame
	var second: StageSelect = await _instantiate(pages[1]) as StageSelect
	if second != null:
		var center: Control = second.get_node("%Center")
		_expect(center.offset_left > 0.0, "swipe: Level 2's card arrives from the right")
		await create_timer(StageSelect.PAGE_SECONDS + 0.2).timeout
		_expect(is_zero_approx(center.offset_left), "swipe: and comes to rest in place")
		# Level 2 is not cleared, so there is no page on to Level 3.
		second.turn_page(1)
		_expect(not second.is_paging(), "swipe: no page past the level the child has reached")
		second.queue_free()
		await process_frame
	state.reset()


## Garden is locked like Lessons until Level 1 is cleared. It opens on the plant
## as it is now, centred, and pages back towards the seed and forward again —
## never past the stage the plant has reached.
func _check_garden(state: GameStateStore) -> void:
	state.reset()
	var hub: Node = await _instantiate("res://scenes/ui/hub.tscn")
	var hub_stages: Array[Texture2D] = []
	var hub_names: Array[String] = []
	var hub_levels: Array[LevelData] = []
	if hub != null:
		var garden_tab: Button = hub.get_node("%GardenButton")
		var icon: ArtSlot = garden_tab.get_parent().get_node("Content/Icon")
		_expect(garden_tab.disabled, "garden tab: locked before Level 1 is cleared")
		_expect(
			hub.garden_icon_locked != null and icon.texture == hub.garden_icon_locked,
			"garden tab: drawn grey while locked"
		)
		_expect(garden_tab.pressed.get_connections().size() == 1, "garden tab: %GardenButton is connected")
		_expect_scene(hub.garden_scene_path, "hub garden_scene_path")
		hub_stages = hub.plant_stages
		hub_names = hub.plant_stage_names
		hub_levels = hub.growth_levels
		hub.queue_free()
		await process_frame
	for stage_number in range(1, 5):
		state.record_stage_cleared(&"level_1", stage_number, 0)
	hub = await _instantiate("res://scenes/ui/hub.tscn")
	if hub != null:
		var garden_tab: Button = hub.get_node("%GardenButton")
		var icon: ArtSlot = garden_tab.get_parent().get_node("Content/Icon")
		_expect(not garden_tab.disabled, "garden tab: open once Level 1 is cleared")
		_expect(icon.texture != hub.garden_icon_locked, "garden tab: drawn in colour once open")
		hub.queue_free()
		await process_frame

	# Level 1 and 2 cleared: the plant is a sprout, and the seed and root are
	# behind it.
	for stage_number in range(1, 6):
		state.record_stage_cleared(&"level_2", stage_number, 0)
	var garden: GardenScreen = await _instantiate("res://scenes/ui/garden.tscn") as GardenScreen
	if garden == null:
		_expect(false, "garden loads")
		state.reset()
		return
	_expect(
		garden.plant_stages == hub_stages and garden.plant_stage_names == hub_names
			and garden.growth_levels == hub_levels,
		"garden: the same plants, names and levels as the hub"
	)
	var plant: ArtSlot = garden.get_node("%Plant")
	var sign: HeaderSign = garden.get_node("%HeaderSign")
	var previous: Button = garden.get_node("%PreviousButton")
	var next: Button = garden.get_node("%NextButton")
	_expect(
		is_equal_approx(plant.get_global_rect().get_center().x, 540.0),
		"garden: the plant is centred (at x %d)" % plant.get_global_rect().get_center().x
	)
	_expect(garden.shown_stage() == 2 and plant.texture == garden.plant_stages[2],
		"garden: opens on the plant as it is now, the sprout")
	_expect(sign.label_text == "My Plant" and sign.title_text == "SPROUT",
		"garden: the sign reads My Plant / SPROUT (is %s / %s)" % [sign.label_text, sign.title_text])
	_expect(previous.visible and not next.visible, "garden: at the sprout, only the way back is offered")
	for button: Button in [previous, next]:
		_expect(button.pressed.get_connections().size() == 1, "garden %s is connected" % button.name)
		_expect(button.size.x >= 160.0 and button.size.y >= 160.0,
			"garden %s clears 160 px (is %dx%d)" % [button.name, button.size.x, button.size.y])
	garden.turn_page(1)
	_expect(not garden.is_paging(), "garden: no page past the stage the plant has reached")

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(300, 900)
	garden._input(press)
	var lift := press.duplicate() as InputEventMouseButton
	lift.pressed = false
	lift.position = Vector2(700, 880)
	garden._input(lift)
	_expect(garden.is_paging(), "garden: a swipe to the right steps back")
	await create_timer(garden.PAGE_SECONDS * 2.0 + 0.2).timeout
	_expect(not garden.is_paging() and garden.shown_stage() == 1 and sign.title_text == "ROOT",
		"garden: and lands on the root")
	_expect(previous.visible and next.visible, "garden: at the root, both ways are offered")
	garden.turn_page(-1)
	await create_timer(garden.PAGE_SECONDS * 2.0 + 0.2).timeout
	_expect(garden.shown_stage() == 0 and plant.texture == garden.plant_stages[0]
		and not previous.visible and next.visible, "garden: the seed is the start of the strip")
	# Every name the sign can show has to fit its banner.
	for stage_name in garden.plant_stage_names:
		sign.title_text = stage_name
		await process_frame
		_expect(sign.text_fits(), "garden: '%s' fits the sign" % stage_name)
	garden.queue_free()
	await process_frame
	state.reset()


## Badges is locked like the other tabs until Level 1 — which earns the first
## badge — is cleared. Its grid shows every badge, the earned ones in colour and
## tappable; a tap opens the badge large with "Tap to close", and a tap closes it.
func _check_badges(state: GameStateStore) -> void:
	state.reset()
	var hub: Node = await _instantiate("res://scenes/ui/hub.tscn")
	if hub != null:
		var tab: Button = hub.get_node("%BadgesButton")
		var icon: ArtSlot = tab.get_parent().get_node("Content/Icon")
		_expect(tab.disabled, "badges tab: locked before Level 1 is cleared")
		_expect(hub.badges_icon_locked != null and icon.texture == hub.badges_icon_locked,
			"badges tab: drawn grey while locked")
		_expect(tab.pressed.get_connections().size() == 1, "badges tab: %BadgesButton is connected")
		_expect_scene(hub.badges_scene_path, "hub badges_scene_path")
		hub.queue_free()
		await process_frame

	# Levels 1 and 2 cleared: Little Planter, Plant Helper and Green Thumb.
	for stage_number in range(1, 5):
		state.record_stage_cleared(&"level_1", stage_number, 0)
	for stage_number in range(1, 6):
		state.record_stage_cleared(&"level_2", stage_number, 0)
	hub = await _instantiate("res://scenes/ui/hub.tscn")
	if hub != null:
		var tab: Button = hub.get_node("%BadgesButton")
		_expect(not tab.disabled, "badges tab: open once Level 1 is cleared")
		hub.queue_free()
		await process_frame
	var screen: BadgesScreen = await _instantiate("res://scenes/ui/badges.tscn") as BadgesScreen
	if screen == null:
		_expect(false, "badges loads")
		state.reset()
		return
	var grid: GridContainer = screen.get_node("%Grid")
	_expect(grid.columns == 3 and grid.get_child_count() == 6,
		"badges: the first six on a 3 x 2 grid (%d)" % grid.get_child_count())
	var star: Button = screen.get_node("%Badge7")
	var star_rect := star.get_global_rect()
	var first_rect := (screen.get_node("%Badge1") as Control).get_global_rect()
	_expect(star.get_parent() != grid and is_equal_approx(star_rect.get_center().x, 540.0),
		"badges: Know to Grow Star stands apart, centred (at x %d)" % star_rect.get_center().x)
	_expect(star_rect.size.x > first_rect.size.x and star_rect.position.y > grid.get_global_rect().end.y,
		"badges: and larger than the rest, under the grid")
	_expect(screen.badges.size() == 7 and screen.badges_locked.size() == 7
		and screen.badge_levels.size() == 7, "badges: seven badges, each with a grey one and a level")
	var sign: HeaderSign = screen.get_node("%HeaderSign")
	_expect(sign.title_text == "3 of 7", "badges: the sign counts 3 of 7 (is %s)" % sign.title_text)
	_expect(sign.text_fits(), "badges: the sign text fits")
	for i in screen.cell_count():
		var cell: Button = screen.get_node("%%Badge%d" % (i + 1))
		var art: ArtSlot = cell.get_node("Badge%dArt" % (i + 1))
		var earned: bool = i < 3
		_expect(cell.disabled == not earned,
			"badges: Badge%d is %s" % [i + 1, "open" if earned else "closed"])
		var want: Texture2D = screen.badges[i] if earned else screen.badges_locked[i]
		_expect(art.texture == want,
			"badges: Badge%d drawn %s" % [i + 1, "in colour" if earned else "grey"])
		_expect(cell.size.x >= 160.0 and cell.size.y >= 160.0,
			"badges: Badge%d clears 160 px (is %dx%d)" % [i + 1, cell.size.x, cell.size.y])
		_expect(cell.get_global_rect().end.y <= 1920.0, "badges: Badge%d is on screen" % (i + 1))
	var view: Control = screen.get_node("%BadgeView")
	_expect(not view.visible, "badges: no badge open at first")
	screen.open_badge(4)
	_expect(not view.visible, "badges: a badge not yet earned does not open")
	(screen.get_node("%Badge2") as Button).pressed.emit()
	var view_art: ArtSlot = screen.get_node("%BadgeViewArt")
	_expect(view.visible and view_art.texture == screen.badges[1], "badges: tapping Plant Helper opens it")
	_expect((screen.get_node("%TapToClose") as Label).text == "Tap to close", "badges: it says Tap to close")
	_expect(_find_by_name(view, "ActionButton") == null and _find_by_name(view, "BannerArt") == null,
		"badges: no Continue and no banner on it")
	screen._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(not view.visible, "badges: Android back closes the badge rather than the screen")
	screen.open_badge(0)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = false
	screen._on_view_input(tap)
	_expect(not view.visible, "badges: a tap closes it")
	screen.queue_free()
	await process_frame
	state.reset()


## The hub's plant is how a finished level shows: seed until Level 1 is cleared,
## the rooted seed after, the leafy sprout once Level 2 is too, the flower once
## Level 3 is, the fruit once Level 4 is. A level part way through must not count.
func _check_hub_grows_the_plant(state: GameStateStore) -> void:
	var plays := {
		0: ["Level 1: Grow a Seed", "res://scenes/ui/level_intro.tscn"],
		1: ["Level 2: Help Your Plant", "res://scenes/ui/level_intro_l2.tscn"],
		2: ["Level 3: Identifying", "res://scenes/ui/level_intro_l3.tscn"],
		3: ["Level 4: Functions", "res://scenes/ui/level_intro_l4.tscn"],
		# Nothing is left past Level 4; Play offers it again until the
		# finished-game screen exists.
		4: ["Level 4: Functions", "res://scenes/ui/level_intro_l4.tscn"],
	}
	# [stages cleared in Levels 1 to 4, plant stage, its name]
	for case: Array in [
		[0, 0, 0, 0, 0, "SEED"], [3, 0, 0, 0, 0, "SEED"], [4, 0, 0, 0, 1, "ROOT"],
		[4, 4, 0, 0, 1, "ROOT"], [4, 5, 0, 0, 2, "SPROUT"], [4, 5, 4, 0, 2, "SPROUT"],
		[4, 5, 5, 0, 3, "FLOWER"], [4, 5, 5, 4, 3, "FLOWER"], [4, 5, 5, 5, 4, "FRUIT"],
	]:
		var level_1: int = case[0]
		var level_2: int = case[1]
		var level_3: int = case[2]
		var level_4: int = case[3]
		var want_stage: int = case[4]
		var want_name: String = case[5]
		var cleared := "%d/%d/%d/%d of Levels 1-4 cleared" % [level_1, level_2, level_3, level_4]
		state.reset()
		for stage_number in range(1, level_1 + 1):
			state.record_stage_cleared(&"level_1", stage_number, 0)
		for stage_number in range(1, level_2 + 1):
			state.record_stage_cleared(&"level_2", stage_number, 0)
		for stage_number in range(1, level_3 + 1):
			state.record_stage_cleared(&"level_3", stage_number, 0)
		for stage_number in range(1, level_4 + 1):
			state.record_stage_cleared(&"level_4", stage_number, 0)
		var hub: Node = await _instantiate("res://scenes/ui/hub.tscn")
		if hub == null:
			continue
		var stage: int = hub.growth_stage()
		var plant: ArtSlot = hub.get_node("%Plant")
		var label: Label = hub.get_node_or_null("%PlantStageLabel") as Label
		_expect(
			stage == want_stage and plant.texture == hub.plant_stages[want_stage]
				and (label == null or label.text == want_name),
			"hub with %s shows the %s (stage %d)" % [cleared, want_name, stage]
		)
		# The play button moves on with the plant: once a level is done it names
		# the next one and leads to that level's overlay, not back into the last.
		var play: Button = hub.get_node("%PlayButton")
		var want: Array = plays[want_stage]
		_expect(
			play.text == want[0] and hub.level_scene_path() == want[1],
			"hub with %s offers \"%s\"" % [cleared, want[0]]
		)
		hub.queue_free()
		await process_frame
	state.reset()


## The finished-game card comes up by itself the first time the hub shows the
## fully grown plant, and never again on that save. Continue Playing lifts it
## off; New Game has to be held, and a hold starts again from the seed.
func _check_finished_game(state: GameStateStore) -> void:
	var audio := root.get_node_or_null("/root/AudioDirector") as AudioDirectorService
	var all_levels := [[&"level_1", 4], [&"level_2", 5], [&"level_3", 5], [&"level_4", 5]]

	# --- not before the last level is done ---
	state.reset()
	for level: Array in all_levels:
		for n in range(1, level[1] + 1):
			if not (level[0] == &"level_4" and n == 5):
				state.record_stage_cleared(level[0], n, 0)
	var hub: Node = await _instantiate("res://scenes/ui/hub.tscn")
	_expect(hub.finished_card() == null, "finished card: not up with Level 4 one stage short")
	hub.queue_free()
	await process_frame

	# --- the first time the fruit shows, it comes up by itself ---
	state.record_stage_cleared(&"level_4", 5, 0)
	hub = await _instantiate("res://scenes/ui/hub.tscn")
	var card: GameCompleteOverlay = hub.finished_card()
	_expect(card != null, "finished card: comes up by itself the first time the fruit shows")
	_expect(state.finished_shown(), "finished card: having come up is saved")
	if audio != null:
		_expect(audio.current_track() == AudioDirectorService.Track.LEVEL_5,
			"finished card: plays the level 5 track")
	if card == null:
		hub.queue_free()
		await process_frame
		return
	var continue_button: Button = card.get_node("%ContinueButton")
	var new_game: HoldButton = card.get_node("%NewGameButton")
	var credits_button: Button = card.get_node("%CreditsButton")
	var art: Control = card.get_node("%CardArt")
	_expect(art.mouse_filter == Control.MOUSE_FILTER_IGNORE, "finished card: its art ignores input")
	for button: Button in [continue_button, new_game, credits_button]:
		_expect(button.theme_type_variation == &"PrimaryButton",
			"finished card: %s is on the primary plate" % button.name)
		_expect(button.size.x >= 160.0 and button.size.y >= 160.0,
			"finished card: %s clears 160 px (is %dx%d)" % [button.name, button.size.x, button.size.y])
		_expect(button.position.y >= art.position.y + art.size.y,
			"finished card: %s sits below the card" % button.name)
	_expect(new_game.require_hold, "finished card: New Game has to be held")
	_expect(credits_button.position.y > new_game.position.y + new_game.size.y,
		"finished card: Credits is below New Game")
	_expect(credits_button.get_global_rect().end.y <= card.get_viewport_rect().size.y,
		"finished card: Credits is on screen")

	# --- Credits rolls up the screen, and a tap ends it early ---
	var credits: CreditsOverlay = card.get_node("%Credits")
	_expect(not credits.is_open(), "credits: starts closed")
	credits_button.pressed.emit()
	_expect(credits.is_open(), "credits: the button opens it")
	var credit_lines: Control = credits.get_node("%Lines")
	var all_text := ""
	for line in credit_lines.get_children():
		if line is Label:
			all_text += (line as Label).text + "
"
	for name_needed: String in ["ChatGPT", "LudoLoon Studio", "Towball", "CC BY 4.0", "Fredoka One", "Godot"]:
		_expect(all_text.contains(name_needed), "credits: names %s" % name_needed)
	for i in 3:
		await process_frame
	var first_y := credit_lines.position.y
	for i in 10:
		await process_frame
	_expect(credit_lines.position.y < first_y,
		"credits: the text rolls upwards (%d -> %d)" % [first_y, credit_lines.position.y])
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	(credits.get_node("%Dim") as ColorRect).gui_input.emit(release)
	_expect(not credits.is_open(), "credits: a tap ends them early")
	_expect(hub.finished_card() == card, "credits: closing them leaves the finished card up")

	# --- Continue Playing lifts it off and the hub's music comes back ---
	continue_button.pressed.emit()
	await process_frame
	_expect(hub.finished_card() == null, "finished card: Continue Playing closes it")
	if audio != null:
		_expect(audio.current_track() == AudioDirectorService.Track.MENU,
			"finished card: the hub's own track comes back")
	_expect(state.total_stars() > 0, "finished card: Continue Playing keeps the progress")
	hub.queue_free()
	await process_frame

	# --- and it does not come back ---
	hub = await _instantiate("res://scenes/ui/hub.tscn")
	_expect(hub.finished_card() == null, "finished card: does not come back on the next visit")
	hub.queue_free()
	await process_frame

	# --- New Game: a tap does nothing, a hold starts again ---
	state.reset()
	for level: Array in all_levels:
		for n in range(1, level[1] + 1):
			state.record_stage_cleared(level[0], n, 0)
	hub = await _instantiate("res://scenes/ui/hub.tscn")
	card = hub.finished_card()
	new_game = card.get_node("%NewGameButton")
	var cancelled := [false]
	new_game.hold_cancelled.connect(func() -> void: cancelled[0] = true)
	new_game.button_down.emit()
	await process_frame
	new_game.button_up.emit()
	new_game.pressed.emit()
	await process_frame
	_expect(cancelled[0], "finished card: letting go of New Game early cancels the hold")
	_expect(state.total_stars() > 0 and hub.finished_card() != null,
		"finished card: a tap on New Game wipes nothing")
	new_game.button_down.emit()
	await process_frame
	_expect(new_game.get_node("HoldFill").visible or new_game.progress() > 0.0,
		"finished card: holding shows its progress")
	await create_timer(new_game.hold_seconds + 0.3).timeout
	_expect(state.total_stars() == 0 and not state.finished_shown(),
		"finished card: a full hold on New Game wipes progress")
	await process_frame
	_expect(hub.finished_card() == null and hub.growth_stage() == 0,
		"finished card: after New Game the hub is back to the seed")
	_expect((hub.get_node("%PlayButton") as Button).text == "Level 1: Grow a Seed",
		"finished card: and Play offers Level 1 again")
	hub.queue_free()
	await process_frame
	state.reset()


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
