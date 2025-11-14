extends Node

# Audio Manager - Handles all sound effects and ambient audio

signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)

# Audio players
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 8

# Volume settings
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var ambient_volume: float = 0.5

# Audio library
var music_tracks: Dictionary = {}
var sfx_library: Dictionary = {}
var ambient_tracks: Dictionary = {}

func _ready():
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# Create ambient player
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Ambient"
	add_child(ambient_player)
	
	# Create SFX player pool
	for i in MAX_SFX_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
	
	_load_audio_library()
	apply_volume_settings()

func _load_audio_library():
	# Load music tracks
	music_tracks["workshop_theme"] = load("res://assets/audio/BeepBox-Song-1.wav")
	music_tracks["main_theme"] = load("res://assets/audio/BeepBox-Song-1.wav")
	
	# Load sound effects
	sfx_library["ui_click"] = load("res://assets/audio/mixkit-game-ball-tap-2073.wav")
	sfx_library["crafting_success"] = load("res://assets/audio/mixkit-game-bonus-reached-2065.wav")
	sfx_library["skill_up"] = load("res://assets/audio/mixkit-video-game-treasure-2066.wav")
	sfx_library["achievement_unlocked"] = load("res://assets/audio/mixkit-video-game-treasure-2066.wav")
	sfx_library["gathering"] = load("res://assets/audio/mixkit-game-ball-tap-2073.wav")
	sfx_library["sketching"] = load("res://assets/audio/mixkit-game-ball-tap-2073.wav")
	sfx_library["footstep"] = load("res://assets/audio/mixkit-game-ball-tap-2073.wav")
	
	# Ambient tracks (using music for now, you can add dedicated ambient files later)
	ambient_tracks["workshop_ambient"] = load("res://assets/audio/BeepBox-Song-1.wav")
	ambient_tracks["city_ambient"] = load("res://assets/audio/BeepBox-Song-1.wav")

func play_music(track_name: String, fade_duration: float = 1.0):
	if not music_tracks.has(track_name):
		push_warning("Music track not found: " + track_name)
		return
	
	if music_player.playing:
		# Fade out current track
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_duration)
		tween.tween_callback(func(): _start_music(track_name, fade_duration))
	else:
		_start_music(track_name, fade_duration)

func _start_music(track_name: String, fade_duration: float):
	music_player.stream = music_tracks[track_name]
	music_player.volume_db = -80
	music_player.play()
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_duration)

func stop_music(fade_duration: float = 1.0):
	if not music_player.playing:
		return
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80, fade_duration)
	tween.tween_callback(music_player.stop)

func play_ambient(ambient_name: String, loop: bool = true):
	if not ambient_tracks.has(ambient_name):
		push_warning("Ambient track not found: " + ambient_name)
		return
	
	ambient_player.stream = ambient_tracks[ambient_name]
	ambient_player.volume_db = linear_to_db(ambient_volume)
	if loop and ambient_player.stream is AudioStreamWAV:
		ambient_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambient_player.play()

func stop_ambient(fade_duration: float = 0.5):
	if not ambient_player.playing:
		return
	
	var tween = create_tween()
	tween.tween_property(ambient_player, "volume_db", -80, fade_duration)
	tween.tween_callback(ambient_player.stop)

func play_sfx(sfx_name: String, pitch_variation: float = 0.0):
	# Find available SFX player
	var player: AudioStreamPlayer = null
	for p in sfx_players:
		if not p.playing:
			player = p
			break
	
	if player == null:
		# All players busy, use first one
		player = sfx_players[0]
	
	if not sfx_library.has(sfx_name):
		push_warning("SFX not found: " + sfx_name)
		return
	
	player.stream = sfx_library[sfx_name]
	player.volume_db = linear_to_db(sfx_volume)
	
	if pitch_variation > 0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	else:
		player.pitch_scale = 1.0
	
	player.play()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume) if music_volume > 0 else -80
	music_volume_changed.emit(music_volume)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	sfx_volume_changed.emit(sfx_volume)

func set_ambient_volume(volume: float):
	ambient_volume = clamp(volume, 0.0, 1.0)
	ambient_player.volume_db = linear_to_db(ambient_volume) if ambient_volume > 0 else -80

func apply_volume_settings():
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)
	set_ambient_volume(ambient_volume)

# Convenience methods for common game sounds
func play_ui_click():
	play_sfx("ui_click", 0.1)

func play_crafting_success():
	play_sfx("crafting_success")

func play_skill_up():
	play_sfx("skill_up")

func play_gathering():
	play_sfx("gathering", 0.15)

func play_sketching():
	play_sfx("sketching", 0.1)

func play_footstep():
	play_sfx("footstep", 0.2)
