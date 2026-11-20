extends CanvasLayer

var bar_width := 0.0

@onready var hp_fill: ColorRect = $HPBar/Fill
@onready var hp_label: Label = $HPBar/HPLabel


func _ready() -> void:
	bar_width = hp_fill.size.x
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.health, player.max_health)


func _on_health_changed(current: int, maximum: int) -> void:
	hp_label.text = "%d / %d" % [current, maximum]
	hp_fill.size.x = bar_width * float(current) / float(maximum)
