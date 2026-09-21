class_name TopBar
extends Control

## The row across the top of a stage: Back on the left, Music and Sound effects
## on the right, all three in one line above the header.
##
## Back is only announced here, through [signal back_pressed]; the screen that
## holds the bar decides where back leads. [SubScreen] connects it to its own
## [method SubScreen.go_back], so a stage's back and Android's back gesture go to
## the same place. The two toggles need nothing from the screen — they talk to
## the [AudioDirectorService] directly, and the choice is saved there.
##
## A switched-off toggle is dimmed and struck through. The strike is drawn in
## code, and is the fallback until off-state art exists: set
## [member music_off_art] or [member sfx_off_art] and that drawing is shown
## instead, with no strike.

signal back_pressed

## How dark a switched-off toggle's art is drawn when it has no off-state art.
const OFF_TINT := Color(0.55, 0.55, 0.55, 1.0)

## The strike across a switched-off toggle: a cream edge round a red bar, so it
## reads on the brown disc and the green leaves alike. The shape, not the colour,
## is what says "off".
const STRIKE_EDGE := Color(1.0, 0.95, 0.82, 1.0)
const STRIKE_FILL := Color(0.82, 0.18, 0.12, 1.0)
const STRIKE_EDGE_WIDTH := 16.0
const STRIKE_FILL_WIDTH := 8.0

## Drawn in place of the music art while music is off. Empty until that art is
## made; the dim-and-strike fallback is used meanwhile.
@export var music_off_art: Texture2D

## Drawn in place of the sound effects art while effects are off. See
## [member music_off_art].
@export var sfx_off_art: Texture2D

var _music_on_art: Texture2D
var _sfx_on_art: Texture2D

@onready var _back_button: ArtButton = %BackButton
@onready var _music_button: ArtButton = %MusicButton
@onready var _sfx_button: ArtButton = %SfxButton
@onready var _music_art: ArtSlot = %MusicArt
@onready var _sfx_art: ArtSlot = %SfxArt
@onready var _music_strike: Control = %MusicStrike
@onready var _sfx_strike: Control = %SfxStrike

## Fetched rather than named: see [GameStateStore] for why.
@onready var _audio: AudioDirectorService = (
	get_node_or_null("/root/AudioDirector") as AudioDirectorService
)


func _ready() -> void:
	_music_on_art = _music_art.texture
	_sfx_on_art = _sfx_art.texture
	_back_button.pressed.connect(back_pressed.emit)
	_music_button.pressed.connect(_on_music_pressed)
	_sfx_button.pressed.connect(_on_sfx_pressed)
	_music_strike.draw.connect(_draw_strike.bind(_music_strike))
	_sfx_strike.draw.connect(_draw_strike.bind(_sfx_strike))
	if _audio != null:
		_audio.sound_changed.connect(_refresh)
	_refresh()


func _on_music_pressed() -> void:
	if _audio != null:
		_audio.set_music_on(not _audio.is_music_on())


func _on_sfx_pressed() -> void:
	if _audio != null:
		_audio.set_sfx_on(not _audio.is_sfx_on())


func _refresh() -> void:
	var music_on := _audio == null or _audio.is_music_on()
	var sfx_on := _audio == null or _audio.is_sfx_on()
	_show_state(_music_art, _music_strike, music_on, _music_on_art, music_off_art)
	_show_state(_sfx_art, _sfx_strike, sfx_on, _sfx_on_art, sfx_off_art)


## Shows one toggle on or off. The dim goes on `self_modulate`, because
## [ArtButton] owns `modulate` for its press tint and would wipe a dim set there.
## The strike is a child of the art, so it bounces with it on a press.
func _show_state(
	art: ArtSlot, strike: Control, on: bool, on_art: Texture2D, off_art: Texture2D
) -> void:
	if on:
		art.texture = on_art
		art.self_modulate = Color.WHITE
		strike.visible = false
	elif off_art != null:
		art.texture = off_art
		art.self_modulate = Color.WHITE
		strike.visible = false
	else:
		art.texture = on_art
		art.self_modulate = OFF_TINT
		strike.visible = true


## A diagonal bar, top-right to bottom-left, across the middle of the disc.
func _draw_strike(strike: Control) -> void:
	var inset := strike.size * 0.3
	var from := Vector2(strike.size.x - inset.x, inset.y)
	var to := Vector2(inset.x, strike.size.y - inset.y)
	strike.draw_line(from, to, STRIKE_EDGE, STRIKE_EDGE_WIDTH, true)
	strike.draw_line(from, to, STRIKE_FILL, STRIKE_FILL_WIDTH, true)
