class_name PlayerCharacter
extends CharacterBody3D

signal hp_changed(character: PlayerCharacter)
signal charge_changed(character: PlayerCharacter)
signal died(character: PlayerCharacter)

enum State { IDLE, CHARGING, ACTING, DEAD }

@export var stats: CharacterStats
@export var move_speed: float = 6.0
@export var is_leader: bool = false

var state: State = State.IDLE
var charge_time: float = 0.0
var charge_duration: float = 1.0
var charge_action: String = ""
var charge_target: Node3D = null
var acting_timer: float = 0.0
var acting_duration: float = 0.5

# Formation offset for followers
var formation_offset: Vector3 = Vector3.ZERO

# Auto-attack timer for non-leader tactics
var auto_attack_cooldown: float = 0.0
var auto_attack_delay: float = 2.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mesh: MeshInstance3D
var collision: CollisionShape3D
var hp_bar_fill: MeshInstance3D

func _ready() -> void:
	# Find child nodes created programmatically
	for child in get_children():
		if child is MeshInstance3D:
			mesh = child
		elif child is CollisionShape3D:
			collision = child
		elif child.name == "HPBar":
			for sub in child.get_children():
				if sub.name == "Fill":
					hp_bar_fill = sub

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	match state:
		State.IDLE:
			_handle_idle(delta)
		State.CHARGING:
			_handle_charging(delta)
		State.ACTING:
			_handle_acting(delta)

	move_and_slide()
	_update_hp_bar()

func _update_hp_bar() -> void:
	if hp_bar_fill and stats:
		var ratio = clampf(float(stats.current_hp) / float(stats.max_hp), 0.0, 1.0)
		hp_bar_fill.scale.x = ratio
		# Shift left so bar drains from right
		hp_bar_fill.position.x = -(1.0 - ratio) * 0.6

func _handle_idle(_delta: float) -> void:
	if is_leader:
		# Leader movement handled by input in main.gd
		pass
	else:
		# Non-leader: slow to stop when idle
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

func _handle_charging(delta: float) -> void:
	charge_time += delta
	charge_changed.emit(self)

	# Move toward target if out of range
	if charge_target and is_instance_valid(charge_target):
		var dist = global_position.distance_to(charge_target.global_position)
		if dist > stats.weapon_range:
			var dir = (charge_target.global_position - global_position).normalized()
			dir.y = 0
			velocity.x = dir.x * move_speed * 0.5
			velocity.z = dir.z * move_speed * 0.5
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)

	if charge_time >= charge_duration:
		_execute_action()

func _handle_acting(delta: float) -> void:
	acting_timer += delta
	velocity.x = move_toward(velocity.x, 0, move_speed)
	velocity.z = move_toward(velocity.z, 0, move_speed)
	if acting_timer >= acting_duration:
		state = State.IDLE
		charge_changed.emit(self)

func start_charge(action: String, target: Node3D, duration: float) -> void:
	if state == State.DEAD:
		return
	# Cancel any existing charge (no credit for partial)
	state = State.CHARGING
	charge_action = action
	charge_target = target
	charge_duration = duration
	charge_time = 0.0
	charge_changed.emit(self)

func cancel_charge() -> void:
	if state == State.CHARGING:
		state = State.IDLE
		charge_action = ""
		charge_target = null
		charge_time = 0.0
		charge_changed.emit(self)

func _execute_action() -> void:
	state = State.ACTING
	acting_timer = 0.0

	if charge_action == "attack" and charge_target and is_instance_valid(charge_target):
		var damage = _calculate_damage()
		if charge_target.has_method("take_hit"):
			charge_target.take_hit(damage)

	charge_action = ""
	charge_target = null
	charge_time = 0.0
	charge_changed.emit(self)

func _calculate_damage() -> int:
	var base_damage = stats.get_attack_power()
	# Simple variance
	var variance = randf_range(0.85, 1.15)
	return maxi(1, int(base_damage * variance))

func take_hit(damage: int) -> void:
	if state == State.DEAD:
		return
	var reduced = maxi(1, damage - stats.defense)
	stats.take_damage(reduced)
	hp_changed.emit(self)
	if not stats.is_alive():
		_die()

func _die() -> void:
	state = State.DEAD
	died.emit(self)
	# Fall over
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees:z", 90.0, 0.5)
	tween.tween_property(self, "position:y", position.y - 0.5, 0.3)

func get_charge_progress() -> float:
	if state == State.CHARGING and charge_duration > 0:
		return charge_time / charge_duration
	elif state == State.ACTING:
		return 1.0
	return 0.0

func get_charge_text() -> String:
	if state == State.CHARGING:
		return charge_action.capitalize() + "..."
	elif state == State.ACTING:
		return charge_action.capitalize() + "!"
	return ""

func apply_leader_input(input_dir: Vector2, cam_basis: Basis) -> void:
	if state == State.DEAD:
		return
	if input_dir.length() > 0.1:
		var dir = (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		dir.y = 0
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		# Face movement direction
		if dir.length() > 0.1:
			var target_angle = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 0.15)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

func follow_target(target_pos: Vector3, _delta: float) -> void:
	if state != State.IDLE or is_leader:
		return
	var desired = target_pos + formation_offset
	var dist = global_position.distance_to(desired)
	if dist > 1.0:
		var dir = (desired - global_position).normalized()
		dir.y = 0
		velocity.x = dir.x * move_speed * 0.8
		velocity.z = dir.z * move_speed * 0.8
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
