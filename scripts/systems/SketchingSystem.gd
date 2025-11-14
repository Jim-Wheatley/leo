extends Node
class_name SketchingSystem

# Sketching System for City Exploration
# Handles different subject types and sketching mechanics

enum SubjectType {
	BUILDING,
	PERSON,
	OBJECT,
	SCENE
}

enum SketchingPhase {
	OBSERVATION,
	SKETCHING,
	COMPLETION
}

signal sketch_completed(sketch_data: ArtworkData)
signal sketching_started(subject_type: SubjectType)
signal sketching_cancelled()

var current_subject: Node = null
var current_subject_type: SubjectType
var current_phase: SketchingPhase
var observation_time: float = 0.0
var sketching_progress: float = 0.0
var is_sketching: bool = false

# Subject-specific parameters
var subject_data: Dictionary = {}

func _ready():
	# Initialize sketching system
	print("🎨 Sketching system initialized")

func can_sketch_subject(subject: Node) -> bool:
	"""Check if a subject can be sketched"""
	if not subject:
		return false
	
	# Check if subject has sketching metadata
	return subject.has_meta("sketchable") and subject.get_meta("sketchable", false)

func get_subject_type(subject: Node) -> SubjectType:
	"""Determine the type of subject being sketched"""
	if not subject:
		return SubjectType.OBJECT
	
	var subject_type_string = subject.get_meta("subject_type", "object")
	match subject_type_string:
		"building":
			return SubjectType.BUILDING
		"person":
			return SubjectType.PERSON
		"scene":
			return SubjectType.SCENE
		_:
			return SubjectType.OBJECT

func start_sketching(subject: Node) -> bool:
	"""Start sketching a subject"""
	if is_sketching:
		print("⚠️ Already sketching something!")
		return false
	
	if not can_sketch_subject(subject):
		print("⚠️ This subject cannot be sketched")
		return false
	
	current_subject = subject
	current_subject_type = get_subject_type(subject)
	current_phase = SketchingPhase.OBSERVATION
	is_sketching = true
	observation_time = 0.0
	sketching_progress = 0.0
	
	# Get subject-specific data
	subject_data = get_subject_data(subject)
	
	print("🎨 Starting to sketch: %s (%s)" % [subject_data.get("name", "Unknown"), SubjectType.keys()[current_subject_type]])
	
	sketching_started.emit(current_subject_type)
	return true

func get_subject_data(subject: Node) -> Dictionary:
	"""Get data about the subject being sketched"""
	var data = {}
	
	# Basic subject information
	data["name"] = subject.get_meta("subject_name", subject.name)
	data["description"] = subject.get_meta("subject_description", "An interesting subject")
	data["difficulty"] = subject.get_meta("difficulty", 1.0)
	data["previous_sketches"] = get_previous_sketch_count(subject)
	
	# Subject-type specific data
	match current_subject_type:
		SubjectType.BUILDING:
			data["architectural_style"] = subject.get_meta("architectural_style", "Renaissance")
			data["complexity"] = subject.get_meta("complexity", "Medium")
		SubjectType.PERSON:
			data["pose"] = subject.get_meta("pose", "Standing")
			data["movement"] = subject.get_meta("movement", "Static")
		SubjectType.SCENE:
			data["elements"] = subject.get_meta("scene_elements", ["Buildings", "People"])
			data["lighting"] = subject.get_meta("lighting", "Daylight")
		SubjectType.OBJECT:
			data["material"] = subject.get_meta("material", "Stone")
			data["size"] = subject.get_meta("size", "Medium")
	
	return data

func get_previous_sketch_count(subject: Node) -> int:
	"""Get how many times this subject has been sketched before"""
	if not GameManager.player_data:
		return 0
	
	var subject_id = subject.get_meta("subject_id", subject.name)
	var count = 0
	
	for artwork in GameManager.player_data.portfolio:
		if artwork.artwork_type == ArtworkData.ArtworkType.SKETCH:
			if artwork.has_meta("subject_id") and artwork.get_meta("subject_id") == subject_id:
				count += 1
	
	return count

