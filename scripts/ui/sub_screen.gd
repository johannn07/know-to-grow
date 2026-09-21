class_name SubScreen
extends Control

## Shared behaviour for any screen reached from the main menu: one way back,
## reachable both from an on-screen button and from Android's back gesture.
##
## Attach this to the root of a screen that has a Button named BackButton with
## "Access as Unique Name" enabled. The button is optional — a screen whose
## artwork draws no back control (the hub, for instance) still gets the Android
## back gesture, which on a phone is the gesture children actually use.

## Touch floor at the 1080-wide design resolution. Several screens are a single
## drawn image with their controls painted into it, and a painted control is
## routinely smaller than a small thumb needs — the How To Play card's button is
## 104 px tall. The hit area over one is grown to reach this, which an invisible
## target can do without looking wrong.
const MIN_TOUCH := 160.0

@export_file("*.tscn") var back_scene_path: String = "res://scenes/ui/main_menu.tscn"

## What this screen sounds like. Asking for the track that is already playing
## does nothing, so screens in the same run share one continuous loop rather
## than restarting it at every scene change.
@export var music_track: AudioDirectorService.Track = AudioDirectorService.Track.NONE

@onready var _back_button: Button = get_node_or_null("%BackButton") as Button

## The back / music / effects row a stage carries. Its back goes wherever this
## screen's back goes, so the button and the gesture cannot disagree.
@onready var _top_bar: TopBar = get_node_or_null("%TopBar") as TopBar

## What the child has finished so far. Fetched rather than named: see the note
## on [GameStateStore] for why `GameState` cannot be written directly here. Null
## only if the autoload is missing, so screens that read it should say so rather
## than assume.
@onready var progress: GameStateStore = get_node_or_null("/root/GameState") as GameStateStore

## Sound. Fetched rather than named, for the same reason as [member progress].
@onready var audio: AudioDirectorService = (
	get_node_or_null("/root/AudioDirector") as AudioDirectorService
)


func _ready() -> void:
	if _back_button != null:
		_back_button.pressed.connect(go_back)
	if _top_bar != null:
		_top_bar.back_pressed.connect(go_back)
	if audio != null:
		audio.play_music(music_track)
	dress_every_button(self)


## Gives every button under [param root_node] its tap sound and its bounce, so a
## screen does not have to remember either per control. Buttons added later —
## the feedback card's, for instance — are already covered, because they live
## in the scene too.
##
## Both hang off `button_down`/`button_up`, not `pressed`. A child hears and sees
## the press the instant a thumb lands rather than when it lifts, which is what
## makes a button feel like it responded. It also leaves `pressed` carrying
## exactly the one thing the screen does, which is what the smoke test checks.
##
## A themed button bounces itself. An [ArtButton] is an invisible hotspot, so it
## bounces its own art and is left alone here — scaling the hotspot would only
## move where the tap lands.
##
## A disabled button emits nothing, so a locked stage row stays still and silent
## without needing to be skipped.
func dress_every_button(root_node: Node) -> void:
	for node in root_node.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if not button.button_down.is_connected(_on_any_button_down):
			button.button_down.connect(_on_any_button_down)
		var face := button as Control
		if face != null and not (button is ArtButton) and not button.has_meta(&"_bounces"):
			button.set_meta(&"_bounces", true)
			button.button_down.connect(PressBounce.press.bind(face))
			button.button_up.connect(PressBounce.release.bind(face))


func _on_any_button_down() -> void:
	if audio != null:
		audio.play_tap()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func go_back() -> void:
	if back_scene_path.is_empty() or not ResourceLoader.exists(back_scene_path):
		push_warning("SubScreen: back scene is unset or missing: '%s'" % back_scene_path)
		return
	get_tree().change_scene_to_file(back_scene_path)


## Anchors a control over a region of its parent, in fractions of that parent.
func anchor_to(control: Control, frac: Rect2) -> void:
	control.anchor_left = frac.position.x
	control.anchor_top = frac.position.y
	control.anchor_right = frac.end.x
	control.anchor_bottom = frac.end.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


## Grows a control's hit area outwards, evenly, until it clears [constant
## MIN_TOUCH] in both directions. A control already over the floor is left alone.
##
## This is done in code rather than with offsets typed into the scene on purpose.
## A hand-tuned offset is right only for the layout it was measured against, and
## falls under the floor silently the next time anything near it moves — which is
## exactly how this screen's two buttons ended up at 510x154 and 142x136 and
## stayed that way through several sessions. Padding computed from the control's
## own size cannot drift.
func pad_to_touch_floor(control: Control) -> void:
	# Anchors do not become a size until the parent has had a layout pass.
	await get_tree().process_frame
	var pad_x: float = maxf(0.0, (MIN_TOUCH - control.size.x) * 0.5)
	var pad_y: float = maxf(0.0, (MIN_TOUCH - control.size.y) * 0.5)
	control.offset_left = -pad_x
	control.offset_right = pad_x
	control.offset_top = -pad_y
	control.offset_bottom = pad_y


## Anchors a hotspot over a control drawn into the artwork, then pads it out to
## the touch floor.
func place_hotspot(control: Control, frac: Rect2) -> void:
	anchor_to(control, frac)
	await pad_to_touch_floor(control)
