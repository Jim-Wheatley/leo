extends Control
class_name PortfolioUI

# Portfolio UI for viewing completed artworks and sketches

signal artwork_selected(artwork: ArtworkData)
signal close_requested()

@onready var artwork_grid: GridContainer = $VBoxContainer/ScrollContainer/ArtworkGrid
@onready var artwork_info_panel: Control = $VBoxContainer/ArtworkInfoPanel
@onready var artwork_title_label: Label = $VBoxContainer/ArtworkInfoPanel/VBoxContainer/ArtworkTitleLabel
@onready var artwork_details_label: Label = $VBoxContainer/ArtworkInfoPanel/VBoxContainer/ArtworkDetailsLabel
@onready var artwork_description_label: Label = $VBoxContainer/ArtworkInfoPanel/VBoxContainer/ArtworkDescriptionLabel
@onready var close_button: Button = $VBoxContainer/HeaderPanel/CloseButton
@onready var filter_option: OptionButton = $VBoxContainer/HeaderPanel/FilterOption

var selected_artwork: ArtworkData = null
var artwork_buttons: Array[Button] = []
var current_filter: ArtworkData.ArtworkType = -1  # -1 means show all

func _ready():
	# WORKAROUND: Force HeaderPanel to fill width
	var header_panel = $VBoxContainer/HeaderPanel
	if header_panel:
		header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		await get_tree().process_frame
		header_panel.custom_minimum_size.x = 900
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		close_button.mouse_entered.connect(_on_close_button_mouse_entered)
		close_button.mouse_exited.connect(_on_close_button_mouse_exited)
	
	if filter_option:
		filter_option.item_selected.connect(_on_filter_changed)
	
	# Set up filter options
	setup_filter_options()
	
	# Hide artwork info panel initially
	artwork_info_panel.visible = false
	
	# Set up grid
	artwork_grid.columns = 4
	
	# Initially hidden
	visible = false

func setup_filter_options():
	"""Set up the filter dropdown options"""
	filter_option.add_item("All Artworks", -1)
	filter_option.add_item("Sketches", ArtworkData.ArtworkType.SKETCH)
	filter_option.add_item("Paintings", ArtworkData.ArtworkType.PAINTING)
	filter_option.add_item("Studies", ArtworkData.ArtworkType.STUDY)
	filter_option.add_item("Masterworks", ArtworkData.ArtworkType.MASTERWORK)

func show_portfolio():
	"""Show the portfolio UI and refresh artworks"""
	visible = true
	refresh_portfolio()

func hide_portfolio():
	"""Hide the portfolio UI"""
	visible = false
	clear_selection()

func refresh_portfolio():
	"""Refresh the portfolio display with current artworks"""
	clear_artwork_grid()
	
	if not GameManager.player_data:
		return
	
	# Filter and sort artworks
	var filtered_artworks = filter_artworks(GameManager.player_data.portfolio)
	var sorted_artworks = sort_artworks_by_date(filtered_artworks)
	
	# Add artworks to grid
	for artwork in sorted_artworks:
		add_artwork_to_grid(artwork)
	
	# Show message if no artworks
	if sorted_artworks.is_empty():
		add_empty_message()

func filter_artworks(artworks: Array) -> Array:
	"""Filter artworks based on current filter"""
	if current_filter == -1:
		return artworks  # Show all
	
	var filtered = []
	for artwork in artworks:
		if artwork.artwork_type == current_filter:
			filtered.append(artwork)
	
	return filtered

func sort_artworks_by_date(artworks: Array) -> Array:
	"""Sort artworks by creation date (newest first)"""
	var sorted = artworks.duplicate()
	sorted.sort_custom(func(a, b): return a.creation_date > b.creation_date)
	return sorted

func clear_artwork_grid():
	"""Clear all artworks from the grid"""
	# Clear all children from the grid (including empty message labels)
	for child in artwork_grid.get_children():
		child.queue_free()
	artwork_buttons.clear()

