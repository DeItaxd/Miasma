extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal herbs_changed(current: int, maximum: int)
signal died

const ENEMY_MASK := 4
const DamagePopup := preload("res://scripts/damage_popup.gd")
const ThrownScythe := preload("res://scenes/thrown_scythe.tscn")

@export var max_health := 10
@export var invulnerable_time := 0.6
@export var max_carry := 3

@export var max_speed := 140.0
@export var acceleration := 1200.0
@export var friction := 1400.0

@export_group("Light Attack")
@export var light_damage := 1
@export var light_cooldown := 0.28
@export var light_reach := 20.0
@export var light_size := Vector2(22, 30)
@export var light_knockback := 150.0
@export var light_lunge := 200.0
@export var light_active_time := 0.12

@export_group("Heavy Attack")
@export var heavy_damage := 2
@export var heavy_cooldown := 0.5
@export var heavy_reach := 26.0
@export var heavy_size := Vector2(34, 46)
@export var heavy_knockback := 450.0
@export var heavy_lunge := 360.0
@export var heavy_active_time := 0.18
@export var heavy_tint := Color(1.0, 0.8, 0.45)

@export_group("Combo")
@export var combo_window := 0.6
@export var input_buffer_time := 0.15

@export_group("Spin")
@export var spin_hold_time := 0.3
@export var spin_damage := 2
@export var spin_radius := 44.0
@export var spin_knockback := 380.0
@export var spin_time := 0.3
@export var spin_cooldown := 0.6
@export var spin_tint := Color(0.7, 0.9, 1.0)

@export_group("Throw")
@export var throw_speed := 340.0
@export var throw_return_speed := 420.0
@export var throw_range := 230.0
@export var throw_damage := 2
@export var throw_knockback := 250.0
@export var throw_cooldown := 0.25

@export_group("Reaper's Toss")
@export var toss_damage := 2
@export var toss_speed := 380.0
@export var toss_range := 260.0
@export var toss_knockback := 120.0
@export var toss_pull := 520.0
@export var toss_size := 1.4
@export var toss_tint := Color(1.0, 0.8, 0.45)

@export_group("Catch")
@export var catch_window := 0.8
@export var catch_flash := Color(1.6, 1.6, 1.2)

@export_group("Scoop")
@export var scoop_damage := 1
@export var scoop_radius := 30.0
@export var scoop_knockback := 300.0
@export var scoop_time := 0.2

@export_group("Scythe Look")
@export var hold_angle := -70.0
@export var hold_offset := Vector2(7, -5)
@export var light_arc := 150.0
@export var heavy_arc := 220.0
@export var windup_angle := 110.0
@export var scythe_follow := 18.0

@export_group("Regen")
@export var regen_delay := 2.0
@export var regen_interval := 1.0
@export var regen_amount := 1

@export_group("Feel")
@export var hurt_shake := 3.0
@export var light_shake := 0.8
@export var heavy_shake := 2.5
@export var light_hitstop := 0.02
@export var heavy_hitstop := 0.07
@export var shake_decay := 12.0
@export var face_hold := 0.3

var shake := 0.0
var current_heavy := false
var in_safe_zone := false
var time_since_hurt := 0.0
var regen_timer := 0.0

var health := 0
var herbs := 0
var invulnerable_timer := 0.0
var facing := Vector2.DOWN
var attack_timer := 0.0
var active_timer := 0.0
var combo_step := 0
var combo_timer := 0.0
var buffer_timer := 0.0
var current_damage := 1
var current_knockback := 0.0
var current_reach := 0.0
var attack_dir := Vector2.RIGHT
var already_hit: Array[Object] = []
var attack_shape := RectangleShape2D.new()
var spin_shape := CircleShape2D.new()
var charging := false
var charge_time := 0.0
var spinning := false
var has_scythe := true
var throw_buffer := 0.0
var caught_combo := false
var face_timer := 0.0
var spin_radius_now := 0.0
var spin_time_now := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_pivot: Node2D = $AttackPivot
@onready var slash: Sprite2D = $AttackPivot/Slash
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	health = max_health
	spin_shape.radius = spin_radius
	slash.visible = false


