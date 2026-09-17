extends CharacterBody2D
## Slaim – prosty wróg: chodzi w lewo/prawo, zawraca przy ścianie i na krawędzi platformy.
## Skok na głowę go pokonuje, dotknięcie z boku rani gracza.
## Nasionko go pokonuje, lodowy pocisk zamienia go na chwilę w bryłę lodu, na której można stanąć.

const LEDGE_CHECK_X := 7.0
## Tolerancja (px) przy rozpoznawaniu skoku na głowę.
const STOMP_TOLERANCE := 3.0
## Ile sekund Slaim zostaje zamrożony.
const FREEZE_TIME := 4.0
const LAYER_ENEMIES := 4
## Warstwa "frozen": zderza się z nią tylko gracz (może stanąć na lodzie), inne Slaimy przez nią przechodzą.
const LAYER_FROZEN := 8

@export var speed: float = 30.0
@export_enum("Lewo:-1", "Prawo:1") var direction: int = -1

var _dead := false
var _frozen_timer := 0.0
var _player: Player

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ice_block: Sprite2D = $IceBlock
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ledge_check: RayCast2D = $LedgeCheck


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	ice_block.hide()
	_face(direction)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	if _frozen_timer > 0.0:
		_frozen_timer -= delta
		# Ostatnia sekunda – lód miga, że zaraz puści
		ice_block.visible = _frozen_timer > 1.0 or fmod(_frozen_timer, 0.2) > 0.1
		if _frozen_timer <= 0.0:
			_unfreeze()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
	elif _should_turn():
		_face(-direction)

	velocity.x = direction * speed
	move_and_slide()
	_check_player(delta)


func is_frozen() -> bool:
	return _frozen_timer > 0.0


func freeze() -> void:
	if _dead:
		return
	_frozen_timer = FREEZE_TIME
	velocity = Vector2.ZERO
	sprite.pause()
	sprite.modulate = Color(0.65, 0.85, 1.0)
	ice_block.show()
	Sfx.play("freeze", 0.05)
	# Gracz może stanąć na zamrożonym Slaimie; inne Slaimy go ignorują.
	collision_layer = LAYER_FROZEN | LAYER_ENEMIES


func hit_by_seed() -> void:
	if not _dead:
		_die()


func _unfreeze() -> void:
	_frozen_timer = 0.0
	sprite.play()
	sprite.modulate = Color.WHITE
	ice_block.hide()
	collision_layer = LAYER_ENEMIES


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
	if _frozen_timer > 0.0:
		_unfreeze()
	_dead = true
	velocity = Vector2.ZERO
	sprite.play(&"squished")
	Sfx.play("stomp", 0.1)
	collision_shape.set_deferred("disabled", true)
	get_tree().create_timer(0.5).timeout.connect(queue_free)
