extends CharacterBody2D
## Slaim – prosty wróg: chodzi w lewo/prawo, zawraca przy ścianie i na krawędzi platformy.
## Skok na głowę go pokonuje, dotknięcie z boku rani gracza.

const LEDGE_CHECK_X := 7.0
## Tolerancja (px) przy rozpoznawaniu skoku na głowę.
const STOMP_TOLERANCE := 3.0

@export var speed: float = 30.0
@export_enum("Lewo:-1", "Prawo:1") var direction: int = -1

var _dead := false
var _player: Player

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ledge_check: RayCast2D = $LedgeCheck


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	_face(direction)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
	elif _should_turn():
		_face(-direction)

	velocity.x = direction * speed
	move_and_slide()
	_check_player(delta)


func _should_turn() -> bool:
	if is_on_wall() and get_wall_normal().x * direction < 0.0:
		return true
	ledge_check.force_raycast_update()
	return not ledge_check.is_colliding()


func _face(dir: int) -> void:
	direction = dir
	ledge_check.position.x = LEDGE_CHECK_X * dir
	sprite.flip_h = dir > 0


## Porównuje aktualne prostokąty kolizji (Area2D zgłasza nakładanie z opóźnieniem klatki,
## przez co szybko spadający gracz "wpadał" w Slaima zamiast na niego skoczyć).
func _check_player(delta: float) -> void:
	if _player == null or _player.is_dead():
		return
	var player_box := _player.get_hitbox()
	var shape := collision_shape.shape as RectangleShape2D
	var my_box := Rect2(collision_shape.global_position - shape.size / 2.0, shape.size).grow(-1.0)
	if not my_box.intersects(player_box):
		return

	# Skok na głowę: gracz spada, a w poprzedniej klatce jego stopy były nad głową Slaima.
	var previous_feet_y := player_box.end.y - _player.velocity.y * delta
	if _player.velocity.y > 0.0 and previous_feet_y <= my_box.position.y + STOMP_TOLERANCE:
		_player.bounce()
		_die()
	else:
		_player.take_hit()


func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	sprite.play(&"squished")
	collision_shape.set_deferred("disabled", true)
	get_tree().create_timer(0.5).timeout.connect(queue_free)
