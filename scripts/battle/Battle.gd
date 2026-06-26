extends CanvasLayer
## Turn-based battle, EarthBound-flavored. You command only the hero; allies and
## enemies act via AI. HP is a rolling odometer (see Battler) so a lethal hit is
## survivable if you heal or win before it ticks to zero.
##
## Drive it with: setup(enemy_ids, is_boss) ; await battle_finished.

signal battle_finished(result: String)   # "win" | "lose" | "ran"

const WIN := "win"
const LOSE := "lose"
const RAN := "ran"

var heroes: Array = []        # hero + allies (player side battlers)
var enemies: Array = []
var is_boss := false

var enemy_sprites: Dictionary = {}     # Battler -> TextureRect
var status_panels: Dictionary = {}     # Battler -> Dictionary of labels
var _result := ""
var _msg_busy := false
var auto_play := false        # test mode: hero acts via AI, no menus
var fast := false             # test mode: skip message delays

@onready var root: Control = $Root
@onready var bg: ColorRect = $Root/BG
@onready var enemy_row: HBoxContainer = $Root/EnemyRow
@onready var msg_panel: PanelContainer = $Root/MsgPanel
@onready var msg_label: Label = $Root/MsgPanel/Msg
@onready var status_row: HBoxContainer = $Root/StatusRow
@onready var menu_root: Control = $Root/MenuRoot

var _font_big := 22
var _menu: Array = []          # current navigable buttons
var _menu_index := 0

func setup(enemy_ids: Array, boss := false) -> void:
	is_boss = boss
	heroes = [GameState.make_hero_battler()]
	heroes.append_array(GameState.make_ally_battlers())
	for id in enemy_ids:
		enemies.append(EnemyDB.make(id))

func _ready() -> void:
	layer = 20
	add_to_group("battle")
	_build_static_ui()
	_spawn_enemies()
	_spawn_status()
	set_process(true)
	_run.call_deferred()

# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------
func _win_style(border := Color(0.55, 0.85, 1.0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.07, 0.96)
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

func _build_static_ui() -> void:
	# message panel near top-middle
	msg_panel.add_theme_stylebox_override("panel", _win_style())
	msg_label.add_theme_font_size_override("font_size", 10)

func _spawn_enemies() -> void:
	for b in enemies:
		var tr := TextureRect.new()
		tr.texture = load(b.sprite_path)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(40, 48) * b.sprite_scale * 0.5
		tr.mouse_filter = Control.MOUSE_FILTER_STOP
		enemy_row.add_child(tr)
		enemy_sprites[b] = tr

func _spawn_status() -> void:
	for b in heroes:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _win_style(Color(0.6, 1.0, 0.7) if b.is_hero() else Color(1.0, 0.85, 0.5)))
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 0)
		panel.add_child(vb)
		var nm := Label.new()
		nm.text = b.display_name
		nm.add_theme_font_size_override("font_size", 9)
		var hp := Label.new()
		hp.add_theme_font_size_override("font_size", 12)
		var pp := Label.new()
		pp.add_theme_font_size_override("font_size", 8)
		vb.add_child(nm); vb.add_child(hp); vb.add_child(pp)
		status_row.add_child(panel)
		status_panels[b] = {"hp": hp, "pp": pp, "name": nm}
	_refresh_status()

func _refresh_status() -> void:
	for b in heroes:
		var p: Dictionary = status_panels[b]
		p.hp.text = "HP %3d/%d" % [b.shown_hp(), b.max_hp]
		p.pp.text = "PP %d/%d  Lv%d" % [b.pp, b.max_pp, GameState.stats.level if b.is_hero() else GameState.stats.level]
		p.hp.modulate = Color(1, 0.5, 0.5) if b.shown_hp() <= b.max_hp / 5 else Color.WHITE
		if not b.alive:
			p.name.modulate = Color(0.5, 0.5, 0.5)

func _process(_delta: float) -> void:
	var changed := false
	for b in heroes + enemies:
		if b.tick_roll(_delta):
			changed = true
			_on_ko(b)
	# rolling numbers update every frame
	for b in heroes:
		if status_panels.has(b):
			status_panels[b].hp.text = "HP %3d/%d" % [b.shown_hp(), b.max_hp]
			status_panels[b].hp.modulate = Color(1, 0.45, 0.45) if b.shown_hp() <= b.max_hp / 5 else Color.WHITE

func _on_ko(b: Battler) -> void:
	if b.is_enemy() and enemy_sprites.has(b):
		var tr: TextureRect = enemy_sprites[b]
		var tw := create_tween()
		tw.tween_property(tr, "modulate:a", 0.0, 0.4)
		tw.tween_callback(tr.queue_free)
	elif status_panels.has(b):
		status_panels[b].name.modulate = Color(0.5, 0.5, 0.5)

