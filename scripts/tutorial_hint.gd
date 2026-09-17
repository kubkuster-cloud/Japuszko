@tool
extends Area2D
## Strefa samouczka: gdy gracz w niej jest, na dole ekranu wyświetla się podpowiedź.
## Rozmiar strefy ustawiasz polem "size" w Inspektorze (widać go od razu w edytorze).

@export_multiline var text := ""
@export var size := Vector2(96, 320):
	set(value):
		size = value
		_update_shape()


func _ready() -> void:
	_update_shape()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _update_shape() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		get_tree().call_group("hud", "show_hint", text)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		get_tree().call_group("hud", "hide_hint", text)
