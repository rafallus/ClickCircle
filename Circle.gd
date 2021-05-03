tool
extends Control
class_name Circle

signal clicked

const COLORS := [Color('295fcc'), Color('9629cc'), Color('cc295f'),
				Color('cc9629'), Color('5fcc29'), Color('29cccc')]
const NUM_COLORS := 6
const DEFAULT_SIZE := 78

export var check_input := false

onready var _radius := int(rect_size.x * 0.5)
var _color := Color(1,1,1)
var _area := Vector2()
var _direction := Vector2()
var _speed := 0.0
var _kill := false
var _kill_amount := 1.0

var color_index := 0

func _ready():
	update_parent_size(get_parent().rect_size)


func _draw():
	draw_circle(Vector2(_radius, _radius), _radius, _color)


func _gui_input(event: InputEvent):
	if !check_input:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed and mouse_event.button_index == BUTTON_LEFT:
		var sqrd := (mouse_event.position - Vector2(_radius, _radius)).length_squared()
		if sqrd <= _radius * _radius:
			emit_signal("clicked")
			_kill = true


func _process(delta: float):
	var x := self.rect_position.x + 0.5 * self.rect_size.x
	var y := self.rect_position.y + 0.5 * self.rect_size.y
	if x < 0.0 or x > _area.x:
		_direction.x = -_direction.x
	elif y < 0.0 or y > _area.y:
		_direction.y = -_direction.y
	var displacement := _direction * _speed * delta
	_set_position(self.rect_position + displacement)
	if _kill:
		_kill_amount -= delta * 7.0
		if _kill_amount < 0.0:
			queue_free()
		else:
			_color.a = _kill_amount
			update()

func set_color_index(i: int):
	color_index = i
	_color = COLORS[i]
	update()


func set_size_scale(sz: float):
	var size := int(sz * DEFAULT_SIZE)
	rect_size = Vector2(size, size)


func get_half_rect_size() -> Vector2:
	return 0.5 * rect_size


func update_parent_size(size: Vector2):
	_area = size


func set_speed(speed: float):
	_speed = speed
	_direction = Vector2(randf() - 0.5, randf() - 0.5).normalized()


