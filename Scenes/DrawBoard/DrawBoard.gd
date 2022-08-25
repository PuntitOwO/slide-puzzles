extends Node2D

# Child nodes
onready var lines = $Lines
onready var color_picker = $ControlsLayer/PanelContainer/VBoxContainer/HBoxContainer2/ColorPickerButton
onready var width_slider = $ControlsLayer/PanelContainer/VBoxContainer/HBoxContainer3/HSlider
onready var width_values = $ControlsLayer/PanelContainer/VBoxContainer/HBoxContainer3/values
onready var clear_button = $ControlsLayer/PanelContainer/VBoxContainer/HBoxContainer/Clear
onready var undo_button = $ControlsLayer/PanelContainer/VBoxContainer/HBoxContainer/Undo

# Settings
export (float) var min_distance = 1.0

# Mouse status
var was_mouse_pressed : bool = false
var is_mouse_pressed : bool = false

# Current Drawing
var current_line : Line2D = null
var current_point : Vector2 = Vector2.ZERO
var current_color : Color = Color.blue setget set_color, get_color
var current_width : float = 10.0 setget set_width, get_width

func _ready():
	# To change color when selected on color picker
	var _er1 = color_picker.connect("color_changed", self, "set_color")
	var _er2 = width_slider.connect("value_changed", self, "set_width")
	var _er3 = clear_button.connect("pressed", self, "clear_all")
	var _er4 = undo_button.connect("pressed", self, "clear_last")

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			is_mouse_pressed = event.pressed

func _process(_delta):
	var mouse_pos : Vector2 = get_global_mouse_position()
	var echo = is_mouse_pressed == was_mouse_pressed
	
	# Just pressed
	if is_mouse_pressed and not echo:
		# Create new Line2D with mouse_pos as first point
		current_point = mouse_pos
		current_line = Line2D.new()
		init_line(current_line)
		lines.add_child(current_line)
		current_line.add_point(current_point)
		current_line.add_point(current_point + Vector2(0.001,0))
	
	# Pressed
	if is_mouse_pressed and echo:
		# Sanity check
		if not is_instance_valid(current_line):
			return
		# Add new point
		if mouse_pos.distance_to(current_point) > min_distance:
			current_point = mouse_pos
			current_line.add_point(current_point)
	# Just released
	if not is_mouse_pressed and not echo:
		current_line.antialiased = true
		current_line = null
		current_point = Vector2.ZERO
	# Released
	if not is_mouse_pressed and echo:
		pass
	
	was_mouse_pressed = is_mouse_pressed

## Initializes Line2D with current selected settings
func init_line(line : Line2D):
	line.width = current_width
	line.default_color = current_color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND

func set_color(value : Color):
	current_color = value

func get_color() -> Color:
	return current_color

func set_width(value : float):
	current_width = value
	width_values.text = var2str(value)

func get_width() -> float:
	return current_width

func clear_last():
	var index = lines.get_child_count()
	if index > 0:
		var last_line = lines.get_child(index-1)
		lines.remove_child(last_line)
		last_line.queue_free()
	

func clear_all():
	for child in lines.get_children():
		lines.remove_child(child)
		child.queue_free()
