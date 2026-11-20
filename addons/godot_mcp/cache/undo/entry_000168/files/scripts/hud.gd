extends CanvasLayer

const RESTART_DELAY_MS := 600

var bar_width := 0.0
var main
var over_since := 0
var banner: Label
var warning: Label
var arrow: Polygon2D
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
	banner = Label.new()
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.visible = false
	style_label(banner, 40, Color("ff8a3d"))
	add_child(banner)
	move_child(banner, game_over.get_index())
	var brazier = get_tree().get_first_node_in_group("brazier")
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


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()
	elif game_over.visible and Time.get_ticks_msec() - over_since > RESTART_DELAY_MS and (event.is_action_pressed("restart") or event.is_action_pressed("attack")):
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
