extends Control
## Scrolling credits. Auto-scrolls; tap or press B to return to the title.

const TEXT := """STATIC FALLS
a quiet weird little town


~ THE END ~


Thank you for playing.


— ASSEMBLED FROM OPEN SOURCE —


ENGINE
Godot Engine  (MIT)
Juan Linietsky, Ariel Manzur & contributors


CODE COMPONENTS
Dialogue Manager  (MIT)
Nathan Hoad


ART
RPG Urban Pack  (CC0)
Kenney

Mobile Controls  (CC0)
Kenney

RPG Enemy Sprites  (CC-BY 3.0)
Stephen Challener (Redshrike)
via OpenGameArt.org


MUSIC
15 Melodic RPG Chiptunes  (CC0)
Aureolus_Omicron
via OpenGameArt.org


All art & audio sourced from open
libraries — none AI-generated.
Full attributions in CREDITS.md.


Story, design & code glue
built for this game.


STATIC FALLS
2026


"""

@onready var scroller: Label = $Scroller

func _ready() -> void:
	AudioManager.play_bgm("res://audio/bgm/story.ogg")
	scroller.text = TEXT
	scroller.position.y = get_viewport_rect().size.y
	var dist: float = get_viewport_rect().size.y + 900.0
	var tw := create_tween()
	tw.tween_property(scroller, "position:y", -900.0, 26.0)
	tw.tween_callback(_to_title)

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("cancel") or e.is_action_pressed("interact") \
			or (e is InputEventScreenTouch and e.pressed):
		_to_title()

func _to_title() -> void:
	if get_tree():
		get_tree().change_scene_to_file("res://scenes/ui/Title.tscn")
