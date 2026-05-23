extends Node2D

@onready var grid : TileMapLayer = get_node("../grid")
var VIEWPORT_SIZE = Vector2(720, 720)
var origin_shift_can_gen = true

signal maze_generated

func make_maze() -> void:
	await create_grid()
	match Global.gen_algorithm:
		0: await generate_maze_dfs()
		1: await generate_maze_hak()
		2: await gen_maze_origin_shift()
	color_start_and_end()
	
func create_grid() -> void:
	var maze_size = Global.maze_size
	var cells_amount = (maze_size * 2) if Global.gen_algorithm == 3 else (maze_size * 2 + 1)
	var cell_size = VIEWPORT_SIZE / cells_amount
	var end_cell = null
	var start_asigned = false
	var count = 0
	
	grid.scale = cell_size
	
	for x in range(cells_amount):
		for y in range(cells_amount):
			if x % 2 == 0 and y % 2 == 0:
				continue
				
			var is_wall = x % 2 == 0 or y % 2 == 0
			grid.set_cell(Vector2(x, y), 0, Vector2(Global.Tiles.WALL if is_wall else Global.Tiles.DEFAULT, 0))
			
			count += 1
			if Global.visualize_grid_creation:
				if Global.visualization_speed < 1.0:
					for i in range(int(1 / Global.visualization_speed)):
						await get_tree().create_timer(0.01).timeout
				elif count % int(Global.visualization_speed) == 0:
					await get_tree().create_timer(0.01).timeout
			

func remove_wall(x : float, y : float, custom_text : int = Global.Tiles.PATH):
	grid.set_cell(Vector2(x, y), 0, Vector2(custom_text, 0))

func add_wall(x : float, y : float):
	grid.set_cell(Vector2(x, y), 0, Vector2(Global.Tiles.WALL, 0))


func color_start_and_end():
	grid.set_cell(get_parent().start, 0, Vector2(Global.Tiles.START, 0))
	grid.set_cell(get_parent().end, 0, Vector2(Global.Tiles.END, 0))
	
	
func generate_maze_dfs():
	var stack = [Vector2.ONE]
	var count = 0

	while len(stack) > 0 and Global.is_maze_generating:
		var curr = stack.pop_back()
		grid.set_cell(curr, 0, Vector2(Global.Tiles.PATH, 0))

		var unvisited = []
		var neighbours = {  "up": curr + Vector2(0, -2),
							"right": curr + Vector2(2, 0),
							"down": curr + Vector2(0, 2),
							"left": curr + Vector2(-2, 0)  }
		for dir in neighbours:
			if grid.get_cell_atlas_coords(neighbours[dir]).x == Global.Tiles.DEFAULT:
					unvisited.append(dir)
		
		if len(unvisited) == 0:
			continue
		
		count += 1
		if Global.visualize:
			if Global.visualization_speed < 1.0:
				for i in range(int(1 / Global.visualization_speed)):
					await get_tree().create_timer(0.01).timeout
			elif count % int(Global.visualization_speed) == 0:
				await get_tree().create_timer(0.01).timeout

			
		stack.append(curr)
		
		var random_num = randi_range(1, len(unvisited))
		var dir = unvisited[random_num - 1]
		var neighbour = neighbours[dir]
		
		match dir:
			"up": remove_wall(curr.x, curr.y - 1)
			"right": remove_wall(curr.x + 1, curr.y)
			"down": remove_wall(curr.x, curr.y + 1)
			"left": remove_wall(curr.x - 1, curr.y)
		
		if curr not in get_parent().graph:
			get_parent().graph[curr] = []
		if neighbour not in get_parent().graph:
			get_parent().graph[neighbour] = []
		get_parent().graph[curr].append(neighbour)
		get_parent().graph[neighbour].append(curr)
		
		stack.append(neighbour)
		
	emit_signal("maze_generated")

