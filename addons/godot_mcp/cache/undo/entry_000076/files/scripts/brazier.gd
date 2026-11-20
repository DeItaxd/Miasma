extends StaticBody2D

const ZoneShader := preload("res://shaders/miasma_zone.gdshader")

@export var radius := 192.0:
	set(value):
		radius = value
		if zone_material:
			zone_material.set_shader_parameter("radius", radius)
@export var miasma_damage := 1
@export var miasma_tick := 1.0

var zone_material: ShaderMaterial
var tick_timer := 0.0
var player: Node2D

@onready var overlay: ColorRect = $MiasmaOverlay


func _ready() -> void:
	zone_material = ShaderMaterial.new()
	zone_material.shader = ZoneShader
	zone_material.set_shader_parameter("center", global_position)
	zone_material.set_shader_parameter("radius", radius)
	overlay.material = zone_material
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if is_inside(player.global_position):
		tick_timer = 0.0
		return
	tick_timer += delta
	if tick_timer >= miasma_tick:
		tick_timer -= miasma_tick
		player.take_damage(miasma_damage)


func is_inside(point: Vector2) -> bool:
	return point.distance_to(global_position) <= radius
