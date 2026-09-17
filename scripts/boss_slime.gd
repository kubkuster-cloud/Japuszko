extends CharacterBody2D
## Boss-Slaim: skacze w stronę gracza, a przy lądowaniu trzęsie ekranem.
## Skok na głowę zabiera 4 punkty życia, nasionko 1, lód zamraża go na chwilę (można na nim stanąć).
## Poniżej połowy życia skacze wyżej i częściej. Po pokonaniu emituje "defeated".

signal defeated

enum State { INTRO, IDLE, JUMP, STUNNED, FROZEN, DEAD }

const MAX_HEALTH := 12
const PHASE_TWO_HEALTH := 6
const STOMP_DAMAGE := 4
const SEED_DAMAGE := 1
const FREEZE_TIME := 2.0
## Tolerancja (px) przy rozpoznawaniu skoku na głowę – boss jest duży, więc hojniej niż u Slaima.
const STOMP_TOLERANCE := 6.0
const LAYER_ENEMIES := 4
## Warstwa "frozen": zderza się z nią tylko gracz (może stanąć na lodzie).
const LAYER_FROZEN := 8

## Granice areny (środek bossa), w których boss ląduje.
@export var arena_left := 60.0
@export var arena_right := 420.0

var health := MAX_HEALTH

var _state := State.INTRO
var _timer := 0.0
var _invulnerable := 0.0
var _airborne := false
var _player: Player

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ice_block: Sprite2D = $IceBlock
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	ice_block.hide()
	sprite.play(&"jump")
	get_tree().call_group("hud", "show_boss_bar", "Boss-Slaim", MAX_HEALTH)


func is_defeated() -> bool:
	return _state == State.DEAD


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	sprite.visible = _invulnerable <= 0.0 or fmod(_invulnerable, 0.16) > 0.08

	match _state:
		State.INTRO, State.JUMP:
			velocity.y += get_gravity().y * delta
			move_and_slide()
			if not is_on_floor():
				_airborne = true
			elif _airborne:
				_land()
		State.IDLE, State.STUNNED:
			velocity.x = 0.0
			velocity.y += get_gravity().y * delta
			move_and_slide()
			_timer -= delta
			if _timer <= 0.0:
				if _state == State.STUNNED:
					_state = State.IDLE
					_timer = 0.5 if _is_angry() else 1.0
					sprite.play(&"idle")
				else:
					_jump()
		State.FROZEN:
			_timer -= delta
			ice_block.visible = _timer > 0.6 or fmod(_timer, 0.2) > 0.1
			if _timer <= 0.0:
				_unfreeze()
			return

	_check_player(delta)


func take_damage(amount: int, invulnerability := 1.0) -> void:
	if _state == State.DEAD or _invulnerable > 0.0:
		return
	health = maxi(health - amount, 0)
	get_tree().call_group("hud", "set_boss_health", health)
	_invulnerable = invulnerability
	if _state == State.FROZEN:
		_unfreeze()
	if health <= 0:
		_die()


func hit_by_seed() -> void:
	take_damage(SEED_DAMAGE, 0.3)


func freeze() -> void:
	if _state not in [State.IDLE, State.STUNNED]:
		return
	_state = State.FROZEN
	_timer = FREEZE_TIME
	velocity = Vector2.ZERO
	sprite.pause()
	sprite.modulate = Color(0.65, 0.85, 1.0)
	ice_block.show()
	collision_layer = LAYER_FROZEN | LAYER_ENEMIES


func _unfreeze() -> void:
	sprite.modulate = Color.WHITE
	ice_block.hide()
	collision_layer = LAYER_ENEMIES
	_state = State.IDLE
	_timer = 0.3
	sprite.play(&"idle")


func _is_angry() -> bool:
	return health <= PHASE_TWO_HEALTH


func _jump() -> void:
	var jump_speed := 440.0 if _is_angry() else 380.0
	var air_time := 2.0 * jump_speed / get_gravity().y
	var target := global_position.x
	if _player and not _player.is_dead():
		target = _player.global_position.x
	target = clampf(target, arena_left, arena_right)
	velocity = Vector2(clampf((target - global_position.x) / air_time, -220.0, 220.0), -jump_speed)
	_state = State.JUMP
	_airborne = false
	sprite.play(&"jump")


func _land() -> void:
	velocity = Vector2.ZERO
	_airborne = false
	_state = State.STUNNED
	_timer = 0.35 if _is_angry() else 0.6
	sprite.play(&"land")
	_shake(0.3, 4.0)


func _check_player(delta: float) -> void:
	if _player == null or _player.is_dead() or _invulnerable > 0.0:
		return
	var player_box := _player.get_hitbox()
	var shape := collision_shape.shape as RectangleShape2D
	var my_box := Rect2(collision_shape.global_position - shape.size / 2.0, shape.size).grow(-2.0)
	if not my_box.intersects(player_box):
		return

	var previous_feet_y := player_box.end.y - (_player.velocity.y - velocity.y) * delta
	if _player.velocity.y > velocity.y and previous_feet_y <= my_box.position.y + STOMP_TOLERANCE:
		take_damage(STOMP_DAMAGE)
		_player.bounce()
		_player.velocity.y = -330.0
	else:
		_player.take_hit()


func _die() -> void:
	_state = State.DEAD
	velocity = Vector2.ZERO
	sprite.visible = true
	sprite.play(&"dead")
	collision_shape.set_deferred("disabled", true)
	_shake(0.6, 5.0)
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_callback(get_tree().call_group.bind("hud", "hide_boss_bar"))
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tween.tween_callback(defeated.emit)


func _shake(duration: float, strength: float) -> void:
	if _player == null:
		return
	var camera := _player.camera
	var tween := create_tween()
	for i in int(duration / 0.05):
		tween.tween_property(camera, "offset", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.05)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
