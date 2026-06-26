class_name EnemyDB
extends RefCounted
## Definitions for every enemy. Sprites are the reskinned Redshrike battlers in
## art/enemies/. Stats are tuned around a level-1 hero (hp30, off8, def6).

const DB := {
	"lawn_slurry": {
		"name": "Lawn Slurry", "sprite": "slime_green", "scale": 3.0,
		"hp": 13, "off": 5, "def": 2, "spd": 3, "exp": 4, "money": 2, "ai": "basic"},
	"toadstool": {
		"name": "Backyard Toadstool", "sprite": "mushroom", "scale": 3.0,
		"hp": 17, "off": 6, "def": 3, "spd": 4, "exp": 6, "money": 4, "ai": "basic"},
	"slushie": {
		"name": "Spilled Slushie", "sprite": "slime_red", "scale": 3.0,
		"hp": 22, "off": 8, "def": 4, "spd": 5, "exp": 8, "money": 6, "ai": "basic"},
	"gnome": {
		"name": "Feral Lawn Gnome", "sprite": "goblin", "scale": 3.2,
		"hp": 28, "off": 11, "def": 5, "spd": 7, "exp": 12, "money": 9, "ai": "aggressive"},
	"wraith": {
		"name": "Static Wraith", "sprite": "skeleton", "scale": 3.2,
		"hp": 24, "off": 9, "def": 4, "spd": 9, "exp": 11, "money": 7,
		"psi": ["spark"], "ai": "caster"},
	"signal": {
		"name": "Screaming Signal", "sprite": "skull", "scale": 3.2,
		"hp": 30, "off": 10, "def": 6, "spd": 11, "exp": 16, "money": 12,
		"psi": ["spark", "lull"], "ai": "caster"},
	"mimic": {
		"name": "Mimic Mailbox", "sprite": "mimic", "scale": 2.6,
		"hp": 40, "off": 14, "def": 8, "spd": 6, "exp": 25, "money": 40, "ai": "aggressive"},
	"golem": {
		"name": "Curbside Golem", "sprite": "golem", "scale": 2.8,
		"hp": 64, "off": 13, "def": 11, "spd": 3, "exp": 30, "money": 25, "ai": "aggressive"},
	"mr_static": {
		"name": "MR. STATIC", "sprite": "skull", "scale": 6.5,
		"hp": 240, "off": 18, "def": 9, "spd": 8, "exp": 150, "money": 120,
		"psi": ["spark_all", "lull", "spark"], "ai": "boss", "boss": true},
}

static func make(id: String) -> Battler:
	var d: Dictionary = DB[id]
	var b := Battler.new()
	b.enemy_id = id
	b.display_name = d.name
	b.side = "enemy"
	b.max_hp = d.hp
	b.hp = d.hp
	b.roll_hp = d.hp
	b.offense = d.off
	b.defense = d.def
	b.speed = d.spd
	b.luck = 2
	b.exp_reward = d.exp
	b.money_reward = d.money
	b.sprite_path = "res://art/enemies/%s.png" % d.sprite
	b.sprite_scale = d.get("scale", 3.0)
	b.psi = d.get("psi", [])
	b.ai = d.get("ai", "basic")
	return b

## Weak enemies the hero can instantly rout on contact (EarthBound "you won").
static func is_trivial(id: String, hero_level: int) -> bool:
	var d: Dictionary = DB.get(id, {})
	return d.get("exp", 999) <= 6 and hero_level >= 4
