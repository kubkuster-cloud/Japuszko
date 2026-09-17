extends Area2D
## Meta poziomu (drogowskaz). Gdy gracz do niej dojdzie, emituje "reached" – resztą zajmuje się poziom.

signal reached

var _done := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if _done or player == null or player.is_dead():
		return
	_done = true
	reached.emit()
