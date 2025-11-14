extends Control

# Tutorial UI - Displays tutorial messages and guidance

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var message_label = $Panel/VBoxContainer/MessageLabel
@onready var continue_button = $Panel/VBoxContainer/ContinueButton
@onready var skip_button = $Panel/VBoxContainer/SkipButton

var current_highlight: Node = null

func _ready():
	hide()
	continue_button.pressed.connect(_on_continue_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	if TutorialManager:
		TutorialManager.tutorial_started.connect(_on_tutorial_started)
		TutorialManager.tutorial_completed.connect(_on_tutorial_completed)

func show_tutorial(tutorial_title: String, message: String, highlight_target: String = ""):
	title_label.text = tutorial_title
	message_label.text = message
	
	# Clear previous highlight
	_clear_highlight()
	
	# Add new highlight if specified
	if highlight_target != "":
		_highlight_element(highlight_target)
	
	show()

func hide_tutorial():
	_clear_highlight()
	hide()

func _on_continue_pressed():
	if TutorialManager:
		TutorialManager.advance_tutorial()

func _on_skip_pressed():
	if TutorialManager:
		TutorialManager.skip_tutorial()

func _on_tutorial_started(tutorial_id: String):
	show()

func _on_tutorial_completed(tutorial_id: String):
	hide_tutorial()

func _highlight_element(target_name: String):
	# Find the target element in the scene
	var target = _find_node_by_name(get_tree().root, target_name)
	if target and target is Node2D:
		if VFXManager:
			current_highlight = VFXManager.create_interaction_highlight(target)

func _clear_highlight():
	if current_highlight:
		current_highlight.queue_free()
		current_highlight = null

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_name(child, target_name)
		if result:
			return result
	
	return null
