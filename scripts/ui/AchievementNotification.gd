extends Control

# Achievement Notification - Shows popup when achievements are unlocked

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var description_label = $Panel/VBoxContainer/DescriptionLabel
@onready var icon_rect = $Panel/VBoxContainer/IconRect

var notification_queue: Array = []
var is_showing: bool = false

func _ready():
	modulate.a = 0.0
	
	# Don't connect to signal - UIManager will call queue_notification directly
	# This prevents duplicate notifications

func _on_achievement_unlocked(achievement_id: String):
	if not AchievementManager.achievements.has(achievement_id):
		return
	
	var achievement = AchievementManager.achievements[achievement_id]
	queue_notification(achievement["title"], achievement["description"])

func queue_notification(title: String, description: String):
	notification_queue.append({"title": title, "description": description})
	
	if not is_showing:
		_show_next_notification()

func _show_next_notification():
	if notification_queue.is_empty():
		is_showing = false
		return
	
	is_showing = true
	var notification = notification_queue.pop_front()
	
	title_label.text = notification["title"]
	description_label.text = notification["description"]
	
	# Play sound
	if AudioManager:
		AudioManager.play_sfx("achievement_unlocked")
	
	# Animate in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_interval(3.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_show_next_notification)
