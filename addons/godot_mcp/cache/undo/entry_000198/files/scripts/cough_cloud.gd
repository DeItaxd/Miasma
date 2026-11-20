extends Area2D

@export var speed := 130.0
@export var damage := 1
@export var lifetime := 4.0

var direction := Vector2.RIGHT


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()


func take_hit(_damage: int, _push: Vector2) -> void:
	queue_free()
