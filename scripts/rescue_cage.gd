extends Area2D
## Klatka ze slime'u z uwięzionym mieszkańcem. Dotknięcie przez gracza uwalnia mieszkańca.
## Poziom liczy klatki w węźle "Rescues" i pokazuje licznik w HUD.

signal rescued

var _is_free := false

@onready var resident: AnimatedSprite2D = $Resident
@onready var cage: Sprite2D = $Cage
@onready var thanks: Label = $Thanks


func _ready() -> void:
	thanks.hide()
	body_entered.connect(_on_body_entered)


func is_rescued() -> bool:
	return _is_free


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if _is_free or player == null or player.is_dead():
		return
	_is_free = true
	set_deferred("monitoring", false)
	rescued.emit()
	Sfx.play("rescue")

	# Klatka pęka
	var burst := create_tween().set_parallel()
	burst.tween_property(cage, "scale", Vector2(1.4, 1.4), 0.25)
	burst.tween_property(cage, "modulate:a", 0.0, 0.25)

	# Mieszkaniec skacze z radości, dziękuje i znika
	var y := resident.position.y
	resident.play(&"jump")
	var hop := create_tween()
	hop.tween_property(resident, "position:y", y - 14.0, 0.2).set_ease(Tween.EASE_OUT)
	hop.tween_property(resident, "position:y", y, 0.2).set_ease(Tween.EASE_IN)
	hop.tween_callback(resident.play.bind(&"idle"))
	hop.tween_interval(0.6)
	hop.tween_property(resident, "modulate:a", 0.0, 0.4)

	thanks.show()
	var text := create_tween().set_parallel()
	text.tween_property(thanks, "position:y", thanks.position.y - 12.0, 1.2)
	text.tween_property(thanks, "modulate:a", 0.0, 0.6).set_delay(0.6)
