extends CharacterBody2D

const DamagePopup := preload("res://scripts/damage_popup.gd")
const DeathPuff := preload("res://scripts/death_puff.gd")

@export var max_health := 3
@export var speed := 40.0
@export var knockback_friction := 900.0
@export var stop_distance := 18.0
@export var contact_damage := 1
@export var attack_range := 22.0
@export var attack_cooldown := 1.0
@export var sprite_faces_left := false

var health := 0
var attack_timer := 0.0
var knockback := Vector2.ZERO
var target: Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = max_health
	target = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
	var chase := Vector2.ZERO
	if is_instance_valid(target):
		var to_target := target.global_position - global_position
		face(to_target.normalized().x)
		if to_target.length() > stop_distance:
			chase = to_target.normalized() * speed
		if to_target.length() <= attack_range and attack_timer == 0.0 and target.has_method("take_damage"):
			attack_timer = attack_cooldown
			target.take_damage(contact_damage)
	knockback = knockback.move_toward(Vector2.ZERO, knockback_friction * delta)
	velocity = chase + knockback
	move_and_slide()


func face(x: float) -> void:
	if absf(x) > 0.25:
		sprite.flip_h = (x > 0.0) == sprite_faces_left


func take_hit(damage: int, push: Vector2) -> void:
	if health <= 0:
		return
	health -= damage
	knockback = push
	DamagePopup.spawn(self, damage, Color("ffe08a"))
	sprite.modulate = Color(10, 10, 10)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		DeathPuff.spawn(self, Color("c0392b"))
		queue_free()
