extends CharacterBody2D

signal health_changed(current: int, maximum: int)

const ENEMY_MASK := 4
const DamagePopup := preload("res://scripts/damage_popup.gd")

@export var max_health := 10
@export var invulnerable_time := 0.6

@export var max_speed := 140.0
@export var acceleration := 1200.0
@export var friction := 1400.0

@export var attack_damage := 1
@export var attack_cooldown := 0.35
@export var attack_reach := 20.0
@export var attack_size := Vector2(22, 30)
@export var attack_knockback := 400.0
@export var attack_active_time := 0.15
@export var lunge_speed := 240.0

var health := 0
var invulnerable_timer := 0.0
var facing := Vector2.DOWN
var attack_timer := 0.0
var active_timer := 0.0
var attack_dir := Vector2.RIGHT
var already_hit: Array[Object] = []
var attack_shape := RectangleShape2D.new()

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_pivot: Node2D = $AttackPivot
@onready var slash: Sprite2D = $AttackPivot/Slash


func _ready() -> void:
	health = max_health
	attack_shape.size = attack_size
	slash.visible = false


func _physics_process(delta: float) -> void:
	invulnerable_timer = maxf(invulnerable_timer - delta, 0.0)
	attack_timer = maxf(attack_timer - delta, 0.0)
	if Input.is_action_just_pressed("attack") and attack_timer == 0.0:
		start_attack()
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		facing = input.normalized()
		velocity = velocity.move_toward(input * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	if input.x != 0.0:
		sprite.flip_h = input.x < 0.0
	if active_timer > 0.0:
		active_timer -= delta
		check_hits()
		if active_timer <= 0.0:
			slash.visible = false


func start_attack() -> void:
	attack_timer = attack_cooldown
	active_timer = attack_active_time
	already_hit.clear()
	attack_dir = (get_global_mouse_position() - attack_pivot.global_position).normalized()
	if attack_dir == Vector2.ZERO:
		attack_dir = facing
	attack_pivot.rotation = attack_dir.angle()
	slash.visible = true
	velocity += attack_dir * lunge_speed


func check_hits() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = attack_shape
	query.transform = Transform2D(attack_dir.angle(), attack_pivot.global_position + attack_dir * attack_reach)
	query.collision_mask = ENEMY_MASK
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var body: Object = hit["collider"]
		if body in already_hit or not body.has_method("take_hit"):
			continue
		already_hit.append(body)
		body.take_hit(attack_damage, attack_dir * attack_knockback)
