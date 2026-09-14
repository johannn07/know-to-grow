extends Node

## Autoload. Project > Project Settings > Globals > Autoload, name it "GameState".
## Holds run-time progress for the current level and persists level completion.
##
## Deliberately has no idea what a plant is. Keep it that way: content lives in
## .tres files, presentation lives in scenes, bookkeeping lives here.

signal score_changed(score: int, total: int)
signal challenge_changed(challenge: ChallengeData, index: int, total: int)
signal level_completed(level_id: StringName, score: int, total: int)

const SAVE_PATH := "user://know_to_grow.cfg"

var current_level: LevelData = null
var current_index: int = 0
var score: int = 0

## Per-challenge mistake counts. Never shown to the learner - this is for you,
## so you can see which stages confuse children during playtesting.
var misses: Dictionary = {}

var _completed: Dictionary = {}


func _ready() -> void:
	load_progress()


func start_level(level: LevelData) -> void:
	current_level = level
	current_index = 0
	score = 0
	misses.clear()
	if level.shuffle_challenges:
		current_level = level.duplicate(true)
		current_level.challenges.shuffle()
	score_changed.emit(score, total_challenges())
	challenge_changed.emit(current_challenge(), current_index, total_challenges())


func total_challenges() -> int:
	return current_level.challenges.size() if current_level else 0


func current_challenge() -> ChallengeData:
	if current_level == null or current_index >= current_level.challenges.size():
		return null
	return current_level.challenges[current_index]


func register_correct() -> void:
	score += 1
	score_changed.emit(score, total_challenges())


func register_miss(option_id: StringName) -> void:
	var challenge := current_challenge()
	if challenge == null:
		return
	var key := "%s/%s" % [challenge.id, option_id]
	misses[key] = int(misses.get(key, 0)) + 1
	# No score penalty, no lives, no timer. This is by design.


## Returns false when the level is over.
func advance() -> bool:
	current_index += 1
	if current_index >= total_challenges():
		mark_completed(current_level.id)
		level_completed.emit(current_level.id, score, total_challenges())
		return false
	challenge_changed.emit(current_challenge(), current_index, total_challenges())
	return true


func mark_completed(level_id: StringName) -> void:
	_completed[String(level_id)] = true
	save_progress()


func is_completed(level_id: StringName) -> bool:
	return _completed.get(String(level_id), false)


func save_progress() -> void:
	var cfg := ConfigFile.new()
	for key in _completed:
		cfg.set_value("completed", key, true)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save progress: %s" % err)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	_completed.clear()
	if cfg.has_section("completed"):
		for key in cfg.get_section_keys("completed"):
			_completed[key] = true
