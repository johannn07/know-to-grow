extends Control

## Title screen: Continue, New Game, How To Play and Exit, all sized for a
## five-year-old's thumb.
##
## Continue appears only when there is a save — any stage cleared — and picks up
## on the hub, where the plant already shows how far the child got. New Game
## starts from the seed. Over a save it is a [HoldButton] that has to be held,
## decided by the project owner, so one stray tap cannot wipe a garden; with no
## save there is nothing to lose and it is a plain tap. Its hint line shows only
## while the hold is needed.
##
## Exit, and Android's back gesture here, open the [ExitOverlay] to ask first;
## only its Yes closes the app. Back again while it is up closes the card. Exit
## is hidden on the web build, where a page cannot close its own tab and the button would
## do nothing. Progress is saved as it is earned, so leaving loses nothing.
##
## Destinations are exported rather than hardcoded so the flow can be re-pointed
## from the Inspector as real screens replace the stubs.

## Where both Continue and New Game lead. The hub draws the plant from progress,
## so the only difference between them is whether progress was wiped first.
@export_file("*.tscn") var start_scene_path: String = "res://scenes/ui/hub.tscn"
@export_file("*.tscn") var how_to_play_scene_path: String = "res://scenes/ui/how_to_play.tscn"

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: HoldButton = %NewGameButton
@onready var _hold_hint: Label = %HoldHint
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _exit_button: Button = %ExitButton
@onready var _exit_overlay: ExitOverlay = %ExitOverlay

## Sound. This screen is not a [SubScreen] — there is nowhere behind the title
## to go back to — so it fetches the director and starts the music itself.
@onready var _audio: AudioDirectorService = (
	get_node_or_null("/root/AudioDirector") as AudioDirectorService
)

## Progress, fetched for the same reason: see [GameStateStore].
@onready var _progress: GameStateStore = get_node_or_null("/root/GameState") as GameStateStore


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.held.connect(_on_new_game_held)
	_how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	_exit_button.pressed.connect(_exit_overlay.open)
	_exit_overlay.exit_confirmed.connect(_on_exit_confirmed)
	_exit_button.visible = not OS.has_feature("web")
	_show_save_state()
	if _audio != null:
		_audio.play_music(AudioDirectorService.Track.MENU)
	# button_down, so the tap and the squash land under the thumb rather than on
	# release. Same treatment SubScreen gives every other screen.
	for node in find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if _audio != null:
			button.button_down.connect(_audio.play_tap)
		button.button_down.connect(PressBounce.press.bind(button))
		button.button_up.connect(PressBounce.release.bind(button))


func _notification(what: int) -> void:
	# Android's system back gesture on the title screen means "leave the game",
	# asked the same way the Exit button asks.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _exit_overlay.is_open():
			_exit_overlay.close()
		else:
			_exit_overlay.open()


## Whether there is a save to continue from, and so to guard.
func has_save() -> bool:
	return _progress != null and _progress.has_progress()


func _show_save_state() -> void:
	var saved := has_save()
	_continue_button.visible = saved
	_new_game_button.require_hold = saved
	_hold_hint.visible = saved


func _on_continue_pressed() -> void:
	_change_scene(start_scene_path)


func _on_new_game_held() -> void:
	# The same reset the finished-game card's New Game uses.
	if _progress != null:
		_progress.reset()
	_change_scene(start_scene_path)


func _on_how_to_play_pressed() -> void:
	_change_scene(how_to_play_scene_path)


func _on_exit_confirmed() -> void:
	get_tree().quit()


func _change_scene(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("MainMenu: destination scene is unset or missing: '%s'" % path)
		return
	get_tree().change_scene_to_file(path)