func _process(delta: float) -> void:
	shake = move_toward(shake, 0.0, shake_decay * delta)
	camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))


func add_shake(amount: float) -> void:
	shake = maxf(shake, amount)


func hitstop(duration: float) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = 0.05
	get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)


func _physics_process(delta: float) -> void:
	invulnerable_timer = maxf(invulnerable_timer - delta, 0.0)
	time_since_hurt += delta
	update_regen(delta)
	attack_timer = maxf(attack_timer - delta, 0.0)
	combo_timer = maxf(combo_timer - delta, 0.0)
	buffer_timer = maxf(buffer_timer - delta, 0.0)
	throw_buffer = maxf(throw_buffer - delta, 0.0)
	face_timer = maxf(face_timer - delta, 0.0)
	if Input.is_action_just_pressed("attack"):
		buffer_timer = input_buffer_time
	if Input.is_action_just_pressed("throw"):
		throw_buffer = input_buffer_time
	if throw_buffer > 0.0 and has_scythe and active_timer <= 0.0:
		throw_buffer = 0.0
		throw_scythe()
	if charging:
		update_charge(delta)
	elif has_scythe and buffer_timer > 0.0 and attack_timer == 0.0:
		buffer_timer = 0.0
		if combo_step == 2 and combo_timer > 0.0:
			charging = true
			charge_time = 0.0
		else:
			start_attack()
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		facing = input.normalized()
		velocity = velocity.move_toward(input * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	if spinning:
		sprite.flip_h = cos(attack_pivot.rotation) < 0.0
	elif face_timer == 0.0 and input.x != 0.0:
		sprite.flip_h = input.x < 0.0
	if active_timer > 0.0:
		active_timer -= delta
		if spinning:
			attack_pivot.rotation += TAU / spin_time_now * delta
		check_hits()
		if active_timer <= 0.0:
			slash.visible = false
			spinning = false


func take_damage(amount: int) -> void:
	if invulnerable_timer > 0.0 or health <= 0:
		return
	health = maxi(health - amount, 0)
	invulnerable_timer = invulnerable_time
	time_since_hurt = 0.0
	health_changed.emit(health, max_health)
	DamagePopup.spawn(self, amount, Color("ff5a4f"))
	add_shake(hurt_shake)
	sprite.modulate = Color(10, 10, 10)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if health == 0:
		died.emit()


func update_regen(delta: float) -> void:
	if not in_safe_zone or health >= max_health or health <= 0 or time_since_hurt < regen_delay:
		regen_timer = 0.0
		return
	regen_timer += delta
	if regen_timer >= regen_interval:
		regen_timer -= regen_interval
		heal(regen_amount)


func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)
	DamagePopup.spawn(self, "+%d" % amount, Color("7ed957"))


func add_herb() -> bool:
	if herbs >= max_carry:
		return false
	herbs += 1
	herbs_changed.emit(herbs, max_carry)
	return true


func take_herbs() -> int:
	var count := herbs
	herbs = 0
	herbs_changed.emit(herbs, max_carry)
	return count


func start_attack() -> void:
	if combo_timer == 0.0:
		combo_step = 0
	var heavy := combo_step == 2
	current_heavy = heavy
	current_damage = heavy_damage if heavy else light_damage
	current_knockback = heavy_knockback if heavy else light_knockback
	current_reach = heavy_reach if heavy else light_reach
	attack_shape.size = heavy_size if heavy else light_size
	attack_timer = heavy_cooldown if heavy else light_cooldown
	active_timer = heavy_active_time if heavy else light_active_time
	combo_step = 0 if heavy else combo_step + 1
	combo_timer = 0.0 if heavy else combo_window
	caught_combo = false
	already_hit.clear()
	attack_dir = aim()
	face(attack_dir)
	attack_pivot.rotation = attack_dir.angle()
	slash.position = Vector2(current_reach, 0)
	slash.scale = attack_shape.size / slash.texture.get_size()
	slash.modulate = heavy_tint if heavy else Color.WHITE
	slash.visible = true
	velocity += attack_dir * (heavy_lunge if heavy else light_lunge)


