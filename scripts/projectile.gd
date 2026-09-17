extends Area2D
## Pocisk z mocy gracza: nasionko (pokonuje Slaima) albo lodowy pocisk (zamraża Slaima).
## Leci poziomo i znika po trafieniu w cokolwiek albo po czasie "lifetime".

const SEED_TEXTURE := preload("res://assets/sprites/seed.png")
const ICE_TEXTURE := preload("res://assets/sprites/ice_shot.png")

@export var speed := 220.0
@export var lifetime := 1.0

## 1 = w prawo, -1 = w lewo. Ustawiane przed dodaniem do sceny.
var direction := 1.0
var kind: GameState.Power = GameState.Power.SEEDS

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = ICE_TEXTURE if kind == GameState.Power.FREEZE else SEED_TEXTURE
	sprite.flip_h = direction < 0.0
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta
	if kind == GameState.Power.FREEZE:
		sprite.rotation += 10.0 * delta


func _on_body_entered(body: Node2D) -> void:
	if kind == GameState.Power.FREEZE and body.has_method("freeze"):
		body.freeze()
	elif kind == GameState.Power.SEEDS and body.has_method("hit_by_seed"):
		body.hit_by_seed()
	queue_free()
