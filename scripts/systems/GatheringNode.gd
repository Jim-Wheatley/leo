class_name GatheringNode
extends Area2D

signal resource_gathered(item_id: String, quantity: int)
signal resource_depleted

@export var resource_id: String = "clay"
@export var resource_name: String = "Clay Deposit"
@export var max_resources: int = 10
@export var current_resources: int = 10
@export var regeneration_time: float = 300.0  # 5 minutes in seconds
@export var base_gather_amount: int = 1
@export var rare_material_chance: float = 0.1  # 10% chance for rare materials
@export var required_skill_level: int = 0
@export var skill_experience_gain: int = 5

var is_depleted: bool = false
var regeneration_timer: Timer
var interaction_area: CollisionShape2D
var visual_sprite: Sprite2D

func _ready():
	# Set up the interaction area
	interaction_area = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 32.0
	interaction_area.shape = shape
	add_child(interaction_area)
	
	# Set up regeneration timer
	regeneration_timer = Timer.new()
	regeneration_timer.wait_time = regeneration_time
	regeneration_timer.one_shot = true
	regeneration_timer.timeout.connect(_on_regeneration_complete)
	add_child(regeneration_timer)
	
	# Connect to player interaction
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_update_visual_state()

func _on_body_entered(body):
	if body.has_method("set_interaction_target"):
		body.set_interaction_target(self)

func _on_body_exited(body):
	if body.has_method("clear_interaction_target"):
		body.clear_interaction_target(self)

func can_gather() -> bool:
	if is_depleted or current_resources <= 0:
		return false
	
	# Check if player has required skill level
	var player_skill = SkillManager.get_skill_level("gathering")
	return player_skill >= required_skill_level

func gather_resource() -> Dictionary:
	if not can_gather():
		return {"success": false, "message": "Cannot gather from this resource"}
	
	var player_skill = SkillManager.get_skill_level("gathering")
	var skill_bonus = max(0, (player_skill - required_skill_level) / 10.0)
	
	# Calculate gather amount with skill bonus
	var gather_amount = base_gather_amount + int(skill_bonus)
	gather_amount = min(gather_amount, current_resources)
	
	# Check for rare materials
	var items_gathered = []
	var rare_found = false
	
	for i in range(gather_amount):
		if randf() < rare_material_chance:
			items_gathered.append(_get_rare_material())
			rare_found = true
		else:
			items_gathered.append(resource_id)
	
	# Update resource count
	current_resources -= gather_amount
	
	# Add items to player inventory
	for item_id in items_gathered:
		GameManager.add_item_to_inventory(item_id, 1)
	
	# Grant skill experience
	SkillManager.add_experience("gathering", skill_experience_gain)
	
	# Notify task system about resource gathering
	TaskManager.on_resource_gathered(resource_id, rare_found)
	
	# Check if depleted
	if current_resources <= 0:
		_set_depleted(true)
	
	_update_visual_state()
	
	# Emit signals
	resource_gathered.emit(resource_id, gather_amount)
	
	var result = {
		"success": true,
		"items": items_gathered,
		"rare_found": rare_found,
		"remaining": current_resources
	}
	
	return result

func _get_rare_material() -> String:
	# Override in subclasses for specific rare materials
	match resource_id:
		"clay":
			return "rare_ochre"
		"mineral_vein":
			return "precious_pigment"
		_:
			return resource_id + "_rare"

func _set_depleted(depleted: bool):
	is_depleted = depleted
	if depleted and current_resources <= 0:
		regeneration_timer.start()
		resource_depleted.emit()

func _on_regeneration_complete():
	current_resources = max_resources
	is_depleted = false
	_update_visual_state()
	print("Resource node regenerated: ", resource_name)

func _update_visual_state():
	# Update visual appearance based on resource availability
	if visual_sprite:
		if is_depleted or current_resources <= 0:
			visual_sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)  # Grayed out
		elif current_resources < max_resources * 0.3:
			visual_sprite.modulate = Color(1.0, 0.8, 0.6, 1.0)  # Yellowish (low resources)
		else:
			visual_sprite.modulate = Color.WHITE  # Full color

func get_interaction_text() -> String:
	if not can_gather():
		if is_depleted:
			var time_left = regeneration_timer.time_left
			return "Depleted (Regenerates in " + str(int(time_left)) + "s)"
		else:
			return "Requires Gathering Skill " + str(required_skill_level)
	
	return "Gather from " + resource_name + " (" + str(current_resources) + " remaining)"

func save_data() -> Dictionary:
	return {
		"current_resources": current_resources,
		"is_depleted": is_depleted,
		"regeneration_time_left": regeneration_timer.time_left if regeneration_timer.time_left > 0 else 0
	}

func load_data(data: Dictionary):
	current_resources = data.get("current_resources", max_resources)
	is_depleted = data.get("is_depleted", false)
	var time_left = data.get("regeneration_time_left", 0)
	
	if time_left > 0:
		regeneration_timer.wait_time = time_left
		regeneration_timer.start()
	
	_update_visual_state()