func aim() -> Vector2:
	var dir := (get_global_mouse_position() - attack_pivot.global_position).normalized()
	return facing if dir == Vector2.ZERO else dir


func face(dir: Vector2) -> void:
	if dir.x != 0.0:
		sprite.flip_h = dir.x < 0.0
	face_timer = face_hold


func update_charge(delta: float) -> void:
	charge_time += delta
	sprite.modulate = Color.WHITE.lerp(Color(1.8, 1.8, 1.2), minf(charge_time / spin_hold_time, 1.0))
	face(aim())
	if not Input.is_action_pressed("attack"):
		end_charge()
		combo_timer = 1.0
		start_attack()
	elif charge_time >= spin_hold_time:
		end_charge()
		start_spin()


func end_charge() -> void:
	charging = false
	sprite.modulate = Color.WHITE


func start_spin() -> void:
	combo_step = 0
	combo_timer = 0.0
	caught_combo = false
	begin_spin(spin_damage, spin_knockback, spin_radius, spin_time, spin_cooldown, spin_tint, true)


func begin_spin(damage: int, knockback: float, radius: float, duration: float, cooldown: float, tint: Color, heavy: bool) -> void:
	spinning = true
	current_heavy = heavy
	current_damage = damage
	current_knockback = knockback
	spin_radius_now = radius
	spin_time_now = duration
	attack_timer = cooldown
	active_timer = duration
	already_hit.clear()
	attack_dir = aim()
	attack_pivot.rotation = attack_dir.angle()
	current_reach = radius * 0.6
	slash.position = Vector2(current_reach, 0)
	slash.scale = Vector2(radius * 0.8, radius) / slash.texture.get_size()
	slash.modulate = tint
	slash.visible = true


func throw_scythe() -> void:
	var toss := combo_step == 2 and (combo_timer > 0.0 or charging) and not caught_combo
	if charging:
		end_charge()
	var dir := aim()
	face(dir)
	has_scythe = false
	combo_step = 0
	combo_timer = 0.0
	buffer_timer = 0.0
	attack_timer = throw_cooldown
	var scythe := ThrownScythe.instantiate()
	scythe.thrower = self
	scythe.direction = dir
	scythe.return_speed = throw_return_speed
	if toss:
		scythe.piercing = true
		scythe.speed = toss_speed
		scythe.max_range = toss_range
		scythe.damage = toss_damage
		scythe.knockback = toss_knockback
		scythe.pull = toss_pull
		scythe.tint = toss_tint
		scythe.scale = Vector2.ONE * toss_size
	else:
		scythe.speed = throw_speed
		scythe.max_range = throw_range
		scythe.damage = throw_damage
		scythe.knockback = throw_knockback
	get_tree().current_scene.add_child(scythe)
	scythe.global_position = attack_pivot.global_position + dir * 10.0


func catch_scythe(from_ground: bool) -> void:
	has_scythe = true
	if from_ground:
		begin_spin(scoop_damage, scoop_knockback, scoop_radius, scoop_time, scoop_time, Color.WHITE, false)
		return
	combo_step = 2
	combo_timer = catch_window
	caught_combo = true
	add_shake(0.6)
	sprite.modulate = catch_flash
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)


func check_hits() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	if spinning:
		spin_shape.radius = spin_radius_now
		query.shape = spin_shape
		query.transform = Transform2D(0.0, attack_pivot.global_position)
	else:
		query.shape = attack_shape
		query.transform = Transform2D(attack_dir.angle(), attack_pivot.global_position + attack_dir * current_reach)
	query.collision_mask = ENEMY_MASK
	query.collide_with_areas = true
	var landed := false
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var body: Object = hit["collider"]
		if body in already_hit or not body.has_method("take_hit"):
			continue
		already_hit.append(body)
		var push := attack_dir
		if spinning and body is Node2D:
			push = (body.global_position - global_position).normalized()
		if current_heavy and body.has_method("reflect"):
			body.reflect(push)
		else:
			body.take_hit(current_damage, push * current_knockback)
		landed = true
	if landed:
		add_shake(heavy_shake if current_heavy else light_shake)
		hitstop(heavy_hitstop if current_heavy else light_hitstop)
