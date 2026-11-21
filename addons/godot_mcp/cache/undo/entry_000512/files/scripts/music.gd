extends AudioStreamPlayer

const Track := preload("res://assets/sounds/placeholder-bgm.mp3")
const VOLUME_DB := 8.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var track := Track.duplicate() as AudioStreamMP3
	track.loop = true
	stream = track
	volume_db = VOLUME_DB
	play()
