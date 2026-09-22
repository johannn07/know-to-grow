class_name SparkleBurst
extends CanvasLayer

## Stars bursting out of a right answer.
##
## A layer of its own, above everything on the stage, because the Correct card
## and its dim come up the same moment the answer is chosen: drawn on the stage
## itself the burst would be hidden under them. From up here the stars fly out of
## the chosen card and over the Correct card as it appears.
##
## The stars are the game's own star, [code]icon_star_filled.png[/code], since a
## right answer is what earns them. Two small one-shot CPU emitters, a few dozen
## particles for about a second, then the node frees itself — nothing is left
## running on a low-end phone.

@onready var _emitters: Array[CPUParticles2D] = [%Stars, %Glints]


## Fires every emitter once from [param point], in the stage's own coordinates,
## and frees the burst when the longest-lived particle is gone.
func burst_at(point: Vector2) -> void:
	var longest := 0.0
	for emitter in _emitters:
		emitter.position = point
		emitter.restart()
		longest = maxf(longest, emitter.lifetime)
	var tween := create_tween()
	tween.tween_interval(longest + 0.1)
	tween.tween_callback(queue_free)


## True while any of its particles are still in flight.
func is_bursting() -> bool:
	for emitter in _emitters:
		if emitter.emitting:
			return true
	return false