func update_sketching(delta: float):
	"""Update the sketching process"""
	if not is_sketching:
		return
	
	match current_phase:
		SketchingPhase.OBSERVATION:
			update_observation_phase(delta)
		SketchingPhase.SKETCHING:
			update_sketching_phase(delta)
		SketchingPhase.COMPLETION:
			complete_sketch()

func update_observation_phase(delta: float):
	"""Update the observation phase"""
	observation_time += delta
	
	var required_observation_time = get_required_observation_time()
	
	if observation_time >= required_observation_time:
		current_phase = SketchingPhase.SKETCHING
		print("👁️ Observation complete. Beginning sketch...")

func get_required_observation_time() -> float:
	"""Get the required observation time based on subject type and difficulty"""
	var base_time = 2.0
	var difficulty_multiplier = subject_data.get("difficulty", 1.0)
	
	match current_subject_type:
		SubjectType.BUILDING:
			base_time = 3.0
		SubjectType.PERSON:
			base_time = 2.5
		SubjectType.SCENE:
			base_time = 4.0
		SubjectType.OBJECT:
			base_time = 1.5
	
	return base_time * difficulty_multiplier

func update_sketching_phase(delta: float):
	"""Update the actual sketching phase"""
	var sketching_speed = get_sketching_speed()
	sketching_progress += sketching_speed * delta
	
	if sketching_progress >= 1.0:
		current_phase = SketchingPhase.COMPLETION

func get_sketching_speed() -> float:
	"""Get sketching speed based on player skills"""
	var base_speed = 0.2
	var sketching_skill = SkillManager.get_skill_level("sketching")
	var observation_skill = SkillManager.get_skill_level("observation")
	
	# Higher skills = faster sketching
	var skill_multiplier = 1.0 + (sketching_skill + observation_skill) * 0.1
	
	return base_speed * skill_multiplier

func complete_sketch():
	"""Complete the current sketch"""
	if not is_sketching:
		return
	
	# Calculate sketch quality
	var quality = calculate_sketch_quality()
	
	# Create sketch artwork
	var sketch = create_sketch_artwork(quality)
	
	# Add to portfolio
	if GameManager.player_data:
		GameManager.player_data.add_artwork(sketch)
	
	# Notify task system about sketch creation
	var sketch_type = "sketch"
	var subject_name = subject_data.get("name", "Unknown")
	if current_subject_type == SubjectType.BUILDING and current_subject.has_meta("is_landmark"):
		sketch_type = "landmark"
	TaskManager.on_sketch_created(sketch_type, subject_name)
	
	# Award skill experience
	award_sketching_experience(quality)
	
	print("✅ Sketch completed! Quality: %.1f (%s)" % [quality, sketch.get_quality_description()])
	
	# Emit completion signal
	sketch_completed.emit(sketch)
	
	# Reset sketching state
	reset_sketching_state()

func calculate_sketch_quality() -> float:
	"""Calculate the quality of the completed sketch"""
	var base_quality = 3.0
	
	# Skill-based quality
	var sketching_skill = SkillManager.get_skill_level("sketching")
	var observation_skill = SkillManager.get_skill_level("observation")
	var skill_bonus = (sketching_skill + observation_skill) * 0.3
	
	# Observation time bonus (good observation improves quality)
	var required_time = get_required_observation_time()
	var observation_bonus = min(observation_time / required_time, 2.0) * 0.5
	
	# Previous sketches bonus (practice makes perfect)
	var previous_count = subject_data.get("previous_sketches", 0)
	var practice_bonus = min(previous_count * 0.2, 1.0)
	
	# Subject difficulty affects quality potential
	var difficulty = subject_data.get("difficulty", 1.0)
	var difficulty_multiplier = 0.8 + (difficulty * 0.4)
	
	var final_quality = (base_quality + skill_bonus + observation_bonus + practice_bonus) * difficulty_multiplier
	
	# Add some randomness
	final_quality += randf_range(-0.3, 0.3)
	
	return clamp(final_quality, 1.0, 10.0)

