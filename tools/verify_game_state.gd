extends SceneTree

## Headless check for [GameState] — the star rule, unlocking, and that progress
## survives a reload:
##
##   godot --headless --path . -s res://tools/verify_game_state.gd
##
## **This writes to user://progress.cfg**, so running it wipes whatever progress
## is on the machine. It resets to empty on the way out rather than leaving a
## test score behind.
##
## The rules being checked are decisions, not implementation details: three
## stars first try, two on the second, one after that; a stage opens when the
## one before it is done; and a replay can raise a score but never lower it.

var _failures := 0

## The autoload, fetched rather than named. A script run with -s is compiled
## before the autoload list is registered, so the global identifier does not
## resolve here even though it does everywhere else in the game.
var _state: GameStateStore = null


func _initialize() -> void:
	await process_frame
	_state = root.get_node_or_null("/root/GameState") as GameStateStore
	if _state == null:
		print("FAIL — GameState is not autoloaded; check project.godot")
		quit(1)
		return
	_state.reset()

	# --- the star rule ---
	for wrong in [0, 1, 2, 3, 7]:
		_state.reset()
		_state.record_stage_cleared(&"level_1", 1, wrong)
		var expected := maxi(1, 3 - wrong)
		_expect(
			_state.stars_for(&"level_1", 1) == expected,
			"%d wrong answer(s) earns %d star(s) (got %d)"
				% [wrong, expected, _state.stars_for(&"level_1", 1)]
		)

	# --- a replay never costs anything ---
	_state.reset()
	_state.record_stage_cleared(&"level_1", 1, 0)
	_state.record_stage_cleared(&"level_1", 1, 5)
	_expect(_state.stars_for(&"level_1", 1) == 3, "a worse replay does not lower the score")
	_state.record_stage_cleared(&"level_1", 2, 2)
	_state.record_stage_cleared(&"level_1", 2, 0)
	_expect(_state.stars_for(&"level_1", 2) == 3, "a better replay raises it")

	# --- unlocking ---
	_state.reset()
	_expect(_state.is_stage_unlocked(&"level_1", 1), "stage 1 is open on a fresh start")
	_expect(not _state.is_stage_unlocked(&"level_1", 2), "stage 2 is closed until stage 1 is done")
	_expect(not _state.is_stage_cleared(&"level_1", 1), "nothing is cleared on a fresh start")
	_expect(_state.total_stars() == 0, "a fresh start has no stars")

	_state.record_stage_cleared(&"level_1", 1, 0)
	_expect(_state.is_stage_unlocked(&"level_1", 2), "stage 2 opens once stage 1 is done")
	_expect(not _state.is_stage_unlocked(&"level_1", 3), "stage 3 stays closed")
	_expect(_state.stages_cleared(&"level_1") == 1, "one stage cleared")
	_expect(not _state.is_level_cleared(&"level_1", 4), "the level is not done after one stage")

	# A stage finished out of order must not unlock the whole level.
	_state.record_stage_cleared(&"level_1", 4, 0)
	_expect(
		_state.stages_cleared(&"level_1") == 1,
		"clearing stage 4 early does not count stages 2 and 3 (got %d)"
			% _state.stages_cleared(&"level_1")
	)
	_expect(not _state.is_stage_unlocked(&"level_1", 3), "stage 3 is still closed")

	# --- a finished level ---
	_state.reset()
	for stage in [1, 2, 3, 4]:
		_state.record_stage_cleared(&"level_1", stage, 0)
	_expect(_state.is_level_cleared(&"level_1", 4), "four of four is a finished level")
	_expect(_state.total_stars() == 12, "four stages at three stars is 12 (got %d)" % _state.total_stars())

	# --- it survives a reload ---
	_state.record_stage_cleared(&"level_2", 1, 1)
	_state.load_progress()
	_expect(_state.stars_for(&"level_1", 3) == 3, "level 1 stage 3 survives a reload")
	_expect(_state.stars_for(&"level_2", 1) == 2, "level 2 stage 1 survives with its 2 stars")
	_expect(_state.total_stars() == 14, "the total survives (got %d)" % _state.total_stars())

	# --- nonsense is refused rather than filed ---
	_state.reset()
	_state.record_stage_cleared(&"", 1, 0)
	_state.record_stage_cleared(&"level_1", 0, 0)
	_expect(_state.total_stars() == 0, "a stage with no level or no number is not recorded")

	_state.reset()
	print("\n%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(1 if _failures > 0 else 0)


func _expect(condition: bool, what: String) -> void:
	if condition:
		print("  ok    %s" % what)
	else:
		_failures += 1
		print("  FAIL  %s" % what)
