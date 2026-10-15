extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := load("res://scenes/world/main.tscn").instantiate() as Node3D
	world.get_node("Forest").randomize_seed = false
	world.get_node("Rocks").randomize_seed = false
	root.add_child(world)
	var player := world.get_node("Player") as CharacterBody3D
	for frame in range(120):
		await physics_frame
	if not check(player.is_on_floor(), "Player lands on generated terrain"):
		return
	var forest := world.get_node("Forest")
	var trees := forest.get_children()
	if not check(trees.size() == forest.tree_count, "Requested tree count generated"):
		return
	for i in range(trees.size()):
		var point: Vector3 = trees[i].global_position
		if not check_silent(Vector2(point.x, point.z).length() >= forest.spawn_clearance, "Trees respect spawn clearance"):
			return
		if not check_silent(absf(point.x) <= 145.0 and absf(point.z) <= 145.0, "Trees stay inside terrain"):
			return
		for j in range(i):
			var other: Vector3 = trees[j].global_position
			if not check_silent(Vector2(point.x, point.z).distance_to(Vector2(other.x, other.z)) >= forest.minimum_spacing, "Trees respect minimum spacing"):
				return
	print("PASS: Tree placement bounds, spacing, and spawn clearance")
	var trunk_center: Vector3 = trees[0].global_position + Vector3.UP
	var ray := PhysicsRayQueryParameters3D.create(trunk_center + Vector3.LEFT * 2.0, trunk_center + Vector3.RIGHT * 2.0, 2)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	if not check(not hit.is_empty() and hit.collider == trees[0], "Generated trunk has collision"):
		return
	var start := player.position
	var rocks := world.get_node("Rocks").get_children()
	var sizes := {"small": 0, "medium": 0, "large": 0}
	for rock in rocks:
		sizes[rock.get_meta("size_category")] += 1
		if not check_silent(Vector2(rock.position.x, rock.position.z).length() >= 14.0 + float(rock.get_meta("extent")), "Rocks respect spawn clearance"):
			return
	if not check(rocks.size() == 300 and sizes.small == 210 and sizes.medium == 75 and sizes.large == 15, "Rock count and small/medium/large proportions"):
		return
	var rock_center: Vector3 = rocks[0].global_position
	var rock_ray := PhysicsRayQueryParameters3D.create(rock_center + Vector3.UP * 5.0, rock_center - Vector3.UP * 5.0, 4)
	var rock_hit := world.get_world_3d().direct_space_state.intersect_ray(rock_ray)
	if not check(not rock_hit.is_empty() and rock_hit.collider == rocks[0] and player.collision_mask & 4 != 0, "Rock collision is present and enabled for player"):
		return
	Input.action_press("move_forward")
	for frame in range(60):
		await physics_frame
	Input.action_release("move_forward")
	if not check(player.position.z < start.z - 3.0, "W moves player forward"):
		return
	for frame in range(30):
		await physics_frame
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	if not check(player.velocity.y > 0.0, "Jump produces upward velocity"):
		return
	for frame in range(120):
		await physics_frame
	if not check(player.is_on_floor(), "Player lands after jumping"):
		return
	var rig := player.get_node("CameraRig") as Node3D
	var toggle := InputEventKey.new()
	toggle.physical_keycode = KEY_V
	toggle.pressed = true
	var saved_position := player.position
	var saved_yaw := rig.rotation.y
	rig._unhandled_input(toggle)
	if not check(rig.first_person and rig.first_person_camera.current and not player.get_node("Visual").visible and rig.first_person_camera.get_node("Hands").visible, "V activates first person with hands and hidden body"):
		return
	if not check(player.position == saved_position and rig.rotation.y == saved_yaw, "Switch preserves player position and yaw"):
		return
	Input.action_press("move_forward")
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	if not check(player.velocity.y > 0.0, "First-person jump works"):
		return
	for frame in range(60):
		await physics_frame
	Input.action_release("move_forward")
	if not check(player.position.z < saved_position.z - 3.0, "First-person movement works"):
		return
	rig.orbit(Vector2(100, 10000))
	if not check(rig.rotation.y < 0.0, "Mouse changes orbit yaw"):
		return
	var arm := rig.get_node("SpringArm3D") as SpringArm3D
	if not check(is_equal_approx(arm.rotation.x, deg_to_rad(rig.minimum_pitch)), "Camera pitch is clamped"):
		return
	var saved_pitch: float = rig.first_person_camera.rotation.x
	saved_yaw = rig.rotation.y
	rig._unhandled_input(toggle)
	if not check(not rig.first_person and rig.third_person_camera.current and player.get_node("Visual").visible and not rig.first_person_camera.get_node("Hands").visible, "V restores third person and body"):
		return
	if not check(is_equal_approx(saved_pitch, arm.rotation.x) and is_equal_approx(saved_yaw, rig.rotation.y), "Return to third person preserves look direction"):
		return
	player.position.y = -40.0
	await physics_frame
	await physics_frame
	if not check(player.position.distance_to(player.spawn_position) < 0.1, "Falling off terrain respawns player"):
		return
	print("PASS: All headless gameplay smoke checks")
	quit(0)

func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("FAIL: " + message)
		quit(1)
		return false
	print("PASS: " + message)
	return true

func check_silent(condition: bool, message: String) -> bool:
	if not condition:
		return check(false, message)
	return true
