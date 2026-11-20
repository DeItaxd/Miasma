extends CanvasLayer

const RESTART_DELAY_MS := 600

var bar_width := 0.0
var main
var over_since := 0
var banner: Label
var warning: Label
var arrow: Polygon2D
var pause_menu: ColorRect
var hurt_flash: ColorRect
var last_health := -1
var brazier

@onready var hp_fill: ColorRect = $HPBar/Fill
@onready var hp_label: Label = $HPBar/HPLabel
@onready var herb_label: Label = $HerbLabel
@onready var time_label: Label = $TimeLabel
@onready var game_over: ColorRect = $GameOver
@onready var game_over_label: Label = $GameOver/GameOverLabel


func _ready() -> void:
	style_label(hp_label, 15, Color.WHITE)
	style_label(herb_label, 15, Color("7cff4f"))
	style_label(time_label, 28, Color.WHITE)
	style_label(game_over_label, 32, Color.WHITE)
	game_over.visible = false
	hurt_flash = ColorRect.new()
	hurt_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	hurt_flash.color = Color(0.85, 0.1, 0.1, 0.0)
	hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hurt_flash)
	move_child(hurt_flash, 0)
	banner = Label.new()
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.visible = false
	style_label(banner, 40, Color("ff8a3d"))
	add_child(banner)
	move_child(banner, game_over.get_index())
	warning = Label.new()
	warning.anchor_right = 1.0
	warning.offset_top = 60.0
	warning.offset_bottom = 110.0
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning.text = "RATS AT THE FIRE!"
	warning.visible = false
	style_label(warning, 30, Color("ff5a4f"))
	add_child(warning)
	move_child(warning, game_over.get_index())
	arrow = Polygon2D.new()
	arrow.polygon = PackedVector2Array([Vector2(20, 0), Vector2(-12, -14), Vector2(-6, 0), Vector2(-12, 14)])
	arrow.visible = false
	arrow.scale = Vector2(1.5, 1.5)
	add_child(arrow)
	move_child(arrow, game_over.get_index())
	build_pause_menu()
	brazier = get_tree().get_first_node_in_group("brazier")
	if brazier:
		brazier.went_out.connect(_on_fire_out)
	bar_width = hp_fill.size.x
	main = get_tree().current_scene
	if main and main.has_signal("game_over"):
		main.game_over.connect(_on_game_over)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.herbs_changed.connect(_on_herbs_changed)
		_on_health_changed(player.health, player.max_health)
		_on_herbs_changed(player.herbs, player.max_carry)


func _process(_delta: float) -> void:
	if main and "elapsed" in main:
		time_label.text = format_time(main.elapsed)
	update_fire_alerts()


func update_fire_alerts() -> void:
	var rats_at_fire := false
	for rat in get_tree().get_nodes_in_group("rats"):
		if rat.at_fire:
			rats_at_fire = true
			break
	var blink := 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.012)
	warning.visible = rats_at_fire and not game_over.visible
	warning.modulate.a = blink
	if not is_instance_valid(brazier) or brazier.is_out or game_over.visible:
		arrow.visible = false
		return
	var screen_size := get_viewport().get_visible_rect().size
	var pos: Vector2 = get_viewport().get_canvas_transform() * brazier.global_position
	var margin := 48.0
	if Rect2(Vector2.ZERO, screen_size).grow(-margin).has_point(pos):
		arrow.visible = false
		return
	var center := screen_size * 0.5
	var dir := (pos - center).normalized()
	var half := center - Vector2(margin, margin)
	var reach := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
	arrow.visible = true
	arrow.position = center + dir * reach
	arrow.rotation = dir.angle()
	arrow.color = Color("ff5a4f") if rats_at_fire else Color("ffc861")
	arrow.modulate.a = blink if rats_at_fire else 0.85


func _input(event: InputEvent) -> void:
	if game_over.visible:
		if event.is_action_pressed("quit"):
			get_tree().quit()
		elif Time.get_ticks_msec() - over_since > RESTART_DELAY_MS and (event.is_action_pressed("restart") or event.is_action_pressed("attack")):
			restart()
		return
	if event.is_action_pressed("quit"):
		set_paused(not pause_menu.visible)
		get_viewport().set_input_as_handled()
	elif pause_menu.visible:
		if event.is_action_pressed("restart"):
			restart()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
			get_tree().quit()


func build_pause_menu() -> void:
	pause_menu = ColorRect.new()
	pause_menu.color = Color(0, 0, 0, 0.6)
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.visible = false
	add_child(pause_menu)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 16)
	pause_menu.add_child(box)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_label(title, 48, Color.WHITE)
	box.add_child(title)
	var entries := [["Resume  (Esc)", func() -> void: set_paused(false)], ["Restart  (R)", restart], ["Quit  (Q)", get_tree().quit]]
	for entry in entries:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(300, 56)
		button.add_theme_font_size_override("font_size", 26)
		button.pressed.connect(entry[1])
		box.add_child(button)


func set_paused(value: bool) -> void:
	pause_menu.visible = value
	get_tree().paused = value


func restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4 if font_size < 20 else 6)


func format_time(seconds: float) -> String:
	return "%d:%02d" % [int(seconds / 60.0), int(seconds) % 60]


func _on_health_changed(current: int, maximum: int) -> void:
	if last_health >= 0 and current < last_health:
		hurt_flash.color.a = 0.28
		create_tween().tween_property(hurt_flash, "color:a", 0.0, 0.3)
	last_health = current
	hp_label.text = "%d / %d" % [current, maximum]
	hp_fill.size.x = bar_width * float(current) / float(maximum)


func _on_herbs_changed(current: int, maximum: int) -> void:
	herb_label.text = "Herbs %d / %d" % [current, maximum]


func _on_fire_out() -> void:
	banner.text = "THE FIRE WENT OUT\nLast stand"
	banner.modulate.a = 1.0
	banner.visible = true
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(banner, "modulate:a", 0.0, 1.0)
	tween.tween_callback(banner.hide)


func _on_game_over(reason: String, time: float, best: float, new_best: bool) -> void:
	over_since = Time.get_ticks_msec()
	var best_text := "NEW BEST!" if new_best else "Best  %s" % format_time(best)
	game_over_label.text = "%s\n\nSurvived  %s\n%s\n\nR or click to restart    Esc to quit" % [reason, format_time(time), best_text]
	game_over.visible = true