# ---------------------------------------------------------------------------
# Messages
# ---------------------------------------------------------------------------
func say(text: String, hold := 0.9) -> void:
	msg_label.text = text
	await get_tree().create_timer(0.02 if fast else hold).timeout

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
func _run() -> void:
	var names := ", ".join(enemies.map(func(e): return e.display_name))
	await say("%s appeared!" % names, 1.1)
	while true:
		var actions: Array = []
		# hero + ally action selection
		for h in heroes:
			if not h.alive:
				continue
			if h.is_hero():
				var a = await _choose_hero_action(h)
				if a == null:    # ran away
					return
				actions.append(a)
			else:
				actions.append(_ai_action(h))
		# enemies
		for e in enemies:
			if e.alive:
				actions.append(_ai_action(e))
		# order by speed (with jitter), execute
		actions.sort_custom(func(a, b): return a.actor.speed + a.jitter > b.actor.speed + b.jitter)
		for act in actions:
			if not act.actor.alive:
				continue
			await _execute(act)
			if _check_end():
				await _finish()
				return
		# end of round upkeep
		for b in heroes + enemies:
			if b.alive:
				b.tick_statuses()
		await get_tree().create_timer(0.05).timeout

func _check_end() -> bool:
	var enemies_alive := enemies.any(func(e): return e.alive)
	var heroes_alive := heroes.any(func(h): return h.alive)
	if not enemies_alive:
		_result = WIN
		return true
	if not heroes_alive:
		_result = LOSE
		return true
	return false

# ---------------------------------------------------------------------------
# Hero command menu
# ---------------------------------------------------------------------------
func _choose_hero_action(hero: Battler):
	if auto_play:
		return _ai_action(hero)
	while true:
		var cmd = await _menu_select(["BASH", "PSI", "GOODS", "GUARD", "RUN"], "Command")
		match cmd:
			"BASH":
				var t = await _pick_enemy()
				if t == null: continue
				return {"actor": hero, "type": "bash", "target": t, "jitter": randf() * 2.0}
			"GUARD":
				return {"actor": hero, "type": "guard", "jitter": randf() * 2.0}
			"RUN":
				if await _try_run():
					return null
				return {"actor": hero, "type": "wait", "jitter": 0.0}
			"PSI":
				var pid = await _pick_psi(hero)
				if pid == null: continue
				var pdef: Dictionary = PsiDB.get_def(pid)
				var tgt = await _resolve_target_for(pdef, hero)
				if tgt == "cancel": continue
				return {"actor": hero, "type": "psi", "psi": pid, "target": tgt, "jitter": randf() * 2.0}
			"GOODS":
				var iid = await _pick_item()
				if iid == null: continue
				var idef: Dictionary = ItemDB.get_def(iid)
				var tgt2 = await _resolve_target_for(idef, hero)
				if tgt2 == "cancel": continue
				return {"actor": hero, "type": "item", "item": iid, "target": tgt2, "jitter": randf() * 2.0}

func _resolve_target_for(def: Dictionary, hero: Battler):
	var t: String = def.get("target", "one_ally")
	match t:
		"one_enemy":
			var e = await _pick_enemy()
			return "cancel" if e == null else e
		"one_ally":
			return await _pick_ally()
		"self":
			return hero
		_:
			return null   # all_enemies / field

# ---------------------------------------------------------------------------
# Navigable menus (touch tap OR D-pad+A)
# ---------------------------------------------------------------------------
func _menu_select(options: Array, _title := ""):
	_clear_menu()
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _win_style())
	var vb := VBoxContainer.new()
	box.add_child(vb)
	var buttons: Array = []
	for opt in options:
		var btn := Button.new()
		btn.text = opt
		btn.add_theme_font_size_override("font_size", 11)
		btn.focus_mode = Control.FOCUS_ALL
		vb.add_child(btn)
		buttons.append(btn)
	menu_root.add_child(box)
	box.position = Vector2(8, 150)
	return await _await_buttons(buttons, options, true)

func _await_buttons(buttons: Array, values: Array, cancelable: bool):
	_menu = buttons
	_menu_index = 0
	var result = [null]
	for i in buttons.size():
		var idx := i
		buttons[i].pressed.connect(func(): result[0] = values[idx]; _menu_done())
	_highlight()
	_menu_active = true
	_menu_cancel = cancelable
	_menu_result = result
	await _menu_finished
	_clear_menu()
	return result[0] if not _menu_canceled else null

