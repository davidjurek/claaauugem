extends Control
## Title screen: New Game (with name entry) / Continue / Credits.

@onready var menu := $Center/Menu
@onready var name_panel := $NamePanel
@onready var name_edit: LineEdit = $NamePanel/Box/NameEdit
@onready var blurb: Label = $Center/Blurb

var _buttons: Array = []
var _index := 0

func _ready() -> void:
	AudioManager.play_bgm("res://audio/bgm/title.ogg")
	name_panel.visible = false
	$NamePanel/Box/OK.pressed.connect(_confirm_name)
	name_edit.text_submitted.connect(func(_t): _confirm_name())
	_build_menu()

func _build_menu() -> void:
	for c in menu.get_children():
		c.queue_free()
	_buttons.clear()
	var opts := [["New Game", _new_game]]
	if GameState.has_save():
		opts.append(["Continue", _continue])
	opts.append(["Credits", _credits])
	for o in opts:
		var b := Button.new()
		b.text = o[0]
		b.add_theme_font_size_override("font_size", 14)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(o[1])
		menu.add_child(b)
		_buttons.append(b)
	_index = 0
	_highlight()

func _highlight() -> void:
	for i in _buttons.size():
		_buttons[i].modulate = Color(1, 1, 0.5) if i == _index else Color.WHITE
	if _buttons.size() > 0:
		_buttons[_index].grab_focus()

func _unhandled_input(e: InputEvent) -> void:
	if name_panel.visible:
		if e.is_action_pressed("interact"):
			_confirm_name()
		return
	if e.is_action_pressed("move_down"):
		_index = (_index + 1) % _buttons.size(); _highlight()
	elif e.is_action_pressed("move_up"):
		_index = (_index - 1 + _buttons.size()) % _buttons.size(); _highlight()
	elif e.is_action_pressed("interact"):
		_buttons[_index].emit_signal("pressed")

func _new_game() -> void:
	name_panel.visible = true
	name_edit.text = "Niko"
	name_edit.grab_focus()
	name_edit.select_all()

func _confirm_name() -> void:
	var n := name_edit.text.strip_edges()
	if n == "":
		n = "Niko"
	GameState.reset()
	GameState.hero_name = n.substr(0, 10)
	GameState.set_flag("game_started", true)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _continue() -> void:
	if GameState.load_game():
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _credits() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Credits.tscn")
