extends CanvasLayer
## A shop. Pass `stock` (item ids) before adding to the tree. Buy with money.

signal closed

var stock: Array = []
var _buttons: Array = []
var _index := 0

@onready var money_label: Label = $Root/Panel/Box/Money
@onready var list_box: VBoxContainer = $Root/Panel/Box/List
@onready var info: Label = $Root/Panel/Box/Info

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_build()

func _build() -> void:
	for c in list_box.get_children():
		c.queue_free()
	_buttons.clear()
	for iid in stock:
		var d: Dictionary = ItemDB.get_def(iid)
		var b := Button.new()
		b.text = "%-18s $%d" % [d.name, d.price]
		b.add_theme_font_size_override("font_size", 10)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_buy.bind(iid))
		b.mouse_entered.connect(func(): info.text = d.get("desc", ""))
		list_box.add_child(b)
		_buttons.append(b)
	var close := Button.new()
	close.text = "Leave"
	close.add_theme_font_size_override("font_size", 10)
	close.pressed.connect(_close)
	list_box.add_child(close)
	_buttons.append(close)
	_index = 0
	_refresh()

func _refresh() -> void:
	money_label.text = "Your money: $%d" % GameState.money
	for i in _buttons.size():
		_buttons[i].modulate = Color(1, 1, 0.5) if i == _index else Color.WHITE
	if not _buttons.is_empty():
		_buttons[_index].grab_focus()
	if _index < stock.size():
		info.text = ItemDB.get_def(stock[_index]).get("desc", "")

func _buy(iid: String) -> void:
	var price: int = ItemDB.price_of(iid)
	if GameState.money >= price:
		GameState.add_money(-price)
		GameState.add_item(iid)
		AudioManager.sfx("buy")
		info.text = "Bought %s!" % ItemDB.name_of(iid)
	else:
		AudioManager.sfx("cancel")
		info.text = "Not enough money."
	_refresh()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("move_down"):
		_index = (_index + 1) % _buttons.size(); _refresh(); AudioManager.sfx("cursor"); get_viewport().set_input_as_handled()
	elif e.is_action_pressed("move_up"):
		_index = (_index - 1 + _buttons.size()) % _buttons.size(); _refresh(); AudioManager.sfx("cursor"); get_viewport().set_input_as_handled()
	elif e.is_action_pressed("interact"):
		_buttons[_index].emit_signal("pressed"); get_viewport().set_input_as_handled()
	elif e.is_action_pressed("cancel") or e.is_action_pressed("menu"):
		_close(); get_viewport().set_input_as_handled()

func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
