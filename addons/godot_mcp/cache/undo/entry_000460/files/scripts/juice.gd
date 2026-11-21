extends RefCounted

static var streak: GradientTexture2D


static func streak_texture() -> Texture2D:
	if streak == null:
		streak = GradientTexture2D.new()
		streak.width = 2
		streak.height = 9
		var solid := Gradient.new()
		solid.set_color(0, Color.WHITE)
		solid.set_color(1, Color.WHITE)
		streak.gradient = solid
	return streak


static func sparks(source: Node, pos: Vector2, dir: Vector2, color: Color, amount: int = 10, speed: float = 220.0) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.3
	p.explosiveness = 1.0
	p.texture = streak_texture()
	p.particle_flag_align_y = true
	p.direction = dir if dir != Vector2.ZERO else Vector2.UP
	p.spread = 40.0 if dir != Vector2.ZERO else 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.45
	p.initial_velocity_max = speed
	p.damping_min = speed * 1.5
	p.damping_max = speed * 2.5
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.color = color
	var ramp := Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	p.z_index = 70
	source.get_tree().current_scene.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


static func ring(source: Node, pos: Vector2, radius: float, color: Color, life: float = 0.25, width: float = 3.0) -> void:
	var line := Line2D.new()
	line.closed = true
	line.width = width
	line.default_color = color
	line.z_index = 70
	source.get_tree().current_scene.add_child(line)
	line.global_position = pos
	var tween := line.create_tween().set_parallel(true)
	tween.tween_method(func(r: float) -> void: line.points = circle(r), radius * 0.2, radius, life).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(line, "width", 0.5, life)
	tween.tween_property(line, "modulate:a", 0.0, life).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(line.queue_free)


static func circle(r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 24:
		points.append(Vector2.from_angle(TAU * i / 24.0) * r)
	return points


static func squash(sprite: Node2D, amount: Vector2, time: float = 0.25) -> void:
	if not is_instance_valid(sprite):
		return
	if not sprite.has_meta("base_scale"):
		sprite.set_meta("base_scale", sprite.scale)
	var base: Vector2 = sprite.get_meta("base_scale")
	if sprite.has_meta("squash_tween"):
		var old: Variant = sprite.get_meta("squash_tween")
		if old is Tween and old.is_valid():
			old.kill()
	sprite.scale = base * amount
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", base, time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	sprite.set_meta("squash_tween", tween)


static func ghost(sprite: Sprite2D, color: Color, life: float = 0.12, z: int = 0) -> void:
	var copy := Sprite2D.new()
	copy.texture = sprite.texture
	copy.offset = sprite.offset
	copy.centered = sprite.centered
	copy.flip_h = sprite.flip_h
	copy.flip_v = sprite.flip_v
	copy.modulate = color
	copy.z_index = z
	sprite.get_tree().current_scene.add_child(copy)
	copy.global_transform = sprite.global_transform
	var tween := copy.create_tween()
	tween.tween_property(copy, "modulate:a", 0.0, life)
	tween.tween_callback(copy.queue_free)
