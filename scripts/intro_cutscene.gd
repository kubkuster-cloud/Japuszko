extends Node2D
## Intro Miasta Jabłuszek: spokojne miasto → napad Slaimów → porwanie mieszkańców → ucieczka.
## Zaraz potem gracz przejmuje sterowanie i ucieka przez samouczek.
## Można pominąć (Spacja / Enter / Esc). Po obejrzeniu (GameState.intro_seen) przy kolejnym
## wczytaniu poziomu od razu ustawia stan "po napadzie", bez animacji.

const SLIME_SCENE := preload("res://scenes/enemies/slime.tscn")
## Z jakiej wysokości (px) spadają Slaimy.
const DROP_HEIGHT := 260.0

## Dodatkowe Slaimy (poza tymi, które porywają mieszkańców) – pozycje x.
@export var extra_slime_x: Array[float] = [-376.0]

var _finished := false
var _slime_x: Array[float] = []

@onready var camera: Camera2D = $Camera2D
@onready var ui: CanvasLayer = $UI
@onready var fade: ColorRect = $UI/Fade
@onready var top_bar: ColorRect = $UI/TopBar
@onready var bottom_bar: ColorRect = $UI/BottomBar
@onready var caption: Label = $UI/BottomBar/Caption

@onready var level: Node = get_parent()
@onready var player: Player = level.get_node("Player")
@onready var residents: Node2D = level.get_node("Residents")
@onready var town_slimes: Node2D = level.get_node("TownSlimes")
@onready var checkpoint: Marker2D = level.get_node("Checkpoint")
@onready var hud: CanvasLayer = level.get_node("HUD")


func _ready() -> void:
	if GameState.intro_seen:
		_finish(true)
	else:
		_play()


## Scena zmieniona w trakcie intro (np. wyjście do menu) – przerywamy animację.
func _exit_tree() -> void:
	_finished = true


func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(false)


func _play() -> void:
	player.controls_enabled = false
	player.sprite.flip_h = true
	hud.visible = false
	camera.enabled = true
	camera.make_current()
	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, 1.0)

	await _say("Miasto Jabłuszek. Spokojny, słoneczny dzień...", 3.0)
	if _finished:
		return
	_shake(0.8)
	await _say("Nagle ziemia zadrżała...", 1.8)
	if _finished:
		return

	caption.text = "SLAIMY!"
	Sfx.play("sting")
	for resident in residents.get_children():
		_drop_slime(resident.position.x, true)
		_scare(resident)
		await _wait(0.35)
		if _finished:
			return
	for x in extra_slime_x:
		_drop_slime(x, true)
	await _wait(1.2)
	if _finished:
		return

	for resident in residents.get_children():
		_capture(resident)
	await _say("Slaimy porywają mieszkańców!", 2.2)
	if _finished:
		return

	player.sprite.flip_h = false
	player.velocity.y = -160.0
	Sfx.play("jump")
	await _say("Jabłuszko, uciekaj!", 1.6)
	_finish(false)


func _finish(instant: bool) -> void:
	if _finished:
		return
	_finished = true
	GameState.intro_seen = true

	for resident in residents.get_children():
		resident.hide()
		_drop_slime(resident.position.x, false)
	for x in extra_slime_x:
		_drop_slime(x, false)

	# Po śmierci gracz wraca za miasto, a nie między Slaimy.
	player.spawn_position = checkpoint.global_position
	player.sprite.flip_h = false
	hud.visible = true
	player.camera.make_current()
	camera.enabled = false

	if instant:
		ui.hide()
		player.controls_enabled = true
		return

	caption.text = ""
	fade.hide()
	var tween := create_tween().set_parallel()
	tween.tween_property(top_bar, "position:y", -top_bar.size.y, 0.4)
	tween.tween_property(bottom_bar, "position:y", bottom_bar.position.y + bottom_bar.size.y, 0.4)
	tween.chain().tween_callback(ui.hide)
	# Krótka przerwa, żeby Spacja użyta do pominięcia nie wywołała od razu skoku.
	await get_tree().create_timer(0.2).timeout
	player.controls_enabled = true


func _say(text: String, seconds: float) -> void:
	caption.text = text
	await _wait(seconds)


## Czeka podaną liczbę sekund albo do pominięcia intro.
func _wait(seconds: float) -> void:
	var end_ms := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end_ms and not _finished:
		await get_tree().process_frame


func _drop_slime(x: float, from_sky: bool) -> void:
	if x in _slime_x:
		return
	_slime_x.append(x)
	var slime: CharacterBody2D = SLIME_SCENE.instantiate()
	# Slaimy w mieście stoją w miejscu – pilnują porwanych mieszkańców.
	slime.speed = 0.0
	slime.position = Vector2(x, checkpoint.position.y - (DROP_HEIGHT if from_sky else 0.0))
	town_slimes.add_child(slime)
	if from_sky:
		Sfx.play("fall", 0.1, -4.0)
		# Plaśnięcie, gdy Slaim spadnie (czas swobodnego spadku z DROP_HEIGHT).
		var fall_time := sqrt(2.0 * DROP_HEIGHT / slime.get_gravity().y) if slime.get_gravity().y > 0.0 else 0.73
		get_tree().create_timer(fall_time).timeout.connect(Sfx.play.bind("splat", 0.1))


func _scare(resident: AnimatedSprite2D) -> void:
	resident.play(&"hurt")
	Sfx.play("eek", 0.15)
	var y := resident.position.y
	var tween := create_tween()
	tween.tween_property(resident, "position:y", y - 10.0, 0.15)
	tween.tween_property(resident, "position:y", y, 0.2)


func _capture(resident: AnimatedSprite2D) -> void:
	Sfx.play("gloop", 0.15)
	var tween := create_tween().set_parallel()
	tween.tween_property(resident, "modulate", Color(0.7, 0.45, 1.0), 0.4)
	tween.tween_property(resident, "scale", Vector2(0.2, 0.2), 0.4)
	tween.chain().tween_callback(resident.hide)


func _shake(duration: float) -> void:
	Sfx.play("rumble")
	var tween := create_tween()
	for i in int(duration / 0.05):
		tween.tween_property(camera, "offset", Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0)), 0.05)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
