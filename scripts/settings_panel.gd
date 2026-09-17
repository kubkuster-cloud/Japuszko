class_name SettingsPanel
extends VBoxContainer
## Panel ustawień używany w menu głównym i w pauzie. Zmiany są od razu stosowane i zapisywane.

signal closed

var _fullscreen := CheckButton.new()
var _scale := OptionButton.new()
var _volume := HSlider.new()
var _volume_label := Label.new()
var _back: Button


func _init() -> void:
	add_theme_constant_override("separation", 6)
	add_child(UIStyle.make_label("Ustawienia", UIStyle.GOLD))

	_add_row("Pełny ekran", _fullscreen)
	_fullscreen.toggled.connect(_on_fullscreen_toggled)

	for s in Settings.WINDOW_SCALES:
		_scale.add_item("%d x %d" % [480 * s, 270 * s])
	_scale.custom_minimum_size = Vector2(130, 0)
	_add_row("Rozmiar okna", _scale)
	_scale.item_selected.connect(_on_scale_selected)

	var volume_box := HBoxContainer.new()
	_volume.min_value = 0
	_volume.max_value = 100
	_volume.step = 10
	_volume.custom_minimum_size = Vector2(90, 16)
	_volume.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume.value_changed.connect(_on_volume_changed)
	_volume_label.label_settings = UIStyle.text_settings()
	_volume_label.custom_minimum_size = Vector2(40, 0)
	volume_box.add_child(_volume)
	volume_box.add_child(_volume_label)
	_add_row("Głośność", volume_box)

	_back = UIStyle.make_button("Wróć", 120)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(closed.emit)
	add_child(_back)

	visibility_changed.connect(_on_visibility_changed)


func focus_first() -> void:
	_fullscreen.grab_focus()


func _add_row(text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = text
	label.label_settings = UIStyle.text_settings()
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)
	row.add_child(control)
	add_child(row)


func _on_visibility_changed() -> void:
	if not visible:
		return
	_fullscreen.set_pressed_no_signal(Settings.fullscreen)
	_scale.select(Settings.WINDOW_SCALES.find(Settings.window_scale))
	_scale.disabled = Settings.fullscreen
	_volume.set_value_no_signal(roundi(Settings.volume * 100.0))
	_volume_label.text = "%d%%" % roundi(Settings.volume * 100.0)


func _on_fullscreen_toggled(on: bool) -> void:
	Settings.fullscreen = on
	_scale.disabled = on
	_save_and_apply()


func _on_scale_selected(index: int) -> void:
	Settings.window_scale = Settings.WINDOW_SCALES[index]
	_save_and_apply()


func _on_volume_changed(value: float) -> void:
	Settings.volume = value / 100.0
	_volume_label.text = "%d%%" % roundi(value)
	_save_and_apply()


func _save_and_apply() -> void:
	Settings.apply()
	Settings.save_settings()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
