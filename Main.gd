extends Control

const MIN_RADIUS := 0.4
const MIN_CIRCLES := 3
const MAX_GOAL_CIRCLES := 7
const INCREASE_GOAL_LEVELS := 20
const MIN_SPEED := 20.0
const MAX_SPEED := 200.0
const PLATEAU_LEVEL := 180

export(NodePath) onready var _reference_circle = get_node(_reference_circle) as Circle
export(NodePath) onready var _circles = get_node(_circles) as Control
export(NodePath) onready var _level_label = get_node(_level_label) as Label

var _level := 0
var _total_circles := 0
var _num_goal_circles := 0
var _clicked_goals := 0
var _max_n_circles := 0
var _grid := Grid.new()
var _scale := 1.0
var _speed := 20.0


func _ready():
	randomize()
	update_params()
	next_level()


func _notification(what: int):
	if what == NOTIFICATION_RESIZED and _circles is Control:
		update_params()


func update_params():
	var radius := MIN_RADIUS * Circle.DEFAULT_SIZE
	var size: Vector2 = _circles.rect_size
	_max_n_circles = int(0.9 * size.x * size.y / (PI * radius * radius))
	_grid.update_ratio(size)
	for circle in _circles.get_children():
		circle.update_parent_size(size)


func next_level():
	_level += 1
	_clicked_goals = 0
	for child in _circles.get_children():
		child.queue_free()
	var color_i := randi() % Circle.NUM_COLORS
	_reference_circle.set_color_index(color_i)
	set_difficulty_params()
	generate_circles(color_i)
	_level_label.text = String(_level)


func generate_circles(goal_index: int):
	var indices := []
	for i in Circle.NUM_COLORS:
		if i == goal_index:
			continue
		indices.append(i)

	# Add circles with random colors (different from goal color)
	var circles := []
	for i in _total_circles - _num_goal_circles:
		var ii := randi() % (Circle.NUM_COLORS - 1)
		var circle := Circle.new()
		circle.set_color_index(indices[ii])
		circles.append(circle)

	# Add goal circles
	for i in _num_goal_circles:
		var goal := Circle.new()
		goal.set_color_index(goal_index)
		goal.check_input = true
		var e := goal.connect("clicked", self, "_on_goal_clicked")
		assert(e == OK, "Signal connection failed")
		circles.append(goal)

	# Create grid
	var grid_positions := _grid.get_grid_positions(_total_circles)

	# Add circles to scene
	for i in _total_circles:
		var circle: Circle = circles[i]
		circle.set_size_scale(_scale)
		var speed := _speed * (0.85 + randf() * 0.3)
		circle.set_speed(speed)
		_circles.add_child(circle)
		circle.rect_position = grid_positions[i] - circle.get_half_rect_size()


func set_difficulty_params():
	_total_circles = MIN_CIRCLES + int(((_level - 1) * (_max_n_circles - MIN_CIRCLES)) / float(PLATEAU_LEVEL))
	_total_circles = int(min(_max_n_circles, _total_circles))
	_num_goal_circles = int(_level / float(INCREASE_GOAL_LEVELS)) + 1
	_num_goal_circles = int(min(_num_goal_circles, MAX_GOAL_CIRCLES))
	_scale = 1.0 - (_level - 1) * (1.0 - MIN_RADIUS) / float(PLATEAU_LEVEL)
	_scale = max(_scale, MIN_RADIUS)
	_speed = MIN_SPEED + (_level - 1) * (MAX_SPEED - MIN_SPEED) / float(PLATEAU_LEVEL)
	_speed = min(_speed, MAX_SPEED)


func _on_goal_clicked():
	_clicked_goals += 1
	if _clicked_goals == _num_goal_circles:
		$Timer.start()


func _on_timer_timeout():
	next_level()


class Grid:
	var _ratio := 1.0
	var _ny := 0
	var _nx := 0
	var _grid := PoolVector2Array()
	var _area := Vector2()

	func get_grid_positions(n: int) -> PoolVector2Array:
		var ny := int(ceil(sqrt(1.2 * n / _ratio)))

		if (ny != _ny):
			update_grid(ny)

		# Generate index array
		var indices := PoolIntArray()
		indices.resize(_grid.size())
		for i in _grid.size():
			indices[i] = i

		# Get grid cell size
		var szx := _area.x / _nx
		var szy := _area.y / _ny

		# Select positions and add random displacement
		var selected_grid := PoolVector2Array()
		selected_grid.resize(n)
		for i in n:
			var index := randi() % indices.size()
			var pos := _grid[indices[index]]
			selected_grid[i] = Vector2(szx * (pos.x + randf()), szy * (pos.y + randf()))
			indices.remove(index)

		return selected_grid


	func update_grid(ny: int):
		_ny = ny
		_nx = int(ceil(_ratio * ny))
		_grid.resize(_nx * _ny)

		# Get grid positions
		var index := 0
		for ix in _nx:
			for iy in _ny:
				_grid[index] = Vector2(ix, iy)
				index += 1


	func update_ratio(area: Vector2):
		_ratio = area.x / area.y
		_area = area
		_ny = -1


