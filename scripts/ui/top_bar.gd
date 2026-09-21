class_name TopBar
extends Control

## The row across the top of a stage: Back on the left, Settings on the right,
## both in one line above the header.
##
## Back is only announced here, through [signal back_pressed]; the screen that
## holds the bar decides where back leads. [SubScreen] connects it to its own
## [method SubScreen.go_back], so a stage's back and Android's back gesture go to
## the same place.
##
## Settings opens the [SettingsOverlay] this bar carries, where music, sound
## effects and Main Menu live. It is kept here rather than in every stage scene
## so that nineteen stages get it from one place.
##
## The hub carries one too, with [member show_back] off: it has settings but no
## back button, since Android's back gesture already leaves it.

signal back_pressed

## Whether the row has a back button. Off on the hub.
@export var show_back: bool = true

@onready var _back_button: ArtButton = %BackButton
@onready var _back_art: ArtSlot = %BackArt
@onready var _settings_button: ArtButton = %SettingsButton
@onready var _settings: SettingsOverlay = %Settings


func _ready() -> void:
	_back_button.pressed.connect(back_pressed.emit)
	_back_button.visible = show_back
	_back_art.visible = show_back
	_settings_button.pressed.connect(open_settings)


func open_settings() -> void:
	_settings_button.clear_tint()
	_settings.open()


func close_settings() -> void:
	_settings.close()


func settings_open() -> bool:
	return _settings.is_open()
