extends Node
## Muzyka w tle (autoload "Music"). Utwory przechodzą jeden w drugi płynnie;
## ten sam utwór gra dalej bez przerwy przy zmianie sceny (np. między poziomami Miasta Pomarańczek).
## Gra na kanale "Music" – jego głośność ustawia suwak "Muzyka" w ustawieniach.

const TRACKS_DIR := "res://assets/music/"
const FADE_TIME := 0.8
const SILENT_DB := -40.0

var current_track := ""

var _player := AudioStreamPlayer.new()
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player.bus = Settings.MUSIC_BUS
	add_child(_player)


## Włącza utwór o nazwie pliku z assets/music (np. "apple"). Pusta nazwa wycisza muzykę.
func play(track: String) -> void:
	if track == current_track:
		return
	current_track = track
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if _player.playing:
		_tween.tween_property(_player, "volume_db", SILENT_DB, FADE_TIME * 0.5)
	_tween.tween_callback(_switch_to.bind(track))
	if track != "":
		_tween.tween_property(_player, "volume_db", 0.0, FADE_TIME * 0.5)


func stop() -> void:
	play("")


func _switch_to(track: String) -> void:
	_player.stop()
	if track == "":
		return
	var path := TRACKS_DIR + track + ".wav"
	if not ResourceLoader.exists(path):
		push_warning("Brak utworu: " + path)
		return
	_player.stream = load(path)
	_player.volume_db = SILENT_DB
	_player.play()
