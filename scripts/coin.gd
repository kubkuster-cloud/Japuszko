extends Area2D
## Pieniążek do zebrania. Zebrane pieniążki nie wracają po śmierci gracza.

@export var value: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or player.is_dead():
		return
	set_deferred("monitoring", false)
	GameState.add_coins(value)

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 12.0, 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
