extends Node3D

@export var mouse_sensitivity: float = 0.003
@export_range(-89.0, 0.0) var minimum_pitch: float = -65.0
@export_range(0.0, 89.0) var maximum_pitch: float = 25.0
@export var initial_pitch: float = -18.0
@export var camera_distance: float = 6.0
@export var start_in_first_person: bool = false
@export var first_person_eye_height: float = 1.65

@onready var arm: SpringArm3D = $SpringArm3D
@onready var third_person_camera: Camera3D = $SpringArm3D/Camera3D
@onready var first_person_camera: Camera3D = $FirstPersonCamera
@onready var body_visual: Node3D = get_parent().get_node("Visual")
var first_person: bool = false
var third_person_height: float

func _ready() -> void:
	arm.rotation.x = deg_to_rad(initial_pitch)
	arm.spring_length = camera_distance
	arm.add_excluded_object(get_parent().get_rid())
	third_person_height = position.y
	set_first_person(start_in_first_person)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_view"):
		set_first_person(not first_person)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		orbit(event.relative)

func orbit(relative: Vector2) -> void:
	rotation.y -= relative.x * mouse_sensitivity
	arm.rotation.x = clampf(arm.rotation.x - relative.y * mouse_sensitivity, deg_to_rad(minimum_pitch), deg_to_rad(maximum_pitch))
	first_person_camera.rotation.x = arm.rotation.x

func set_first_person(enabled: bool) -> void:
	first_person = enabled
	position.y = first_person_eye_height if enabled else third_person_height
	body_visual.visible = not enabled
	first_person_camera.get_node("Hands").visible = enabled
	first_person_camera.rotation.x = arm.rotation.x
	if enabled:
		first_person_camera.make_current()
	else:
		third_person_camera.make_current()
