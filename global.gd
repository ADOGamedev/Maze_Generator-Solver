extends Node

var maze_size = 15

var visualize = false
var visualization_speed = 30.0
var visualize_grid_creation = false

var sol_algorithm = 0
var gen_algorithm = 0

enum Tiles { END, FOUND, DEFAULT, PATH, START, VISITED, WALL, CURR }

var maze_generated = false
var is_maze_generating = false
var is_maze_solving = false
