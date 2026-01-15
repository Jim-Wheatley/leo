extends CanvasLayer

# Achievement Notification - Shows popup when achievements are unlocked

@onready var panel = $NotificationPanel
@onready var title_label = $NotificationPanel/VBoxContainer/TitleLabel
@onready var description_label = $NotificationPanel/VBoxContainer/DescriptionLabel
@onready var icon_rect = $NotificationPanel/VBoxContainer/IconRect

var notification_queue: Array = []
var is_showing: bool = false

func _ready():
	panel.visible = false
	panel.modulate.a = 1.0

func queue_notification(title: String, description: String):
	notification_queue.append({"title": title, "description": description})
	
	if not is_showing:
		_show_next_notification()

func _show_next_notification():
	if notification_queue.is_empty():
		is_showing = false
		panel.visible = false
		return
	
	is_showing = true
	var notification = notification_queue.pop_front()
	
	title_label.text = notification["title"]
	description_label.text = notification["description"]
	
	# Play sound
	if AudioManager:
		AudioManager.play_sfx("achievement_unlocked")
	
	# Show and animate in
	panel.visible = true
	panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(3.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_show_next_notification)
