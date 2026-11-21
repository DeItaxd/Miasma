extends Node2D

signal game_over(reason: String, time: float, best: float, new_best: bool)

const SAVE_PATH := "user://best.cfg"
const GroundShader := preload("res://shaders/ground.gdshader")

var elapsed := 0.0
var is_over := false
var kills := 0
var brazier


func _ready() -> void:
	add_to_group("kill_counter")
	brazier = get_tree().get_first_node_in_group("brazier")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.died.connect(_on_player_died)


func _on_player_died() -> void:
	end_game("THE HAZE TOOK YOU" if brazier and brazier.is_out else "YOU DIED")


func add_kill() -> void:
	if not is_over:
		kills += 1


func _physics_process(delta: float) -> void:
	if not is_over:
		elapsed += delta


func end_game(reason: String) -> void:
	if is_over:
		return
	is_over = true
	var best := load_best()
	var new_best := elapsed > best
	if new_best:
		best = elapsed
		save_best(best)
	get_tree().paused = true
	game_over.emit(reason, elapsed, best, new_best)


func load_best() -> float:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0.0
	return float(config.get_value("survival", "best", 0.0))


func save_best(value: float) -> void:
	var config := ConfigFile.new()
	config.set_value("survival", "best", value)
	config.save(SAVE_PATH)
