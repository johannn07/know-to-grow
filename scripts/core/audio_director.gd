extends Node

## Autoload named "AudioDirector".
## Call it from day one. It no-ops safely while res://audio/ is empty, so you
## never have to go back and hunt for "where should the ding go?" later.

const SFX_DIR := "res://audio/sfx/"
const VO_DIR := "res://audio/vo/en/"

var mute_sfx: bool = false
var mute_vo: bool = false

var _sfx_player: AudioStreamPlayer
var _vo_player: AudioStreamPlayer
var _cache: Dictionary = {}


func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	add_child(_sfx_player)

	_vo_player = AudioStreamPlayer.new()
	_vo_player.bus = "VO" if AudioServer.get_bus_index("VO") != -1 else "Master"
	add_child(_vo_player)


## play_sfx(&"correct"), play_sfx(&"wrong"), play_sfx(&"pickup"), play_sfx(&"drop")
func play_sfx(key: StringName) -> void:
	if mute_sfx:
		return
	var stream := _load(SFX_DIR + String(key) + ".ogg")
	if stream == null:
		print_rich("[color=gray][sfx] %s[/color]" % key)  # placeholder feedback
		return
	_sfx_player.stream = stream
	_sfx_player.play()


## Voice-over. Interrupts itself - a child should never hear two lines at once.
func play_vo(key: StringName) -> void:
	if mute_vo or key == &"":
		return
	var stream := _load(VO_DIR + String(key) + ".ogg")
	if stream == null:
		print_rich("[color=gray][vo] %s[/color]" % key)
		return
	_vo_player.stop()
	_vo_player.stream = stream
	_vo_player.play()


func stop_vo() -> void:
	_vo_player.stop()


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	_cache[path] = stream
	return stream
