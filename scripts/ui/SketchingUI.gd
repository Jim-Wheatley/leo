extends Control
class_name SketchingUI

# Sketching UI for displaying sketching progress and controls

signal sketching_cancelled()

@onready var background: ColorRect = $Background
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subject_label: Label = $VBoxContainer/SubjectLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var cancel_button: Button = $VBoxContainer/CancelButton
@onready var instructions_label: Label = $VBoxContainer/InstructionsLabel

var sketching_system: SketchingSystem

func _ready():
	# Initially hidden
	visible = false
	
	# Connect cancel button
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Set up UI styling
	setup_ui_styling()

func setup_ui_styling():
	"""Set up the visual styling for the sketching UI"""
	if background:
		background.color = Color(0.1, 0.1, 0.15, 0.9)
	
	if progress_bar:
		# Style the progress bar
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.4, 1.0)
		progress_bar.add_theme_stylebox_override("background", style)
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.6, 0.8, 0.4, 1.0)
		progress_bar.add_theme_stylebox_override("fill", fill_style)

func set_sketching_system(system: SketchingSystem):
	"""Set the sketching system reference"""
	sketching_system = system
	
	if sketching_system:
		# Connect to sketching system signals
		sketching_system.sketching_started.connect(_on_sketching_started)
		sketching_system.sketch_completed.connect(_on_sketch_completed)
		sketching_system.sketching_cancelled.connect(_on_sketching_cancelled)

func _on_sketching_started(subject_type: SketchingSystem.SubjectType):
	"""Called when sketching starts"""
	show_sketching_ui()
	update_subject_info(subject_type)

func show_sketching_ui():
	"""Show the sketching UI"""
	visible = true
	
	# Update instructions
	if instructions_label:
		instructions_label.text = "Hold still and observe carefully.\nPress ESC to cancel sketching."

func hide_sketching_ui():
	"""Hide the sketching UI"""
	visible = false

func update_subject_info(subject_type: SketchingSystem.SubjectType):
	"""Update the subject information display"""
	if not sketching_system:
		return
	
	var progress_data = sketching_system.get_sketching_progress()
	
	if title_label:
		title_label.text = "Sketching in Progress"
	
	if subject_label:
		var subject_name = progress_data.get("subject_name", "Unknown")
		var type_name = progress_data.get("subject_type", "OBJECT")
		subject_label.text = "%s (%s)" % [subject_name, type_name.capitalize()]

func _process(_delta):
	"""Update the UI each frame"""
	if visible and sketching_system and sketching_system.is_sketching:
		update_progress_display()

func update_progress_display():
	"""Update the progress bar and status"""
	var progress_data = sketching_system.get_sketching_progress()
	
	if progress_bar:
		var progress = progress_data.get("progress", 0.0)
		progress_bar.value = progress * 100.0
	
	if status_label:
		status_label.text = progress_data.get("status", "Sketching...")

func _on_cancel_pressed():
	"""Called when cancel button is pressed"""
	if sketching_system:
		sketching_system.cancel_sketching()

func _on_sketch_completed(sketch_data: ArtworkData):
	"""Called when a sketch is completed"""
	show_completion_message(sketch_data)
	
	# Hide UI after a short delay
	await get_tree().create_timer(2.0).timeout
	hide_sketching_ui()

func show_completion_message(sketch_data: ArtworkData):
	"""Show completion message"""
	if status_label:
		status_label.text = "Sketch completed!\n'%s' added to portfolio" % sketch_data.title
	
	if progress_bar:
		progress_bar.value = 100.0
	
	if cancel_button:
		cancel_button.text = "Close"

func _on_sketching_cancelled():
	"""Called when sketching is cancelled"""
	hide_sketching_ui()

func _input(event):
	"""Handle input events"""
	if visible and event.is_action_pressed("ui_cancel"):
		if sketching_system:
			sketching_system.cancel_sketching()