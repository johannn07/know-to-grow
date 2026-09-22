class_name FallingLeaves
extends Control

## Leaves drifting down the screen in the wind.
##
## Every leaf is one quad from one small sheet, so the whole effect is a single
## batched draw and a loop over a dozen numbers. That is deliberate: this runs
## on low-end phones and behind every other animation, so it never allocates
## per frame, and it stops altogether while it is hidden.
##
## Placed behind the buttons and it takes no input. With no [member leaf_sheet]
## it draws nothing, the same as an [ArtSlot] with hide_when_empty.

## The leaves, laid out on a grid of equal square cells. See art/MANIFEST.md.
@export var leaf_sheet: Texture2D:
	set(value):
		leaf_sheet = value
		queue_redraw()
@export var sheet_columns: int = 4
@export var sheet_rows: int = 2

## How many leaves are in the air at once. The main cost lever on a slow phone.
@export_range(0, 40) var leaf_count: int = 10
## Drawn size of a leaf, in design pixels, picked between these two.
@export var leaf_size_range: Vector2 = Vector2(60.0, 120.0)
## Fall speed, in design pixels a second, picked between these two.
@export var fall_speed_range: Vector2 = Vector2(70.0, 140.0)
## Steady sideways drift, in design pixels a second. Positive blows right.
@export var wind: float = 30.0

## How far outside the rect a leaf travels before it is sent back to the top,
## so none pops in or out at the edge.
const EDGE_MARGIN := 120.0

var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _started := false

# One entry per leaf. Kept as packed arrays so a frame allocates nothing.
var _x := PackedFloat32Array()
var _y := PackedFloat32Array()
var _size := PackedFloat32Array()
var _fall := PackedFloat32Array()
var _sway_px := PackedFloat32Array()
var _sway_rate := PackedFloat32Array()
var _phase := PackedFloat32Array()
var _cell := PackedInt32Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _process(delta: float) -> void:
	if leaf_sheet == null or leaf_count <= 0 or size.x <= 0.0:
		return
	if not _started:
		_start()
	_time += delta
	var bottom := size.y + EDGE_MARGIN
	var width := size.x + EDGE_MARGIN * 2.0
	for i in _x.size():
		_y[i] += _fall[i] * delta
		_x[i] += wind * delta
		if _y[i] > bottom:
			_spawn(i, -EDGE_MARGIN)
		elif _x[i] > size.x + EDGE_MARGIN:
			_x[i] -= width
		elif _x[i] < -EDGE_MARGIN:
			_x[i] += width
	queue_redraw()


func _draw() -> void:
	if leaf_sheet == null or not _started:
		return
	var cell := Vector2(
		leaf_sheet.get_width() / float(maxi(sheet_columns, 1)),
		leaf_sheet.get_height() / float(maxi(sheet_rows, 1))
	)
	for i in _x.size():
		var wave := _time * _sway_rate[i] + _phase[i]
		var pos := Vector2(_x[i] + sin(wave) * _sway_px[i], _y[i])
		# The leaf rocks with its sway, and its width follows a slower cosine so
		# it seems to turn over as it falls.
		var turn := cos(wave * 0.6)
		draw_set_transform(pos, sin(wave) * 0.6, Vector2(turn, 1.0))
		var half := _size[i] * 0.5
		var column := _cell[i] % sheet_columns
		var row := floori(_cell[i] / float(sheet_columns))
		var region := Rect2(Vector2(column, row) * cell, cell)
		draw_texture_rect_region(
			leaf_sheet, Rect2(-half, -half, _size[i], _size[i]), region
		)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Fills the arrays, spread over the whole height, so the screen does not open
## empty and fill from the top.
func _start() -> void:
	# One by one: a packed array put in a list is a copy.
	_x.resize(leaf_count)
	_y.resize(leaf_count)
	_size.resize(leaf_count)
	_fall.resize(leaf_count)
	_sway_px.resize(leaf_count)
	_sway_rate.resize(leaf_count)
	_phase.resize(leaf_count)
	_cell.resize(leaf_count)
	for i in leaf_count:
		_spawn(i, _rng.randf_range(-EDGE_MARGIN, size.y))
	_started = true


func _spawn(i: int, y: float) -> void:
	_x[i] = _rng.randf_range(-EDGE_MARGIN, size.x + EDGE_MARGIN)
	_y[i] = y
	_size[i] = _rng.randf_range(leaf_size_range.x, leaf_size_range.y)
	# Bigger leaves fall a little faster, which reads as nearer the camera.
	var near := inverse_lerp(leaf_size_range.x, leaf_size_range.y, _size[i])
	_fall[i] = lerpf(fall_speed_range.x, fall_speed_range.y, near) * _rng.randf_range(0.85, 1.15)
	_sway_px[i] = _rng.randf_range(30.0, 80.0)
	_sway_rate[i] = _rng.randf_range(0.8, 1.6)
	_phase[i] = _rng.randf_range(0.0, TAU)
	_cell[i] = _rng.randi_range(0, maxi(sheet_columns * sheet_rows, 1) - 1)


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())
