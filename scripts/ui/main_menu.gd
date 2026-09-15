extends Control

## Title screen. Two targets, both sized for a five-year-old's thumb.
##
## Destinations are exported rather than hardcoded so the flow can be re-pointed
## from the Inspector as real screens replace the stubs — no edit here when the
## level select is built for real.

@export_file("*.tscn") var start_scene_path: String = "res://scenes/ui/hub.tscn"
@export_file("*.tscn") var how_to_play_scene_path: String = "res://scenes/ui/how_to_play.tscn"

@onready var _start_button: Button = %StartButton
@onready var _how_to_play_button: Button = %HowToPlayButton

## Sound. This screen is not a [SubScreen] — there is nowhere behind the title
## to go back to — so it fetches the director and starts the music itself.
@onready var _audio: AudioDirectorService = (
	get_node_or_null("/root/AudioDirector") as AudioDirectorService
)


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	if _audio != null:
		_audio.play_music(AudioDirectorService.Track.MENU)
		# button_down, so the tap lands under the thumb rather than on release.
		for node in find_children("*", "BaseButton", true, false):
			(node as BaseButton).button_down.connect(_audio.play_tap)


func _notification(what: int) -> void:
	# Android's system back gesture on the title screen means "leave the game".
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()


func _on_start_pressed() -> void:
	_change_scene(start_scene_path)


func _on_how_to_play_pressed() -> void:
	_change_scene(how_to_play_scene_path)


func _change_scene(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("MainMenu: destination scene is unset or missing: '%s'" % path)
		return
	get_tree().change_scene_to_file(path)
