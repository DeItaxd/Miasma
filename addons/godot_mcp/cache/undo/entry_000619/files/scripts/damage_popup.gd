extends RefCounted

const WIDTH := 40.0
const SCALE := 0.5
const NumberFont := preload("res://assets/fonts/PirataOne-Regular.ttf")


static func spawn(source: Node2D, value: Variant, color: Color) -> void:
	var popup := Label.new()
	popup.text = str(value)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_theme_constant_override("outline_size", 5)
	popup.size = Vector2(WIDTH, 23)
	popup.scale = Vector2(SCALE, SCALE)
	popup.z_index = 100
	source.get_tree().current_scene.add_child(popup)
	popup.global_position = source.global_position + Vector2(randf_range(-6.0, 6.0) - WIDTH * SCALE * 0.5, -36)
	var tween := popup.create_tween().set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 14.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(popup, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tween.chain().tween_callback(popup.queue_free)
