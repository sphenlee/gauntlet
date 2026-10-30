class_name CameraController
extends Node3D

@export var follow_target: Node3D
@export var follow_speed: float = 8.0
@export var camera_distance: float = 8.0
@export var pivot_height: float = 1.5
@export var camera_angle_min: float = -50.0
@export var camera_angle_max: float = -15.0
@export var orbit_speed: float = 2.5
@export var drag_speed: float = 1.0

var orbit_yaw: float = 0.0
var orbit_pitch: float = -30.0
var is_player_moving: bool = false
var player_move_direction: Vector3 = Vector3.ZERO
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

	# Smooth follow target position with height offset
	var target_pos = follow_target.global_position + Vector3(0, pivot_height, 0)
	var weight = 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target_pos, weight)

	# Camera orbit input (right stick)
	var cam_input = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if abs(cam_input.x) > 0.1:
		orbit_yaw -= cam_input.x * orbit_speed * delta
	if abs(cam_input.y) > 0.1:
		orbit_pitch = clamp(orbit_pitch - cam_input.y * orbit_speed * delta * 30.0, camera_angle_min, camera_angle_max)

	# Drag behind player movement direction
	if is_player_moving and player_move_direction.length() > 0.1:
		# Calculate the yaw angle that would put the camera behind the movement direction
		var move_angle = atan2(player_move_direction.x, player_move_direction.z)
		var target_yaw = move_angle + PI  # Camera sits behind
		orbit_yaw = lerp_angle(orbit_yaw, target_yaw, drag_speed * delta)

	# Apply orbit
	rotation.y = orbit_yaw
	spring_arm.rotation.x = deg_to_rad(orbit_pitch)

func get_camera_basis() -> Basis:
	return camera.global_transform.basis

func snap_to_target() -> void:
	if follow_target and is_instance_valid(follow_target):
		global_position = follow_target.global_position + Vector3(0, pivot_height, 0)
		# Face the same direction as the target
		orbit_yaw = follow_target.rotation.y + PI
