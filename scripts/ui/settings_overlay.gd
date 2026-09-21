class_name SettingsOverlay
extends Control

## The Settings card, opened from the settings button on a stage's [TopBar].
##
## Music and sound effects switch on and off here, and Main Menu leaves the
## level. The two toggles talk to the [AudioDirectorService] directly, which
## saves the choice, so nothing about them passes through the screen.
##
## It closes three ways, because a five-year-old will try all of them: the round
## back arrow on the card, a tap on the dimmed garden around it, and Android's
## back gesture — [SubScreen] asks [method is_open] before treating that gesture
## as leaving the screen.
##
## A switched-off toggle is its own art drawn darker. That is the whole of the
## off state; there is no separate drawing for it.

## How dark a switched-off toggle is drawn.
const OFF_TINT := Color(0.45, 0.45, 0.45, 1.0)

## Where Main Menu leads.
@export_file("*.tscn") var main_menu_path: String = "res://scenes/ui/main_menu.tscn"

@onready var _dim: ColorRect = %Dim
@onready var _close_button: ArtButton = %CloseButton
@onready var _music_button: ArtButton = %MusicButton
@onready var _sfx_button: ArtButton = %SfxButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _music_art: ArtSlot = %MusicArt
@onready var _sfx_art: ArtSlot = %SfxArt

## Fetched rather than named: see [GameStateStore] for why.
@onready var _audio: AudioDirectorService = (
	get_node_or_null("/root/AudioDirector") as AudioDirectorService
)


func _ready() -> void:
	# Drawn over the whole screen whatever the stage around it is doing, so it
	# is sized to the viewport rather than to the bar it hangs from.
	# Anchors would only fill the bar, so they are dropped for a plain size.
	top_level = true
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_fit_to_screen()
	get_viewport().size_changed.connect(_fit_to_screen)
	_close_button.pressed.connect(close)
	_music_button.pressed.connect(_on_music_pressed)
	_sfx_button.pressed.connect(_on_sfx_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_dim.gui_input.connect(_on_dim_input)
	if _audio != null:
		_audio.sound_changed.connect(_refresh)
	_refresh()
	hide()


func open() -> void:
	_refresh()
	show()


func close() -> void:
	# A press cut short by the card vanishing must not leave its art dark.
	for button: ArtButton in [_close_button, _music_button, _sfx_button]:
		button.clear_tint()
	hide()


func is_open() -> bool:
	return visible


func _fit_to_screen() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size


func _on_dim_input(event: InputEvent) -> void:
	# Release rather than press, so the same touch cannot also land on a card
	# underneath after the overlay has gone.
	var touch := event as InputEventScreenTouch
	var click := event as InputEventMouseButton
	if (touch != null and not touch.pressed) or (
		click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed
	):
		close()


func _on_music_pressed() -> void:
	if _audio != null:
		_audio.set_music_on(not _audio.is_music_on())


func _on_sfx_pressed() -> void:
	if _audio != null:
		_audio.set_sfx_on(not _audio.is_sfx_on())


func _on_main_menu_pressed() -> void:
	if main_menu_path.is_empty() or not ResourceLoader.exists(main_menu_path):
		push_warning("SettingsOverlay: main menu scene is unset or missing: '%s'" % main_menu_path)
		return
	get_tree().change_scene_to_file(main_menu_path)


func _refresh() -> void:
	var music_on := _audio == null or _audio.is_music_on()
	var sfx_on := _audio == null or _audio.is_sfx_on()
	# self_modulate, because [ArtButton] owns `modulate` for its press tint.
	_music_art.self_modulate = Color.WHITE if music_on else OFF_TINT
	_sfx_art.self_modulate = Color.WHITE if sfx_on else OFF_TINT
