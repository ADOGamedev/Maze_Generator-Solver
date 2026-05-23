extends Control

@onready var size_label = %size_label
@onready var size_slider = %size_slider
@onready var speed_label = %speed_label
@onready var speed_slider = %speed_slider

func _on_size_slider_value_changed(value: float) -> void:
	Global.maze_size = int(value)
	speed_slider.max_value = int(value * 3)
	size_label.text = str(int(value))

func _on_speed_slider_value_changed(value: float) -> void:
	if value > 1.0:
		speed_slider.value = int(value)
	speed_slider.step = 0.01 if value <= 1.0 else 1.0
	speed_label.text = str(value) if value <= 1.0 else str(int(value))
	Global.visualization_speed = value

func _on_visualize_toggled(toggled_on: bool) -> void:
	Global.visualize = toggled_on

func _on_solving_algorithm_item_selected(index: int) -> void:
	Global.sol_algorithm = index

func _on_generating_algorithm_item_selected(index: int) -> void:
	Global.gen_algorithm = index
	if index == 0:
		Global.maze_size = min(Global.maze_size, 500)
		size_slider.max_value = 500
	else:
		Global.maze_size = min(Global.maze_size, 50)
		size_slider.max_value = 50

func _on_visualize_grid_creation_toggled(toggled_on: bool) -> void:
	Global.visualize_grid_creation = toggled_on
