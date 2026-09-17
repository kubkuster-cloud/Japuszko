extends Node
## Ustawienia gry (autoload "Settings"), zapisywane w user://settings.cfg.

const PATH := "user://settings.cfg"
const WINDOW_SCALES := [2, 3, 4]
## Rozmiar okna ustawiony w projekcie (1440x810 = 480x270 razy 3).
const DEFAULT_SCALE := 3
## Kanał audio muzyki (tworzony przy starcie, wysyła dźwięk do Master).
const MUSIC_BUS := "Music"
## Kanał audio efektów dźwiękowych.
const SFX_BUS := "SFX"

var fullscreen := false
var window_scale := DEFAULT_SCALE
## Głośność ogólna 0..1.
var volume := 0.8
## Głośność muzyki 0..1 (względem głośności ogólnej).
var music_volume := 0.7
## Głośność efektów 0..1 (względem głośności ogólnej).
var sfx_volume := 0.8


## Emitowany, gdy ustawienia zmienią się poza panelem (np. F11) – panel odświeża przełączniki.
signal changed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	load_settings()
	apply(true)


## F11 – przełącza pełny ekran w dowolnym miejscu gry (także w pauzie i w menu).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		get_viewport().set_input_as_handled()
		toggle_fullscreen()


func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	apply()
	save_settings()
	changed.emit()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	fullscreen = cfg.get_value("display", "fullscreen", fullscreen)
	window_scale = cfg.get_value("display", "window_scale", window_scale)
	volume = cfg.get_value("audio", "volume", volume)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "window_scale", window_scale)
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.save(PATH)


## Stosuje ustawienia. Przy starcie gry nie rusza okna, jeśli ustawienia są domyślne.
func apply(at_startup := false) -> void:
	_set_bus_volume("Master", volume)
	_set_bus_volume(MUSIC_BUS, music_volume)
	_set_bus_volume(SFX_BUS, sfx_volume)

	if DisplayServer.get_name() == "headless":
		return
	if at_startup and not fullscreen and window_scale == DEFAULT_SCALE:
		return
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var size := Vector2i(480, 270) * window_scale
	DisplayServer.window_set_size(size)
	var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)


func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus == -1:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(bus, value <= 0.0)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var bus := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, bus_name)
	AudioServer.set_bus_send(bus, "Master")
