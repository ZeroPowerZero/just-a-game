class_name drawability
extends Node3D

# ==============================
# SETTINGS
# ==============================

@export var pen_sensitivity: float = 15.0 # Increased slightly for snappier follow
@export var draw_threshold: float = 5.0   # Minimum distance between points

const NUM_POINTS = 64
const SQUARE_SIZE = 250.0

# ==============================
# REFERENCES
# ==============================

@onready var drawing: Line2D = $Drawing
@onready var pen: Node3D = $Pen
@onready var last_spell_label: Label = $"../UI -- For Just Test/Last_Spell_Label"

var immediate_mesh: ImmediateMesh

# ==============================
# STROKE DATA
# ==============================

var stroke_points: Array[Vector2] = []
var stroke_points_3d: Array[Vector3] = []

var mouse_pos: Vector2
var last_mouse_pos: Vector2

# ==============================
# READY
# ==============================

func _ready() -> void:
	mouse_pos = get_viewport().get_visible_rect().size / 2.0
	last_mouse_pos = mouse_pos
	
	# Use call_deferred instead of a magic timer to ensure nodes are ready
	call_deferred("_request_mesh")

func _request_mesh():
	EventBus.emit_signal("get_mesh", attach_immediate_mesh)

func attach_immediate_mesh(mesh: ImmediateMesh):
	immediate_mesh = mesh

# ==============================
# PROCESS
# ==============================

func _process(delta: float) -> void:
	# Smooth pen follow
	pen.position = pen.position.lerp(_get_pen_target_pos(), pen_sensitivity * delta)
	
	# Handle drawing logic continuously
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		left_clicked()
	elif EventBus.currentState & EventBus.state.DRAW:
		left_released()

# ==============================
# INPUT
# ==============================

func _input(event: InputEvent) -> void:
	# Always track mouse position, regardless of click state
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		last_mouse_pos = mouse_pos

# ==============================
# HELPERS
# ==============================

func _get_pen_target_pos() -> Vector3:
	# Adjusting screen to world mapping based on your specific offsets
	return Vector3(
		mouse_pos.x / 800.0,
		-mouse_pos.y / 800.0,
		0
	) - Vector3(0.4, -0.9, 0.0)

# ==============================
# DRAW START
# ==============================

func left_clicked():
	# If this is the very first frame of drawing
	if not (EventBus.currentState & EventBus.state.DRAW):
		EventBus.currentState |= EventBus.state.DRAW
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		pen.position = _get_pen_target_pos() # Snap pen instantly to avoid trailing
	
	# Add new point only if far enough
	if stroke_points.is_empty() or stroke_points.back().distance_to(mouse_pos) > draw_threshold:
		
		stroke_points.append(mouse_pos)
		drawing.add_point(mouse_pos) # Fixed: Actually draw the 2D line!
		
		stroke_points_3d.append(
			pen.global_position - pen.global_basis.z * 0.4
		)
		
		update_mesh()

# ==============================
# DRAW END
# ==============================

func left_released():
	EventBus.currentState &= ~EventBus.state.DRAW
	
	if stroke_points.size() > 10:
		recognize_shape(stroke_points)
	
	clear_stroke()

func clear_stroke():
	stroke_points.clear()
	stroke_points_3d.clear()
	drawing.clear_points()
	
	if immediate_mesh:
		immediate_mesh.clear_surfaces()

# ==============================
# UPDATE MESH
# ==============================

func update_mesh():
	if not immediate_mesh or stroke_points_3d.size() < 2:
		return
	
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for p in stroke_points_3d:
		immediate_mesh.surface_add_vertex(p)
	
	immediate_mesh.surface_end()

# ==============================
# STROKE PROCESSING (Gesture Recognition)
# ==============================

func process_stroke(points: Array[Vector2]) -> Array[Vector2]:
	var resampled = resample(points, NUM_POINTS)
	var translated = translate_to_origin(resampled)
	var scaled = scale_to_square(translated, SQUARE_SIZE)
	return scaled

func resample(points: Array[Vector2], n: int) -> Array[Vector2]:
	if points.size() < 2:
		return points.duplicate()
	
	var total_length = path_length(points)
	var interval_length = total_length / max(n - 1, 1)
	
	if interval_length <= 0.001:
		var tiny: Array[Vector2] = []
		tiny.resize(n)
		tiny.fill(points[0])
		return tiny
	
	var D := 0.0
	var new_points: Array[Vector2] = [points[0]]
	var working_points = points.duplicate()
	
	var i := 1
	var safety_counter := 0
	var MAX_ITERATIONS := 10000 
	
	while i < working_points.size() and safety_counter < MAX_ITERATIONS:
		safety_counter += 1
		var d = working_points[i - 1].distance_to(working_points[i])
		
		if d <= 0.0001:
			i += 1
			continue
		
		if D + d >= interval_length:
			var ratio = (interval_length - D) / d
			var q = working_points[i - 1].lerp(working_points[i], ratio)
			
			new_points.append(q)
			working_points.insert(i, q)
			D = 0.0
			i += 1
		else:
			D += d
			i += 1
	
	while new_points.size() < n:
		new_points.append(working_points.back())
	
	return new_points

func path_length(points: Array[Vector2]) -> float:
	var d = 0.0
	for i in range(1, points.size()):
		d += points[i-1].distance_to(points[i])
	return d

func translate_to_origin(points: Array[Vector2]) -> Array[Vector2]:
	var centroid = Vector2.ZERO
	for p in points:
		centroid += p
	centroid /= max(points.size(), 1)
	
	var new_points: Array[Vector2] = []
	for p in points:
		new_points.append(p - centroid)
	return new_points

func scale_to_square(points: Array[Vector2], size: float) -> Array[Vector2]:
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for p in points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	
	var width = max(max_x - min_x, 0.0001)
	var height = max(max_y - min_y, 0.0001)
	
	var new_points: Array[Vector2] = []
	for p in points:
		var qx = p.x * (size / width)
		var qy = p.y * (size / height)
		new_points.append(Vector2(qx, qy))
	return new_points

# ==============================
# RECOGNITION
# ==============================

func recognize_shape(points: Array[Vector2]):
	var processed_points = process_stroke(points)
	var best_match = null
	var best_score = INF
	
	for template in Templates.spells:
		var score = compare_paths(processed_points, template.get_coords())
		if score < best_score:
			best_score = score
			best_match = template
	
	if best_match and last_spell_label:
		last_spell_label.text = best_match.get_spell().name

func compare_paths(path1: Array[Vector2], path2: Array[Vector2]) -> float:
	if path1.is_empty() or path2.is_empty():
		return INF
	
	var total_distance = 0.0
	var count = min(path1.size(), path2.size())
	
	for i in range(count):
		total_distance += path1[i].distance_to(path2[i])
	
	return total_distance / count
