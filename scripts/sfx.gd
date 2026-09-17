extends Node
## Efekty dźwiękowe (autoload "Sfx"). Sfx.play("coin") odtwarza assets/sfx/coin.wav na kanale "SFX".
## Dźwięki interfejsu (przesuwanie po menu, kliknięcie przycisku) dodaje sam – dla wszystkich przycisków w grze.

const DIR := "res://assets/sfx/"
## Ile dźwięków może grać naraz.
const VOICES := 12

## Ostatnio zagrane dźwięki (przydatne przy testach).
var history: PackedStringArray = []

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = Settings.SFX_BUS
		add_child(player)
		_players.append(player)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	get_tree().node_added.connect(_on_node_added)


## pitch_jitter: losowa zmiana wysokości (np. 0.05), żeby powtarzane dźwięki nie brzmiały identycznie.
func play(effect: String, pitch_jitter := 0.0, volume_db := 0.0) -> void:
	var stream := _stream(effect)
	if stream == null:
		return
	var player := _free_player()
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.volume_db = volume_db
	player.play()
	history.append(effect)
	if history.size() > 100:
		history.remove_at(0)


func _stream(effect: String) -> AudioStream:
	if not _cache.has(effect):
		var path := DIR + effect + ".wav"
		_cache[effect] = load(path) if ResourceLoader.exists(path) else null
		if _cache[effect] == null:
			push_warning("Brak dźwięku: " + path)
	return _cache[effect]


func _free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	# Wszystkie zajęte – zabieramy najstarszy.
	_next = (_next + 1) % _players.size()
	return _players[_next]


func _on_focus_changed(control: Control) -> void:
	if control is BaseButton or control is Slider:
		play("ui_move", 0.0, -8.0)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(play.bind("ui_select", 0.0, -4.0))
