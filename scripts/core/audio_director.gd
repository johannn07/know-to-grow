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
var _music_on := true
var _sfx_on := true
var _vo_on := true

@onready var _music: AudioStreamPlayer = $Music
@onready var _voices: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for child in $Sfx.get_children():
		if child is AudioStreamPlayer:
			_voices.append(child)
	if _voices.is_empty():
		push_warning("AudioDirector: no SFX players in the scene, so effects are silent")
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
func play_sfx(stream: AudioStream) -> void:
	if stream == null or _voices.is_empty():
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.play()


func play_tap() -> void:
	play_sfx(tap)


func play_correct() -> void:
	play_sfx(correct_answer)


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
