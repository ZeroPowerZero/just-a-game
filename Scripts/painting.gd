extends Control
#"""
#Professional Spell Drawing System
#----------------------------------
#• Full screen drawing board
#• Event-driven input (_gui_input)
#• Clean stroke recording
#• Proper gesture normalization (Resample → Center → Scale)
#• No magic numbers
#• No polling
#"""

# ====== CONFIGURATION ======

const NUM_POINTS: int = 64            # Number of points after resampling
const SQUARE_SIZE: float = 250.0      # Normalized bounding size
const MIN_POINT_DISTANCE: float = 4.0 # Minimum distance before adding new stroke point
const LINE_INTERPOLATION_STEP: float = 6.0

# ====== NODES ======

@onready var drawing: Line2D = $Drawing

# ====== STATE ======

var stroke_points: Array[Vector2] = []
var is_drawing: bool = false
var current_draw_index: int = 0


# ==========================================================
# INPUT SYSTEM (Event Driven)
# ==========================================================

func _gui_input(event: InputEvent) -> void:
	
	# Mouse pressed → start new stroke
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			
			if event.pressed:
				_start_stroke(event.position)
			else:
				_end_stroke()
	
	
	# Mouse moved while pressed → continue stroke
	if event is InputEventMouseMotion and is_drawing:
		_update_stroke(event.position)



# ==========================================================
# STROKE CONTROL
# ==========================================================

func _start_stroke(position: Vector2) -> void:
	#"""
	#Initializes a new stroke.
	#Clears previous drawing and begins recording.
	#"""
	is_drawing = true
	
	stroke_points.clear()
	drawing.clear_points()
	
	stroke_points.append(position)
	drawing.add_point(position)


func _update_stroke(position: Vector2) -> void:
	#"""
	#Adds new points to the stroke while drawing.
	#Interpolates if mouse moves too fast.
	#"""
	var last_point = stroke_points.back()
	
	# If movement is large → interpolate to avoid gaps
	if last_point.distance_to(position) > LINE_INTERPOLATION_STEP:
		_interpolate_line(last_point, position)
	else:
		_add_point(position)


func _end_stroke() -> void:
	#"""
	#Ends drawing and processes stroke if valid.
	#"""
	is_drawing = false
	
	if stroke_points.size() > 10:
		stroke_points = _process_stroke(stroke_points)



# ==========================================================
# DRAWING HELPERS
# ==========================================================

func _add_point(position: Vector2) -> void:
	#"""
	#Adds a point to both visual line and stroke data
	#only if far enough from last stored point.
	#"""
	if stroke_points.is_empty() or stroke_points.back().distance_to(position) > MIN_POINT_DISTANCE:
		stroke_points.append(position)
		drawing.add_point(position)


func _interpolate_line(from: Vector2, to: Vector2) -> void:
	#"""
	#Smoothly inserts intermediate points between two distant points.
	#Prevents visual and data gaps.
	#"""
	var current = from
	
	while current.distance_to(to) > 1.0:
		current = current.move_toward(to, LINE_INTERPOLATION_STEP)
		_add_point(current)



# ==========================================================
# GESTURE NORMALIZATION PIPELINE
# ==========================================================

func _process_stroke(points: Array[Vector2]) -> Array[Vector2]:
	#"""
	#Converts raw stroke into normalized gesture.
	#
	#Steps:
	#1. Resample → fixed number of points
	#2. Translate → center to origin
	#3. Scale → uniform size
	#"""
	var resampled = _resample(points, NUM_POINTS)
	var centered = _translate_to_origin(resampled)
	var scaled = _scale_to_square(centered, SQUARE_SIZE)
	
	return scaled



# ==========================================================
# RESAMPLING (Equal Point Distribution)
# ==========================================================

func _resample(points: Array[Vector2], n: int) -> Array[Vector2]:
	if points.size() < 2:
		return points.duplicate()
	
	var total_length = _path_length(points)
	var interval = total_length / (n - 1)
	
	if interval <= 0.001:
		return _duplicate_points(points[0], n)
	
	var D: float = 0.0
	var new_points: Array[Vector2] = [points[0]]
	var working = points.duplicate()
	
	var i: int = 1
	
	while i < working.size():
		var d = working[i - 1].distance_to(working[i])
		
		if D + d >= interval:
			var ratio = (interval - D) / d if d > 0 else 0.0
			var new_point = working[i - 1].lerp(working[i], ratio)
			
			new_points.append(new_point)
			working.insert(i, new_point)
			D = 0.0
		else:
			D += d
			i += 1
	
	while new_points.size() < n:
		new_points.append(working.back())
	
	return new_points


func _duplicate_points(point: Vector2, n: int) -> Array[Vector2]:
	var arr: Array[Vector2] = []
	for i in range(n):
		arr.append(point)
	return arr


func _path_length(points: Array[Vector2]) -> float:
	var length: float = 0.0
	for i in range(1, points.size()):
		length += points[i - 1].distance_to(points[i])
	return length



# ==========================================================
# NORMALIZATION HELPERS
# ==========================================================

func _translate_to_origin(points: Array[Vector2]) -> Array[Vector2]:
	#"""
	#Moves gesture so centroid becomes (0,0).
	#Removes position dependency.
	#"""
	var centroid = Vector2.ZERO
	
	for p in points:
		centroid += p
	
	centroid /= points.size()
	
	var new_points: Array[Vector2] = []
	for p in points:
		new_points.append(p - centroid)
	
	return new_points


func _scale_to_square(points: Array[Vector2], size: float) -> Array[Vector2]:
	#"""
	#Scales gesture uniformly so largest dimension fits inside square.
	#Preserves aspect ratio.
	#"""
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for p in points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	var scale = size / max(width, height) if max(width, height) != 0 else 1.0
	
	var new_points: Array[Vector2] = []
	for p in points:
		new_points.append(p * scale)
	
	return new_points



# ==========================================================
# FINISH BUTTON
# ==========================================================

func _on_finish_button_pressed() -> void:
	#"""
	#Sends normalized gesture to Templates system.
	#"""
	if stroke_points.size() <= 10:
		return
	
	var spell_name = Templates.add_new_spell(current_draw_index, stroke_points.duplicate())
	
	stroke_points.clear()
	drawing.clear_points()
	
	current_draw_index += 1
	
	if not spell_name:
		get_tree().change_scene_to_file("res://Scenes/first_person_demo.tscn")
		return
	
	get_parent().get_node("Label").text = spell_name
