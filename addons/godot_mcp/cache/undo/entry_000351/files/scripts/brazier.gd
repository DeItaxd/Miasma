extends StaticBody2D

signal went_out

const ZoneShader := preload("res://shaders/miasma_zone.gdshader")
const DamagePopup := preload("res://scripts/damage_popup.gd")

@export_group("Zone")
@export var max_radius := 288.0
@export var miasma_damage := 1
@export var miasma_tick := 1.0

@export_group("Haze Edge")
@export var jag_amount := 10.0
@export var jag_speed := 1.0

@export_group("Fuel")
@export var max_fuel := 100.0
@export var start_fuel := 100.0
@export var burn_rate := 2.0
@export var herb_fuel := 20.0
@export var deposit_range := 36.0

var fuel := 0.0
var radius := 0.0
var is_out := false
var zone_material: ShaderMaterial
var tick_timer := 0.0
var player: Node2D

@onready var overlay: ColorRect = $MiasmaOverlay
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	fuel = start_fuel
	zone_material = ShaderMaterial.new()
	zone_material.shader = ZoneShader
	zone_material.set_shader_parameter("center", global_position)
	overlay.material = zone_material
	player = get_tree().get_first_node_in_group("player")
	update_radius()


func _physics_process(delta: float) -> void:
	if not is_out:
		fuel = maxf(fuel - burn_rate * delta, 0.0)
		update_radius()
	if not is_instance_valid(player):
		return
	if not is_out and player.herbs > 0 and player.global_position.distance_to(global_position) <= deposit_range:
		add_fuel(player.take_herbs() * herb_fuel)
	player.in_safe_zone = is_inside(player.global_position)
	if player.in_safe_zone:
		tick_timer = 0.0
		return
	tick_timer += delta
	if tick_timer >= miasma_tick:
		tick_timer -= miasma_tick
		player.take_damage(miasma_damage)


func is_inside(point: Vector2) -> bool:
	return point.distance_to(global_position) <= radius


func add_fuel(amount: float) -> void:
	if is_out:
		return
	fuel = minf(fuel + amount, max_fuel)
	update_radius()
	DamagePopup.spawn(self, "+%d" % roundi(amount), Color("7ed957"))


func drain_fuel(amount: float) -> void:
	if is_out:
		return
	fuel = maxf(fuel - amount, 0.0)
	update_radius()
	DamagePopup.spawn(self, "-%d" % roundi(amount), Color("ff8a3d"))


func update_radius() -> void:
	radius = max_radius * sqrt(fuel / max_fuel)
	zone_material.set_shader_parameter("radius", radius)
	if fuel <= 0.0 and not is_out:
		is_out = true
		sprite.modulate = Color(0.3, 0.3, 0.3)
		if is_instance_valid(player):
			player.add_shake(6.0)
		went_out.emit()
