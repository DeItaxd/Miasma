extends Node

const ChoryScene := preload("res://scenes/chory.tscn")
const DouserScene := preload("res://scenes/douser.tscn")
const WALL_TILE := Vector2i(2, 0)

@export var ground_path: NodePath = ^"../Ground"
@export var entities_path: NodePath = ^"../Entities"
@export var first_spawn_delay := 3.0
@export var start_interval := 4.0
@export var min_interval := 1.2
@export var ramp_time := 180.0
@export var max_alive := 12
@export var min_player_distance := 200.0
@export var spawn_outside_zone := true
@export var arena_min := Vector2(-592, -336)
@export var arena_max := Vector2(592, 336)

var elapsed := 0.0
var spawn_timer := 0.0
var player: Node2D
var brazier: Node2D

@onready var ground: TileMapLayer = get_node(ground_path)
@onready var entities: Node2D = get_node(entities_path)


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	brazier = get_tree().get_first_node_in_group("brazier")
	spawn_timer = start_interval - first_spawn_delay


func _physics_process(delta: float) -> void:
	elapsed += delta
	spawn_timer += delta
	if spawn_timer >= current_interval():
		spawn_timer = 0.0
		if get_tree().get_nodes_in_group("enemies").size() < max_alive:
			spawn_enemy()


func current_interval() -> float:
	return lerpf(start_interval, min_interval, clampf(elapsed / ramp_time, 0.0, 1.0))


func spawn_enemy() -> void:
	for attempt in 40:
		var pos := Vector2(randf_range(arena_min.x, arena_max.x), randf_range(arena_min.y, arena_max.y))
		if is_instance_valid(player) and pos.distance_to(player.global_position) < min_player_distance:
			continue
		if spawn_outside_zone and attempt < 30 and is_instance_valid(brazier) and pos.distance_to(brazier.global_position) <= brazier.radius:
			continue
		var cell := ground.local_to_map(ground.to_local(pos))
		if ground.get_cell_source_id(cell) == -1 or ground.get_cell_atlas_coords(cell) == WALL_TILE:
			continue
		var enemy := ChoryScene.instantiate()
		entities.add_child(enemy)
		enemy.global_position = pos
		return