func gen_simple_maze(dir_tree: Dictionary):
	var prev_node = null
	var maze_size = Global.maze_size
	var count = 0

	for col_idx in range(maze_size):
		var x = 1 + col_idx * 2
		var going_down = col_idx % 2 == 0

		for row_idx in range(maze_size):
			var actual_row = row_idx if going_down else (maze_size - 1 - row_idx)
			var y = 1 + actual_row * 2
			var curr = Vector2(x, y)

			grid.set_cell(curr, 0, Vector2(Global.Tiles.PATH, 0))

			count += 1
			if Global.visualize:
				if Global.visualization_speed < 1.0:
					for j in range(int(1 / Global.visualization_speed)):
						await get_tree().create_timer(0.01).timeout
				elif count % int(Global.visualization_speed) == 0:
					await get_tree().create_timer(0.01).timeout

			if prev_node:
				dir_tree[prev_node] = curr  # Vector2 directo

			if curr not in get_parent().graph:
				get_parent().graph[curr] = []
			if prev_node:
				if prev_node not in get_parent().graph:
					get_parent().graph[prev_node] = []
				get_parent().graph[prev_node].append(curr)
				get_parent().graph[curr].append(prev_node)

			# Pared entre celdas consecutivas dentro de la misma columna
			if row_idx < maze_size - 1:
				if going_down:
					remove_wall(x, y + 1)
				else:
					remove_wall(x, y - 1)

			prev_node = curr

		# Pared entre esta columna y la siguiente, en el extremo donde termina el snake
		if col_idx < maze_size - 1:
			var end_y = 1 + (maze_size - 1) * 2 if going_down else 1
			remove_wall(x + 1, end_y)


func _origin_shift_step(root: Vector2, prev_root, dir_tree: Dictionary):
	grid.set_cell(root, 0, Vector2(Global.Tiles.CURR, 0))
	
	var available = {}
	var neighbours = {  "up":    root + Vector2(0, -2),
						"right": root + Vector2(2, 0),
						"down":  root + Vector2(0, 2),
						"left":  root + Vector2(-2, 0)  }

	for dir in neighbours:
		var coord = grid.get_cell_atlas_coords(neighbours[dir]).x
		if (coord == Global.Tiles.PATH or
			coord == Global.Tiles.DEFAULT or
			coord == Global.Tiles.CURR):
				available[dir] = neighbours[dir]

	var random_dir = available.keys()[randi_range(0, len(available.keys()) - 1)]
	var random_neighbour = available[random_dir]

	# Si el vecino elegido ya apuntaba a alguien, restaurar esa pared
	if random_neighbour in dir_tree:
		var old_target: Vector2 = dir_tree[random_neighbour]
		var wall_pos = Vector2.ZERO
		if old_target.y == random_neighbour.y:
			wall_pos = Vector2(int((old_target.x + random_neighbour.x) / 2), random_neighbour.y)
		else:
			wall_pos = Vector2(random_neighbour.x, int((old_target.y + random_neighbour.y) / 2))
		add_wall(wall_pos.x, wall_pos.y)
		if random_neighbour in get_parent().graph:
			get_parent().graph[random_neighbour].erase(old_target)
		if old_target in get_parent().graph:
			get_parent().graph[old_target].erase(random_neighbour)

	# Romper pared entre root actual y el vecino elegido
	match random_dir:
		"up":    remove_wall(root.x, root.y - 1)
		"right": remove_wall(root.x + 1, root.y)
		"down":  remove_wall(root.x, root.y + 1)
		"left":  remove_wall(root.x - 1, root.y)

	# root ahora apunta al vecino; el vecino se convierte en la nueva raíz (sin puntero saliente)
	dir_tree[root] = random_neighbour
	dir_tree.erase(random_neighbour)

	# Actualizar grafo bidireccional
	if root not in get_parent().graph:
		get_parent().graph[root] = []
	if random_neighbour not in get_parent().graph:
		get_parent().graph[random_neighbour] = []
	if random_neighbour not in get_parent().graph[root]:
		get_parent().graph[root].append(random_neighbour)
	if root not in get_parent().graph[random_neighbour]:
		get_parent().graph[random_neighbour].append(root)

	grid.set_cell(root, 0, Vector2(Global.Tiles.PATH, 0))
	prev_root = root
	root = random_neighbour

	return {"root": root, "prev_root": prev_root}
					
