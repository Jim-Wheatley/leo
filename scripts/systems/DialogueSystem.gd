class_name DialogueSystem extends Node

# Simple dialogue system for NPC interactions

signal dialogue_finished()
signal option_selected(option_index: int)

var current_dialogue: Dictionary = {}
var current_speaker: String = ""
var is_active: bool = false
var current_options: Array = []

func _ready():
	# Simple console-based dialogue system for now
	is_active = false

func show_dialogue(speaker: String, text: String, options: Array = []):
	"""Show dialogue with optional response options"""
	current_speaker = speaker
	current_options = options
	is_active = true
	
	# For now, just print to console
	print("\n💬 %s: \"%s\"" % [speaker, text])
	
	if options.size() > 0:
		print("Options:")
		for i in range(options.size()):
			print("  %d. %s" % [i + 1, options[i]])
		print("(Auto-selecting first option for testing)")
		# Auto-select first option for testing
		call_deferred("_auto_select_option", 0)
	else:
		print("(Press any key to continue)")
		call_deferred("hide_dialogue")

func hide_dialogue():
	"""Hide the dialogue panel"""
	is_active = false
	dialogue_finished.emit()

func _auto_select_option(option_index: int):
	"""Auto-select an option for testing"""
	print("Selected option %d: %s" % [option_index + 1, current_options[option_index]])
	option_selected.emit(option_index)
	hide_dialogue()

func _input(event):
	"""Handle input during dialogue"""
	if not is_active:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if current_options.size() == 0:
			hide_dialogue()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		hide_dialogue()
		get_viewport().set_input_as_handled()

# Convenience methods for common dialogue patterns
func show_simple_dialogue(speaker: String, text: String):
	"""Show simple dialogue with just a continue button"""
	show_dialogue(speaker, text, [])

func show_choice_dialogue(speaker: String, text: String, choices: Array):
	"""Show dialogue with multiple choice options"""
	show_dialogue(speaker, text, choices)

func show_task_assignment_dialogue(task: TaskData):
	"""Show dialogue for task assignment"""
	var options = ["Accept Task", "Not Now"]
	show_dialogue("Master Artist", task.assignment_dialogue, options)

func show_task_completion_dialogue(task: TaskData):
	"""Show dialogue for task completion"""
	show_simple_dialogue("Master Artist", task.completion_dialogue)