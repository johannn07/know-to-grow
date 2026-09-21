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
}

## How many effects can overlap before the oldest is cut off. A tap landing on
## top of a correct answer is normal, so one player is not enough.
const SFX_VOICES := 4

@export_group("Music")
@export var menu_music: AudioStream
@export var level_1_music: AudioStream
@export var level_2_music: AudioStream
@export var level_3_music: AudioStream
@export var level_4_music: AudioStream

@export_group("Effects")
## Any button, anywhere. Connected for a whole screen by [SubScreen].
@export var tap: AudioStream
@export var correct_answer: AudioStream
@export var wrong_answer: AudioStream

var _current := Track.NONE
var _next_voice := 0

@onready var _music: AudioStreamPlayer = $Music
@onready var _voices: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for child in $Sfx.get_children():
		if child is AudioStreamPlayer:
			_voices.append(child)
	if _voices.is_empty():
		push_warning("AudioDirector: no SFX players in the scene, so effects are silent")


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
