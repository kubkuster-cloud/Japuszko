extends CanvasLayer
## HUD: życia i pieniążki w lewym górnym rogu, podpowiedzi samouczka na dole ekranu.

var _hint_text := ""

@onready var lives_label: Label = $Bar/LivesLabel
@onready var coins_label: Label = $Bar/CoinsLabel
@onready var rescue_label: Label = $Bar/RescueLabel
@onready var rescue_nodes: Array[Control] = [$Bar/RescueSpacer, $Bar/RescueIcon, $Bar/RescueLabel]
@onready var hint: PanelContainer = $HintArea/Hint
@onready var hint_label: Label = $HintArea/Hint/Label


func _ready() -> void:
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.coins_changed.connect(_on_coins_changed)
	_on_lives_changed(GameState.lives)
	_on_coins_changed(GameState.coins)
	hint.hide()


func show_hint(text: String) -> void:
	if text == _hint_text:
		return
	_hint_text = text
	hint_label.text = text
	hint.show()
	hint.modulate.a = 0.0
	create_tween().tween_property(hint, "modulate:a", 1.0, 0.2)


## Chowa podpowiedź, ale tylko jeśli to ta sama, która jest wyświetlana
## (gracz mógł już wejść do kolejnej strefy).
func hide_hint(text: String) -> void:
	if text != _hint_text:
		return
	_hint_text = ""
	hint.hide()


## Licznik uratowanych mieszkańców – widoczny tylko na poziomach z klatkami.
func set_rescued(count: int, total: int) -> void:
	for node in rescue_nodes:
		node.visible = total > 0
	rescue_label.text = "%d/%d" % [count, total]


func _on_lives_changed(lives: int) -> void:
	lives_label.text = "x%d" % lives


func _on_coins_changed(coins: int) -> void:
	coins_label.text = "x%d" % coins
