extends CanvasLayer
## Field menu (the ≡ button). Shows the hero's stats and lets you use items.
## Saving is intentionally NOT here — that's done at pay phones (save points).

signal closed

var _buttons: Array = []
var _index := 0
var _mode := "main"

@onready var stats_label: Label = $Root/StatsPanel/Stats
@onready var list_box: VBoxContainer = $Root/ListPanel/List
@onready var hint: Label = $Root/Hint

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_refresh_stats()
	_show_main()

func _refresh_stats() -> void:
	var s: Dictionary = GameState.stats
	var party := "Niko" if GameState.party.is_empty() else "%s, %s" % [GameState.hero_name, "Pidge"]
	stats_label.text = "%s   Lv %d\n\nHP  %d / %d\nPP  %d / %d\nEXP %d (next %d)\n\nOFF %d   DEF %d\nSPD %d   LUCK %d\n\n$%d\n\nParty: %s\nPSI: %s" % [
		GameState.hero_name, s.level, s.hp, s.max_hp, s.pp, s.max_pp,
		s.exp, GameState.exp_to_next(), s.offense, s.defense, s.speed, s.luck,
		GameState.money,
		party,
		", ".join(GameState.known_psi.map(func(p): return PsiDB.name_of(p)))]

func _clear_list() -> void:
	for c in list_box.get_children():
		c.queue_free()
	_buttons.clear()

func _add_button(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 11)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	list_box.add_child(b)
	_buttons.append(b)

func _show_main() -> void:
	_mode = "main"
	_clear_list()
	_add_button("Goods", _show_goods)
	_add_button("Close", _close)
	_add_button("Quit to Title", _quit)
	hint.text = "≡ menu — D-pad to move, A select, B back"
	_index = 0
	_highlight()

func _show_goods() -> void:
	_mode = "goods"
	_clear_list()
	var usable := GameState.inventory.filter(func(i): return ItemDB.get_def(i).kind in ["heal", "pp", "cure"])
	if usable.is_empty():
		_add_button("(no usable items)", _show_main)
	else:
		var counts := {}
		for i in usable:
			counts[i] = counts.get(i, 0) + 1
		for iid in counts:
			_add_button("%s x%d" % [ItemDB.name_of(iid), counts[iid]], _use_item.bind(iid))
	_add_button("< Back", _show_main)
	_index = 0
	_highlight()

func _use_item(iid: String) -> void:
	var d: Dictionary = ItemDB.get_def(iid)
	match d.kind:
		"heal":
			GameState.stats.hp = mini(GameState.stats.max_hp, GameState.stats.hp + d.power)
		"pp":
			GameState.stats.pp = mini(GameState.stats.max_pp, GameState.stats.pp + d.power)
		"cure":
			pass
	GameState.inventory.erase(iid)
	_refresh_stats()
	_show_goods()

func _highlight() -> void:
	for i in _buttons.size():
		_buttons[i].modulate = Color(1, 1, 0.5) if i == _index else Color.WHITE
	if not _buttons.is_empty():
		_buttons[_index].grab_focus()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("move_down"):
		_index = (_index + 1) % _buttons.size(); _highlight(); get_viewport().set_input_as_handled()
	elif e.is_action_pressed("move_up"):
		_index = (_index - 1 + _buttons.size()) % _buttons.size(); _highlight(); get_viewport().set_input_as_handled()
	elif e.is_action_pressed("interact"):
		_buttons[_index].emit_signal("pressed"); get_viewport().set_input_as_handled()
	elif e.is_action_pressed("cancel") or e.is_action_pressed("menu"):
		if _mode == "main": _close()
		else: _show_main()
		get_viewport().set_input_as_handled()

func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()

func _quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/Title.tscn")
