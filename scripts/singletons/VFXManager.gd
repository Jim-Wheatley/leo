extends Node

# VFX Manager - Handles visual effects for game events

# Particle scenes
var particle_scenes: Dictionary = {}

# Effect colors
const SKILL_UP_COLOR = Color(1.0, 0.9, 0.3)
const CRAFTING_SUCCESS_COLOR = Color(0.3, 1.0, 0.5)
const GATHERING_COLOR = Color(0.8, 0.6, 0.3)
const RARE_ITEM_COLOR = Color(1.0, 0.3, 1.0)

func _ready():
	_load_particle_scenes()

func _load_particle_scenes():
	# Placeholder for loading particle scenes
	# In production, load actual particle scenes from res://scenes/vfx/
	pass

func create_skill_up_effect(position: Vector2, skill_name: String = ""):
	_create_particle_burst(position, SKILL_UP_COLOR, 20)
	
	# Add floating text
	if skill_name != "":
		_create_floating_text(position, skill_name + " +", SKILL_UP_COLOR)
	
	# Play sparkle animation
	_create_sparkle_ring(position, SKILL_UP_COLOR)

func create_crafting_success_effect(position: Vector2):
	_create_particle_burst(position, CRAFTING_SUCCESS_COLOR, 15)
	_create_sparkle_ring(position, CRAFTING_SUCCESS_COLOR)
	
	# Add success indicator
	_create_floating_text(position, "Success!", CRAFTING_SUCCESS_COLOR)

func create_gathering_effect(position: Vector2, is_rare: bool = false):
	var color = RARE_ITEM_COLOR if is_rare else GATHERING_COLOR
	_create_particle_burst(position, color, 10)
	
	if is_rare:
		_create_sparkle_ring(position, color)
		_create_floating_text(position, "Rare!", color)

func create_level_up_effect(global_position: Vector2):
	# Large celebration effect
	_create_particle_burst(global_position, SKILL_UP_COLOR, 40)
	_create_sparkle_ring(global_position, SKILL_UP_COLOR, 2.0)
	_create_floating_text(global_position, "Level Up!", SKILL_UP_COLOR, 1.5)

func create_item_pickup_effect(position: Vector2):
	_create_particle_burst(position, Color.WHITE, 8)

func _create_particle_burst(position: Vector2, color: Color, count: int):
	var particles = CPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = count
	particles.lifetime = 0.8
	particles.explosiveness = 0.8
	
	# Appearance
	particles.color = color
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	
	# Movement
	particles.direction = Vector2.UP
	particles.spread = 180
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.gravity = Vector2(0, 200)
	
	# Add to scene
	get_tree().current_scene.add_child(particles)
	
	# Auto-cleanup after lifetime
	get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)

func _create_sparkle_ring(position: Vector2, color: Color, scale: float = 1.0):
	var ring = Node2D.new()
	ring.position = position
	get_tree().current_scene.add_child(ring)
	
	# Create sparkles in a ring
	var sparkle_count = 12
	for i in sparkle_count:
		var angle = (i / float(sparkle_count)) * TAU
		var sparkle_pos = Vector2(cos(angle), sin(angle)) * 30 * scale
		
		var sparkle = CPUParticles2D.new()
		sparkle.position = sparkle_pos
		sparkle.emitting = true
		sparkle.one_shot = true
		sparkle.amount = 3
		sparkle.lifetime = 0.5
		sparkle.color = color
		sparkle.scale_amount_min = 3.0
		sparkle.scale_amount_max = 5.0
		sparkle.initial_velocity_min = 20
		sparkle.initial_velocity_max = 40
		sparkle.direction = Vector2(cos(angle), sin(angle))
		sparkle.spread = 30
		
		ring.add_child(sparkle)
	
	# Animate ring expansion
	var tween = create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE * 1.5, 0.5)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.5)
	tween.tween_callback(ring.queue_free)

func _create_floating_text(position: Vector2, text: String, color: Color, scale: float = 1.0):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", int(24 * scale))
	label.modulate = color
	label.position = position - Vector2(50, 20)
	label.z_index = 100
	
	# Add outline for visibility
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	
	get_tree().current_scene.add_child(label)
	
	# Animate upward float
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(label.queue_free)

func create_interaction_highlight(node: Node2D):
	# Create a pulsing highlight effect
	var highlight = ColorRect.new()
	highlight.color = Color(1, 1, 1, 0.3)
	highlight.size = Vector2(64, 64)
	highlight.position = -highlight.size / 2
	node.add_child(highlight)
	
	var tween = create_tween().set_loops()
	tween.tween_property(highlight, "modulate:a", 0.1, 0.8)
	tween.tween_property(highlight, "modulate:a", 0.5, 0.8)
	
	return highlight

func screen_flash(color: Color, duration: float = 0.2):
	var flash = ColorRect.new()
	flash.color = color
	flash.modulate.a = 0.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Make it cover the screen
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	get_tree().root.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.5, duration / 2)
	tween.tween_property(flash, "modulate:a", 0.0, duration / 2)
	tween.tween_callback(flash.queue_free)
