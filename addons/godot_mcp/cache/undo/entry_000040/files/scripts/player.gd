extends CharacterBody2D

const ENEMY_MASK := 4

@export var max_speed := 140.0
@export var acceleration := 1200.0
@export var friction := 1400.0

@export var attack_damage := 1
@export var attack_cooldown := 0.35
@export var attack_reach := 20.0
@export var attack_size := Vector2(22, 30)
@export var attack_knockback := 260.0
@export var slash_time := 0.1

var facing := Vector2.DOWN
var attack_timer := 0.0
var attack_shape := RectangleShape2D.new()

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_pivot: Node2D = $AttackPivot
@onready var slash: Sprite2D = $AttackPivot/Slash


func _ready() -> void:
	attack_shape.size = attack_size
	slash.visible = false


func _physics_process(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
	if Input.is_action_just_pressed("attack") and attack_timer == 0.0:
		attack()
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		facing = input.normalized()
		velocity = velocity.move_toward(input * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	if input.x != 0.0:
		sprite.flip_h = input.x < 0.0
