extends CanvasLayer
## Ekran końca poziomu: napis, ściemnienie i przejście do następnego poziomu.
## Z tekstem zakończenia (ending_text) czeka na Enter przed przejściem.
## Jeśli następnego poziomu jeszcze nie ma – napis "już wkrótce" i Enter, żeby zagrać od nowa.

## Ile sekund napis "Poziom ukończony!" jest widoczny przed ściemnieniem.
const SHOW_TIME := 1.8

var _waiting := false
var _next_after_enter := ""

@onready var fade: ColorRect = $Fade
@onready var content: Control = $Center
@onready var title: Label = $Center/VBox/Title
@onready var info: Label = $Center/VBox/Info
@onready var next_label: Label = $Center/VBox/Next


func play(next_level: String, next_level_name: String, rescued := 0, rescue_total := 0,
		title_text := "", ending_text := "") -> void:
	# Muzyka cichnie, gra dżingiel zwycięstwa.
	Music.stop()
	Sfx.play("level_complete")
	if title_text != "":
		title.text = title_text
	info.text = "Pieniążki: %d    Życia: %d" % [GameState.coins, GameState.lives]
	if rescue_total > 0:
		info.text += "\nUratowani mieszkańcy: %d/%d" % [rescued, rescue_total]
	next_label.hide()
	content.modulate.a = 0.0
	fade.color.a = 0.0

	var tween := create_tween()
	tween.tween_property(content, "modulate:a", 1.0, 0.4)
	tween.tween_interval(SHOW_TIME)
	tween.tween_property(fade, "color:a", 1.0, 0.8)
	await tween.finished

	var next_exists := next_level != "" and ResourceLoader.exists(next_level)
	if ending_text != "":
		next_label.text = ending_text
		_next_after_enter = next_level if next_exists else ""
	elif next_exists:
		get_tree().change_scene_to_file(next_level)
		return
	else:
		next_label.text = "%s – już wkrótce!\nEnter – zagraj od nowa" % next_level_name
	next_label.show()
	_waiting = true


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting or not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	_waiting = false
	if _next_after_enter != "":
		get_tree().change_scene_to_file(_next_after_enter)
	else:
		GameState.new_game()
		get_tree().reload_current_scene()