var _menu_active := false
var _menu_cancel := false
var _menu_canceled := false
var _menu_result := [null]
signal _menu_finished

func _menu_done() -> void:
	if _menu_active:
		_menu_active = false
		_menu_canceled = false
		_menu_finished.emit()

func _menu_cancel_now() -> void:
	if _menu_active and _menu_cancel:
		_menu_active = false
		_menu_canceled = true
		_menu_finished.emit()

func _highlight() -> void:
	for i in _menu.size():
		_menu[i].modulate = Color(1, 1, 0.6) if i == _menu_index else Color.WHITE
	if _menu.size() > 0:
		_menu[_menu_index].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not _menu_active or _menu.is_empty():
		return
	if event.is_action_pressed("move_down"):
		_menu_index = (_menu_index + 1) % _menu.size(); _highlight()
	elif event.is_action_pressed("move_up"):
		_menu_index = (_menu_index - 1 + _menu.size()) % _menu.size(); _highlight()
	elif event.is_action_pressed("interact"):
		_menu[_menu_index].emit_signal("pressed")
	elif event.is_action_pressed("cancel"):
		_menu_cancel_now()

func _clear_menu() -> void:
	for c in menu_root.get_children():
		c.queue_free()
	_menu = []

# target pickers -------------------------------------------------------------
func _pick_enemy():
	var alive := enemies.filter(func(e): return e.alive)
	if alive.is_empty(): return null
	var labels := alive.map(func(e): return e.display_name)
	var pick = await _menu_select(labels, "Target")
	if pick == null: return null
	for e in alive:
		if e.display_name == pick: return e
	return alive[0]

func _pick_ally():
	var alive := heroes.filter(func(h): return h.alive)
	var labels := alive.map(func(h): return h.display_name)
	var pick = await _menu_select(labels, "Who")
	if pick == null: return alive[0]
	for h in alive:
		if h.display_name == pick: return h
	return alive[0]

func _pick_psi(hero: Battler):
	if hero.psi.is_empty():
		await say("%s knows no PSI yet." % hero.display_name, 0.8)
		return null
	var labels := hero.psi.map(func(pid): return "%s (%dpp)" % [PsiDB.name_of(pid), PsiDB.get_def(pid).cost])
	var pick = await _menu_select(labels, "PSI")
	if pick == null: return null
	var i := labels.find(pick)
	var pid: String = hero.psi[i]
	if hero.pp < PsiDB.get_def(pid).cost:
		await say("Not enough PP!", 0.8)
		return null
	return pid

func _pick_item():
	if GameState.inventory.is_empty():
		await say("No goods to use.", 0.8)
		return null
	var usable := GameState.inventory.filter(func(iid): return ItemDB.get_def(iid).kind in ["heal", "pp", "cure"])
	if usable.is_empty():
		await say("Nothing usable here.", 0.8)
		return null
	var labels := usable.map(func(iid): return ItemDB.name_of(iid))
	var pick = await _menu_select(labels, "Goods")
	if pick == null: return null
	return usable[labels.find(pick)]

func _try_run() -> bool:
	if is_boss:
		await say("You can't run from this!", 0.9)
		return false
	var fastest_enemy: int = enemies.reduce(func(a, e): return max(a, e.speed), 0)
	var hero_speed: int = heroes[0].speed
	var chance: float = 0.45 + 0.05 * (hero_speed - fastest_enemy)
	if randf() < clampf(chance, 0.15, 0.92):
		_result = RAN
		await say("You got away!", 0.9)
		await _finish()
		return true
	await say("Couldn't escape!", 0.9)
	return false

# ---------------------------------------------------------------------------
# Action execution
# ---------------------------------------------------------------------------
func _ai_action(actor: Battler) -> Dictionary:
	var foes := (enemies if actor.side != "enemy" else heroes).filter(func(b): return b.alive)
	var friends := (heroes if actor.side != "enemy" else enemies).filter(func(b): return b.alive)
	if foes.is_empty():
		return {"actor": actor, "type": "wait", "jitter": 0.0}
	if actor.has_status("sleep"):
		return {"actor": actor, "type": "asleep", "jitter": 0.0}
	# support allies heal a hurt friend
	if actor.ai == "support" and actor.psi.has("mend") and actor.pp >= 4:
		for f in friends:
			if f.shown_hp() < f.max_hp * 0.45:
				return {"actor": actor, "type": "psi", "psi": "mend", "target": f, "jitter": randf() * 2}
	# casters use psi sometimes
	if actor.ai in ["caster", "boss"] and not actor.psi.is_empty() and actor.pp >= 3 and randf() < 0.55:
		var pid: String = actor.psi.pick_random()
		var pdef: Dictionary = PsiDB.get_def(pid)
		if actor.pp >= pdef.cost:
			var tgt = foes.pick_random() if pdef.get("target") in ["one_enemy", "one_ally"] else null
			return {"actor": actor, "type": "psi", "psi": pid, "target": tgt, "jitter": randf() * 2}
	return {"actor": actor, "type": "bash", "target": foes.pick_random(), "jitter": randf() * 2}

