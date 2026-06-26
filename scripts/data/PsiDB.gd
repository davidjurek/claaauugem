class_name PsiDB
extends RefCounted
## Psychic powers ("PSI"). Original names to avoid trademark. `kind` drives what
## the battle system does; `target` is resolved at cast time.

const DB := {
	"spark": {
		"name": "SPARK α", "cost": 3, "kind": "damage", "power": 16,
		"target": "one_enemy", "flavor": "a snap of blue static"},
	"spark_all": {
		"name": "SPARK Ω", "cost": 8, "kind": "damage", "power": 12,
		"target": "all_enemies", "flavor": "static arcs across the room"},
	"mend": {
		"name": "MEND β", "cost": 4, "kind": "heal", "power": 28,
		"target": "one_ally", "flavor": "a warm hum"},
	"bubble": {
		"name": "BUBBLE", "cost": 3, "kind": "buff", "stat": "defense",
		"amount": 5, "turns": 4, "target": "self", "flavor": "a shimmering shell"},
	"lull": {
		"name": "LULL", "cost": 4, "kind": "status", "status": "sleep",
		"turns": 3, "target": "one_enemy", "flavor": "a drowsy tone"},
}

static func get_def(id: String) -> Dictionary:
	return DB.get(id, {})

static func name_of(id: String) -> String:
	return DB.get(id, {}).get("name", id)
