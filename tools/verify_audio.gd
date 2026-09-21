extends SceneTree

## Headless check that every screen knows what it sounds like, and that the
## music survives a scene change:
##
##   godot --headless --path . -s res://tools/verify_audio.gd
##
## Headless has no audio device, so this cannot hear anything. What it can check
## is the wiring, which is where the mistakes are: a screen with no track set, a
## stream that was never assigned in the director, an effect pointed at the
## wrong bus, and — the one that matters most — music restarting every time the
## scene changes, which is what an autoload exists to prevent.

const MENU_SCREENS: Array[String] = [
	"res://scenes/ui/hub.tscn",
	"res://scenes/ui/how_to_play.tscn",
	"res://scenes/ui/level_select_stub.tscn",
]
const LEVEL_2_SCREENS: Array[String] = [
	"res://scenes/ui/level_intro_l2.tscn",
	"res://scenes/ui/stage_select_l2.tscn",
	"res://scenes/levels/level_2/stage_1.tscn",
	"res://scenes/levels/level_2/stage_2.tscn",
	"res://scenes/levels/level_2/stage_3.tscn",
	"res://scenes/levels/level_2/stage_4.tscn",
	"res://scenes/levels/level_2/stage_5.tscn",
	"res://scenes/ui/level_complete_l2.tscn",
	"res://scenes/ui/badge_unlocked_l2.tscn",
	"res://scenes/ui/badge_unlocked_l2_green_thumb.tscn",
	"res://scenes/ui/level_complete_sign_l2.tscn",
]
const LEVEL_3_SCREENS: Array[String] = [
	"res://scenes/ui/level_intro_l3.tscn",
	"res://scenes/ui/stage_select_l3.tscn",
	"res://scenes/levels/level_3/stage_1.tscn",
	"res://scenes/levels/level_3/stage_2.tscn",
	"res://scenes/levels/level_3/stage_3.tscn",
	"res://scenes/levels/level_3/stage_4.tscn",
	"res://scenes/levels/level_3/stage_5.tscn",
	"res://scenes/ui/level_complete_l3.tscn",
	"res://scenes/ui/badge_unlocked_l3.tscn",
	"res://scenes/ui/level_complete_sign_l3.tscn",
]
const LEVEL_4_SCREENS: Array[String] = [
	"res://scenes/ui/level_intro_l4.tscn",
	"res://scenes/ui/stage_select_l4.tscn",
	"res://scenes/levels/level_4/stage_1.tscn",
	"res://scenes/levels/level_4/stage_2.tscn",
	"res://scenes/levels/level_4/stage_3.tscn",
	"res://scenes/levels/level_4/stage_4.tscn",
	"res://scenes/levels/level_4/stage_5.tscn",
	"res://scenes/ui/level_complete_l4.tscn",
	"res://scenes/ui/badge_unlocked_l4.tscn",
	"res://scenes/ui/badge_unlocked_l4_super_grower.tscn",
	"res://scenes/ui/badge_unlocked_l4_know_to_grow_star.tscn",
	"res://scenes/ui/level_complete_sign_l4.tscn",
]

const LEVEL_SCREENS: Array[String] = [
	"res://scenes/ui/level_intro.tscn",
	"res://scenes/ui/stage_select.tscn",
	"res://scenes/ui/level_complete.tscn",
	"res://scenes/ui/badge_unlocked.tscn",
	"res://scenes/ui/level_complete_sign.tscn",
	"res://scenes/levels/level_1/stage_1.tscn",
	"res://scenes/levels/level_1/stage_2.tscn",
	"res://scenes/levels/level_1/stage_3.tscn",
	"res://scenes/levels/level_1/stage_4.tscn",
]

var _failures := 0
var _audio: AudioDirectorService = null