func gen_maze_origin_shift(bad_apple = false, restriction = []):
	var ideal_steps = Global.maze_size * Global.maze_size * Global.maze_size
	var origin_shift_steps = 0

	var dir_tree = {}
	await gen_simple_maze(dir_tree)
	var root = get_parent().end
	var prev_root = null
	var count = 0
	
	while origin_shift_can_gen and Global.is_maze_generating:
		var res = _origin_shift_step(root, prev_root, dir_tree)
		origin_shift_steps += 1

		root = res["root"]
		prev_root = res["prev_root"]
		count += 1
		if Global.visualize:
			if Global.visualization_speed < 1.0:
				for j in range(int(1 / Global.visualization_speed)):
					await get_tree().create_timer(0.01).timeout
			elif count % int(Global.visualization_speed) == 0:
				await get_tree().create_timer(0.01).timeout
		elif origin_shift_steps > ideal_steps:
			break
			
	emit_signal("maze_generated")

func generate_maze_hak():
	var curr = Vector2.ONE
	var count = 0
	var maze_size = Global.maze_size

	while Global.is_maze_generating:
		grid.set_cell(curr, 0, Vector2(Global.Tiles.PATH, 0))

		var unvisited = []
		var neighbours = {  "up": curr + Vector2(0, -2),
							"right": curr + Vector2(2, 0),
							"down": curr + Vector2(0, 2),
							"left": curr + Vector2(-2, 0)  }
		for dir in neighbours:
			if grid.get_cell_atlas_coords(neighbours[dir]).x == Global.Tiles.DEFAULT:
					unvisited.append(dir)
		
		if len(unvisited) == 0:
			for x in range(maze_size * 2 + 1):
				for y in range(maze_size * 2 + 1):
					var cell = Vector2(x, y)
					neighbours = {  "up": cell + Vector2(0, -2),
								"right": cell + Vector2(2, 0),
								"down": cell + Vector2(0, 2),
								"left": cell + Vector2(-2, 0)  }
					for dir in neighbours:
						if grid.get_cell_atlas_coords(neighbours[dir]).x == Global.Tiles.DEFAULT:
								unvisited.append(dir)
				
					if len(unvisited) > 0:
						curr = cell
						break
				if len(unvisited) > 0:
					break
		
		if len(unvisited) == 0:
			break
		
		count += 1
		if Global.visualize:
			if Global.visualization_speed < 1.0:
				for i in range(int(1 / Global.visualization_speed)):
					await get_tree().create_timer(0.01).timeout
			elif count % int(Global.visualization_speed) == 0:
				await get_tree().create_timer(0.01).timeout
			
		var random_num = randi_range(1, len(unvisited))
		var dir = unvisited[random_num - 1]
		var neighbour = neighbours[dir]
		
		match dir:
			"up": remove_wall(curr.x, curr.y - 1)
			"right": remove_wall(curr.x + 1, curr.y)
			"down": remove_wall(curr.x, curr.y + 1)
			"left": remove_wall(curr.x - 1, curr.y)
		
		if curr not in get_parent().graph:
			get_parent().graph[curr] = []
		if neighbour not in get_parent().graph:
			get_parent().graph[neighbour] = []
		get_parent().graph[curr].append(neighbour)
		get_parent().graph[neighbour].append(curr)
		
		curr = neighbour
		
	emit_signal("maze_generated")

func log2(n: float) -> float:
	return log(n) / log(2)

func _on_stop_origin_shift_pressed() -> void:
	origin_shift_can_gen = false
	
