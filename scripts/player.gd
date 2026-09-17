class_name Player
extends CharacterBody2D
## Jabłuszko – sterowanie gracza: ruch lewo/prawo, skok, grawitacja, śmierć i respawn.

## Emitowany w chwili śmierci (przed animacją spadania).
signal died
## Emitowany po powrocie na spawn. killed_by_enemy = true, jeśli gracz zginął od wroga.
signal respawned(killed_by_enemy: bool)

const PROJECTILE_SCENE := preload("res://scenes/objects/projectile.tscn")

@export var move_speed: float = 120.0
@export var acceleration: float = 900.0
@export var friction: float = 1100.0
@export var air_acceleration: float = 600.0
@export var jump_velocity: float = -290.0
## Mnożnik prędkości w górę po puszczeniu skoku (krótkie wciśnięcie = niższy skok).
@export var jump_cut_multiplier: float = 0.5
@export var max_fall_speed: float = 400.0
## Czas (s), przez który można jeszcze skoczyć po zejściu z krawędzi.
@export var coyote_time: float = 0.1
## Czas (s), przez który wciśnięcie skoku tuż przed lądowaniem jest zapamiętane.
@export var jump_buffer_time: float = 0.1

@export_group("Wrogowie i śmierć")
## Odbicie po skoku na wroga (bez trzymania skoku). Trzymając skok, Jabłuszko odbija się na pełną wysokość.
@export var stomp_bounce_velocity: float = -200.0
## Podskok Jabłuszka w chwili śmierci, zanim spadnie z ekranu.
@export var death_hop_velocity: float = -220.0
## Czas (s) od śmierci do respawnu.
@export var respawn_delay: float = 1.2
## Czas (s) nietykalności po respawnie – wrogowie nie mogą zranić gracza.
@export var respawn_invulnerability: float = 1.5

@export_group("Moce")
## Najkrótszy odstęp (s) między strzałami nasionkami / lodem.
@export var shoot_cooldown: float = 0.35

## Miejsce, w którym gracz pojawia się po śmierci (domyślnie pozycja startowa).
var spawn_position: Vector2
## false w czasie przerywników – gracz nie reaguje na klawisze (grawitacja działa dalej).
var controls_enabled := true

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _was_on_floor := true
var _is_dead := false
var _killed_by_enemy := false
var _invulnerable_timer := 0.0
var _shoot_timer := 0.0

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	spawn_position = global_position


func is_dead() -> bool:
	return _is_dead


## Prostokąt kolizji gracza we współrzędnych globalnych – używany przez wrogów do sprawdzania trafień.
func get_hitbox() -> Rect2:
	var shape := collision_shape.shape as RectangleShape2D
	return Rect2(collision_shape.global_position - shape.size / 2.0, shape.size)


## Śmierć bez względu na nietykalność (np. przepaść).
func die(killed_by_enemy := false) -> void:
	if _is_dead:
		return
	_is_dead = true
	_killed_by_enemy = killed_by_enemy
	velocity = Vector2(0.0, death_hop_velocity)
	visual.scale = Vector2.ONE
	visual.visible = true
	sprite.play(&"hurt")
	Sfx.play("hurt")
	died.emit()
	get_tree().create_timer(respawn_delay).timeout.connect(_respawn)


## Trafienie przez wroga – ignorowane w czasie nietykalności po respawnie.
func take_hit() -> void:
	if _invulnerable_timer > 0.0:
		return
	die(true)


## Odbicie po skoku na wroga.
func bounce() -> void:
	velocity.y = jump_velocity if Input.is_action_pressed("jump") else stomp_bounce_velocity
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_squash(Vector2(0.75, 1.25))


func _physics_process(delta: float) -> void:
	if _is_dead:
		# Podskok i spadanie przez wszystko, jak w Mario
		velocity += get_gravity() * delta
		position += velocity * delta
		return

	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta
		visual.visible = _invulnerable_timer <= 0.0 or fmod(_invulnerable_timer, 0.2) > 0.1

	_shoot_timer -= delta
	if controls_enabled and Input.is_action_just_pressed("shoot"):
		_try_shoot()

	var on_floor := is_on_floor()

	# Grawitacja (wartość z Project Settings > Physics > 2D > Default Gravity)
	if not on_floor:
		velocity += get_gravity() * delta
		velocity.y = minf(velocity.y, max_fall_speed)

	# Coyote time i bufor skoku
	if on_floor:
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if controls_enabled and Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta

	# Skok
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_squash(Vector2(0.75, 1.25))
		Sfx.play("jump", 0.05)

	# Zmienna wysokość skoku
	if controls_enabled and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	# Ruch poziomy
	var direction := Input.get_axis("move_left", "move_right") if controls_enabled else 0.0
	if direction != 0.0:
		var accel := acceleration if on_floor else air_acceleration
		velocity.x = move_toward(velocity.x, direction * move_speed, accel * delta)
	else:
		var decel := friction if on_floor else air_acceleration
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	move_and_slide()

	# Lądowanie
	if is_on_floor() and not _was_on_floor:
		_squash(Vector2(1.25, 0.75))
		Sfx.play("land", 0.1, -10.0)
	_was_on_floor = is_on_floor()

	_update_animation(direction)

	# Powrót do normalnego kształtu po ściśnięciu/rozciągnięciu
	visual.scale = visual.scale.lerp(Vector2.ONE, 1.0 - exp(-15.0 * delta))


func _update_animation(direction: float) -> void:
	if direction != 0.0:
		sprite.flip_h = direction < 0.0

	if not is_on_floor():
		sprite.play(&"jump" if velocity.y < 0.0 else &"fall")
	elif absf(velocity.x) > 10.0:
		sprite.play(&"walk")
	else:
		sprite.play(&"idle")


## Strzał nasionkiem albo lodem – tylko z kupioną mocą.
func _try_shoot() -> void:
	if GameState.power == GameState.Power.NONE or _shoot_timer > 0.0:
		return
	_shoot_timer = shoot_cooldown
	var shot := PROJECTILE_SCENE.instantiate()
	var dir := -1.0 if sprite.flip_h else 1.0
	shot.direction = dir
	shot.kind = GameState.power
	shot.position = global_position + Vector2(8.0 * dir, -9.0)
	get_parent().add_child(shot)
	Sfx.play("shoot_ice" if GameState.power == GameState.Power.FREEZE else "shoot_seed", 0.08)


func _squash(amount: Vector2) -> void:
	visual.scale = amount


func _respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	visual.scale = Vector2.ONE
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_was_on_floor = true
	_is_dead = false
	_invulnerable_timer = respawn_invulnerability
	sprite.play(&"idle")
	camera.reset_smoothing()
	Sfx.play("respawn", 0.0, -4.0)
	respawned.emit(_killed_by_enemy)
