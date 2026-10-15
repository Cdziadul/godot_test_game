extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := load("res://scenes/world/main.tscn").instantiate() as Node3D
	root.add_child(world)
	var player := world.get_node("Player") as CharacterBody3D
	for frame in range(120):
		await physics_frame
	if not check(player.is_on_floor(), "Player lands on generated terrain"):
		return
	var start := player.position
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
