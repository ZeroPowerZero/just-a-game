class_name drawability
extends Node3D

@onready var drawing: Line2D = $Drawing
@onready var pen: Node3D = $Pen

var stroke_points: Array[Vector2] = []
var stroke_points_3d: Array[Vector3] = []
var last_mouse_pos: Vector2 = Vector2(640, 360)
var mouse_pos: Vector2 = Vector2(640, 360)
var immediate_mesh: ImmediateMesh

func _ready() -> void:
	await get_tree().create_timer(0.01).timeout
	EventBus.emit_signal("get_mesh", attach_immediate_mesh as Callable)

func attach_immediate_mesh(mesh):
	immediate_mesh = mesh

func paint(event):
	mouse_pos += event.relative * 2
	mouse_pos = mouse_pos.clamp(Vector2(0, 0), Vector2(1280, 720))
	
	if event.button_mask == MOUSE_BUTTON_LEFT:
		EventBus.currentState |= EventBus.state.DRAW
		
		pen.position = pen.position.lerp(Vector3(mouse_pos.x/1000, -mouse_pos.y/1000, 0) - Vector3(0.3, -0.7, 0.0), 0.1)
		
		if stroke_points.is_empty() or stroke_points.back().distance_to(mouse_pos) > 5:
			stroke_points.append(mouse_pos)
			
			stroke_points_3d.append(pen.global_position+-pen.basis.z*0.2)
			add_point()
	elif EventBus.currentState & EventBus.state.DRAW:
		EventBus.currentState &= ~EventBus.state.DRAW
		
		if stroke_points.size() > 10:
			recognize_shape(stroke_points)
		stroke_points.clear()
		drawing.clear_points()
		
		stroke_points_3d.clear()
		immediate_mesh.clear_surfaces()
	else:
		pen.position = pen.position.lerp(Vector3(0, 0, 0), 0.1)
	
	last_mouse_pos = mouse_pos

func add_point():
	immediate_mesh.clear_surfaces()
	if stroke_points_3d.size() < 2: return
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in stroke_points_3d:
		immediate_mesh.surface_add_vertex(i)
	immediate_mesh.surface_end()

const NUM_POINTS = 64
const SQUARE_SIZE = 250.0

func process_stroke(points: Array[Vector2]) -> Array[Vector2]:
	var resampled = resample(points, NUM_POINTS)
	var translated = translate_to_origin(resampled)
	var scaled = scale_to_square(translated, SQUARE_SIZE)
	return scaled

func resample(points: Array[Vector2], n: int) -> Array[Vector2]:
	if points.size() < 2:
		return points.duplicate()
		
	var interval_length = path_length(points) / (n - 1)
	
	if interval_length <= 0.001:
		var tiny_arr: Array[Vector2] = []
		for j in range(n):
			tiny_arr.append(points[0])
		return tiny_arr
	
	var D = 0.0
	var new_points: Array[Vector2] = [points[0]]
	var i = 1
	
	var working_points = points.duplicate()
	
	while i < working_points.size():
		var d = working_points[i-1].distance_to(working_points[i])
		if D + d >= interval_length:
			var ratio = (interval_length - D) / d if d > 0 else 0.0
			var qx = round(working_points[i-1].x + ratio * (working_points[i].x - working_points[i-1].x))
			var qy = round(working_points[i-1].y + ratio * (working_points[i].y - working_points[i-1].y))
			var q = Vector2(qx, qy)
			
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
	centroid /= points.size()
	
	var new_points: Array[Vector2] = []
	for p in points:
		new_points.append(p - centroid)
	return new_points

func scale_to_square(points: Array[Vector2], size: float) -> Array[Vector2]:
	var min_x = INF; var max_x = -INF
	var min_y = INF; var max_y = -INF
	
	for p in points:
		min_x = min(min_x, p.x); max_x = max(max_x, p.x)
		min_y = min(min_y, p.y); max_y = max(max_y, p.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	
	var new_points: Array[Vector2] = []
	for p in points:
		var qx = p.x * (size / width) if width != 0 else p.x
		var qy = p.y * (size / height) if height != 0 else p.y
		new_points.append(Vector2(qx, qy))
	return new_points

func recognize_shape(points: Array[Vector2]):
	var processed_points = process_stroke(points)
	var best_match: SpellManager = null
	var best_score = INF
	
	for template in Templates.spells:
		var score = compare_paths(processed_points, template.get_coords())
		
		if score < best_score:
			best_score = score
			best_match = template
	
	if best_match:
		$"../UI -- For Just Test/Last_Spell_Label".text = best_match.get_spell().name
	
	stroke_points.clear()
	drawing.clear_points()

func compare_paths(path1: Array[Vector2], path2: Array[Vector2]) -> float:
	var total_distance = 0.0
	for i in range(min(path1.size(), path2.size())):
		total_distance += path1[i].distance_to(path2[i])
	return total_distance / path1.size()
