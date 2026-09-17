extends Area2D
## Strefa śmierci (przepaść, woda itp.). Gracz, który w nią wpadnie, ginie.
## Scenę można też ręcznie wstawiać na poziom i rozciągać jej CollisionShape2D.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
