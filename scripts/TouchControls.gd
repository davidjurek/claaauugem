extends CanvasLayer
## On-screen virtual D-pad + A/B buttons for iOS. Tracks individual fingers so
## you can hold a direction and tap A at the same time. Injects the project's
## input actions, so Player/menus read the same actions whether input came from
## a keyboard (desktop testing) or touch (device).

const DIRS := {
	"move_up": Vector2.UP,
	"move_down": Vector2.DOWN,
	"move_left": Vector2.LEFT,
	"move_right": Vector2.RIGHT,
}

var dpad_center := Vector2.ZERO
var dpad_radius := 64.0
var deadzone := 12.0
var _dpad_finger := -2          # -2 = none, otherwise touch index (-1 = mouse)
var _btn_finger := {}           # action -> finger index
var _pressed_dirs := {}         # action -> bool

@onready var root: Control = $Root
@onready var dpad_tex: TextureRect = $Root/DPad
@onready var btn_a: TextureRect = $Root/ButtonA
@onready var btn_b: TextureRect = $Root/ButtonB
@onready var btn_menu: TextureRect = $Root/ButtonMenu

func _ready() -> void:
	# Only show on touch devices; keep visible in editor for layout/testing.
	visible = DisplayServer.is_touchscreen_available() or OS.has_feature("editor") or OS.is_debug_build()
	get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()

func _layout() -> void:
	var c := dpad_tex.get_global_rect()
	dpad_center = c.position + c.size / 2.0
	dpad_radius = c.size.x / 2.0

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)
	elif event is InputEventMouseButton:
		_handle_touch(-1, event.position, event.pressed)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_handle_drag(-1, event.position)

func _handle_touch(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if dpad_tex.get_global_rect().grow(8).has_point(pos) and _dpad_finger == -2:
			_dpad_finger = index
			_update_dpad(pos)
			return
		for pair in [["interact", btn_a], ["cancel", btn_b], ["menu", btn_menu]]:
			var act: String = pair[0]
			var node: TextureRect = pair[1]
			if node.visible and node.get_global_rect().grow(6).has_point(pos):
				_btn_finger[act] = index
				Input.action_press(act)
				node.modulate = Color(0.7, 0.7, 0.7)
				return
	else:
		if index == _dpad_finger:
			_dpad_finger = -2
			_release_all_dirs()
		for act in _btn_finger.keys():
			if _btn_finger[act] == index:
				Input.action_release(act)
				_btn_finger.erase(act)
				_button_node(act).modulate = Color.WHITE

func _handle_drag(index: int, pos: Vector2) -> void:
	if index == _dpad_finger:
		_update_dpad(pos)

func _update_dpad(pos: Vector2) -> void:
	var v := pos - dpad_center
	if v.length() < deadzone:
		_release_all_dirs()
		return
	var dir := v.normalized()
	for act in DIRS.keys():
		var want: bool = dir.dot(DIRS[act]) > 0.38
		if want and not _pressed_dirs.get(act, false):
			Input.action_press(act)
			_pressed_dirs[act] = true
		elif not want and _pressed_dirs.get(act, false):
			Input.action_release(act)
			_pressed_dirs[act] = false

func _release_all_dirs() -> void:
	for act in DIRS.keys():
		if _pressed_dirs.get(act, false):
			Input.action_release(act)
			_pressed_dirs[act] = false

func _button_node(act: String) -> TextureRect:
	match act:
		"interact": return btn_a
		"cancel": return btn_b
		"menu": return btn_menu
	return btn_a
