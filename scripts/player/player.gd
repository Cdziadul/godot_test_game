extends CharacterBody3D

@export var move_speed: float = 8.0
@export var acceleration: float = 28.0
@export var jump_velocity: float = 8.0
@export var gravity: float = 22.0
@export var turn_speed: float = 12.0
@export var respawn_height: float = -30.0

@onready var camera_rig: Node3D = $CameraRig
@onready var visual: Node3D = $Visual
var spawn_position: Vector3

func _ready() -> void:
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := camera_rig.global_basis * Vector3(input.x, 0.0, input.y)
	direction.y = 0.0
	direction = direction.normalized() * input.length()
	velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
	if direction.length_squared() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)
	move_and_slide()
	if global_position.y < respawn_height:
		global_position = spawn_position
		velocity = Vector3.ZERO
