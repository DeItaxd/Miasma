extends CanvasLayer

const RESTART_DELAY_MS := 600
const VignetteShader := preload("res://shaders/death_vignette.gdshader")

static var title_seen := false

@export_group("Death Screen")
@export var vignette_delay := 0.3
@export var vignette_frame := 0.55
@export var vignette_frame_time := 1.0
@export var vignette_linger := 0.6
@export var vignette_close_time := 0.7
@export var results_fade_time := 0.5
@export var results_stagger := 0.15

var dying := false
var vignette: ColorRect
var vignette_material: ShaderMaterial
var results_box: VBoxContainer
var results_prompt: Label

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
var player
var herb_arrow: Polygon2D
var scythe_arrow: Polygon2D
var combo := 0
var combo_box: Control
var combo_count: Label
var combo_word: Label
var combo_tween: Tween
var impact_flash: ColorRect
var best_combo := 0
var title: ColorRect
var start_label: Label

@onready var hp_fill: ColorRect = $HPBar/Fill
@onready var hp_label: Label = $HPBar/HPLabel
@onready var herb_label: Label = $HerbLabel
@onready var time_label: Label = $TimeLabel
@onready var game_over: ColorRect = $GameOver
@onready var game_over_label: Label = $GameOver/GameOverLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	herb_arrow = Polygon2D.new()
	herb_arrow.polygon = arrow.polygon
	herb_arrow.color = Color("7cff4f")
	herb_arrow.scale = Vector2(1.6, 1.6)
	herb_arrow.visible = false
	var outline := Line2D.new()
	outline.points = arrow.polygon
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color(0.05, 0.15, 0.03)
	herb_arrow.add_child(outline)
	add_child(herb_arrow)
	move_child(herb_arrow, game_over.get_index())
	scythe_arrow = Polygon2D.new()
	scythe_arrow.polygon = arrow.polygon
	scythe_arrow.color = Color("ffe08a")
	scythe_arrow.scale = Vector2(1.4, 1.4)
	scythe_arrow.visible = false
	var scythe_outline := Line2D.new()
	scythe_outline.points = arrow.polygon
	scythe_outline.closed = true
	scythe_outline.width = 3.0
	scythe_outline.default_color = Color(0.2, 0.12, 0.02)
	scythe_arrow.add_child(scythe_outline)
	add_child(scythe_arrow)
	move_child(scythe_arrow, game_over.get_index())
	build_combo()
	build_pause_menu()
	build_title()
	build_vignette()
	if not title_seen:
		title.visible = true
		get_tree().paused = true
	brazier = get_tree().get_first_node_in_group("brazier")
	if brazier:
		brazier.went_out.connect(_on_fire_out)
	bar_width = hp_fill.size.x
	main = get_tree().current_scene
	if main and main.has_signal("game_over"):
		main.game_over.connect(_on_game_over)
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.herbs_changed.connect(_on_herbs_changed)
		player.hit_landed.connect(_on_hit_landed)
		_on_health_changed(player.health, player.max_health)
		_on_herbs_changed(player.herbs, player.max_carry)


func _process(_delta: float) -> void:
	if main and "elapsed" in main:
		time_label.text = format_time(main.elapsed)
	update_fire_alerts()
	update_herb_arrow()
	update_scythe_arrow()
	update_combo()
	update_vignette()
	if title.visible:
		start_label.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)
	if results_prompt and game_over.visible:
		results_prompt.self_modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)


