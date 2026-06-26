extends Node
## Global, persistent game state (autoload). Story flags, the hero's name and
## stats, money, inventory, party, and the save system. Dialogue files read and
## write this via e.g.  `if GameState.get_flag("met_pidge")`  /  `do GameState.set_flag(...)`.

const SAVE_PATH := "user://psycho_suburbia_save.json"

signal flag_changed(flag: String, value)
signal money_changed(amount: int)

var hero_name: String = "Niko"
var flags: Dictionary = {}
var money: int = 0

# Combat/RPG stats (used from M2 on). Kept here so saves are forward-compatible.
var stats: Dictionary = {
	"level": 1, "exp": 0,
	"hp": 30, "max_hp": 30,
	"pp": 12, "max_pp": 12,
	"offense": 8, "defense": 6, "speed": 7, "luck": 4,
}
var party: Array = []          # ally ids that fight alongside the hero
var inventory: Array = []      # item ids
var known_psi: Array = []      # learned psychic powers

# Where to resume from (set by save points / world transitions).
var current_world: String = "res://scenes/world/TownSquare.tscn"
var current_spawn: String = "default"

func get_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))

func get_value(flag: String, default = 0):
	return flags.get(flag, default)

func set_flag(flag: String, value = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)

func add_money(amount: int) -> void:
	money = max(0, money + amount)
	money_changed.emit(money)

func has_item(item_id: String) -> bool:
	return inventory.has(item_id)

func add_item(item_id: String) -> void:
	inventory.append(item_id)

func remove_item(item_id: String) -> void:
	inventory.erase(item_id)

# --- save / load -------------------------------------------------------------
func save_game() -> void:
	var data := {
		"hero_name": hero_name,
		"flags": flags,
		"money": money,
		"stats": stats,
		"party": party,
		"inventory": inventory,
		"known_psi": known_psi,
		"current_world": current_world,
		"current_spawn": current_spawn,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
		print("[SAVE] game saved")

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	hero_name = data.get("hero_name", hero_name)
	flags = data.get("flags", {})
	money = int(data.get("money", 0))
	stats = data.get("stats", stats)
	party = data.get("party", [])
	inventory = data.get("inventory", [])
	known_psi = data.get("known_psi", [])
	current_world = data.get("current_world", current_world)
	current_spawn = data.get("current_spawn", current_spawn)
	return true

func reset() -> void:
	flags.clear()
	money = 0
	party.clear()
	inventory.clear()
	known_psi.clear()
	stats = {
		"level": 1, "exp": 0, "hp": 30, "max_hp": 30, "pp": 12, "max_pp": 12,
		"offense": 8, "defense": 6, "speed": 7, "luck": 4,
	}
