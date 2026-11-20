extends Area2D

const DeathPuff := preload("res://scripts/death_puff.gd")

@export var speed := 130.0
@export var damage := 1
@export var lifetime := 4.0
@export var reflect_speed := 1.6
@export var reflect_damage := 2
@export var reflect_knockback := 200.0
@export var reflect_tint := Color(0.6, 1.0, 0.6)

var direction := Vector2.RIGHT
var reflected := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	pop()


func take_hit(_damage: int, _push: Vector2) -> void:
	pop()


func pop() -> void:
	if is_queued_for_deletion():
		return
	DeathPuff.spawn(self, Color("e0d24a"), 6)
	queue_free()
