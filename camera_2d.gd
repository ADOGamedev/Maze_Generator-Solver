extends Camera2D

@onready var VIEWPORT_SIZE := Vector2(720, 720)
var MAX_ZOOM = Vector2(20.0, 20.0)
var MIN_ZOOM = Vector2(1.0, 1.0)
@onready var max_pos = VIEWPORT_SIZE - (VIEWPORT_SIZE / (2 * zoom))
@onready var min_pos = VIEWPORT_SIZE / (2 * zoom)

var ZOOM_INCREMENT_MULTIPIER := 1.05

func _ready() -> void:
	position = VIEWPORT_SIZE / 2


func _process(_delta: float) -> void:
	zoom = clamp(zoom, MIN_ZOOM, MAX_ZOOM)
	position.x = clamp(position.x, min_pos.x, max_pos.x)
	position.y = clamp(position.y, min_pos.y, max_pos.y)
	if zoom == MIN_ZOOM:
		position = VIEWPORT_SIZE / 2


func input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("move_cam"):
			position -= event.relative / zoom.x


	if event is InputEventMouseButton:
		if Input.is_action_pressed("zoom"):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom *= ZOOM_INCREMENT_MULTIPIER
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom /= ZOOM_INCREMENT_MULTIPIER

			if MIN_ZOOM < zoom and zoom < MAX_ZOOM:
				var target = get_global_mouse_position()
				position = position.lerp(target, 0.05)

			max_pos = VIEWPORT_SIZE - (VIEWPORT_SIZE / (2 * zoom))
			min_pos = VIEWPORT_SIZE / (2 * zoom)

			if min_pos.x > max_pos.x:
				max_pos.x = min_pos.x
