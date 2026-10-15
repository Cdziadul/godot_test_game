extends Node3D

@export var terrain_path: NodePath = NodePath("../Terrain")
@export var player_path: NodePath = NodePath("../Player")
@export_range(0, 1000) var tree_count: int = 220
@export var forest_seed: int = 7319
@export var randomize_seed: bool = true
@export_range(1.0, 30.0) var minimum_spacing: float = 7.0
@export_range(1.0, 50.0) var spawn_clearance: float = 14.0
@export_range(1.0, 20.0) var edge_margin: float = 5.0
@export_range(2.0, 20.0) var tree_height: float = 8.0
@export_range(0.1, 1.0) var trunk_radius: float = 0.3
@export_range(0.5, 5.0) var canopy_radius: float = 2.0
@export var scale_range: Vector2 = Vector2(0.75, 1.3)
@export var trunk_color: Color = Color(0.30, 0.17, 0.08)
@export var foliage_color: Color = Color(0.12, 0.32, 0.16)

func _ready() -> void:
	# Wait until the terrain's generated collision is in the physics world.
	await get_tree().physics_frame
	generate()

func generate() -> void:
	var terrain = get_node(terrain_path)
	var player := get_node(player_path) as CharacterBody3D
	var rng := RandomNumberGenerator.new()
	if randomize_seed:
		rng.randomize()
	else:
		rng.seed = forest_seed
	var half_size: Vector2 = terrain.terrain_size * 0.5 - Vector2.ONE * edge_margin
	if half_size.x <= 0.0 or half_size.y <= 0.0:
		push_warning("Terrain is too small for the forest edge margin.")
		return
	var positions: Array[Vector2] = []
	var spawn := Vector2(player.global_position.x, player.global_position.z)
	var bark := StandardMaterial3D.new()
	bark.albedo_color = trunk_color
	bark.roughness = 1.0
	for attempt in range(tree_count * 30):
		if positions.size() >= tree_count:
			break
		var local_point := Vector3(rng.randf_range(-half_size.x, half_size.x), 0, rng.randf_range(-half_size.y, half_size.y))
		var world_point: Vector3 = terrain.to_global(local_point)
		var point := Vector2(world_point.x, world_point.z)
		if point.distance_to(spawn) < spawn_clearance:
			continue
		var crowded := false
		for existing in positions:
			if existing.distance_to(point) < minimum_spacing:
				crowded = true
				break
		if crowded:
			continue
		var vertical_range: float = abs(terrain.hill_height) + 100.0
		var query := PhysicsRayQueryParameters3D.create(world_point + Vector3.UP * vertical_range, world_point - Vector3.UP * vertical_range, terrain.collision_layer)
		query.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.collider != terrain:
			continue
		positions.append(point)
		var size := rng.randf_range(maxf(0.1, minf(scale_range.x, scale_range.y)), maxf(0.1, maxf(scale_range.x, scale_range.y)))
		var tree := build_tree(size, rng, bark)
		add_child(tree)
		tree.global_position = hit.position - Vector3.UP * 0.08
	if positions.size() < tree_count:
		push_warning("Placed %d of %d trees; reduce spacing or count for this terrain." % [positions.size(), tree_count])

func build_tree(size: float, rng: RandomNumberGenerator, bark: Material) -> StaticBody3D:
	var tree := StaticBody3D.new()
	tree.name = "Tree"
	# Separate layer allows placement rays to hit only the terrain.
	tree.collision_layer = 2
	var height := tree_height * size
	var radius := trunk_radius * size
	var trunk := CylinderMesh.new()
	trunk.top_radius = radius * 0.65
	trunk.bottom_radius = radius
	trunk.height = height * 0.65
	trunk.radial_segments = 8
	add_mesh(tree, trunk, bark, trunk.height * 0.5)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = trunk.height
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = shape.height * 0.5
	tree.add_child(collision)
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = foliage_color.lightened(rng.randf_range(0.0, 0.12))
	leaves.roughness = 1.0
	for tier in range(3):
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = canopy_radius * size * (1.0 - tier * 0.23)
		cone.height = height * 0.45
		cone.radial_segments = 9
		add_mesh(tree, cone, leaves, height * (0.38 + tier * 0.20))
	return tree

func add_mesh(parent: Node3D, mesh: Mesh, material: Material, height: float) -> void:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.position.y = height
	parent.add_child(visual)
