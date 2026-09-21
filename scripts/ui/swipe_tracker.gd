class_name SwipeTracker
extends RefCounted

## Turns presses and releases into sideways swipes, for the screens that page:
## stage select between levels, the Garden between stages of the plant.
##
## Fed from a screen's `_input`, not its `_gui_input`, because a swipe usually
## starts on something tappable — a stage row, the plant — and has to be seen
## anyway. [method feed] answers on the release, and the screen swallows that
## release when it turns the page, so whatever was under the finger does not
## open as well.
##
## Mouse events only: a touch arrives as an emulated mouse press on the phone,
## and a real one on the desktop, so reading touches too would count it twice.

## How far a finger has to travel sideways, in design pixels, before a drag is a
## swipe. About a tenth of the screen: further than a wobbly tap, short enough
## for a small hand.
const MIN_TRAVEL := 120.0
## A swipe has to be this much more sideways than up-and-down, so a slip while
## tapping does not turn the page.
const SLOPE := 1.5

var _press_at := Vector2.ZERO
var _pressing := false


## Watches one input event. Returns the page a finished swipe asks for — 1 the
## next, -1 the previous — or 0 for anything else, including every press.
func feed(event: InputEvent) -> int:
	var click := event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return 0
	if click.pressed:
		_press_at = click.position
		_pressing = true
		return 0
	if not _pressing:
		return 0
	_pressing = false
	return direction(click.position - _press_at)


## Which page a drag of [param travel] asks for: a swipe to the left moves on,
## to the right goes back, and anything short or steep is not a swipe.
static func direction(travel: Vector2) -> int:
	if absf(travel.x) < MIN_TRAVEL or absf(travel.x) < absf(travel.y) * SLOPE:
		return 0
	return 1 if travel.x < 0.0 else -1
