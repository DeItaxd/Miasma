extends Node

const ChoryScene := preload("res://scenes/chory.tscn")
const RatScene := preload("res://scenes/rat.tscn")
const CougherScene := preload("res://scenes/cougher.tscn")
const Props := preload("res://scripts/props.gd")
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

@export_group("Rat")
@export var rat_first_delay := 25.0
@export var rat_start_interval := 20.0
@export var rat_min_interval := 10.0
@export var max_rats := 2

@export_group("Cougher")
@export var cougher_first_delay := 45.0
@export var cougher_start_interval := 25.0
@export var cougher_min_interval := 12.0
@export var max_coughers := 3

@export_group("Last Stand")
@export var frenzy_interval := 0.8
@export var frenzy_max_alive := 20

var frenzy := false
var elapsed := 0.0
var spawn_timer := 0.0
var rat_timer := 0.0
var cougher_timer := 0.0
var player: Node2D
var brazier: Node2D

@onready var ground: TileMapLayer = get_node(ground_path)
@onready var entities: Node2D = get_node(entities_path)


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	brazier = get_tree().get_first_node_in_group("brazier")
	spawn_timer = start_interval - first_spawn_delay
	rat_timer = rat_start_interval - rat_first_delay
	cougher_timer = cougher_start_interval - cougher_first_delay
	if brazier:
		brazier.went_out.connect(_on_fire_out)


func _physics_process(delta: float) -> void:
	elapsed += delta
	spawn_timer += delta
	rat_timer += delta
	cougher_timer += delta
	if cougher_timer >= lerpf(cougher_start_interval, cougher_min_interval, ramp()):
		cougher_timer = 0.0
		if get_tree().get_nodes_in_group("coughers").size() < max_coughers:
			spawn_enemy(CougherScene)
	if spawn_timer >= current_interval():
		spawn_timer = 0.0
		var cap := frenzy_max_alive if frenzy else max_alive
		if get_tree().get_nodes_in_group("enemies").size() < cap:
			spawn_enemy(ChoryScene)
	if not frenzy and rat_timer >= lerpf(rat_start_interval, rat_min_interval, ramp()):
		rat_timer = 0.0
		if get_tree().get_nodes_in_group("rats").size() < max_rats:
			spawn_enemy(RatScene)


func ramp() -> float:
	return clampf(elapsed / ramp_time, 0.0, 1.0)


func current_interval() -> float:
	if frenzy:
		return frenzy_interval
	return lerpf(start_interval, min_interval, ramp())


func _on_fire_out() -> void:
	frenzy = true
	spawn_timer = frenzy_interval


func spawn_enemy(scene: PackedScene) -> void:
	for attempt in 40:
		var pos := Vector2(randf_range(arena_min.x, arena_max.x), randf_range(arena_min.y, arena_max.y))
		if is_instance_valid(player) and pos.distance_to(player.global_position) < min_player_distance:
			continue
		if spawn_outside_zone and attempt < 30 and is_instance_valid(brazier) and pos.distance_to(brazier.global_position) <= brazier.radius:
			continue
		var cell := ground.local_to_map(ground.to_local(pos))
		if ground.get_cell_source_id(cell) == -1 or ground.get_cell_atlas_coords(cell) == WALL_TILE:
			continue
		if Props.blocked(get_tree(), pos, 12.0):
			continue
		var enemy := scene.instantiate()
		entities.add_child(enemy)
		enemy.global_position = pos
		return
