extends Node
## Ustawienia gry (autoload "Settings"), zapisywane w user://settings.cfg.

const PATH := "user://settings.cfg"
const WINDOW_SCALES := [2, 3, 4]
## Rozmiar okna ustawiony w projekcie (1440x810 = 480x270 razy 3).
const DEFAULT_SCALE := 3

var fullscreen := false
var window_scale := DEFAULT_SCALE
## Głośność 0..1.
var volume := 0.8


func _ready() -> void:
	load_settings()
	apply(true)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	fullscreen = cfg.get_value("display", "fullscreen", fullscreen)
	window_scale = cfg.get_value("display", "window_scale", window_scale)
	volume = cfg.get_value("audio", "volume", volume)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "window_scale", window_scale)
	cfg.set_value("audio", "volume", volume)
	cfg.save(PATH)


## Stosuje ustawienia. Przy starcie gry nie rusza okna, jeśli ustawienia są domyślne.
func apply(at_startup := false) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus, volume <= 0.0)

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
