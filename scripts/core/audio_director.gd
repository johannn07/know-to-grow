class_name AudioDirectorService
extends Node

## Everything the game plays. Autoloaded as `AudioDirector`.
##
## It exists mainly so that **music does not restart when the scene changes**.
## A player inside a screen dies with that screen, so walking hub → level
## overlay → stage select would start the same track three times. This lives
## above the scene, and asking for a track that is already playing does nothing.
##
## Streams are set in `scenes/core/audio_director.tscn` rather than loaded by
## path here, so what plays where is visible in the Inspector — the same reason
## art is assigned to an [ArtSlot] instead of hardcoded.
##
## The class name and the autoload name differ on purpose: see [GameStateStore]
## for why a bare `AudioDirector` cannot be written inside a `godot -s` script.

## Which music a screen wants. Screens name a track rather than carrying a
## stream, so there is one place that decides what each one sounds like.
##
## **Add new tracks at the end.** A screen's scene stores its track as this
## number, so inserting one in the middle would silently move every screen
## after it onto a different track.
enum Track {
	NONE, ## Silence. Also means "leave whatever is playing alone".
	MENU, ## Title, How To Play, hub — everything outside a level.
	LEVEL_1,
	LEVEL_2,
	LEVEL_3,
	LEVEL_4,
	LEVEL_5, ## The finished-game screen alone.
}

## How many effects can overlap before the oldest is cut off. A tap landing on
## top of a correct answer is normal, so one player is not enough.
const SFX_VOICES := 4

## Where a spoken line lives, named by the `*_vo_key` in content/*.tres:
## `res://assets/audio/vo/en/<key>.ogg`. This is the one place in the game that
## builds a path out of a name rather than taking a resource set in a scene. The
## music and the stings are a handful of files a screen chooses between, so they
## are exported and visible in the Inspector; the voice-over is one file per
## reviewed line, and exporting two dozen of them by hand would only be a longer
## way of writing this convention down. `SCRIPT.md`, which the recordings are
## made from, states the same path.
const VO_DIR := "res://assets/audio/vo/en/"
const VO_EXT := ".ogg"

## The two "if needed" praise lines, played in turn on a correct answer so the
## same one is not heard twice running.
const PRAISE_KEYS: Array[StringName] = [&"praise_great_job", &"praise_amazing"]

## How far the music drops while something is being said or played over it. The
## music is written to sit under a child's attention, not under a voice, and at
## full volume it covers both the spoken lines and the level-complete fanfare.
const DUCK_DB := -12.0
## Quick down so the first word is not lost, slow back up so the return is not
## a noticeable swell.
const DUCK_IN := 0.15
const DUCK_OUT := 0.7

## The child's sound choices, kept apart from `user://progress.cfg` on purpose:
## New Game wipes progress, and it should not also turn the music back on.
const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "sound"

## Fires when music or effects are switched on or off, so every on-screen
## toggle can redraw itself, not only the one that was pressed.
signal sound_changed

@export_group("Music")
@export var menu_music: AudioStream
@export var level_1_music: AudioStream
@export var level_2_music: AudioStream
@export var level_3_music: AudioStream
@export var level_4_music: AudioStream
@export var level_5_music: AudioStream

@export_group("Effects")
## Any button, anywhere. Connected for a whole screen by [SubScreen].
@export var tap: AudioStream
@export var correct_answer: AudioStream
@export var wrong_answer: AudioStream

var _current := Track.NONE
var _next_voice := 0
var _next_praise := 0
var _music_on := true
var _sfx_on := true
var _vo_on := true

## How many things are talking over the music. The music comes back up when the
## last of them finishes, so a fanfare and a spoken line that overlap do not
## uncover the music between them.
var _ducks := 0
## True while the line being spoken is the thing holding the music down, so that
## replacing one line with another does not stack a second hold.
var _vo_ducking := false
var _duck_tween: Tween = null

