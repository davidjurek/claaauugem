class_name Player
extends CharacterBody2D
## The single playable character. Reads the four move_* actions (keyboard or the
## on-screen D-pad, which maps to the same actions), animates the Kenney sprite,
## tracks facing, and probes for interactables in front when `interact` is pressed.

@export var speed: float = 78.0
@export var character_sheet: Texture2D

var facing: String = "down"
var can_move: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactor: Area2D = $Interactor

const FACE_OFFSET := {
	"down": Vector2(0, 10),
	"up": Vector2(0, -10),
	"left": Vector2(-10, 2),
	"right": Vector2(10, 2),
}

func _ready() -> void:
	if character_sheet:
		sprite.sprite_frames = CharacterFactory.build(character_sheet)
	sprite.play("idle_down")
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var input := Vector2.ZERO
	if can_move:
		input.x = Input.get_axis("move_left", "move_right")
		input.y = Input.get_axis("move_up", "move_down")
		input = input.limit_length(1.0)
	velocity = input * speed
	move_and_slide()
	_update_animation(input)
	# Keep the interaction probe in front of the player every frame so overlap
	# queries are already settled when `interact` is pressed.
	interactor.position = FACE_OFFSET[facing]

func _update_animation(input: Vector2) -> void:
	if input == Vector2.ZERO:
		sprite.play("idle_" + facing)
		return
	# Prefer the dominant axis for facing so diagonals pick a sensible sprite.
	if abs(input.x) > abs(input.y):
		facing = "right" if input.x > 0 else "left"
	else:
		facing = "down" if input.y > 0 else "up"
	interactor.position = FACE_OFFSET[facing]
	sprite.play("walk_" + facing)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_move:
		_try_interact()

func _try_interact() -> void:
	interactor.position = FACE_OFFSET[facing]
	for area in interactor.get_overlapping_areas():
		var target := area if area.has_method("interact") else area.get_parent()
		if target and target.has_method("interact"):
			target.interact(self)
			return
	for body in interactor.get_overlapping_bodies():
		if body.has_method("interact"):
			body.interact(self)
			return

func set_movement_locked(locked: bool) -> void:
	can_move = not locked
	if locked:
		velocity = Vector2.ZERO
		sprite.play("idle_" + facing)
