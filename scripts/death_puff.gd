extends RefCounted


static func spawn(source: Node2D, color: Color, amount: int = 12) -> void:
	var puff := CPUParticles2D.new()
	puff.one_shot = true
	puff.amount = amount
	puff.lifetime = 0.45
	puff.explosiveness = 1.0
	puff.direction = Vector2.UP
	puff.spread = 180.0
	puff.gravity = Vector2.ZERO
	puff.initial_velocity_min = 50.0
	puff.initial_velocity_max = 120.0
	puff.damping_min = 120.0
	puff.damping_max = 180.0
	puff.scale_amount_min = 2.0
	puff.scale_amount_max = 4.0
	puff.color = color
	var ramp := Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(1, 1, 1, 0))
	puff.color_ramp = ramp
	puff.z_index = 60
	source.get_tree().current_scene.add_child(puff)
	puff.global_position = source.global_position + Vector2(0, -10)
	puff.emitting = true
	puff.finished.connect(puff.queue_free)