@onready var _music: AudioStreamPlayer = $Music
@onready var _vo: AudioStreamPlayer = $Vo
@onready var _voices: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for child in $Sfx.get_children():
		if child is AudioStreamPlayer:
			_voices.append(child)
	if _voices.is_empty():
		push_warning("AudioDirector: no SFX players in the scene, so effects are silent")
	_vo.finished.connect(_on_vo_finished)
	_load_settings()


## Starts a track, or does nothing if it is already the one playing. This is
## what keeps the music running across a scene change.
func play_music(track: Track) -> void:
	if track == Track.NONE or track == _current:
		return
	var stream := music_for(track)
	if stream == null:
		push_warning("AudioDirector: no stream assigned for track %d" % track)
		return
	_current = track
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_current = Track.NONE
	_music.stop()


func _exit_tree() -> void:
	# Tidy on the way out. Note this does **not** silence the "1 resources still
	# in use at exit" line that appears once music has played: that is the audio
	# server's own playback object outliving the tree, and stopping the players,
	# clearing their streams and nulling the exports here all leave it. It is a
	# shutdown-order quirk, not a real leak — the same run with music never
	# started exits clean. Flagged in CLAUDE.md so it is not mistaken for one.
	stop_music()
	_music.stream = null
	_vo.stop()
	_vo.stream = null
	for voice in _voices:
		voice.stop()
		voice.stream = null


func music_for(track: Track) -> AudioStream:
	match track:
		Track.MENU: return menu_music
		Track.LEVEL_1: return level_1_music
		Track.LEVEL_2: return level_2_music
		Track.LEVEL_3: return level_3_music
		Track.LEVEL_4: return level_4_music
		Track.LEVEL_5: return level_5_music
	return null


## The track playing now, so a screen can check rather than assume.
func current_track() -> Track:
	return _current


## Plays an effect on the next free voice, round-robin, so effects that land on
## top of each other both get heard.
##
## [param over_music] holds the music down for as long as the effect lasts. It is
## for the two that are the moment rather than a detail of it — the level-complete
## fanfare and the plant growing in — not for taps and answer stings, which are
## meant to sit inside the music.
func play_sfx(stream: AudioStream, over_music: bool = false) -> void:
	if stream == null or _voices.is_empty():
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.play()
	if over_music:
		_duck_for(stream.get_length())


## Holds the music down for [param seconds], for something that has no "finished"
## to wait on — an effect on a shared voice, which the next effect may cut off.
func _duck_for(seconds: float) -> void:
	if seconds <= 0.0:
		return
	duck_music()
	# Always, so a card that pauses the tree behind it still lets the music up.
	var timer := get_tree().create_timer(seconds, true, false, true)
	timer.timeout.connect(release_music)


## Speaks the line filed under [param key] — a `*_vo_key` from content/*.tres.
##
## One line at a time: a new one cuts the last off, because a prompt arriving
## while the previous stage's prompt is still talking means the child has moved
## on. A key with no recording is a mistake rather than a silence, so it says so;
## lines that were never recorded are simply never asked for.
func play_vo(key: StringName) -> void:
	if key == &"":
		return
	var path := VO_DIR + String(key) + VO_EXT
	if not ResourceLoader.exists(path):
		push_warning("AudioDirector: no recording for '%s' (looked for %s)" % [key, path])
		return
	# Replacing a line keeps the hold it already has, rather than stacking a
	# second one — stop() does not report itself finished.
	_vo.stop()
	_vo.stream = load(path) as AudioStream
	_vo.play()
	if not _vo_ducking:
		_vo_ducking = true
		duck_music()


## One of the two praise lines, on a correct answer. They alternate rather than
## being picked at random so a child cannot hear the same one three times over.
func play_praise() -> void:
	play_vo(PRAISE_KEYS[_next_praise])
	_next_praise = (_next_praise + 1) % PRAISE_KEYS.size()


