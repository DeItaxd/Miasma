extends StaticBody2D

signal went_out

const ZoneShader := preload("res://shaders/miasma_zone.gdshader")
const DamagePopup := preload("res://scripts/damage_popup.gd")

@export_group("Zone")
@export var max_radius := 288.0
@export var miasma_damage := 6
@export var miasma_tick := 1.0
@export var radius_ease := 6.0

@export_group("Last Stand")
@export var last_stand_ramp := 0.4
@export var last_stand_max_damage := 60
@export var last_stand_thicken := 0.006
@export var last_stand_max_alpha := 0.75

@export_group("Haze Edge")
@export var jag_amount := 16.0
@export var jag_speed := 1.0

@export_group("Fuel")
@export var max_fuel := 100.0
@export var start_fuel := 100.0
@export var burn_rate := 2.0
@export var herb_fuel := 20.0
@export var deposit_range := 36.0

var fuel := 0.0
var radius := 0.0
var target_radius := 0.0
var is_out := false
var zone_material: ShaderMaterial
var tick_timer := 0.0
var haze_time := 0.0
var out_time := 0.0
var base_tint: Color
var player: Node2D

@onready var overlay: ColorRect = $MiasmaOverlay
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	fuel = start_fuel
	zone_material = ShaderMaterial.new()
	zone_material.shader = ZoneShader
	zone_material.set_shader_parameter("center", global_position)
	zone_material.set_shader_parameter("jag", jag_amount)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	var fog := NoiseTexture2D.new()
	fog.width = 256
	fog.height = 256
	fog.seamless = true
	fog.noise = noise
	zone_material.set_shader_parameter("fog_noise", fog)
	overlay.material = zone_material
	var tint_default: Variant = RenderingServer.shader_get_parameter_default(ZoneShader.get_rid(), "tint")
	base_tint = tint_default if tint_default is Color else Color(0.55, 0.48, 0.16, 0.42)
	player = get_tree().get_first_node_in_group("player")
	update_radius()
	radius = target_radius
	zone_material.set_shader_parameter("radius", radius)


func _physics_process(delta: float) -> void:
	haze_time += delta * jag_speed
	zone_material.set_shader_parameter("time", haze_time)
	if not is_out:
		fuel = maxf(fuel - burn_rate * delta, 0.0)
		update_radius()
	else:
		out_time += delta
		var thick := Color(base_tint.r, base_tint.g, base_tint.b, minf(base_tint.a + out_time * last_stand_thicken, last_stand_max_alpha))
		zone_material.set_shader_parameter("tint", thick)
	radius = lerpf(radius, target_radius, 1.0 - exp(-radius_ease * delta))
	zone_material.set_shader_parameter("radius", radius)
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
		player.take_damage(haze_damage(), true)


func haze_damage() -> int:
	if not is_out:
		return miasma_damage
	return mini(miasma_damage + roundi(out_time * last_stand_ramp), last_stand_max_damage)


func is_inside(point: Vector2) -> bool:
	return point.distance_to(global_position) <= edge_radius(point)


func edge_radius(point: Vector2) -> float:
	var amount := minf(jag_amount, radius * 0.25)
	var u := (point - global_position).angle() / TAU
	var wave := 0.45 * tri(u * 11.0 + haze_time * 0.04) + 0.35 * tri(u * 31.0 - haze_time * 0.07) + 0.2 * tri(u * 67.0 + haze_time * 0.11)
	return radius + amount * wave


func tri(x: float) -> float:
	return 1.0 - 4.0 * absf(fposmod(x, 1.0) - 0.5)


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
	target_radius = max_radius * sqrt(fuel / max_fuel)
	if fuel <= 0.0 and not is_out:
		is_out = true
		sprite.modulate = Color(0.3, 0.3, 0.3)
		if is_instance_valid(player):
			player.add_shake(6.0)
		went_out.emit()
