extends Node3D

@export var terrain_path: NodePath = NodePath("../Terrain")
@export var forest_path: NodePath = NodePath("../Forest")
@export var player_path: NodePath = NodePath("../Player")
@export_range(0, 1000) var rock_count: int = 300
@export var randomize_seed: bool = true
@export var rock_seed: int = 4821
@export_group("Size Mix")
@export_range(0.0, 1.0) var small_fraction: float = 0.70
@export_range(0.0, 1.0) var medium_fraction: float = 0.25
@export var small_radius: Vector2 = Vector2(0.25, 0.55)
@export var medium_radius: Vector2 = Vector2(0.8, 1.3)
@export var large_radius: Vector2 = Vector2(1.8, 2.8)
@export_group("Placement")
@export var spawn_clearance: float = 14.0
@export var object_gap: float = 1.0
@export var rock_color: Color = Color(0.42, 0.44, 0.46)

func _ready() -> void:
	# Forest generation runs on the first physics frame.
	await get_tree().physics_frame
	await get_tree().physics_frame
	generate()

func generate() -> void:
	var terrain = get_node(terrain_path)
	var forest := get_node(forest_path)
	var player := get_node(player_path) as CharacterBody3D
	var rng := RandomNumberGenerator.new()
	if randomize_seed:
		rng.randomize()
	else:
		rng.seed = rock_seed
	var small_count := int(round(rock_count * clampf(small_fraction, 0.0, 1.0)))
	var medium_count := mini(rock_count - small_count, int(round(rock_count * clampf(medium_fraction, 0.0, 1.0))))
	# Exact quotas keep the requested size mix, even with random placement.
	for index in range(rock_count):
		var category := "small" if index < small_count else ("medium" if index < small_count + medium_count else "large")
		var limits: Vector2 = small_radius if category == "small" else (medium_radius if category == "medium" else large_radius)
		var radius := rng.randf_range(maxf(0.05, minf(limits.x, limits.y)), maxf(0.05, maxf(limits.x, limits.y)))
		var extent := radius * 1.4
		var half_size: Vector2 = terrain.terrain_size * 0.5 - Vector2.ONE * (extent + 1.0)
		var placed := false
		for attempt in range(100):
			if half_size.x <= 0.0 or half_size.y <= 0.0:
				break
			var point: Vector3 = terrain.to_global(Vector3(rng.randf_range(-half_size.x, half_size.x), 0, rng.randf_range(-half_size.y, half_size.y)))
			var flat := Vector2(point.x, point.z)
			if flat.distance_to(Vector2(player.global_position.x, player.global_position.z)) < spawn_clearance + extent:
				continue
			var blocked := false
			for tree in forest.get_children():
				var tree_radius: float = forest.trunk_radius * maxf(forest.scale_range.x, forest.scale_range.y)
				if flat.distance_to(Vector2(tree.global_position.x, tree.global_position.z)) < extent + tree_radius + object_gap:
					blocked = true
					break
			if blocked:
				continue
			for rock in get_children():
				if flat.distance_to(Vector2(rock.global_position.x, rock.global_position.z)) < extent + float(rock.get_meta("extent")) + object_gap:
					blocked = true
					break
			if blocked:
				continue
			var ray_height: float = absf(terrain.hill_height) + 100.0
			var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * ray_height, point - Vector3.UP * ray_height, terrain.collision_layer)
			query.exclude = [player.get_rid()]
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or hit.collider != terrain:
				continue
			var rock := build_rock(radius, rng)
			rock.set_meta("size_category", category)
			rock.set_meta("extent", extent)
			add_child(rock)
			rock.global_position = hit.position + Vector3.UP * radius * 0.25
			rock.rotation.y = rng.randf_range(-PI, PI)
			placed = true
			break
		if not placed:
			push_warning("Could not place a %s rock; reduce density or clearance." % category)

func build_rock(radius: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var base := SphereMesh.new()
	base.radius = 1.0
	base.height = 2.0
	base.radial_segments = 8
	base.rings = 3
	var proportions := Vector3(rng.randf_range(0.85, 1.15), rng.randf_range(0.55, 0.85), rng.randf_range(0.85, 1.15)) * radius
	var phase := rng.randf_range(0.0, TAU)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in base.get_faces():
		# Position-based distortion preserves shared edges and closed geometry.
		var distortion := 1.0 + 0.12 * sin(vertex.x * 7.0 + vertex.y * 4.0 + vertex.z * 5.0 + phase)
		surface.set_smooth_group(-1)
		surface.add_vertex(vertex * proportions * distortion)
	surface.generate_normals()
	var mesh := surface.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = rock_color.lightened(rng.randf_range(-0.12, 0.12))
	material.roughness = 1.0
	var rock := StaticBody3D.new()
	rock.name = "Rock"
	rock.collision_layer = 4
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	rock.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_convex_shape()
	rock.add_child(collision)
	return rock