## Stops the line being spoken and lets the music back up. Called by a screen as
## it leaves, so a line started on one screen does not carry into the next.
func stop_vo() -> void:
	_vo.stop()
	_on_vo_finished()


func _on_vo_finished() -> void:
	if not _vo_ducking:
		return
	_vo_ducking = false
	release_music()


## Holds the music down until the matching [method release_music]. Nestable: two
## holds need two releases, so whichever finishes second is the one that brings
## the music back.
func duck_music() -> void:
	_ducks += 1
	if _ducks == 1:
		_tween_music_volume(DUCK_DB, DUCK_IN)


func release_music() -> void:
	_ducks = maxi(0, _ducks - 1)
	if _ducks == 0:
		_tween_music_volume(0.0, DUCK_OUT)


## Whether the music is being held down right now. For the smoke tests, which
## cannot hear it.
func is_music_ducked() -> bool:
	return _ducks > 0


func _tween_music_volume(to_db: float, seconds: float) -> void:
	if _duck_tween != null:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_music, "volume_db", to_db, seconds)


## Whether a line is being spoken now. What ducks the music under it.
func is_vo_playing() -> bool:
	return _vo.playing


func play_tap() -> void:
	play_sfx(tap)


## [param over_music] for the plant growing in on the hub, which borrows this
## sting and is the whole screen for a moment.
func play_correct(over_music: bool = false) -> void:
	play_sfx(correct_answer, over_music)


func play_wrong() -> void:
	play_sfx(wrong_answer)


## Whether music is heard. Switching it off mutes the Music bus rather than
## stopping the player, so switching it back on picks the loop up mid-phrase
## instead of starting it again.
func is_music_on() -> bool:
	return _music_on


## Whether effects are heard: taps and the answer stings. Voice-over has its own
## bus and its own switch, so turning the stings off never takes the prompt away
## with them.
func is_sfx_on() -> bool:
	return _sfx_on


## Whether the spoken lines are heard. Off mutes the VO bus, which is separate
## from music and effects on purpose: a child who can read may not want the voice,
## and a child who cannot read needs it whatever else is switched off.
func is_vo_on() -> bool:
	return _vo_on


func set_music_on(on: bool) -> void:
	_music_on = on
	_apply_mutes()
	_save_settings()
	sound_changed.emit()


func set_sfx_on(on: bool) -> void:
	_sfx_on = on
	_apply_mutes()
	_save_settings()
	sound_changed.emit()


func set_vo_on(on: bool) -> void:
	_vo_on = on
	_apply_mutes()
	_save_settings()
	sound_changed.emit()


func _apply_mutes() -> void:
	_mute_bus(&"Music", not _music_on)
	_mute_bus(&"SFX", not _sfx_on)
	_mute_bus(&"VO", not _vo_on)


func _mute_bus(bus_name: StringName, mute: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_warning("AudioDirector: no '%s' bus in the bus layout" % bus_name)
		return
	AudioServer.set_bus_mute(index, mute)


func _load_settings() -> void:
	var file := ConfigFile.new()
	# A missing file is the normal first run: both stay on.
	if file.load(SETTINGS_PATH) == OK:
		_music_on = bool(file.get_value(SETTINGS_SECTION, "music_on", true))
		_sfx_on = bool(file.get_value(SETTINGS_SECTION, "sfx_on", true))
		_vo_on = bool(file.get_value(SETTINGS_SECTION, "vo_on", true))
	_apply_mutes()


func _save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value(SETTINGS_SECTION, "music_on", _music_on)
	file.set_value(SETTINGS_SECTION, "sfx_on", _sfx_on)
	file.set_value(SETTINGS_SECTION, "vo_on", _vo_on)
	var error := file.save(SETTINGS_PATH)
	if error != OK:
		push_warning("AudioDirector: could not save to %s (error %d)" % [SETTINGS_PATH, error])