func _execute(act: Dictionary) -> void:
	var a: Battler = act.actor
	match act.type:
		"wait":
			pass
		"asleep":
			await say("%s is fast asleep." % a.display_name, 0.7)
		"guard":
			a.add_status("guard", 1)
			await say("%s is on guard." % a.display_name, 0.7)
		"bash":
			await _do_attack(a, act.target)
		"psi":
			await _do_psi(a, act.psi, act.get("target"))
		"item":
			await _do_item(a, act.item, act.get("target"))

func _do_attack(a: Battler, t: Battler) -> void:
	if t == null or not t.alive:
		t = _retarget(a)
		if t == null: return
	var crit := randf() < 0.06 + a.luck * 0.004
	var base := a.offense * 2 - t.defense
	base = max(1, base) + randi_range(-2, 2)
	if t.has_status("guard"): base = int(base * 0.5)
	if crit: base *= 2
	var dmg: int = t.take_damage(base)
	await say("%s%s hit %s for %d!" % [a.display_name, " SMASH" if crit else "", t.display_name, dmg], 0.85)

func _do_psi(a: Battler, pid: String, target) -> void:
	var d: Dictionary = PsiDB.get_def(pid)
	a.spend_pp(d.cost)
	await say("%s tried %s!" % [a.display_name, d.name], 0.8)
	match d.kind:
		"damage":
			var targets: Array = []
			if d.target == "all_enemies":
				targets = (enemies if a.side != "enemy" else heroes).filter(func(b): return b.alive)
			elif target != null and target.alive:
				targets = [target]
			else:
				targets = [_retarget(a)]
			for t in targets:
				if t == null: continue
				var dmg: int = t.take_damage(maxi(1, d.power + randi_range(-3, 3) - t.defense / 2))
				await say("%s took %d!" % [t.display_name, dmg], 0.55)
		"heal":
			var t: Battler = target if target != null else a
			var amt: int = t.heal(d.power + randi_range(-2, 4))
			await say("%s recovered %d HP." % [t.display_name, amt], 0.7)
		"buff":
			var t2: Battler = target if target != null else a
			t2.add_status("shield", d.turns)
			t2.defense += d.amount
			await say("%s is shielded!" % t2.display_name, 0.7)
		"status":
			var t3 = target if target != null else _retarget(a)
			if t3 != null:
				if randf() < 0.7:
					t3.add_status(d.status, d.turns)
					await say("%s fell asleep!" % t3.display_name, 0.7)
				else:
					await say("...but it had no effect.", 0.7)

func _do_item(a: Battler, iid: String, target) -> void:
	var d: Dictionary = ItemDB.get_def(iid)
	var t: Battler = target if target != null else a
	GameState.inventory.erase(iid)
	match d.kind:
		"heal":
			var amt: int = t.heal(d.power)
			await say("%s ate the %s. +%d HP!" % [a.display_name, d.name, amt], 0.9)
		"pp":
			t.pp = mini(t.max_pp, t.pp + d.power)
			await say("%s restored %d PP." % [t.display_name, d.power], 0.9)
		"cure":
			t.statuses.clear()
			await say("%s feels better." % t.display_name, 0.9)

func _retarget(a: Battler):
	var foes := (enemies if a.side != "enemy" else heroes).filter(func(b): return b.alive)
	return foes.pick_random() if not foes.is_empty() else null

# ---------------------------------------------------------------------------
# Resolution
# ---------------------------------------------------------------------------
func _finish() -> void:
	# wait for the odometers to settle for drama
	await get_tree().create_timer(0.5).timeout
	GameState.sync_hero_from(heroes[0])
	if _result == WIN:
		var exp := 0
		var money := 0
		for e in enemies:
			exp += e.exp_reward
			money += e.money_reward
		await say("You won!", 1.0)
		await say("Got %d EXP and $%d." % [exp, money], 1.0)
		GameState.add_money(money)
		var ups := GameState.add_exp(exp)
		for m in ups:
			await say(m, 1.0)
	elif _result == LOSE:
		await say("%s is out of action..." % GameState.hero_name, 1.2)
	battle_finished.emit(_result)
	queue_free()
