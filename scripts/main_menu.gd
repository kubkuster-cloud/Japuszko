extends Control
## Menu główne: Kontynuuj, Nowa gra, Wczytaj grę, Ustawienia, Wyjście.
## Nowa gra i Wczytaj grę prowadzą do wyboru jednego z 3 miejsc zapisu.

const FIRST_LEVEL := "res://scenes/levels/apple_town.tscn"

var _panels := {}
var _slot_mode := "new"
var _slot_buttons: Array[Button] = []
var _slots_header: Label
var _confirm_label: Label
var _pending_slot := 0

@onready var menu_area: CenterContainer = $MenuArea


func _ready() -> void:
	get_tree().paused = false
	RenderingServer.set_default_clear_color(Color(0.55, 0.8, 0.95))
	$Title.text = ProjectSettings.get_setting("application/config/name")
	_build_main()
	_build_slots()
	_build_confirm()
	var settings := SettingsPanel.new()
	settings.closed.connect(_show.bind("main"))
	_add_panel("settings", settings)
	_show("main")


func _add_panel(panel_name: String, content: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style())
	panel.add_child(content)
	menu_area.add_child(panel)
	_panels[panel_name] = panel


func _button(parent: Container, text: String, action: Callable, width := 170.0) -> Button:
	var button := UIStyle.make_button(text, width)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _build_main() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var latest := SaveManager.latest_slot()
	if latest > 0:
		_button(box, "Kontynuuj", _load_slot.bind(latest))
	_button(box, "Nowa gra", _open_slots.bind("new"))
	_button(box, "Wczytaj grę", _open_slots.bind("load")).disabled = not SaveManager.has_any_save()
	_button(box, "Ustawienia", _show.bind("settings"))
	_button(box, "Wyjście", get_tree().quit)
	_add_panel("main", box)


func _build_slots() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_slots_header = UIStyle.make_label("", UIStyle.GOLD)
	box.add_child(_slots_header)
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		var button := _button(box, "", _on_slot_pressed.bind(slot), 400)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_slot_buttons.append(button)
	_button(box, "Wróć", _show.bind("main"), 120)
	_add_panel("slots", box)


func _build_confirm() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_confirm_label = UIStyle.make_label("")
	box.add_child(_confirm_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	_button(row, "Tak", _on_confirm_yes, 90)
	_button(row, "Nie", _show.bind("slots"), 90)
	box.add_child(row)
	_add_panel("confirm", box)


func _show(panel_name: String) -> void:
	for key in _panels:
		_panels[key].visible = key == panel_name
	match panel_name:
		"settings":
			(_panels.settings.get_child(0) as SettingsPanel).focus_first()
		"confirm":
			_focus_first_button(_panels.confirm)
		_:
			_focus_first_button(_panels[panel_name])


func _focus_first_button(node: Node) -> void:
	for child in node.find_children("*", "Button", true, false):
		var button := child as Button
		if not button.disabled:
			button.grab_focus()
			return


func _open_slots(mode: String) -> void:
	_slot_mode = mode
	_slots_header.text = "Nowa gra – wybierz miejsce zapisu" if mode == "new" else "Wczytaj grę"
	for i in _slot_buttons.size():
		var slot := i + 1
		var info := SaveManager.get_info(slot)
		var button := _slot_buttons[i]
		if info.is_empty():
			button.text = "%d.  – pusty –" % slot
		else:
			button.text = "%d.  %s\n     Życia: %d   Pieniążki: %d   %s" % [
				slot, info.level_name, info.lives, info.coins, str(info.saved_at).substr(0, 16)]
		button.disabled = mode == "load" and info.is_empty()
	_show("slots")


func _on_slot_pressed(slot: int) -> void:
	if _slot_mode == "load":
		_load_slot(slot)
	elif SaveManager.has_save(slot):
		_pending_slot = slot
		_confirm_label.text = "Miejsce %d jest zajęte.\nNadpisać zapis nową grą?" % slot
		_show("confirm")
	else:
		_start_new(slot)


func _on_confirm_yes() -> void:
	_start_new(_pending_slot)


func _start_new(slot: int) -> void:
	SaveManager.start_new_game(slot)
	get_tree().change_scene_to_file(FIRST_LEVEL)


func _load_slot(slot: int) -> void:
	var scene := SaveManager.load_game(slot)
	if scene != "" and ResourceLoader.exists(scene):
		get_tree().change_scene_to_file(scene)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _panels.slots.visible:
		get_viewport().set_input_as_handled()
		_show("main")
	elif _panels.confirm.visible:
		get_viewport().set_input_as_handled()
		_show("slots")
