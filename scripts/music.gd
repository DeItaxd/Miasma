extends AudioStreamPlayer

const Track := preload("res://assets/sounds/soundtrak.mp3")
const MenuTrack := preload("res://assets/sounds/startmenuwind.mp3")
const VOLUME_DB := 8.0
const MENU_VOLUME_DB := 0.0
const CLEAR_HZ := 20500.0
const MUFFLED_HZ := 650.0
const MUFFLED_DROP_DB := -5.0
const FADE_TIME := 0.25
const CROSSFADE_TIME := 1.5
const SILENT_DB := -40.0

var filter := AudioEffectLowPassFilter.new()
var tween: Tween
var menu := AudioStreamPlayer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = looped(Track)
	volume_db = VOLUME_DB
	var index := AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, "Music")
	AudioServer.set_bus_send(index, "Master")
	filter.cutoff_hz = CLEAR_HZ
	AudioServer.add_bus_effect(index, filter)
	bus = "Music"
	menu.stream = looped(MenuTrack)
	menu.volume_db = MENU_VOLUME_DB
	menu.bus = "Music"
	add_child(menu)
	menu.play()


func looped(track: AudioStreamMP3) -> AudioStreamMP3:
	var copy := track.duplicate() as AudioStreamMP3
	copy.loop = true
	return copy


func start() -> void:
	if playing:
		return
	volume_db = SILENT_DB
	play()
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_ignore_time_scale(true)
	tween.tween_property(self, "volume_db", VOLUME_DB, CROSSFADE_TIME)
	if menu.playing:
		var fade := create_tween().set_ignore_time_scale(true)
		fade.tween_property(menu, "volume_db", SILENT_DB, CROSSFADE_TIME)
		fade.tween_callback(menu.stop)


func set_muffled(value: bool) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_parallel(true).set_ignore_time_scale(true)
	tween.tween_property(filter, "cutoff_hz", MUFFLED_HZ if value else CLEAR_HZ, FADE_TIME).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "volume_db", VOLUME_DB + (MUFFLED_DROP_DB if value else 0.0), FADE_TIME)
