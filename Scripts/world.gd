extends Node3D

var immediate_mesh: ImmediateMesh
var mesh_instance: MeshInstance3D

func _ready() -> void:
	#region immediate mesh
	immediate_mesh = ImmediateMesh.new()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate_mesh
	add_child(mesh_instance)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0) # Turkuaz/Mavi
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat
	#endregion
	
	EventBus.get_mesh.connect(get_mesh)

func get_mesh(function: Callable):
	function.call(immediate_mesh)