func add_artwork_to_grid(artwork: ArtworkData):
	"""Add an artwork button to the grid"""
	var artwork_button = Button.new()
	artwork_button.custom_minimum_size = Vector2(120, 100)
	artwork_button.text = get_artwork_display_text(artwork)
	artwork_button.tooltip_text = get_artwork_tooltip(artwork)
	
	# Style based on artwork type and quality
	style_artwork_button(artwork_button, artwork)
	
	# Connect signal
	artwork_button.pressed.connect(_on_artwork_selected.bind(artwork))
	
	artwork_grid.add_child(artwork_button)
	artwork_buttons.append(artwork_button)

func add_empty_message():
	"""Add a message when no artworks are available"""
	var message_label = Label.new()
	message_label.text = "No artworks in portfolio yet.\nCreate some art to see it here!"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.custom_minimum_size = Vector2(300, 100)
	
	artwork_grid.add_child(message_label)

func get_artwork_display_text(artwork: ArtworkData) -> String:
	"""Get display text for artwork button"""
	var title = artwork.title
	if title.length() > 15:
		title = title.substr(0, 12) + "..."
	
	var type_icon = get_artwork_type_icon(artwork.artwork_type)
	var quality = artwork.get_quality_description()
	
	return "%s %s\n%s" % [type_icon, title, quality]

func get_artwork_type_icon(type: ArtworkData.ArtworkType) -> String:
	"""Get icon/symbol for artwork type"""
	match type:
		ArtworkData.ArtworkType.SKETCH:
			return "✏️"
		ArtworkData.ArtworkType.PAINTING:
			return "🎨"
		ArtworkData.ArtworkType.STUDY:
			return "📚"
		ArtworkData.ArtworkType.MASTERWORK:
			return "👑"
		_:
			return "🖼️"

func get_artwork_tooltip(artwork: ArtworkData) -> String:
	"""Get tooltip text for artwork"""
	return "%s\nQuality: %.1f (%s)\nCreated: %s" % [
		artwork.title,
		artwork.quality_score,
		artwork.get_quality_description(),
		format_date(artwork.creation_date)
	]

func format_date(date_string: String) -> String:
	"""Format date string for display"""
	# Simple formatting - could be enhanced
	if date_string.length() > 10:
		return date_string.substr(0, 10)
	return date_string

func style_artwork_button(button: Button, artwork: ArtworkData):
	"""Apply styling to artwork button based on type and quality"""
	var style = StyleBoxFlat.new()
	
	# Base color based on artwork type
	match artwork.artwork_type:
		ArtworkData.ArtworkType.SKETCH:
			style.bg_color = Color(0.8, 0.8, 0.8, 0.8)  # Light gray
		ArtworkData.ArtworkType.PAINTING:
			style.bg_color = Color(0.6, 0.4, 0.8, 0.8)  # Purple
		ArtworkData.ArtworkType.STUDY:
			style.bg_color = Color(0.4, 0.6, 0.8, 0.8)  # Blue
		ArtworkData.ArtworkType.MASTERWORK:
			style.bg_color = Color(0.9, 0.7, 0.2, 0.8)  # Gold
		_:
			style.bg_color = Color(0.5, 0.5, 0.5, 0.8)  # Default gray
	
	# Adjust brightness based on quality
	var quality_multiplier = 0.7 + (artwork.quality_score / 10.0) * 0.3
	style.bg_color = style.bg_color * quality_multiplier
	
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	
	button.add_theme_stylebox_override("normal", style)

func _on_artwork_selected(artwork: ArtworkData):
	"""Called when an artwork is selected"""
	selected_artwork = artwork
	show_artwork_info(artwork)
	artwork_selected.emit(artwork)

