extends Area2D

@export var textures: Array[Texture2D] = [
	preload("res://assets/sprites/lavender.png"),
	preload("res://assets/sprites/mint.png"),
	preload("res://assets/sprites/rosemary.png"),
]
@export var random_flip := true

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not textures.is_empty():
		sprite.texture = textures.pick_random()
	if random_flip:
		sprite.flip_h = randf() < 0.5


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_herb") and body.add_herb():
		queue_free()
