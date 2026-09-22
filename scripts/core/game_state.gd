class_name GameStateStore
extends Node

## What the child has finished, and how well. Autoloaded as `GameState`.
##
## The class name and the autoload name differ on purpose. `GameState` as a bare
## identifier resolves when the game runs, but **not inside a `godot -s` tool
## script**, which is compiled before the autoload list is registered — and those
## tool scripts are how everything here is verified. Any script that reaches for
## progress does it through [member SubScreen.progress], which fetches the node
## and is typed by this class, so it compiles in both.
##
## This is the only thing in the game that survives closing it. It holds one
## number per stage — the stars earned, 1 to 3, with 0 meaning never finished —
## and everything else is derived from that: whether a stage is unlocked,
## whether a level is done, how many stars the hub shows.
##
## **Stars come from attempts**, decided by the project owner: three for getting
## it right first try, two on the second, one after that. Worth knowing that the
## design document says Level 1 has no penalties and no "Wrong" label, and a
## grade that falls with attempts sits in some tension with that. It is recorded
## in checklist.md §4 so whoever owns the teaching content sees it.
##
## **Stars are never taken away.** Replaying a stage can raise the score and
## never lowers it, so going back to an early stage cannot cost anything.
##
## Saving is deliberately dull: a ConfigFile in user://, which is plain text and
## can be read or deleted by hand while the game is being built. There is no
## account, nothing leaves the device, and a corrupt or missing file is treated
## as a fresh start rather than an error.

## Emitted whenever anything here changes, so a screen showing progress can
## redraw without polling.
signal progress_changed

const SAVE_PATH := "user://progress.cfg"
const SAVE_SECTION := "stars"
const FLAGS_SECTION := "flags"
const MAX_STARS := 3

## Stars per stage, keyed by [method _key]. Absent means never finished.
var _stars: Dictionary[String, int] = {}

## Whether the finished-game screen has already come up. It appears by itself
## the first time the hub shows the fully grown plant, and only that once, so
## the fact has to outlive closing the game. See [method mark_finished_shown].
var _finished_shown := false

## The plant stage the hub last finished showing. When progress is ahead of it,
## the hub grows the plant in rather than just drawing it grown, then records
## the new stage here. See [method mark_plant_stage_shown].
var _plant_stage_shown := 0


func _ready() -> void:
	load_progress()


## Records a finished stage. [param wrong_attempts] is how many wrong answers
## were tried before the right one, so 0 means first time.
func record_stage_cleared(
	level_id: StringName, stage_number: int, wrong_attempts: int
) -> void:
	if level_id.is_empty() or stage_number < 1:
		push_warning("GameState: refusing to record '%s' stage %d" % [level_id, stage_number])
		return
	var earned := clampi(MAX_STARS - wrong_attempts, 1, MAX_STARS)
	var key := _key(level_id, stage_number)
	# Never downgrade: a replay can only improve on what is already there.
	if earned <= _stars.get(key, 0):
		return
	_stars[key] = earned
	save_progress()
	progress_changed.emit()


## Stars earned for one stage, or 0 if it has never been finished.
func stars_for(level_id: StringName, stage_number: int) -> int:
	return _stars.get(_key(level_id, stage_number), 0)


func is_stage_cleared(level_id: StringName, stage_number: int) -> bool:
	return stars_for(level_id, stage_number) > 0


## A stage is open once the one before it is done. The first always is, so a
## level can always be started.
func is_stage_unlocked(level_id: StringName, stage_number: int) -> bool:
	if stage_number <= 1:
		return true
	return is_stage_cleared(level_id, stage_number - 1)


## How many stages of a level are finished, counted from the first. Stops at the
## first gap, so this is "how far they have got", not a total.
func stages_cleared(level_id: StringName) -> int:
	var count := 0
	while is_stage_cleared(level_id, count + 1):
		count += 1
	return count


func is_level_cleared(level_id: StringName, stage_count: int) -> bool:
	return stage_count > 0 and stages_cleared(level_id) >= stage_count


## How many of [param levels] are cleared, counting from the first and stopping
## at the first that is not — so a level cleared out of order does not count.
## This is how far the plant has grown: the hub shows it, the Garden pages up to
## it.
func levels_cleared_in_order(levels: Array[LevelData]) -> int:
	var count := 0
	for level in levels:
		if level == null or not is_level_cleared(level.id, level.challenges.size()):
			break
		count += 1
	return count


## Every star earned anywhere, which is what the hub counts.
func total_stars() -> int:
	var sum := 0
	for value in _stars.values():
		sum += value
	return sum


## Whether there is a save worth continuing, and worth guarding: any stage
## cleared at all. The main menu shows Continue, and makes New Game a hold, on
## this.
func has_progress() -> bool:
	return not _stars.is_empty()


## True once the finished-game screen has been shown on this save.
func finished_shown() -> bool:
	return _finished_shown


## Records that the finished-game screen has come up, so the hub does not bring
## it back on every visit. A New Game clears it along with everything else.
func mark_finished_shown() -> void:
	if _finished_shown:
		return
	_finished_shown = true
	save_progress()
	progress_changed.emit()


## The plant stage the hub has already grown in on screen. 0 is the seed.
func plant_stage_shown() -> int:
	return _plant_stage_shown


## Records that the hub has shown the plant growing into [param stage], so the
## next visit draws it grown without growing it again.
func mark_plant_stage_shown(stage: int) -> void:
	if stage == _plant_stage_shown:
		return
	_plant_stage_shown = maxi(stage, 0)
	save_progress()
	progress_changed.emit()


## Wipes progress. For a "start over" control, and for tests that need a known
## state — call it before asserting anything about stars.
func reset() -> void:
	_stars.clear()
	_finished_shown = false
	_plant_stage_shown = 0
	save_progress()
	progress_changed.emit()


func save_progress() -> void:
	var file := ConfigFile.new()
	for key in _stars:
		file.set_value(SAVE_SECTION, key, _stars[key])
	if _finished_shown:
		file.set_value(FLAGS_SECTION, "finished_shown", true)
	if _plant_stage_shown > 0:
		file.set_value(FLAGS_SECTION, "plant_stage_shown", _plant_stage_shown)
	var error := file.save(SAVE_PATH)
	if error != OK:
		push_warning("GameState: could not save to %s (error %d)" % [SAVE_PATH, error])


func load_progress() -> void:
	_stars.clear()
	_finished_shown = false
	_plant_stage_shown = 0
	var file := ConfigFile.new()
	# A missing file is the normal first run, not a problem worth reporting. So
	# is a file with no stars in it, which is what reset() leaves behind.
	if file.load(SAVE_PATH) != OK:
		return
	_finished_shown = file.get_value(FLAGS_SECTION, "finished_shown", false) == true
	var shown: Variant = file.get_value(FLAGS_SECTION, "plant_stage_shown", 0)
	_plant_stage_shown = maxi(shown, 0) if shown is int else 0
	if not file.has_section(SAVE_SECTION):
		return
	for key in file.get_section_keys(SAVE_SECTION):
		var value: Variant = file.get_value(SAVE_SECTION, key, 0)
		if value is int and value > 0:
			_stars[key] = clampi(value, 1, MAX_STARS)
	progress_changed.emit()


func _key(level_id: StringName, stage_number: int) -> String:
	return "%s/%d" % [level_id, stage_number]
