extends CanvasLayer
## Ekran końca poziomu: napis, ściemnienie i przejście do następnego poziomu.
## Jeśli następnego poziomu jeszcze nie ma – napis "już wkrótce" i Enter, żeby zagrać od nowa.

## Ile sekund napis "Poziom ukończony!" jest widoczny przed ściemnieniem.
const SHOW_TIME := 1.8

var _waiting_for_restart := false

@onready var fade: ColorRect = $Fade
@onready var content: Control = $Center
@onready var info: Label = $Center/VBox/Info
@onready var next_label: Label = $Center/VBox/Next


func play(next_level: String, next_level_name: String) -> void:
	info.text = "Pieniążki: %d    Życia: %d" % [GameState.coins, GameState.lives]
	next_label.hide()
	content.modulate.a = 0.0
	fade.color.a = 0.0

	var tween := create_tween()
	tween.tween_property(content, "modulate:a", 1.0, 0.4)
	tween.tween_interval(SHOW_TIME)
	tween.tween_property(fade, "color:a", 1.0, 0.8)
	await tween.finished

	if next_level != "" and ResourceLoader.exists(next_level):
		get_tree().change_scene_to_file(next_level)
		return

	next_label.text = "%s – już wkrótce!\nEnter – zagraj od nowa" % next_level_name
	next_label.show()
	_waiting_for_restart = true


func _unhandled_input(event: InputEvent) -> void:
	if _waiting_for_restart and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_waiting_for_restart = false
		GameState.new_game()
		get_tree().reload_current_scene()
