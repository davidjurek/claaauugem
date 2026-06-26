class_name Battler
extends RefCounted
## One combatant in a battle (hero, ally, or enemy). Holds the real HP plus the
## EarthBound "rolling" HP odometer: damage drops `hp` instantly, but `roll_hp`
## (what's shown) ticks toward it over time — you only fall if the odometer
## actually reaches 0, so a well-timed heal or a quick KO can save you.

var display_name: String
var side: String = "enemy"        # "hero" | "ally" | "enemy"
var max_hp: int = 1
var hp: int = 1
var roll_hp: float = 1.0
var max_pp: int = 0
var pp: int = 0
var offense: int = 1
var defense: int = 1
var speed: int = 1
var luck: int = 1
var sprite_path: String = ""
var sprite_scale: float = 3.0
var alive: bool = true
var statuses: Dictionary = {}     # name -> remaining turns
var psi: Array = []               # psi ids this battler can use
var enemy_id: String = ""
var exp_reward: int = 0
var money_reward: int = 0
var ai: String = "basic"          # enemy/ally behaviour tag

func is_hero() -> bool: return side == "hero"
func is_enemy() -> bool: return side == "enemy"

func take_damage(amount: int) -> int:
	amount = max(0, amount)
	hp = clampi(hp - amount, 0, max_hp)
	return amount

func heal(amount: int) -> int:
	var before := hp
	hp = clampi(hp + amount, 0, max_hp)
	# Healing also nudges the odometer up immediately so it doesn't keep falling.
	if roll_hp < hp:
		pass
	return hp - before

func spend_pp(amount: int) -> bool:
	if pp < amount:
		return false
	pp -= amount
	return true

func has_status(s: String) -> bool:
	return statuses.has(s) and statuses[s] > 0

func add_status(s: String, turns: int) -> void:
	statuses[s] = turns

func tick_statuses() -> void:
	for s in statuses.keys():
		statuses[s] -= 1
		if statuses[s] <= 0:
			statuses.erase(s)

## Advance the rolling odometer toward real hp. Returns true the moment the
## battler is confirmed down (odometer hit 0 with no hp left).
func tick_roll(delta: float) -> bool:
	if not alive:
		return false
	var rate: float = max(18.0, max_hp * 1.6)
	if absf(roll_hp - hp) < 0.5:
		roll_hp = hp
	elif roll_hp > hp:
		roll_hp = max(float(hp), roll_hp - rate * delta)
	else:
		roll_hp = min(float(hp), roll_hp + rate * delta)
	if roll_hp <= 0.0 and hp <= 0:
		alive = false
		return true
	return false

func shown_hp() -> int:
	return int(ceil(roll_hp))