func build_title() -> void:
	title = ColorRect.new()
	title.color = Color(0.04, 0.035, 0.03, 0.88)
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.visible = false
	add_child(title)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 18)
	title.add_child(box)
	box.add_child(title_label("MIASMA", 120, Color("e8d9b0")))
	box.add_child(title_label("Keep the fire burning. Its smoke is the only safe air.\nEverything you need lies out of its reach.", 26, Color("c9c2b0")))
	var columns := HBoxContainer.new()
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_theme_constant_override("separation", 44)
	box.add_child(columns)
	columns.add_child(title_column("HOW TO PLAY", [
		"Stay in the fire's smoke. The haze outside hurts you.",
		"The fire burns out. Grab herbs and bring them back to feed it.",
		"Rats go for the fire and eat its herbs. Kill them first.",
		"If the fire goes out, it stays out. Survive as long as you can.",
		"Hitting enemies heals you. Longer combos heal more. Getting hit resets your combo.",
	]))
	columns.add_child(title_column("CONTROLS", [
		"WASD or arrows: move",
		"Left click: attack",
		"Right click: throw the scythe",
		"Space or Shift: dash through enemies",
		"Esc: pause",
	]))
	columns.add_child(title_column("SCYTHE COMBOS", [
		"3xM1: heavy finisher",
		"Hold M1 after any swing: spin attack",
		"2xM1 + M2: Reaper's Toss. Cuts through everything, comes back and drags enemies in.",
		"A throw that hits comes back. Catch it and your next click is a finisher.",
		"M2 during a spin: Buzzsaw. Hovers and shreds, then comes back.",
		"Hit a cough with a heavy or a spin to knock it back.",
	]))
	columns.add_child(title_column("DASH COMBOS", [
		"Dash through an enemy and your dash comes back right away. Chain up to 4 dashes.",
		"After dashing through enemies, M1: Rend. Cuts everyone you passed. Longer chains cut harder.",
		"Dash, then M2: Ricochet. The scythe bounces between enemies and hits harder each time.",
		"A throw that misses stays on the ground. Run toward it to sprint after it.",
		"Dash into your scythe on the ground: Pounce. A big spin, and your dash comes back.",
	]))
	start_label = title_label("Click to start", 36, Color("ffc861"))
	box.add_child(start_label)
	box.add_child(title_label("Esc to quit", 20, Color("8a8478")))


func title_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_label(label, font_size, color)
	return label


func title_column(header: String, lines: Array) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(400, 0)
	column.add_theme_constant_override("separation", 9)
	column.add_child(title_label(header, 30, Color("ffc861")))
	for line in lines:
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(400, 0)
		style_label(label, 20, Color("ece6d6"))
		column.add_child(label)
	return column


func start_game() -> void:
	title_seen = true
	title.visible = false
	get_tree().paused = false
	var music := get_node_or_null("/root/Music")
	if music:
		music.start()


func build_combo() -> void:
	impact_flash = ColorRect.new()
	impact_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	impact_flash.color = Color(1, 1, 1, 0)
	impact_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(impact_flash)
	move_child(impact_flash, 1)
	combo_box = Control.new()
	combo_box.anchor_left = 1.0
	combo_box.anchor_right = 1.0
	combo_box.offset_left = -340.0
	combo_box.offset_right = -60.0
	combo_box.offset_top = 150.0
	combo_box.offset_bottom = 290.0
	combo_box.pivot_offset = Vector2(140, 70)
	combo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_box.visible = false
	add_child(combo_box)
	move_child(combo_box, game_over.get_index())
	combo_count = Label.new()
	combo_count.anchor_right = 1.0
	combo_count.offset_bottom = 100.0
	combo_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	style_label(combo_count, 84, Color.WHITE)
	combo_count.add_theme_constant_override("outline_size", 14)
	combo_box.add_child(combo_count)
	combo_word = Label.new()
	combo_word.anchor_right = 1.0
	combo_word.offset_top = 92.0
	combo_word.offset_bottom = 134.0
	combo_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_word.text = "HITS"
	style_label(combo_word, 28, Color.WHITE)
	combo_box.add_child(combo_word)


func update_combo() -> void:
	if combo == 0 or get_tree().paused:
		return
	if not is_instance_valid(player) or player.chain == 0:
		end_combo()
	elif player.chain_left < 0.4:
		combo_box.modulate.a = player.chain_left / 0.4


func end_combo() -> void:
	combo = 0
	combo_box.visible = false


func combo_color(count: int) -> Color:
	if count >= 25:
		return Color("ff3b3b")
	if count >= 15:
		return Color("ff8a3d")
	if count >= 8:
		return Color("ffd23f")
	return Color.WHITE