func show_artwork_info(artwork: ArtworkData):
	"""Show detailed information about the selected artwork"""
	artwork_info_panel.visible = true
	
	artwork_title_label.text = artwork.title
	
	# Build details text
	var details = []
	details.append("Type: %s" % ArtworkData.ArtworkType.keys()[artwork.artwork_type])
	details.append("Quality: %.1f (%s)" % [artwork.quality_score, artwork.get_quality_description()])
	details.append("Created: %s" % format_date(artwork.creation_date))
	
	if not artwork.materials_used.is_empty():
		details.append("Materials: %s" % ", ".join(artwork.materials_used))
	
	if artwork.inspiration_source != "":
		details.append("Inspiration: %s" % artwork.inspiration_source)
	
	# Show skill levels at creation
	if not artwork.skill_level_at_creation.is_empty():
		details.append("\nSkill levels when created:")
		for skill in artwork.skill_level_at_creation:
			details.append("  %s: %d" % [skill.capitalize(), artwork.skill_level_at_creation[skill]])
	
	artwork_details_label.text = "\n".join(details)
	
	# Description based on quality and type
	artwork_description_label.text = generate_artwork_description(artwork)

func generate_artwork_description(artwork: ArtworkData) -> String:
	"""Generate a descriptive text for the artwork"""
	var descriptions = []
	
	# Quality-based description
	if artwork.quality_score >= 8.0:
		descriptions.append("A masterful work that showcases exceptional skill and artistry.")
	elif artwork.quality_score >= 6.0:
		descriptions.append("An excellent piece demonstrating solid technique and vision.")
	elif artwork.quality_score >= 4.0:
		descriptions.append("A good work showing developing skill and understanding.")
	elif artwork.quality_score >= 2.0:
		descriptions.append("A fair attempt with room for improvement.")
	else:
		descriptions.append("An early work showing the beginning stages of artistic development.")
	
	# Type-specific description
	match artwork.artwork_type:
		ArtworkData.ArtworkType.SKETCH:
			descriptions.append("This sketch captures the essence of the subject with confident lines.")
		ArtworkData.ArtworkType.PAINTING:
			descriptions.append("The painting demonstrates your growing mastery of color and composition.")
		ArtworkData.ArtworkType.STUDY:
			descriptions.append("This study shows careful observation and technical practice.")
		ArtworkData.ArtworkType.MASTERWORK:
			descriptions.append("A true masterwork that represents the pinnacle of your artistic achievement.")
	
	return " ".join(descriptions)

func clear_selection():
	"""Clear the current artwork selection"""
	selected_artwork = null
	artwork_info_panel.visible = false

func _on_filter_changed(index: int):
	"""Called when filter selection changes"""
	current_filter = filter_option.get_item_id(index)
	refresh_portfolio()

func _on_close_pressed():
	"""Called when close button is pressed"""
	close_requested.emit()
	hide_portfolio()

func _input(event):
	"""Handle input events - ESC to close"""
	if visible and event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		hide_portfolio()
		get_viewport().set_input_as_handled()

func get_artwork_count() -> int:
	"""Get total number of artworks in portfolio"""
	if not GameManager.player_data:
		return 0
	return GameManager.player_data.portfolio.size()

func get_artwork_count_by_type(type: ArtworkData.ArtworkType) -> int:
	"""Get count of artworks by type"""
	if not GameManager.player_data:
		return 0
	
	var count = 0
	for artwork in GameManager.player_data.portfolio:
		if artwork.artwork_type == type:
			count += 1
	
	return count

func _on_close_button_mouse_entered():
	"""Mouse entered close button"""
	pass

func _on_close_button_mouse_exited():
	"""Mouse exited close button"""
	pass

func _unhandled_input(event: InputEvent):
	"""WORKAROUND: Manually detect clicks on close button
	
	TODO: Investigate why buttons don't receive normal input events and fix root cause.
	"""
	if not visible or not close_button:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var button_rect = close_button.get_global_rect()
		if button_rect.has_point(event.position):
			_on_close_pressed()
			get_viewport().set_input_as_handled()
