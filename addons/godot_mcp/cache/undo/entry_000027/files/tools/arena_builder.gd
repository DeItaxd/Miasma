@tool
extends TileMapLayer

const FLOOR := Vector2i(0, 0)
const FLOOR_ALT := Vector2i(1, 0)
const WALL := Vector2i(2, 0)


func build_arena() -> void:
	clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1347
	var half := Vector2i(20, 12)
	for x in range(-half.x, half.x):
		for y in range(-half.y, half.y):
			var cell := Vector2i(x, y)
			var edge := x == -half.x or x == half.x - 1 or y == -half.y or y == half.y - 1
			if edge:
				set_cell(cell, 0, WALL)
			else:
				set_cell(cell, 0, FLOOR_ALT if rng.randf() < 0.18 else FLOOR)
	var pillars: Array[Vector2i] = [Vector2i(-10, -6), Vector2i(8, -6), Vector2i(-10, 4), Vector2i(8, 4)]
	for origin in pillars:
		for x in 2:
			for y in 2:
				set_cell(origin + Vector2i(x, y), 0, WALL)
