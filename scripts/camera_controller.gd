class_name CameraController
extends Node3D

@export var follow_target: Node3D
@export var follow_speed: float = 5.0
@export var camera_distance: float = 8.0
@export var camera_height: float = 5.0
@export var camera_angle_min: float = -60.0
@export var camera_angle_max: float = -10.0
@export var orbit_speed: float = 2.0
@export var recenter_speed: float = 1.5

var orbit_yaw: float = 0.0
var orbit_pitch: float = -30.0
var is_player_moving: bool = false
var spring_arm: SpringArm3D
var camera: Camera3D

func _ready() -> void:
	for child in get_children():
		if child is SpringArm3D:
			spring_arm = child
			for sub in child.get_children():
				if sub is Camera3D:
					camera = sub
	if spring_arm:
		spring_arm.spring_length = camera_distance
	orbit_pitch = -30.0

func _process(delta: float) -> void:
	if not follow_target or not is_instance_valid(follow_target):
		return

	# Follow target position
	global_position = global_position.lerp(follow_target.global_position, follow_speed * delta)

	# Camera orbit input
	var cam_input = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if abs(cam_input.x) > 0.1:
		orbit_yaw -= cam_input.x * orbit_speed * delta
	if abs(cam_input.y) > 0.1:
		orbit_pitch = clamp(orbit_pitch - cam_input.y * orbit_speed * delta * 30.0, camera_angle_min, camera_angle_max)

	# Auto-recenter when player is moving
	if is_player_moving:
		orbit_yaw = lerp_angle(orbit_yaw, 0.0, recenter_speed * delta)

	# Apply orbit
	rotation.y = orbit_yaw
	spring_arm.rotation.x = deg_to_rad(orbit_pitch)

func get_camera_basis() -> Basis:
	return camera.global_transform.basis

func snap_to_target() -> void:
	if follow_target and is_instance_valid(follow_target):
		global_position = follow_target.global_position
		orbit_yaw = 0.0
