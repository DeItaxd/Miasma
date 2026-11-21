extends Node

const RockShader := preload("res://shaders/rock.gdshader")
const TreeShader := preload("res://shaders/tree.gdshader")
const FLOOR := Vector2i(0, 0)
const WALL := Vector2i(2, 0)

@export var rock_count := Vector2i(7, 10)
@export var tree_count := Vector2i(4, 6)
@export var rock_size := Vector2(14.0, 26.0)
@export var tree_size := Vector2(22.0, 30.0)
@export var walk_gap := 40.0
@export var brazier_clearance := 96.0
@export var start_clearance := 56.0
@export var player_start := Vector2(0, 96)
@export var behind_fade := 0.45

var trees: Array[Dictionary] = []
var player: Node2D


static func blocked(tree: SceneTree, pos: Vector2, margin: float) -> bool:
	for prop in tree.get_nodes_in_group("obstacles"):
		if pos.distance_to(prop.global_position) < float(prop.get_meta("radius")) + margin:
			return true
	return false


func build(ground: TileMapLayer, entities: Node2D, brazier: Node2D) -> void:
	player = get_tree().get_first_node_in_group("player")
	var used := ground.get_used_rect()
	for cell in ground.get_used_cells():
		if ground.get_cell_atlas_coords(cell) != WALL:
			continue
		var edge := cell.x == used.position.x or cell.x == used.end.x - 1 or cell.y == used.position.y or cell.y == used.end.y - 1
		if not edge:
			ground.set_cell(cell, 0, FLOOR)
	var half_tile := Vector2(ground.tile_set.tile_size) * 0.5
	var low := ground.map_to_local(used.position + Vector2i(1, 1)) - half_tile
	var high := ground.map_to_local(used.end - Vector2i(2, 2)) + half_tile
	var placed: Array[Vector3] = []
	for i in randi_range(tree_count.x, tree_count.y):
		var size := randf_range(tree_size.x, tree_size.y)
		var pos := find_spot(low, high, size, size * 0.6, placed, brazier)
		if pos != Vector2.INF:
			placed.append(Vector3(pos.x, pos.y, size * 0.6))
			add_tree(entities, pos, size)
	for i in randi_range(rock_count.x, rock_count.y):
		var size := randf_range(rock_size.x, rock_size.y)
		var pos := find_spot(low, high, size, size, placed, brazier)
		if pos != Vector2.INF:
			placed.append(Vector3(pos.x, pos.y, size))
			add_rock(entities, pos, size)


func find_spot(low: Vector2, high: Vector2, size: float, footprint: float, placed: Array[Vector3], brazier: Node2D) -> Vector2:
	for attempt in 80:
		var pos := Vector2(randf_range(low.x + size + 8.0, high.x - size - 8.0), randf_range(low.y + size + 16.0, high.y - size - 8.0)).round()
		if is_instance_valid(brazier) and pos.distance_to(brazier.global_position) < brazier_clearance + size:
			continue
		if pos.distance_to(player_start) < start_clearance + size:
			continue
		var crowded := false
		for other in placed:
			if pos.distance_to(Vector2(other.x, other.y)) < footprint + other.z + walk_gap:
				crowded = true
				break
		if not crowded:
			return pos
	return Vector2.INF


func make_body(entities: Node2D, pos: Vector2, collision_radius: float, block_radius: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	body.set_meta("radius", block_radius)
	body.add_to_group("obstacles")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = collision_radius
	shape.shape = circle
	body.add_child(shape)
	entities.add_child(body)
	return body


func make_visual(body: Node2D, shader: Shader, size: Vector2, anchor: float) -> ColorRect:
	var visual := ColorRect.new()
	visual.size = size
	visual.position = Vector2(-size.x * 0.5, -size.y * anchor).round()
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look := ShaderMaterial.new()
	look.shader = shader
	look.set_shader_parameter("size", size)
	look.set_shader_parameter("seed", randf() * 100.0)
	visual.material = look
	body.add_child(visual)
	return visual


func add_rock(entities: Node2D, pos: Vector2, radius: float) -> void:
	var body := make_body(entities, pos, radius, radius)
	make_visual(body, RockShader, Vector2(radius * 2.8, radius * 2.8).round(), 0.72)


func add_tree(entities: Node2D, pos: Vector2, canopy: float) -> void:
	var body := make_body(entities, pos, maxf(5.0, canopy * 0.2), canopy * 0.6)
	var visual := make_visual(body, TreeShader, Vector2(canopy * 3.0, canopy * 2.6).round(), 0.94)
	trees.append({"body": body, "visual": visual, "canopy": canopy})


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	for tree in trees:
		var body: Node2D = tree["body"]
		var visual: ColorRect = tree["visual"]
		var canopy: float = tree["canopy"]
		var offset := player.global_position - body.global_position
		var hidden := offset.y < 0.0 and offset.y > -canopy * 2.5 and absf(offset.x) < canopy * 1.1
		visual.modulate.a = move_toward(visual.modulate.a, behind_fade if hidden else 1.0, delta * 4.0)