func _on_hit_landed(count: int, heavy: bool) -> void:
	combo = player.chain if is_instance_valid(player) else combo + count
	best_combo = maxi(best_combo, combo)
	if heavy:
		impact_flash.color.a = 0.12
		create_tween().tween_property(impact_flash, "color:a", 0.0, 0.15)
	if combo < 2:
		combo_box.visible = false
		return
	combo_box.visible = true
	combo_box.modulate.a = 1.0
	combo_count.text = str(combo)
	var mult: float = player.lifesteal_multiplier() if is_instance_valid(player) else 1.0
	combo_word.text = "HITS" if mult <= 1.0 else "HITS   heal x%s" % ("%.2f" % mult).rstrip("0").rstrip(".")
	var color := combo_color(combo)
	combo_count.add_theme_color_override("font_color", color)
	combo_word.add_theme_color_override("font_color", color)
	if combo_tween and combo_tween.is_valid():
		combo_tween.kill()
	combo_box.scale = Vector2.ONE * (1.6 if heavy else 1.3)
	combo_box.rotation = randf_range(-0.14, 0.14)
	combo_tween = create_tween().set_parallel(true)
	combo_tween.tween_property(combo_box, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	combo_tween.tween_property(combo_box, "rotation", randf_range(-0.05, 0.05), 0.25)


func update_scythe_arrow() -> void:
	var scythe = get_tree().get_first_node_in_group("thrown_scythe")
	if not is_instance_valid(scythe) or scythe.is_queued_for_deletion() or not scythe.is_grounded() or not is_instance_valid(player) or game_over.visible:
		scythe_arrow.visible = false
		return
	if player.global_position.distance_to(scythe.global_position) < 40.0:
		scythe_arrow.visible = false
		return
	var canvas := get_viewport().get_canvas_transform()
	var from: Vector2 = canvas * (player.global_position + Vector2(0, -10))
	var dir: Vector2 = (canvas * scythe.global_position - from).normalized()
	var pulse := sin(Time.get_ticks_msec() * 0.01)
	scythe_arrow.visible = true
	scythe_arrow.position = from + dir * (68.0 + 8.0 * pulse)
	scythe_arrow.rotation = dir.angle()


func herbs_full() -> bool:
	return is_instance_valid(player) and player.herbs >= player.max_carry


func update_herb_arrow() -> void:
	if not herbs_full() or not is_instance_valid(brazier) or brazier.is_out or game_over.visible:
		herb_arrow.visible = false
		return
	if player.global_position.distance_to(brazier.global_position) <= brazier.deposit_range * 1.5:
		herb_arrow.visible = false
		return
	var canvas := get_viewport().get_canvas_transform()
	var from: Vector2 = canvas * (player.global_position + Vector2(0, -10))
	var dir: Vector2 = (canvas * brazier.global_position - from).normalized()
	var pulse := sin(Time.get_ticks_msec() * 0.008)
	herb_arrow.visible = true
	herb_arrow.position = from + dir * (85.0 + 10.0 * pulse)
	herb_arrow.rotation = dir.angle()


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
	arrow.color = Color("ff5a4f") if rats_at_fire else (Color("7cff4f") if herbs_full() else Color("ffc861"))
	arrow.modulate.a = blink if rats_at_fire else 0.85


func _input(event: InputEvent) -> void:
	if title.visible:
		if event.is_action_pressed("quit"):
			get_tree().quit()
		elif (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed() and not event.is_echo():
			start_game()
		get_viewport().set_input_as_handled()
		return
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
	var heading := Label.new()
	heading.text = "PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_label(heading, 48, Color.WHITE)
	box.add_child(heading)
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
	muffle_music(value)


func muffle_music(value: bool) -> void:
	var music := get_node_or_null("/root/Music")
	if music:
		music.set_muffled(value)


func restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	muffle_music(false)
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
	end_combo()
	var best_text := "NEW BEST!" if new_best else "Best  %s" % format_time(best)
	var kills: int = main.kills if main and "kills" in main else 0
	game_over_label.text = "%s\n\nSurvived  %s\n%s\n\nKills  %d        Best combo  %d\n\nR or click to restart    Esc to quit" % [reason, format_time(time), best_text, kills, best_combo]
	game_over.visible = true
