extends CharacterBody2D

const DamagePopup := preload("res://scripts/damage_popup.gd")
const DeathPuff := preload("res://scripts/death_puff.gd")
const CoughScene := preload("res://scenes/cough_cloud.tscn")

@export var max_health := 2
@export var speed := 45.0
@export var knockback_friction := 900.0
@export var preferred_distance := 170.0
@export var distance_tolerance := 30.0
@export var shoot_range := 320.0
@export var windup_time := 0.8
@export var shoot_cooldown := 2.5
@export var zone_margin := 16.0
@export var sprite_faces_left := false

var health := 0
var knockback := Vector2.ZERO
var windup := 0.0
var cooldown_timer := 0.0
var target: Node2D
var brazier: Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	target = get_tree().get_first_node_in_group("player")
	brazier = get_tree().get_first_node_in_group("brazier")
	cooldown_timer = randf_range(0.5, shoot_cooldown)


func _physics_process(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, knockback_friction * delta)
	cooldown_timer = maxf(cooldown_timer - delta, 0.0)
	var move := Vector2.ZERO
	if is_instance_valid(target):
		var to_target := target.global_position - global_position
		var dist := to_target.length()
		var dir := to_target.normalized()
		if windup > 0.0:
			windup += delta
			if windup >= windup_time:
				windup = 0.0
				cooldown_timer = shoot_cooldown
				shoot(dir)
		else:
			move = pick_move(dir, dist, delta)
			if cooldown_timer == 0.0 and dist <= shoot_range and knockback == Vector2.ZERO:
				windup = delta
	update_visual()
	velocity = move + knockback
	move_and_slide()


func pick_move(dir: Vector2, dist: float, delta: float) -> Vector2:
	if in_zone(global_position, zone_margin):
		return (global_position - brazier.global_position).normalized() * speed
	var move := Vector2.ZERO
	if dist > preferred_distance + distance_tolerance:
		move = dir * speed
	elif dist < preferred_distance - distance_tolerance:
		move = -dir * speed
	if in_zone(global_position + move * delta, zone_margin):
		return Vector2.ZERO
	return move


func in_zone(point: Vector2, margin: float) -> bool:
	if not is_instance_valid(brazier) or brazier.is_out:
		return false
	return point.distance_to(brazier.global_position) < brazier.radius + margin


func shoot(dir: Vector2) -> void:
	sprite.modulate = Color.WHITE
	var cloud := CoughScene.instantiate()
	cloud.direction = dir
	get_tree().current_scene.add_child(cloud)
	cloud.global_position = global_position + Vector2(0, -10) + dir * 12.0


func update_visual() -> void:
	var swell := windup / windup_time if windup > 0.0 else 0.0
	sprite.scale = Vector2.ONE * (1.0 + 0.3 * swell)
	if swell > 0.0:
		sprite.modulate = Color.WHITE.lerp(Color(1.6, 1.6, 0.6), swell)


func take_hit(damage: int, push: Vector2) -> void:
	health -= damage
	knockback = push
	windup = 0.0
	DamagePopup.spawn(self, damage, Color("ffe08a"))
	sprite.modulate = Color(10, 10, 10)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		DeathPuff.spawn(self, Color("9b59b6"))
		queue_free()
