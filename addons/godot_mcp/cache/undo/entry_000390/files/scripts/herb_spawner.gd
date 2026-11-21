extends Node2D

const HerbScene := preload("res://scenes/herb.tscn")
const WALL_TILE := Vector2i(2, 0)

@export var ground_path: NodePath = ^"../Ground"
@export var max_herbs := 6
@export var initial_herbs := 4
@export var spawn_interval := 3.0
@export var arena_min := Vector2(-592, -336)
@export var arena_max := Vector2(592, 336)
@export var zone_margin := 24.0
@export_range(0.0, 1.0) var inside_chance := 0.7
@export var brazier_clearance := 48.0

var spawn_timer := 0.0
var brazier: Node2D

@onready var ground: TileMapLayer = get_node(ground_path)


func _ready() -> void:
	brazier = get_tree().get_first_node_in_group("brazier")
	for i in initial_herbs:
		spawn_herb()


func _physics_process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		if get_child_count() < max_herbs:
			spawn_herb()


func spawn_herb() -> void:
	var want_inside := randf() < inside_chance
	for attempt in 60:
		var pos := Vector2(randf_range(arena_min.x, arena_max.x), randf_range(arena_min.y, arena_max.y))
		if is_instance_valid(brazier):
			var dist := pos.distance_to(brazier.global_position)
			if dist < brazier_clearance:
				continue
			var inside_ok: bool = dist <= brazier.radius - zone_margin
			var outside_ok: bool = dist >= brazier.radius + zone_margin
			if attempt < 30 and (inside_ok != want_inside or not (inside_ok or outside_ok)):
				continue
			if not (inside_ok or outside_ok):
				continue
		var cell := ground.local_to_map(ground.to_local(pos))
		if ground.get_cell_source_id(cell) == -1 or ground.get_cell_atlas_coords(cell) == WALL_TILE:
			continue
		var herb := HerbScene.instantiate()
		add_child(herb)
		herb.global_position = pos
		return