func _initialize() -> void:
	await process_frame
	# Playing a stage below records real progress, so start from nothing and
	# clear up afterwards, as the other tools do.
	var state: GameStateStore = root.get_node_or_null("/root/GameState") as GameStateStore
	if state != null:
		state.reset()
	_audio = root.get_node_or_null("/root/AudioDirector") as AudioDirectorService
	if _audio == null:
		print("FAIL — AudioDirector is not autoloaded; check project.godot")
		quit(1)
		return

	# --- every stream the director promises actually exists ---
	for track in [AudioDirectorService.Track.MENU, AudioDirectorService.Track.LEVEL_1,
			AudioDirectorService.Track.LEVEL_2, AudioDirectorService.Track.LEVEL_3,
			AudioDirectorService.Track.LEVEL_4]:
		_expect(_audio.music_for(track) != null, "track %d has a stream" % track)
	for named in [["tap", _audio.tap], ["correct", _audio.correct_answer],
			["wrong", _audio.wrong_answer]]:
		_expect(named[1] != null, "%s effect has a stream" % named[0])

	# --- scenes store a track as its number, so the numbers must never move ---
	_expect(
		AudioDirectorService.Track.MENU == 1
			and AudioDirectorService.Track.LEVEL_1 == 2
			and AudioDirectorService.Track.LEVEL_2 == 3
			and AudioDirectorService.Track.LEVEL_3 == 4
			and AudioDirectorService.Track.LEVEL_4 == 5,
		"tracks keep the numbers the scenes stored (a new one goes at the end)"
	)

	# --- music loops, or a screen falls silent after one play ---
	for track in [AudioDirectorService.Track.MENU, AudioDirectorService.Track.LEVEL_1,
			AudioDirectorService.Track.LEVEL_2, AudioDirectorService.Track.LEVEL_3,
			AudioDirectorService.Track.LEVEL_4]:
		var stream := _audio.music_for(track)
		if stream is AudioStreamMP3:
			_expect((stream as AudioStreamMP3).loop, "track %d loops" % track)

	# --- effects go to SFX, music to Music ---
	var music_player: AudioStreamPlayer = _audio.get_node("Music")
	_expect(music_player.bus == &"Music", "music plays on the Music bus")
	var voices := 0
	for child in _audio.get_node("Sfx").get_children():
		if child is AudioStreamPlayer:
			voices += 1
			_expect((child as AudioStreamPlayer).bus == &"SFX",
				"%s plays on the SFX bus" % child.name)
	_expect(voices == AudioDirectorService.SFX_VOICES,
		"there are %d SFX voices, so effects can overlap (found %d)"
			% [AudioDirectorService.SFX_VOICES, voices])

	# --- every screen names a track ---
	for path in MENU_SCREENS:
		await _expect_track(path, AudioDirectorService.Track.MENU, "menu")
	for path in LEVEL_SCREENS:
		await _expect_track(path, AudioDirectorService.Track.LEVEL_1, "level 1")
	for path in LEVEL_2_SCREENS:
		await _expect_track(path, AudioDirectorService.Track.LEVEL_2, "level 2")
	for path in LEVEL_3_SCREENS:
		await _expect_track(path, AudioDirectorService.Track.LEVEL_3, "level 3")
	for path in LEVEL_4_SCREENS:
		await _expect_track(path, AudioDirectorService.Track.LEVEL_4, "level 4")

	# --- and the music does not restart between them ---
	_audio.stop_music()
	var screen: Node = await _spawn("res://scenes/ui/level_intro.tscn")
	_expect(
		_audio.current_track() == AudioDirectorService.Track.LEVEL_1,
		"entering a level starts the level track"
	)
	var playing_since := (_audio.get_node("Music") as AudioStreamPlayer).get_playback_position()
	screen.queue_free()
	await process_frame
	var next: Node = await _spawn("res://scenes/levels/level_1/stage_1.tscn")
	_expect(
		(_audio.get_node("Music") as AudioStreamPlayer).get_playback_position() >= playing_since,
		"walking on to the next screen does not restart the track"
	)
	next.queue_free()
	await process_frame

	# --- the effects reach their dedicated uses ---
	# Headless has no audio device, so this asks what each voice was handed
	# rather than what came out of it.
	var stage: StageScreen = await _spawn("res://scenes/levels/level_1/stage_1.tscn") as StageScreen
	if stage != null:
		var centre := stage._drop_zone.get_global_rect().get_center()
		var wrong: OptionCard = null
		var right: OptionCard = null
		for card in stage.cards():
			if stage.is_correct(card.option_id):
				right = card
			elif wrong == null:
				wrong = card

		_silence_voices()
		stage._on_card_dropped(wrong, centre)
		await process_frame
		_expect(_a_voice_holds(_audio.wrong_answer), "a wrong answer plays the wrong sting")

		_silence_voices()
		stage._on_card_dropped(right, centre)
		await process_frame
		_expect(_a_voice_holds(_audio.correct_answer), "a right answer plays the correct sting")

		_silence_voices()
		var overlay_button: ArtButton = stage.get_node("%OverlayButton")
		overlay_button.button_down.emit()
		await process_frame
		_expect(_a_voice_holds(_audio.tap), "a button press plays the tap")
		stage.queue_free()
		await process_frame

	_silence_voices()
	var complete: CardOverlay = await _spawn("res://scenes/ui/level_complete.tscn") as CardOverlay
	if complete != null:
		_expect(complete.arrival_sfx != null, "level complete has an arrival sting")
		_expect(_a_voice_holds(complete.arrival_sfx), "and plays it on arrival")
		complete.queue_free()
		await process_frame

	_audio.stop_music()
	if state != null:
		state.reset()
	print("\n%s — %d failure(s)" % ["FAIL" if _failures > 0 else "PASS", _failures])
	quit(1 if _failures > 0 else 0)


## Clears every voice, so the next assertion is about what just happened rather
## than what was left over from the last one.
func _silence_voices() -> void:
	for child in _audio.get_node("Sfx").get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
			(child as AudioStreamPlayer).stream = null


func _a_voice_holds(stream: AudioStream) -> bool:
	if stream == null:
		return false
	for child in _audio.get_node("Sfx").get_children():
		if child is AudioStreamPlayer and (child as AudioStreamPlayer).stream == stream:
			return true
	return false


func _expect_track(path: String, want: AudioDirectorService.Track, label: String) -> void:
	var screen: Node = await _spawn(path)
	if screen == null:
		_expect(false, "%s loads" % path.get_file())
		return
	_expect(
		screen.music_track == want,
		"%s asks for the %s track" % [path.get_file(), label]
	)
	screen.queue_free()
	await process_frame


func _spawn(path: String) -> Node:
	var packed: PackedScene = load(path)
	if packed == null:
		return null
	var node := packed.instantiate()
	root.add_child(node)
	root.get_viewport().size = Vector2i(1080, 1920)
	node.set_deferred("size", Vector2(1080, 1920))
	await process_frame
	await process_frame
	return node


func _expect(condition: bool, what: String) -> void:
	if condition:
		print("  ok    %s" % what)
	else:
		_failures += 1
		print("  FAIL  %s" % what)
