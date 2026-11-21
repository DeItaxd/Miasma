extends Area2D

enum State { OUT, RETURN, GROUND }

var thrower: Node2D
var direction := Vector2.RIGHT
var speed := 340.0
var return_speed := 420.0
var max_range := 230.0
var damage := 2
var knockback := 250.0
var catch_distance := 14.0
var pickup_distance := 18.0
var spin_speed := 22.0
var piercing := false
var pull := 0.0
var pull_stop := 24.0
var tint := Color.WHITE

var state := State.OUT
var traveled := 0.0
var hit_bodies: Array[Object] = []

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	sprite.modulate = tint


func _physics_process(delta: float) -> void:
	match state:
		State.OUT:
			var step := direction * speed * delta
			position += step
			traveled += step.length()
			sprite.rotation += spin_speed * delta
			if traveled >= max_range:
				if piercing:
					turn_back()
				else:
					drop()
		State.RETURN:
			if not is_instance_valid(thrower):
				drop()
				return
			var to_thrower := thrower.global_position + Vector2(0, -10) - global_position
			if to_thrower.length() <= catch_distance:
				catch()
				return
			global_position += to_thrower.normalized() * minf(return_speed * delta, to_thrower.length())
			sprite.rotation += spin_speed * delta
		State.GROUND:
			if is_instance_valid(thrower) and global_position.distance_to(thrower.global_position + Vector2(0, -10)) <= pickup_distance:
				catch()


func _on_body_entered(body: Node2D) -> void:
	if state == State.GROUND or body == thrower:
		return
	if body.has_method("take_hit"):
		if body in hit_bodies:
			return
		hit_bodies.append(body)
		body.take_hit(damage, push_for(body))
		if is_instance_valid(thrower):
			thrower.add_shake(1.5)
		if state == State.OUT and not piercing:
			state = State.RETURN
	elif state == State.OUT:
		if piercing:
			turn_back()
		else:
			drop()


func push_for(body: Node2D) -> Vector2:
	if state == State.OUT:
		return direction * knockback
	if piercing and is_instance_valid(thrower):
		var to_thrower := thrower.global_position - body.global_position
		var friction: Variant = body.get("knockback_friction")
		if friction == null:
			return to_thrower.normalized() * pull
		var needed := sqrt(2.0 * float(friction) * maxf(to_thrower.length() - pull_stop, 0.0))
		return to_thrower.normalized() * minf(needed, pull)
	return (body.global_position - global_position).normalized() * knockback


func turn_back() -> void:
	state = State.RETURN
	hit_bodies.clear()


func _on_area_entered(area: Area2D) -> void:
	if state != State.GROUND and area.has_method("take_hit"):
		area.take_hit(damage, Vector2.ZERO)


func drop() -> void:
	state = State.GROUND
	sprite.rotation = randf() * TAU
	sprite.modulate = Color(0.85, 0.85, 0.85)


func catch() -> void:
	if is_instance_valid(thrower):
		thrower.catch_scythe(state == State.GROUND)
	queue_free()
