extends CharacterBody2D

const DamagePopup := preload("res://scripts/damage_popup.gd")

@export var max_health := 2
@export var speed := 55.0
@export var knockback_friction := 900.0
@export var chew_range := 32.0
@export var chew_time := 3.0
@export var chew_amount := 15.0
@export var chew_cooldown := 2.0

var health := 0
var knockback := Vector2.ZERO
var windup := 0.0
var cooldown_timer := 0.0
var at_fire := false
var bar_width := 0.0
var brazier: Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var bar: Node2D = $WindupBar
@onready var bar_fill: ColorRect = $WindupBar/Fill


func _ready() -> void:
	health = max_health
	brazier = get_tree().get_first_node_in_group("brazier")
	bar_width = bar_fill.size.x
	update_windup_visual()


func _physics_process(delta: float) -> void:
	knockback = knockback.move_toward(Vector2.ZERO, knockback_friction * delta)
	cooldown_timer = maxf(cooldown_timer - delta, 0.0)
	var move := Vector2.ZERO
	at_fire = false
	if is_instance_valid(brazier) and brazier.is_out:
		windup = 0.0
	elif is_instance_valid(brazier):
		var to_brazier := brazier.global_position - global_position
		at_fire = to_brazier.length() <= chew_range
		if not at_fire:
			windup = 0.0
			move = to_brazier.normalized() * speed
		elif knockback == Vector2.ZERO and cooldown_timer == 0.0:
			windup += delta
			if windup >= chew_time:
				windup = 0.0
				cooldown_timer = chew_cooldown
				brazier.drain_fuel(chew_amount)
	update_windup_visual()
	velocity = move + knockback
	move_and_slide()


func update_windup_visual() -> void:
	var active := windup > 0.0
	bar.visible = active
	bar_fill.size.x = bar_width * windup / chew_time
	sprite.position.x = sin(Time.get_ticks_msec() * 0.05) * 1.5 if active else 0.0


func take_hit(damage: int, push: Vector2) -> void:
	health -= damage
	knockback = push
	windup = 0.0
	DamagePopup.spawn(self, damage, Color("ffe08a"))
	sprite.modulate = Color(10, 10, 10)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		queue_free()
