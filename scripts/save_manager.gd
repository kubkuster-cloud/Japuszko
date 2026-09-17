extends Node
## Zapisy gry (autoload "SaveManager"): 3 miejsca w user://save_1.cfg ... save_3.cfg.
## Gra zapisuje się sama na początku każdego poziomu i w sklepiku (do wybranego miejsca).

const SLOT_COUNT := 3
const LEVEL_NAMES := {
	"res://scenes/levels/apple_town.tscn": "Miasto Jabłuszek",
	"res://scenes/levels/orange_town.tscn": "Miasto Pomarańczek 1/5",
	"res://scenes/levels/orange_town_2.tscn": "Miasto Pomarańczek 2/5",
	"res://scenes/levels/orange_town_3.tscn": "Miasto Pomarańczek 3/5",
	"res://scenes/ui/shop.tscn": "Sklepik Pomarańczki",
	"res://scenes/levels/orange_town_4.tscn": "Miasto Pomarańczek 4/5",
	"res://scenes/levels/orange_town_5.tscn": "Miasto Pomarańczek 5/5",
	"res://scenes/levels/orange_town_boss.tscn": "Boss-Slaim",
}

## Miejsce zapisu bieżącej gry (1..3). 0 = gra bez zapisu (np. uruchomiona prosto z edytora).
var current_slot := 0


func slot_path(slot: int) -> String:
	return "user://save_%d.cfg" % slot


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func has_any_save() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if has_save(slot):
			return true
	return false


func start_new_game(slot: int) -> void:
	current_slot = slot
	GameState.new_game()


func save_game(scene_path: String) -> void:
	if current_slot < 1 or scene_path == "":
		return
	var cfg := ConfigFile.new()
	cfg.set_value("game", "scene", scene_path)
	cfg.set_value("game", "lives", GameState.lives)
	cfg.set_value("game", "coins", GameState.coins)
	cfg.set_value("game", "power", GameState.power)
	cfg.set_value("game", "intro_seen", GameState.intro_seen)
	cfg.set_value("info", "level_name", LEVEL_NAMES.get(scene_path, scene_path.get_file().get_basename()))
	cfg.set_value("info", "saved_at", Time.get_datetime_string_from_system(false, true))
	cfg.set_value("info", "saved_unix", Time.get_unix_time_from_system())
	cfg.save(slot_path(current_slot))


## Informacje do wyświetlenia w menu. Pusty słownik = brak zapisu.
func get_info(slot: int) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return {}
	return {
		"level_name": cfg.get_value("info", "level_name", "?"),
		"saved_at": cfg.get_value("info", "saved_at", ""),
		"saved_unix": cfg.get_value("info", "saved_unix", 0.0),
		"lives": cfg.get_value("game", "lives", 0),
		"coins": cfg.get_value("game", "coins", 0),
	}


## Wczytuje stan gry z miejsca zapisu. Zwraca ścieżkę sceny do otwarcia ("" = brak zapisu).
func load_game(slot: int) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return ""
	current_slot = slot
	GameState.load_state(
		cfg.get_value("game", "lives", GameState.START_LIVES),
		cfg.get_value("game", "coins", 0),
		cfg.get_value("game", "power", GameState.Power.NONE),
		cfg.get_value("game", "intro_seen", false))
	return cfg.get_value("game", "scene", "")


func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))


## Najnowszy zapis (do przycisku "Kontynuuj"). 0 = brak zapisów.
func latest_slot() -> int:
	var best := 0
	var best_time := -1.0
	for slot in range(1, SLOT_COUNT + 1):
		var info := get_info(slot)
		if not info.is_empty() and float(info.saved_unix) > best_time:
			best = slot
			best_time = info.saved_unix
	return best
