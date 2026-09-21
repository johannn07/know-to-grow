class_name GameCompleteOverlay
extends Control

## "Hooray! You did it!" — the finished-game card, laid over the hub.
##
## The hub brings it up by itself the first time it shows the fully grown plant,
## which is where Grow Now after Level 4 lands. It is an overlay on the hub
## rather than a screen of its own so the child sees the garden they finished
## behind it, and Continue Playing simply lifts it off.
##
## It offers three things, on the themed green plates below the card:
## **Continue Playing**, which closes it and leaves the child on the finished
## hub, **New Game**, which starts again from the seed, and **Credits**. New Game
## is a [HoldButton], because by now there is always a save to lose — decided by
## the project owner.
##
## It only reports the first two. The hub owns what happens next: the music, the
## reset, the reload. Credits is handled here, since it only opens a card over
## this one and changes nothing.

## Close the card and stay on the finished garden.
signal continue_playing
## The hold on New Game finished: start again from the seed.
signal new_game

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: HoldButton = %NewGameButton
@onready var _credits_button: Button = %CreditsButton
@onready var _credits: CreditsOverlay = %Credits


func _ready() -> void:
	_continue_button.pressed.connect(continue_playing.emit)
	_new_game_button.held.connect(new_game.emit)
	_credits_button.pressed.connect(_credits.open)
