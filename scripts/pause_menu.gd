class_name PauseMenu
extends CanvasLayer
## Pauza w trakcie gry (Esc / P / Start): Wznów, Ustawienia, Wyjdź do menu.
## Poziom tworzy ją sam w _ready – nie trzeba jej wstawiać do scen.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

## Gracz – pauzy nie da się włączyć w czasie intro, śmierci ani końca poziomu.
var player: Player

var _buttons: VBoxContainer
var _settings: SettingsPanel


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style())
	center.add_child(panel)

	var content := VBoxContainer.new()
	panel.add_child(content)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 4)
	_buttons.add_child(UIStyle.make_label("Pauza", UIStyle.GOLD))
	for entry in [["Wznów", close], ["Ustawienia", _open_settings], ["Wyjdź do menu", _quit_to_menu]]:
		var button := UIStyle.make_button(entry[0])
		button.pressed.connect(entry[1])
		_buttons.add_child(button)
	content.add_child(_buttons)

	_settings = SettingsPanel.new()
	_settings.hide()
	_settings.closed.connect(_close_settings)
	content.add_child(_settings)

	hide()


func open() -> void:
	Sfx.play("pause")
	show()
	_close_settings()
	get_tree().paused = true


func close() -> void:
	Sfx.play("pause")
	hide()
	get_tree().paused = false


func _can_open() -> bool:
	return not get_tree().paused and player != null and player.controls_enabled and not player.is_dead()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		get_viewport().set_input_as_handled()
		if _settings.visible:
			_close_settings()
		else:
			close()
	elif _can_open():
		get_viewport().set_input_as_handled()
		open()


func _open_settings() -> void:
	_buttons.hide()
	_settings.show()
	_settings.focus_first()


func _close_settings() -> void:
	_settings.hide()
	_buttons.show()
	(_buttons.get_child(1) as Button).grab_focus()


func _quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
