extends Node2D


var graph : Dictionary[Vector2, Array] = {}
var start : Vector2
var end : Vector2

@onready var maze_gen = $maze_gen
@onready var maze_sol = $maze_sol

func _ready() -> void:
	maze_gen.connect("maze_generated", Callable(self, "_on_maze_generated"))
	maze_sol.connect("maze_solved", Callable(self, "_on_maze_solved"))
	
func _reset() -> void:

	_reset_generators()

	graph.clear()
	Global.maze_generated = false
	Global.is_maze_generating = false
	Global.is_maze_solving = false
	maze_gen.origin_shift_can_gen = true
	$grid.clear()



func _reset_generators() -> void:
	maze_gen.queue_free()
	maze_sol.queue_free()

	var new_maze_gen = preload("res://maze_gen.tscn").instantiate()
	var new_maze_sol = preload("res://maze_sol.tscn").instantiate()

	maze_gen = new_maze_gen
	maze_sol = new_maze_sol

	add_child(new_maze_gen)
	add_child(new_maze_sol)
	
	maze_gen.connect("maze_generated", Callable(self, "_on_maze_generated"))
	maze_sol.connect("maze_solved", Callable(self, "_on_maze_solved"))
	
func _on_gen_maze_pressed() -> void:
	_reset()

	await get_tree().create_timer(0.01).timeout
	
	start = Vector2.ONE
	end = Vector2(Global.maze_size * 2 - 1, Global.maze_size * 2 - 1)
	
	Global.is_maze_generating = true
	maze_gen.make_maze()


func _on_sol_maze_pressed() -> void:
	if !Global.maze_generated:
		return

	_reset_generators()

	Global.is_maze_solving = true
	Global.is_maze_generating = false

	for x in range(Global.maze_size * 2 + 1):
		for y in range(Global.maze_size * 2 + 1):
			var cell = Vector2(x, y)
			var cell_type = $grid.get_cell_atlas_coords(cell).x
			
			if cell_type == -1:
				continue
				
			var is_wall = cell_type == Global.Tiles.WALL
			
			if cell == start or cell == end:
				continue
				
			$grid.set_cell(cell, 0, Vector2(Global.Tiles.WALL if is_wall else Global.Tiles.PATH, 0))
			
	Global.is_maze_solving = true
	match Global.sol_algorithm:
		0: maze_sol.solve_maze_a_star(graph, start, end)
		1: maze_sol.solve_maze_bidir_a_star(graph, start, end)
		2: maze_sol.solve_maze_dijkstra(graph, start, end)

func _on_maze_generated():
	Global.maze_generated = true
	Global.is_maze_generating = false


func _on_maze_solved():
	Global.maze_generated = true
	Global.is_maze_solving = false


func _on_stop_originl_shift_pressed() -> void:
	maze_gen._on_stop_origin_shift_pressed()
