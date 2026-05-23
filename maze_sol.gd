extends Node2D
class_name MazeSol

@onready var grid : TileMapLayer= get_node("../grid")
signal maze_solved

class Heapq:
	var heap = []
	
	func _init(starting_node) -> void: 
		push(starting_node)
		
	func push(value):
		heap.append(value)
		_heapify_up(len(heap) - 1)
	
	func pop():
		if len(heap) == 0:
			return null
		var value = heap[0]
		heap[0] = heap[-1]
		heap.pop_back()
		if len(heap) > 0:
			_heapify_down(0)
		return value
	
	func peek():
		if len(heap) == 0:
			return null
		return heap[0]
	
	func _heapify_up(i : int):
		while i > 0:
			var parent_i = floor((i - 1) / 2)
			var parent = heap[parent_i]
			
			if parent[0] <= heap[i][0]:
				break
			heap[parent_i] = heap[i]
			heap[i] = parent
			
			i = parent_i
	
	func _heapify_down(i : int):
		while true:
			var left = i * 2 + 1
			var right = i * 2 + 2
			var smallest = i
			
			if left < len(heap) and heap[left][0] < heap[smallest][0]:
				smallest = left
			if right < len(heap) and heap[right][0] < heap[smallest][0]:
				smallest = right
			if i == smallest:
				break
				
			var temp = heap[i]
			heap[i] = heap[smallest]
			heap[smallest] = temp
			
			i = smallest


func h(from : Vector2, to : Vector2) -> float:
	return abs(from.x - to.x) + abs(from.y - to.y)
	
	
func solve_maze_bidir_a_star(graph : Dictionary, start : Vector2, end : Vector2):
	var heap1 = Heapq.new([h(start, end), 0, start])
	var heap2 = Heapq.new([h(end, start), 0, end])
	var parents1 = {start: null}
	var parents2 = {start: null}
	var visited1 = {}
	var visited2 = {}
	var total_visited = {}
	var count = 0
	var sol1 = []
	var sol2 = []
	
	while Global.is_maze_solving:
		if ((not heap1.heap and not heap2.heap) or
			(sol1 and sol2)):
			break
		if heap1.heap and !sol1:
			sol1 = await _a_star_step(heap1, parents1, graph, start, end, visited1, total_visited)
		if heap2.heap and !sol2:
			sol2 = await _a_star_step(heap2, parents2, graph, end, start, visited2, total_visited)
			
		count -= 1
		if Global.visualize:
			if Global.visualization_speed < 1.0:
				for i in range(int(1 / Global.visualization_speed)):
					await get_tree().create_timer(0.01).timeout
			elif count % int(Global.visualization_speed) == 0:
				await get_tree().create_timer(0.01).timeout
			
	emit_signal("maze_solved")
	sol2.reverse()
	var all_parents = {}
	for k in parents1.keys():
		all_parents[k] = parents1[k]
	for k in parents2.keys():
		all_parents[k] = parents2[k]
	
	await visualize_sol(sol1 + sol2, all_parents)
							
							
func _a_star_step(heap : Heapq, parents : Dictionary,
				graph : Dictionary, start : Vector2, end : Vector2,
				visited : Dictionary, total_visited : Dictionary = {}) -> Array:
					
	var f = heap.peek()[0]
	var g = heap.peek()[1]
	var curr =  heap.pop()[2]
		
	if curr == end or curr in total_visited:
		var sol = get_solution(parents, start, curr)
		fill_path(curr, parents[curr], Global.Tiles.VISITED)
		return sol
			
	if curr in visited:
		return []

	visited[curr] = null
	total_visited[curr] = null
		
			
	for node in graph[curr]:
		if node in visited:
			continue
		var g_new = g + 2
		var h_new = h(node, end)
		var f_new = g_new + h_new

		parents[node] = curr
				
		heap.push([f_new, g_new, node])
						
	if curr in parents and parents[curr]:
		fill_path(curr, parents[curr], Global.Tiles.VISITED)
	
	return []
	
func solve_maze_a_star(graph : Dictionary, start : Vector2, end : Vector2,
						total_visited : Dictionary = {}) -> Array:
	var heap = Heapq.new([h(start, end), 0, start])
	var parents = {start: null}
	var visited = {}
	var count = 0
	
	while heap and Global.is_maze_solving:
		var sol = await _a_star_step(heap, parents, graph, start, end, visited, total_visited)
		if sol:
			emit_signal("maze_solved")
			await visualize_sol(sol, parents)
			return sol

		count += 1
		if Global.visualize:
			if Global.visualization_speed < 1.0:
				for i in range(int(1 / Global.visualization_speed)):
					await get_tree().create_timer(0.01).timeout
			elif count % int(Global.visualization_speed) == 0:
				await get_tree().create_timer(0.01).timeout
	
	return []


func solve_maze_dijkstra(graph : Dictionary, start : Vector2, end : Vector2) -> Array:
	var heap = Heapq.new([0, start])
	var parents = {start: null}
	var visited = {}
	
	var count = 0
	
	while heap and Global.is_maze_solving:
		var g = heap.peek()[0]
		var curr =  heap.pop()[1]
		
		if curr == end:
			emit_signal("maze_solved")
			fill_path(curr, parents[curr], Global.Tiles.VISITED)
			var sol = get_solution(parents, start, end)
			await visualize_sol(sol, parents)
			return sol
			
		if curr in visited:
			continue
			
		count += 1
		if Global.visualize:
			if Global.visualization_speed < 1.0:
				for i in range(int(1 / Global.visualization_speed)):
					await get_tree().create_timer(0.01).timeout
			elif count % int(Global.visualization_speed) == 0:
				await get_tree().create_timer(0.01).timeout
			
		visited[curr] = null
		if curr in parents and parents[curr]:
			fill_path(curr, parents[curr], Global.Tiles.VISITED)
			
		for node in graph[curr]:
			if node in visited:
				continue
			var g_new = g + 2
			
			parents[node] = curr
			heap.push([g_new, node])
	
	return []
	
	
func fill_path(curr : Vector2, prev : Vector2, texture : int) -> void:
	var wall = Vector2.ZERO
	
	if prev.y == curr.y:
		wall = Vector2(int((prev.x + curr.x) / 2), curr.y)
	if prev.x == curr.x:
		wall = Vector2(curr.x, int((prev.y + curr.y) / 2))
			
	if curr != get_parent().start and curr != get_parent().end:
		grid.set_cell(curr, 0, Vector2(texture, 0))
	grid.set_cell(wall, 0, Vector2(texture, 0))
			
			
func get_solution(parents : Dictionary, start : Vector2, end : Vector2) -> Array:
	var sol = []
	var curr = end
	
	while curr != start:
		sol.append(curr)
		curr = parents[curr]
	sol.reverse()
	return [start] + sol
	

func visualize_sol(sol : Array, parents : Dictionary) -> void:
	var count = 0
	for i in range(1, len(sol)):
		count += 1
		if Global.visualize:
			if Global.visualization_speed < 1.0:
				for j in range(int(1 / Global.visualization_speed)):
					await get_tree().create_timer(0.01).timeout
			elif count % int(Global.visualization_speed) == 0:
				await get_tree().create_timer(0.01).timeout
		fill_path(sol[i], sol[i - 1], Global.Tiles.FOUND)
