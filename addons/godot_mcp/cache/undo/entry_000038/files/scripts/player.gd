extends CharacterBody2D

@export var max_speed := 140.0
@export var acceleration := 1200.0
@export var friction := 1400.0

var facing := Vector2.DOWN

@onready var sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		facing = input.normalized()
		velocity = velocity.move_toward(input * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	if input.x != 0.0:
		sprite.flip_h = input.x < 0.0
