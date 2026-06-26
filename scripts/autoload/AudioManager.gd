extends Node
## Simple music + SFX manager (autoload). Looping BGM with quick crossfade, and a
## small pool of one-shot SFX players.

var _music: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _current_path := ""
var _sfx_pool: Array = []
const SFX_VOICES := 6

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = _new_player(-8.0)
	_music_b = _new_player(-8.0)
	_active = _music
	for i in SFX_VOICES:
		_sfx_pool.append(_new_player(-4.0))

func _new_player(vol: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = vol
	add_child(p)
	return p

func play_bgm(path: String, restart := false) -> void:
	if path == _current_path and _active.playing and not restart:
		return
	_current_path = path
	if not ResourceLoader.exists(path):
		return
	var stream := load(path)
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	# crossfade to the idle player
	var nxt: AudioStreamPlayer = _music_b if _active == _music else _music
	nxt.stream = stream
	nxt.volume_db = -40.0
	nxt.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(nxt, "volume_db", -8.0, 0.6)
	tw.tween_property(_active, "volume_db", -40.0, 0.6)
	var prev := _active
	tw.chain().tween_callback(prev.stop)
	_active = nxt

func stop_bgm() -> void:
	_current_path = ""
	_music.stop()
	_music_b.stop()

func play_sfx(path: String, pitch := 1.0) -> void:
	if not ResourceLoader.exists(path):
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = load(path)
			p.pitch_scale = pitch
			p.play()
			return