func create_sketch_artwork(quality: float) -> ArtworkData:
	"""Create an ArtworkData object for the completed sketch"""
	var sketch = ArtworkData.new()
	sketch.title = generate_sketch_title()
	sketch.artwork_type = ArtworkData.ArtworkType.SKETCH
	sketch.quality_score = quality
	sketch.creation_date = Time.get_datetime_string_from_system()
	
	# Store subject information
	sketch.set_meta("subject_id", current_subject.get_meta("subject_id", current_subject.name))
	sketch.set_meta("subject_type", SubjectType.keys()[current_subject_type])
	sketch.set_meta("subject_name", subject_data.get("name", "Unknown"))
	
	# Store skill levels at creation
	sketch.skill_level_at_creation = {
		"sketching": SkillManager.get_skill_level("sketching"),
		"observation": SkillManager.get_skill_level("observation")
	}
	
	# Set inspiration source
	sketch.inspiration_source = subject_data.get("name", "Florence Subject")
	
	return sketch

func generate_sketch_title() -> String:
	"""Generate a title for the sketch based on subject"""
	var subject_name = subject_data.get("name", "Unknown Subject")
	var type_prefix = ""
	
	match current_subject_type:
		SubjectType.BUILDING:
			type_prefix = "Study of "
		SubjectType.PERSON:
			type_prefix = "Portrait of "
		SubjectType.SCENE:
			type_prefix = "Scene: "
		SubjectType.OBJECT:
			type_prefix = "Sketch of "
	
	return type_prefix + subject_name

func award_sketching_experience(quality: float):
	"""Award experience points for sketching"""
	var base_exp = 10.0
	var quality_multiplier = quality / 5.0  # Quality 5 = 1x multiplier
	var difficulty_multiplier = subject_data.get("difficulty", 1.0)
	
	var sketching_exp = base_exp * quality_multiplier * difficulty_multiplier
	var observation_exp = sketching_exp * 0.7  # Observation gets less exp
	
	SkillManager.add_experience("sketching", sketching_exp)
	SkillManager.add_experience("observation", observation_exp)
	
	print("📈 Gained %.1f sketching XP and %.1f observation XP" % [sketching_exp, observation_exp])

func cancel_sketching():
	"""Cancel the current sketching session"""
	if is_sketching:
		print("❌ Sketching cancelled")
		sketching_cancelled.emit()
		reset_sketching_state()

func reset_sketching_state():
	"""Reset all sketching state variables"""
	current_subject = null
	current_phase = SketchingPhase.OBSERVATION
	is_sketching = false
	observation_time = 0.0
	sketching_progress = 0.0
	subject_data.clear()

func get_sketching_progress() -> Dictionary:
	"""Get current sketching progress for UI display"""
	if not is_sketching:
		return {}
	
	var progress_data = {}
	progress_data["is_sketching"] = is_sketching
	progress_data["phase"] = SketchingPhase.keys()[current_phase]
	progress_data["subject_name"] = subject_data.get("name", "Unknown")
	progress_data["subject_type"] = SubjectType.keys()[current_subject_type]
	
	match current_phase:
		SketchingPhase.OBSERVATION:
			var required_time = get_required_observation_time()
			progress_data["progress"] = observation_time / required_time
			progress_data["status"] = "Observing subject..."
		SketchingPhase.SKETCHING:
			progress_data["progress"] = sketching_progress
			progress_data["status"] = "Sketching..."
		SketchingPhase.COMPLETION:
			progress_data["progress"] = 1.0
			progress_data["status"] = "Completing sketch..."
	
	return progress_data

func _process(delta):
	"""Update sketching system each frame"""
	if is_sketching:
		update_sketching(delta)