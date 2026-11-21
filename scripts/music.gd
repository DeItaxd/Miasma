extends AudioStreamPlayer

const Track := preload("res://assets/sounds/placeholder-bgm.mp3")
const VOLUME_DB := 8.0
const CLEAR_HZ := 20500.0
const MUFFLED_HZ := 650.0
const MUFFLED_DROP_DB := -5.0
const FADE_TIME := 0.25

var filter := AudioEffectLowPassFilter.new()
var tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var track := Track.duplicate() as AudioStreamMP3
	track.loop = true
	stream = track
	volume_db = VOLUME_DB
	var index := AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, "Music")
	AudioServer.set_bus_send(index, "Master")
	filter.cutoff_hz = CLEAR_HZ
	AudioServer.add_bus_effect(index, filter)
	bus = "Music"


func start() -> void:
	if not playing:
		play()


func set_muffled(value: bool) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_parallel(true).set_ignore_time_scale(true)
	tween.tween_property(filter, "cutoff_hz", MUFFLED_HZ if value else CLEAR_HZ, FADE_TIME).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "volume_db", VOLUME_DB + (MUFFLED_DROP_DB if value else 0.0), FADE_TIME)
