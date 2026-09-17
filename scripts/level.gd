extends Node2D
## Wspólna logika poziomu. Na podstawie kafelków w węźle Terrain ustawia:
## granice kamery, niewidzialne ściany na lewym/prawym krańcu mapy
## i strefę śmierci pod mapą. Dzięki temu po domalowaniu kafelków nic nie trzeba przesuwać.
## Pilnuje też wrogów: po każdej śmierci gracza wszyscy wrogowie z węzła Enemies wracają na start.

const DEATH_ZONE_SCENE := preload("res://scenes/objects/death_zone.tscn")
const LEVEL_COMPLETE_SCENE := preload("res://scenes/ui/level_complete.tscn")
const WALL_WIDTH := 16.0
const WALL_HEIGHT := 4000.0

## Jak głęboko pod dolną krawędzią mapy zaczyna się strefa śmierci (px).
@export var death_zone_margin: float = 32.0
## Poziom wczytywany po dojściu do mety (węzeł Goal). Pusty = ekran "już wkrótce".
@export_file("*.tscn") var next_level := ""
## Nazwa następnego poziomu na ekranie końca poziomu.
@export var next_level_name := "Miasto Pomarańczek"
## Kolor nieba na tym poziomie.
@export var sky_color := Color(0.55, 0.8, 0.95)

## Uratowani mieszkańcy (klatki w węźle Rescues).
var rescued := 0
var rescue_total := 0

## Kopia węzła Enemies z chwili startu poziomu – z niej odtwarzamy wrogów.
var _enemies_template: Node

@onready var terrain: TileMapLayer = $Terrain
@onready var player: Player = $Player
@onready var enemies: Node = get_node_or_null("Enemies")
@onready var rescues: Node = get_node_or_null("Rescues")


func _ready() -> void:
	RenderingServer.set_default_clear_color(sky_color)

	if rescues:
		for cage in rescues.get_children():
			rescue_total += 1
			cage.rescued.connect(_on_resident_rescued)
	get_tree().call_group("hud", "set_rescued", rescued, rescue_total)

	var bounds := _get_map_bounds()
	_setup_camera(bounds)
	_add_side_walls(bounds)
	_add_death_zone(bounds)

	if enemies:
		_enemies_template = enemies.duplicate()
	player.died.connect(GameState.lose_life)
	player.respawned.connect(_on_player_respawned)

	var goal := get_node_or_null("Goal")
	if goal:
		goal.reached.connect(_on_goal_reached)


func _on_goal_reached() -> void:
	player.controls_enabled = false
	get_tree().call_group("hud", "hide")
	var screen := LEVEL_COMPLETE_SCENE.instantiate()
	add_child(screen)
	screen.play(next_level, next_level_name, rescued, rescue_total)


func _on_resident_rescued() -> void:
	rescued += 1
	get_tree().call_group("hud", "set_rescued", rescued, rescue_total)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_enemies_template):
		_enemies_template.free()


func _on_player_respawned(_killed_by_enemy: bool) -> void:
	if GameState.lives <= 0:
		# Na razie bez ekranu Game Over (dojdzie w dniach 11–12): nowa gra od początku poziomu.
		GameState.reset()
		get_tree().reload_current_scene()
		return
	_reset_enemies()


func _reset_enemies() -> void:
	if _enemies_template == null:
		return
	var fresh := _enemies_template.duplicate()
	var index := enemies.get_index()
	remove_child(enemies)
	enemies.queue_free()
	add_child(fresh)
	# Ta sama pozycja w drzewie – wrogowie liczą się po ruchu gracza.
	move_child(fresh, index)
	enemies = fresh


func _get_map_bounds() -> Rect2:
	var used := terrain.get_used_rect()
	var tile_size := Vector2(terrain.tile_set.tile_size)
	var top_left := terrain.to_global(Vector2(used.position) * tile_size)
	return Rect2(top_left, Vector2(used.size) * tile_size)


func _setup_camera(bounds: Rect2) -> void:
	# Góra zostaje bez limitu – nad mapą jest po prostu niebo.
	player.camera.limit_left = int(bounds.position.x)
	player.camera.limit_right = int(bounds.end.x)
	player.camera.limit_bottom = int(bounds.end.y)
	player.camera.reset_smoothing()


func _add_side_walls(bounds: Rect2) -> void:
	var y := bounds.end.y - WALL_HEIGHT / 2.0
	_add_wall(Vector2(bounds.position.x - WALL_WIDTH / 2.0, y))
	_add_wall(Vector2(bounds.end.x + WALL_WIDTH / 2.0, y))


func _add_wall(center: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WALL_WIDTH, WALL_HEIGHT)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	var wall := StaticBody2D.new()
	wall.name = "BoundaryWall"
	wall.global_position = center
	wall.add_child(collision)
	add_child(wall)


func _add_death_zone(bounds: Rect2) -> void:
	var zone: Area2D = DEATH_ZONE_SCENE.instantiate()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(bounds.size.x + 1000.0, 64.0)
	zone.get_node("CollisionShape2D").shape = shape
	zone.global_position = Vector2(bounds.get_center().x, bounds.end.y + death_zone_margin + shape.size.y / 2.0)
	add_child(zone)
