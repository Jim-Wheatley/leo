class_name MineralVein
extends GatheringNode

func _ready():
	resource_id = "mineral_ore"
	resource_name = "Mineral Vein"
	max_resources = 8
	current_resources = 8
	regeneration_time = 600.0  # 10 minutes
	base_gather_amount = 1
	rare_material_chance = 0.25  # 25% chance for precious pigments
	required_skill_level = 2  # Requires some gathering skill
	skill_experience_gain = 12
	
	super._ready()
	
	# Set up visual sprite
	visual_sprite = Sprite2D.new()
	add_child(visual_sprite)
	
	# Create a simple colored rectangle for now (can be replaced with actual sprite)
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color(0.6, 0.6, 0.7))  # Mineral gray color
	texture.set_image(image)
	visual_sprite.texture = texture

func _get_rare_material() -> String:
	var rare_materials = ["lapis_lazuli", "cinnabar", "malachite", "azurite"]
	return rare_materials[randi() % rare_materials.size()]

func get_interaction_text() -> String:
	if not can_gather():
		if is_depleted:
			var time_left = regeneration_timer.time_left
			return "Vein Depleted (Regenerates in " + str(int(time_left)) + "s)"
		elif SkillManager.get_skill_level("gathering") < required_skill_level:
			return "Requires Gathering Skill " + str(required_skill_level)
		else:
			return "Cannot gather minerals"
	
	return "Mine Minerals (" + str(current_resources) + " remaining)"