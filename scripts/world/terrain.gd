extends StaticBody3D

@export var terrain_size: Vector2 = Vector2(300.0, 300.0)
@export_range(2, 256) var subdivisions: int = 100
@export var hill_height: float = 4.0
@export var hill_frequency: float = 0.035
@export var ground_color: Color = Color(0.27, 0.43, 0.24)
@export_group("Ground Grid")
@export var grid_enabled: bool = true
@export_range(0.1, 50.0, 0.1) var grid_spacing: float = 2.0
@export_range(0.005, 0.5, 0.005) var grid_line_width: float = 0.04
@export var grid_color: Color = Color(0.12, 0.20, 0.10)

const GRID_SHADER = preload("res://shaders/ground_grid.gdshader")

func height_at(x: float, z: float) -> float:
	return hill_height * sin(x * hill_frequency) * sin(z * hill_frequency)

func _ready() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(subdivisions):
		for x in range(subdivisions):
			var a := vertex_at(x, z)
			var b := vertex_at(x + 1, z)
			var c := vertex_at(x + 1, z + 1)
			var d := vertex_at(x, z + 1)
			for vertex in [a, b, c, a, c, d]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh := surface.commit()
	var material := ShaderMaterial.new()
	material.shader = GRID_SHADER
	material.set_shader_parameter("ground_color", ground_color)
	material.set_shader_parameter("grid_enabled", grid_enabled)
	material.set_shader_parameter("grid_spacing", grid_spacing)
	material.set_shader_parameter("line_width", grid_line_width)
	material.set_shader_parameter("grid_color", grid_color)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	add_child(collision)

func vertex_at(x: int, z: int) -> Vector3:
	var px := (float(x) / subdivisions - 0.5) * terrain_size.x
	var pz := (float(z) / subdivisions - 0.5) * terrain_size.y
	return Vector3(px, height_at(px, pz), pz)
