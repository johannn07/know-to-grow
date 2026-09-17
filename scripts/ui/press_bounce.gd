class_name PressBounce
extends RefCounted

## The small squash-and-spring a button does under a thumb.
##
## Pressing shrinks the thing the child can see a little; letting go springs it
## back past full size and settles. Paired with the tint and the tap sound, it
## is what makes a drawn picture feel like a control that answered.
##
## It works on whatever is *visible*: a themed button bounces itself, and an
## [ArtButton] — an invisible hotspot — bounces the art underneath it. Scaling
## is around the centre, so nothing drifts sideways as it moves.
##
## Only one bounce runs per node. A second tap kills the first rather than
## fighting it, which is what stops a quick double-tap leaving a button stuck
## small.

## How far a press squashes. Small on purpose: this is feedback, not a gag.
const PRESSED_SCALE := Vector2(0.93, 0.93)
const PRESS_SECONDS := 0.06
## TRANS_BACK overshoots before it settles, which is the "bounce".
const RELEASE_SECONDS := 0.24

const _TWEEN_META := &"_press_bounce_tween"


static func press(target: Control) -> void:
	if not _usable(target):
		return
	_start(target).tween_property(target, "scale", PRESSED_SCALE, PRESS_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func release(target: Control) -> void:
	if not _usable(target):
		return
	_start(target).tween_property(target, "scale", Vector2.ONE, RELEASE_SECONDS) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Snaps back to full size with no animation. For a control that is being shown
## again, so a press interrupted by a scene change cannot leave it small.
static func reset(target: Control) -> void:
	if target == null:
		return
	_kill(target)
	target.scale = Vector2.ONE


static func _usable(target: Control) -> bool:
	return target != null and target.is_inside_tree()


static func _start(target: Control) -> Tween:
	_kill(target)
	# The size is only final once the control has been laid out, so the pivot is
	# set at the moment of the press rather than once in _ready.
	target.pivot_offset = target.size * 0.5
	var tween := target.create_tween()
	target.set_meta(_TWEEN_META, tween)
	return tween


static func _kill(target: Control) -> void:
	if not target.has_meta(_TWEEN_META):
		return
	var running: Tween = target.get_meta(_TWEEN_META) as Tween
	if running != null and running.is_valid():
		running.kill()
	target.remove_meta(_TWEEN_META)
