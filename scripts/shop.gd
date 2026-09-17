extends Control
## Sklepik między poziomami: +1 życie i moce (nasionka, lód).
## Moce działają do utraty życia; naraz tylko jedna – kupno drugiej podmienia pierwszą.

const HEART_ICON := preload("res://assets/sprites/heart.png")
const SEED_ICON := preload("res://assets/sprites/seed_icon.png")
const ICE_ICON := preload("res://assets/sprites/ice_icon.png")
const GOLD := Color(0.98, 0.78, 0.2)

## Poziom wczytywany po kliknięciu "Dalej".
@export_file("*.tscn") var next_level := "res://scenes/levels/orange_town_4.tscn"

var _items: Array[Dictionary] = []
var _text_settings := LabelSettings.new()

@onready var speech: Label = $Speech
@onready var money_label: Label = $Money/MoneyLabel
@onready var lives_label: Label = $Money/LivesLabel
@onready var items_box: HBoxContainer = $Items
@onready var description: Label = $Description
@onready var next_button: Button = $NextButton


func _ready() -> void:
	_text_settings.outline_size = 4
	_text_settings.outline_color = Color(0.08, 0.04, 0.1)

	_items = [
		{"name": "Życie", "price": GameState.LIFE_PRICE, "icon": HEART_ICON, "power": GameState.Power.NONE,
			"text": "+1 życie. Przyda się na trudnej drodze!"},
		{"name": "Nasionka", "price": 40, "icon": SEED_ICON, "power": GameState.Power.SEEDS,
			"text": "Strzelaj (J / X) – nasionko pokonuje Slaima."},
		{"name": "Lód", "price": 60, "icon": ICE_ICON, "power": GameState.Power.FREEZE,
			"text": "Strzelaj (J / X) – Slaim zamarza, stań na nim!"},
	]
	for item in _items:
		_add_card(item)

	_style_button(next_button)
	next_button.pressed.connect(_on_next_pressed)
	next_button.focus_entered.connect(_describe_next)
	next_button.mouse_entered.connect(_describe_next)

	_refresh()
	_focus_first()


func _add_card(item: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(136, 0)
	panel.add_theme_stylebox_override("panel", _box(Color(0.4, 0.22, 0.12), Color(0.98, 0.6, 0.2), 1, 4.0))
	items_box.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(0, 27)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)

	var title := Label.new()
	title.text = item.name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.label_settings = _text_settings
	box.add_child(title)

	var button := Button.new()
	_style_button(button)
	button.pressed.connect(_buy.bind(item))
	button.focus_entered.connect(_describe.bind(item))
	button.mouse_entered.connect(_describe.bind(item))
	box.add_child(button)
	item["button"] = button


func _refresh() -> void:
	money_label.text = "x%d" % GameState.coins
	lives_label.text = "   Życia: %d" % GameState.lives
	for item in _items:
		var button: Button = item.button
		var owned: bool = item.power != GameState.Power.NONE and GameState.power == item.power
		button.text = "Masz!" if owned else "Kup za %d" % item.price
		button.disabled = owned or GameState.coins < item.price


func _buy(item: Dictionary) -> void:
	if item.power == GameState.Power.NONE:
		if not GameState.buy_life():
			return
		speech.text = "Proszę bardzo, jedno życie!"
	else:
		if not GameState.spend(item.price):
			return
		GameState.set_power(item.power)
		speech.text = "Proszę bardzo! Strzelaj klawiszem J albo X."
	_refresh()
	if (item.button as Button).disabled:
		_focus_first()


func _describe(item: Dictionary) -> void:
	description.text = item.text


func _describe_next() -> void:
	description.text = "Idziemy dalej ratować Miasto Pomarańczek!"


func _focus_first() -> void:
	for item in _items:
		var button: Button = item.button
		if not button.disabled:
			button.grab_focus()
			return
	next_button.grab_focus()


func _on_next_pressed() -> void:
	get_tree().change_scene_to_file(next_level)


func _box(bg: Color, border: Color, border_width: int, margin: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_content_margin_all(margin)
	return style


func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _box(Color(0.32, 0.22, 0.44), Color(0.55, 0.42, 0.7), 1, 3.0))
	button.add_theme_stylebox_override("hover", _box(Color(0.46, 0.32, 0.62), GOLD, 1, 3.0))
	button.add_theme_stylebox_override("pressed", _box(Color(0.46, 0.32, 0.62), GOLD, 1, 3.0))
	button.add_theme_stylebox_override("disabled", _box(Color(0.22, 0.16, 0.2), Color(0.35, 0.28, 0.32), 1, 3.0))
	var focus := _box(Color(0, 0, 0, 0), GOLD, 2, 3.0)
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)
