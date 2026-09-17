class_name SettingsPanel
extends VBoxContainer
## Panel ustawień używany w menu głównym i w pauzie. Zmiany są od razu stosowane i zapisywane.

signal closed

var _fullscreen := CheckButton.new()
var _scale := OptionButton.new()
var _volume := HSlider.new()
var _volume_label := Label.new()
var _music := HSlider.new()
var _music_label := Label.new()
var _sfx := HSlider.new()
var _sfx_label := Label.new()
var _back: Button


func _init() -> void:
	add_theme_constant_override("separation", 5)
	add_child(UIStyle.make_label("Ustawienia", UIStyle.GOLD))

	_add_row("Pełny ekran (F11)", _fullscreen)
	_fullscreen.toggled.connect(_on_fullscreen_toggled)

	for s in Settings.WINDOW_SCALES:
		_scale.add_item("%d x %d" % [480 * s, 270 * s])
	_scale.custom_minimum_size = Vector2(130, 0)
	_add_row("Rozmiar okna", _scale)
	_scale.item_selected.connect(_on_scale_selected)

	_add_slider("Głośność", _volume, _volume_label, _on_volume_changed)
	_add_slider("Muzyka", _music, _music_label, _on_music_changed)
	_add_slider("Efekty", _sfx, _sfx_label, _on_sfx_changed)

	_back = UIStyle.make_button("Wróć", 120)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(closed.emit)
	add_child(_back)

	visibility_changed.connect(_on_visibility_changed)


func _ready() -> void:
	Settings.changed.connect(_on_visibility_changed)


func _exit_tree() -> void:
	if Settings.changed.is_connected(_on_visibility_changed):
		Settings.changed.disconnect(_on_visibility_changed)


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


func _add_slider(text: String, slider: HSlider, value_label: Label, on_changed: Callable) -> void:
	var box := HBoxContainer.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 10
	slider.custom_minimum_size = Vector2(90, 16)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_changed)
	value_label.label_settings = UIStyle.text_settings()
	value_label.custom_minimum_size = Vector2(40, 0)
	box.add_child(slider)
	box.add_child(value_label)
	_add_row(text, box)


func _on_visibility_changed() -> void:
	if not visible:
		return
	_fullscreen.set_pressed_no_signal(Settings.fullscreen)
	_scale.select(Settings.WINDOW_SCALES.find(Settings.window_scale))
	_scale.disabled = Settings.fullscreen
	_show_percent(_volume, _volume_label, Settings.volume)
	_show_percent(_music, _music_label, Settings.music_volume)
	_show_percent(_sfx, _sfx_label, Settings.sfx_volume)


func _show_percent(slider: HSlider, label: Label, value: float) -> void:
	slider.set_value_no_signal(roundi(value * 100.0))
	label.text = "%d%%" % roundi(value * 100.0)


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


func _on_music_changed(value: float) -> void:
	Settings.music_volume = value / 100.0
	_music_label.text = "%d%%" % roundi(value)
	_save_and_apply()


func _on_sfx_changed(value: float) -> void:
	Settings.sfx_volume = value / 100.0
	_sfx_label.text = "%d%%" % roundi(value)
	_save_and_apply()
	# Próbka, żeby było słychać nową głośność
	Sfx.play("coin")


func _save_and_apply() -> void:
	Settings.apply()
	Settings.save_settings()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
