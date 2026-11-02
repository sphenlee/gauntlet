class_name PlayerCharacter
extends CharacterBody3D

signal hp_changed(character: PlayerCharacter)
signal charge_changed(character: PlayerCharacter)
signal died(character: PlayerCharacter)
signal charge_started(character: PlayerCharacter, target: Node3D)
signal damage_taken(character: PlayerCharacter, amount: int)
signal healed(character: PlayerCharacter, amount: int)

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
var last_attack_target: Node3D = null
var last_charge_duration: float = 1.5
var death_position: Vector3 = Vector3.ZERO

# Formation offset for followers
var formation_offset: Vector3 = Vector3.ZERO

# Tactics
var tactics: Array[Tactic] = []
var tactic_cooldown: float = 0.0
var tactic_delay: float = 1.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mesh: MeshInstance3D
var collision: CollisionShape3D
var hp_bar: MeshInstance3D

func _ready() -> void:
	# Find child nodes created programmatically
	for child in get_children():
		if child is MeshInstance3D and child.name != "HPBar":
			mesh = child
		elif child is CollisionShape3D:
			collision = child
		elif child.name == "HPBar":
			hp_bar = child

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
	if hp_bar and stats:
		var ratio = clampf(float(stats.current_hp) / float(stats.max_hp), 0.0, 1.0)
		var mat = hp_bar.get_surface_override_material(0) as ShaderMaterial
		if mat:
			mat.set_shader_parameter("fill_ratio", ratio)

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
		_try_auto_repeat_attack()

func _try_auto_repeat_attack() -> void:
	if not last_attack_target or not is_instance_valid(last_attack_target):
		last_attack_target = null
		return
	# Check if target is still alive
	if last_attack_target.has_method("is_alive") and not last_attack_target.is_alive():
		last_attack_target = null
		return
	if last_attack_target is Enemy and last_attack_target.state == Enemy.State.DEAD:
		last_attack_target = null
		return
	# Auto-repeat attack on same target
	start_charge("attack", last_attack_target, last_charge_duration)

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
	charge_started.emit(self, target)

func cancel_charge() -> void:
	if state == State.CHARGING:
		state = State.IDLE
		charge_action = ""
		charge_target = null
		charge_time = 0.0
		last_attack_target = null
		charge_changed.emit(self)

func _execute_action() -> void:
	state = State.ACTING
	acting_timer = 0.0

	if charge_action == "attack" and charge_target and is_instance_valid(charge_target):
		last_attack_target = charge_target
		last_charge_duration = charge_duration
		var damage = _calculate_damage()
		if charge_target.has_method("take_hit"):
			charge_target.take_hit(damage)
	elif charge_action.begins_with("item:") and charge_target and is_instance_valid(charge_target):
		var item_id = charge_action.trim_prefix("item:")
		match item_id:
			"potion":
				if charge_target is PlayerCharacter and charge_target.state != State.DEAD:
					var heal_amount = int(charge_target.stats.max_hp * 0.25)
					charge_target.stats.heal(heal_amount)
					charge_target.hp_changed.emit(charge_target)
					charge_target.healed.emit(charge_target, heal_amount)
			"hi_potion":
				if charge_target is PlayerCharacter and charge_target.state != State.DEAD:
					var heal_amount = int(charge_target.stats.max_hp * 0.50)
					charge_target.stats.heal(heal_amount)
					charge_target.hp_changed.emit(charge_target)
					charge_target.healed.emit(charge_target, heal_amount)
			"revive":
				if charge_target is PlayerCharacter and charge_target.state == State.DEAD:
					charge_target.revive(0.25)

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
	damage_taken.emit(self, reduced)
	if not stats.is_alive():
		_die()

func _die() -> void:
	state = State.DEAD
	last_attack_target = null
	death_position = global_position
	died.emit(self)
	# Fall over
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees:z", 90.0, 0.5)
	tween.tween_property(self, "position:y", position.y - 0.5, 0.3)

func revive(heal_pct: float) -> void:
	if state != State.DEAD:
		return
	stats.current_hp = int(stats.max_hp * heal_pct)
	state = State.IDLE
	# Restore at death position
	global_position = death_position
	rotation_degrees.z = 0
	hp_changed.emit(self)
	healed.emit(self, stats.current_hp)

func get_charge_progress() -> float:
	if state == State.CHARGING and charge_duration > 0:
		return charge_time / charge_duration
	elif state == State.ACTING:
		return 1.0
	return 0.0

func get_charge_text() -> String:
	var display = charge_action
	if display.begins_with("item:"):
		display = display.trim_prefix("item:").replace("_", " ").capitalize()
	if state == State.CHARGING:
		return display.capitalize() + "..."
	elif state == State.ACTING:
		return display.capitalize() + "!"
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
