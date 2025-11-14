class_name ClayDeposit
extends GatheringNode

func _ready():
	resource_id = "clay"
	resource_name = "Clay Deposit"
	max_resources = 15
	current_resources = 15
	regeneration_time = 240.0  # 4 minutes
	base_gather_amount = 2
	rare_material_chance = 0.15  # 15% chance for rare ochre
	required_skill_level = 0
	skill_experience_gain = 8
	
	super._ready()
	
	# Set up visual sprite
	visual_sprite = Sprite2D.new()
	add_child(visual_sprite)
	
	# Create a simple colored rectangle for now (can be replaced with actual sprite)
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color(0.8, 0.6, 0.4))  # Clay brown color
	texture.set_image(image)
	visual_sprite.texture = texture

func _get_rare_material() -> String:
	var rare_materials = ["rare_ochre", "red_ochre", "yellow_ochre"]
	return rare_materials[randi() % rare_materials.size()]

func get_interaction_text() -> String:
	if not can_gather():
		if is_depleted:
			var time_left = regeneration_timer.time_left
			return "Clay Depleted (Regenerates in " + str(int(time_left)) + "s)"
		else:
			return "Cannot gather clay"
	
	return "Gather Clay (" + str(current_resources) + " remaining)"