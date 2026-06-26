class_name ItemDB
extends RefCounted
## Items: healing/PP/cure consumables and a couple of key/quest items.

const DB := {
	"soda": {"name": "Warm Soda", "kind": "heal", "power": 22, "price": 12,
		"desc": "Flat, but it helps. Restores 22 HP."},
	"burger": {"name": "Gas-Stn Burger", "kind": "heal", "power": 48, "price": 30,
		"desc": "Dubious. Restores 48 HP."},
	"fries": {"name": "Cold Fries", "kind": "heal", "power": 12, "price": 6,
		"desc": "Restores 12 HP."},
	"battery": {"name": "9-Volt", "kind": "pp", "power": 16, "price": 25,
		"desc": "Tastes terrible. Restores 16 PP."},
	"bandage": {"name": "Bandage", "kind": "cure", "status": "all", "price": 10,
		"desc": "Clears status ailments."},
	"cola": {"name": "Mega Cola", "kind": "heal", "power": 90, "price": 70,
		"desc": "Restores 90 HP."},
	# key / quest items (price 0 = not sold)
	"cat_collar": {"name": "Mr. Whiskers' Collar", "kind": "key", "price": 0,
		"desc": "A jingly collar. Smells of tuna."},
	"arcade_token": {"name": "Arcade Token", "kind": "key", "price": 0,
		"desc": "Good for one game. Or one secret."},
	"antenna_key": {"name": "Rooftop Key", "kind": "key", "price": 0,
		"desc": "Opens the door to the broadcast tower."},
}

static func get_def(id: String) -> Dictionary:
	return DB.get(id, {})

static func name_of(id: String) -> String:
	return DB.get(id, {}).get("name", id)

static func price_of(id: String) -> int:
	return DB.get(id, {}).get("price", 0)
