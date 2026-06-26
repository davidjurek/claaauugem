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
var known_psi: Array = ["spark"]   # learned psychic powers

# Hero learns a new PSI power on reaching these levels.
const PSI_BY_LEVEL := {2: "mend", 3: "bubble", 4: "lull", 6: "spark_all"}
# Allies that can join and auto-fight beside the hero.
const ALLY_DB := {
	"pidge": {"name": "Pidge", "char": 2, "hp": 24, "pp": 10, "off": 7, "def": 5,
		"spd": 8, "psi": ["mend", "spark"], "ai": "support"},
}

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

func add_to_party(ally_id: String) -> void:
	if not party.has(ally_id):
		party.append(ally_id)

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
	inventory = ["soda", "soda", "fries"]
	known_psi = ["spark"]
	stats = {
		"level": 1, "exp": 0, "hp": 30, "max_hp": 30, "pp": 12, "max_pp": 12,
		"offense": 8, "defense": 6, "speed": 7, "luck": 4,
	}

# --- leveling -----------------------------------------------------------------
func exp_to_next() -> int:
	var lv: int = stats.level
	return lv * lv * 9 + lv * 6 + 10

## Grants exp; returns an array of human-readable level-up / learned messages.
func add_exp(amount: int) -> Array:
	var msgs: Array = []
	stats.exp += amount
	while stats.exp >= exp_to_next():
		stats.exp -= exp_to_next()
		stats.level += 1
		stats.max_hp += 6 + (stats.level / 2)
		stats.max_pp += 3 + (stats.level / 3)
		stats.offense += 2
		stats.defense += 2
		stats.speed += 1
		stats.luck += 1
		stats.hp = stats.max_hp
		stats.pp = stats.max_pp
		msgs.append("%s grew to LEVEL %d!" % [hero_name, stats.level])
		if PSI_BY_LEVEL.has(stats.level):
			var pid: String = PSI_BY_LEVEL[stats.level]
			if not known_psi.has(pid):
				known_psi.append(pid)
				msgs.append("%s learned %s!" % [hero_name, PsiDB.name_of(pid)])
	return msgs

# --- building battlers from current state ------------------------------------
func make_hero_battler() -> Battler:
	var b := Battler.new()
	b.display_name = hero_name
	b.side = "hero"
	b.max_hp = stats.max_hp
	b.hp = clampi(stats.hp, 1, stats.max_hp)
	b.roll_hp = b.hp
	b.max_pp = stats.max_pp
	b.pp = clampi(stats.pp, 0, stats.max_pp)
	b.offense = stats.offense
	b.defense = stats.defense
	b.speed = stats.speed
	b.luck = stats.luck
	b.psi = known_psi.duplicate()
	b.sprite_path = "res://art/characters/char_01.png"
	b.sprite_scale = 3.0
	return b

func make_ally_battlers() -> Array:
	var out: Array = []
	for ally_id in party:
		if not ALLY_DB.has(ally_id):
			continue
		var d: Dictionary = ALLY_DB[ally_id]
		var lv: int = stats.level
		var b := Battler.new()
		b.display_name = d.name
		b.side = "ally"
		b.max_hp = d.hp + lv * 5
		b.hp = b.max_hp
		b.roll_hp = b.max_hp
		b.max_pp = d.pp + lv * 2
		b.pp = b.max_pp
		b.offense = d.off + lv * 2
		b.defense = d.def + lv
		b.speed = d.spd + lv
		b.luck = 3
		b.psi = d.psi.duplicate()
		b.ai = d.ai
		b.sprite_path = "res://art/characters/char_%02d.png" % d.char
		b.sprite_scale = 3.0
		out.append(b)
	# Persist hero's current hp/pp back after a fight via sync_hero_from().
	return out

## After battle, write the hero battler's surviving hp/pp back to GameState.
func sync_hero_from(b: Battler) -> void:
	stats.hp = b.hp
	stats.pp = b.pp
