extends Control

# Incremental button test - building up to game complexity

@onready var close_button: Button = $VBoxContainer/HeaderPanel/CloseButton
@onready var test_button: Button = $VBoxContainer/ContentPanel/TestButton
@onready var label: Label = $VBoxContainer/ContentPanel/Label
@onready var status_label: Label = $StatusLabel

var test_step = 0
var canvas_layer: CanvasLayer = null
var ui_container: Control = null

func _ready():
	print("\n=== INCREMENTAL BUTTON TEST ===")
	print("Press SPACE to advance through test steps")
	print("Press R to reset")
	
	# Connect buttons
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		close_button.mouse_entered.connect(_on_close_mouse_entered)
		close_button.mouse_exited.connect(_on_close_mouse_exited)
	
	if test_button:
		test_button.pressed.connect(_on_test_pressed)
	
	update_status()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			advance_test()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			reset_test()
			get_viewport().set_input_as_handled()

func advance_test():
	test_step += 1
	
	match test_step:
		1:
			print("\n--- STEP 1: Add CanvasLayer (layer 10) ---")
			canvas_layer = CanvasLayer.new()
			canvas_layer.name = "TestCanvasLayer"
			canvas_layer.layer = 10
			get_tree().root.add_child(canvas_layer)
			print("✅ Added CanvasLayer with layer=10")
			
		2:
			print("\n--- STEP 2: Move UI to CanvasLayer ---")
			get_parent().remove_child(self)
			canvas_layer.add_child(self)
			print("✅ Moved ButtonTest to CanvasLayer")
			
		3:
			print("\n--- STEP 3: Add intermediate Control container ---")
			ui_container = Control.new()
			ui_container.name = "UIContainer"
			ui_container.set_anchors_preset(Control.PRESET_FULL_RECT)
			ui_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			# Move self to container
			canvas_layer.remove_child(self)
			canvas_layer.add_child(ui_container)
			ui_container.add_child(self)
			print("✅ Added UIContainer with MOUSE_FILTER_IGNORE")
			
		4:
			print("\n--- STEP 4: Set root to MOUSE_FILTER_IGNORE ---")
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			print("✅ Set ButtonTest root to MOUSE_FILTER_IGNORE")
			
		5:
			print("\n--- STEP 5: Force HeaderPanel width (like game) ---")
			var header_panel = $VBoxContainer/HeaderPanel
			header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			await get_tree().process_frame
			header_panel.custom_minimum_size.x = 800
			print("✅ Forced HeaderPanel width to 800")
			print("HeaderPanel size:", header_panel.size)
			
		_:
			print("\n--- TEST COMPLETE ---")
			print("All steps applied. Try clicking the close button now.")
			test_step = 5
	
	update_status()

func reset_test():
	print("\n--- RESETTING TEST ---")
	get_tree().reload_current_scene()

func update_status():
	var steps = [
		"STEP 0: Baseline (working)",
		"STEP 1: Add CanvasLayer (layer 10)",
		"STEP 2: Move UI to CanvasLayer",
		"STEP 3: Add UIContainer with IGNORE filter",
		"STEP 4: Set root to IGNORE filter",
		"STEP 5: Force HeaderPanel width"
	]
	
	if test_step < steps.size():
		status_label.text = steps[test_step] + "\n\nPress SPACE to advance\nPress ESC to reset"
	else:
		status_label.text = "TEST COMPLETE\n\nPress ESC to reset"

func _on_close_pressed():
	print("🎉🎉🎉 CLOSE BUTTON PRESSED!")
	label.text = "Close button works at step " + str(test_step) + "!"
	label.modulate = Color.GREEN

func _on_close_mouse_entered():
	print("🖱️ Mouse entered close button")

func _on_close_mouse_exited():
	print("🖱️ Mouse exited close button")

func _on_test_pressed():
	print("🎉 TEST BUTTON PRESSED!")
	label.text = "Test button works!"
	label.modulate = Color.CYAN
