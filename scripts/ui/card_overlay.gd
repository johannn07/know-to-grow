class_name CardOverlay
extends SubScreen

## A dimmed screen showing one drawn card, with a button under it.
##
## Four screens in the level flow are the same shape: the level intro, the stage
## select, level complete and badge unlocked. Each is one picture with its words
## already drawn into it, a dim behind it so the screen it interrupts reads as
## paused, and one control to move on. Only the pictures differ, so only the
## pictures live in the scene — this holds the part that would otherwise be
## written four times.
##
## A scene using this is expected to have %Background, %Dim, %OverlayAspect,
## %CardArt, %BannerArt, %ButtonArt and %ActionButton.
##
## Everything is placed in fractions **of the card**, which is the only node
## whose size is pinned to an image. That is why the banner's y is negative and
## the button's runs past 1.0: they sit outside the card, above and below it,
## and stay there at any screen size.
##
## No wording is set here or in any scene using it. Every word on these cards is
## drawn into the artwork; content/*.tres records it as a transcript for review
## and voice-over. See art/MANIFEST.md.

## Where the button goes when the card has no button drawn into it: centred just
## under the card's bottom edge. The rect is in fractions **of the card**, so a y
## past 1.0 is what puts it outside. Matches the Continue on Level 1 Stage 4.
const BUTTON_BELOW_CARD := Rect2(0.265, 1.04, 0.47, 0.115)

@export_group("Art")
## The card itself. Its pixel ratio sets the shape of the frame it is drawn in,
## so the button rect below stays true at any screen size.
@export var card_art: Texture2D
## The button under the card. Left empty, no button is drawn and the whole card
## becomes the target.
@export var button_art: Texture2D
## An optional banner over the card, for a screen that announces itself twice —
## the badge overlay puts BADGE UNLOCK! above the badge it is unlocking.
@export var banner_art: Texture2D

@export_group("Layout")
## Where [member button_art] sits, in fractions of the card image.
@export var button_rect: Rect2 = BUTTON_BELOW_CARD
## Where [member banner_art] sits. Negative y puts it above the card.
@export var banner_rect: Rect2 = Rect2()

@export_group("Flow")
## Where the button goes. Empty means this overlay is the end of its run.
@export_file("*.tscn") var next_scene_path: String = ""

@onready var _aspect: AspectRatioContainer = %OverlayAspect
@onready var _card_art: ArtSlot = %CardArt
@onready var _banner_art: ArtSlot = %BannerArt
@onready var _button_art: ArtSlot = %ButtonArt
@onready var _action_button: ArtButton = %ActionButton


func _ready() -> void:
	super()
	if card_art == null:
		push_warning("%s: no card art assigned in the scene" % name)
	else:
		_card_art.texture = card_art
		# The button is placed in fractions of the image, so the node it sits in
		# has to be exactly the image's shape — no letterboxing.
		_aspect.ratio = float(card_art.get_width()) / float(card_art.get_height())

	_banner_art.texture = banner_art
	_banner_art.visible = banner_art != null and banner_rect.has_area()
	if _banner_art.visible:
		anchor_to(_banner_art, banner_rect)

	_button_art.texture = button_art
	_button_art.visible = button_art != null and button_rect.has_area()
	if _button_art.visible:
		# The art is anchored but never padded: it has to stay where it was
		# measured. The hotspot over it is free to be larger.
		anchor_to(_button_art, button_rect)
		place_hotspot(_action_button, button_rect)
	else:
		# Nothing drawn to aim at, so the whole card takes the tap.
		anchor_to(_action_button, Rect2(0.0, 0.0, 1.0, 1.0))

	_action_button.pressed.connect(_on_action_pressed)


## Override in a screen that needs to do something before moving on.
func on_action() -> void:
	pass


func _on_action_pressed() -> void:
	on_action()
	if next_scene_path.is_empty():
		push_warning("%s: nowhere to go — next_scene_path is unset" % name)
		return
	if not ResourceLoader.exists(next_scene_path):
		push_warning("%s: next scene is missing: '%s'" % [name, next_scene_path])
		return
	get_tree().change_scene_to_file(next_scene_path)
