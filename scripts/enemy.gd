class_name Enemy
extends CharacterBody3D

signal hp_changed(enemy: Enemy)
signal died(enemy: Enemy)

enum State { IDLE, CHARGING, ACTING, DEAD }

@export var stats: CharacterStats
@export var move_speed: float = 4.0
@export var attack_range: float = 2.0
@export var charge_duration_min: float = 1.5
@export var charge_duration_max: float = 3.0

var state: State = State.IDLE
var charge_time: float = 0.0
var charge_duration: float = 2.0
var charge_target: Node3D = null
var acting_timer: float = 0.0
var acting_duration: float = 0.5
var think_timer: float = 0.0
var think_delay: float = 1.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var party_members: Array = []
var mesh: MeshInstance3D
var collision: CollisionShape3D
var hp_bar_fill: MeshInstance3D

func _ready() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			mesh = child
		elif child is CollisionShape3D:
			collision = child
		elif child.name == "HPBar":
			for sub in child.get_children():
				if sub.name == "Fill":
					hp_bar_fill = sub
	think_timer = randf_range(0.5, think_delay)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

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
		hp_bar_fill.position.x = -(1.0 - ratio) * 0.6

func _handle_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, move_speed)
	velocity.z = move_toward(velocity.z, 0, move_speed)

	think_timer -= delta
	if think_timer <= 0:
		_pick_target_and_attack()
		think_timer = randf_range(think_delay * 0.5, think_delay * 1.5)

func _handle_charging(delta: float) -> void:
	charge_time += delta

	# Move toward target
	if charge_target and is_instance_valid(charge_target):
		var dist = global_position.distance_to(charge_target.global_position)
		if dist > attack_range:
			var dir = (charge_target.global_position - global_position).normalized()
			dir.y = 0
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			# Face target
			var target_angle = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 0.1)
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		# Target died or invalid, pick new one
		state = State.IDLE
		return

	if charge_time >= charge_duration:
		_execute_attack()

func _handle_acting(delta: float) -> void:
	acting_timer += delta
	velocity.x = move_toward(velocity.x, 0, move_speed)
	velocity.z = move_toward(velocity.z, 0, move_speed)
	if acting_timer >= acting_duration:
		state = State.IDLE

func _pick_target_and_attack() -> void:
	var alive = party_members.filter(func(p): return is_instance_valid(p) and p.state != PlayerCharacter.State.DEAD)
	if alive.is_empty():
		return
	charge_target = alive[randi() % alive.size()]
	charge_duration = randf_range(charge_duration_min, charge_duration_max)
	charge_time = 0.0
	state = State.CHARGING

func _execute_attack() -> void:
	state = State.ACTING
	acting_timer = 0.0

	if charge_target and is_instance_valid(charge_target):
		var dist = global_position.distance_to(charge_target.global_position)
		if dist <= attack_range * 1.5:  # Small grace range
			var damage = _calculate_damage()
			if charge_target.has_method("take_hit"):
				charge_target.take_hit(damage)

	charge_target = null
	charge_time = 0.0

func _calculate_damage() -> int:
	var base = stats.get_attack_power()
	var variance = randf_range(0.85, 1.15)
	return maxi(1, int(base * variance))

func take_hit(damage: int) -> void:
	if state == State.DEAD:
		return
	var reduced = maxi(1, damage - stats.defense)
	stats.take_damage(reduced)
	hp_changed.emit(self)
	_flash_damage()
	if not stats.is_alive():
		_die()

func _flash_damage() -> void:
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			var original_color = mat.albedo_color
			mat.albedo_color = Color.WHITE
			var tween = create_tween()
			tween.tween_property(mat, "albedo_color", original_color, 0.2)

func _die() -> void:
	state = State.DEAD
	died.emit(self)
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees:z", -90.0, 0.5)
	tween.tween_property(self, "position:y", position.y - 0.5, 0.3)
	tween.tween_callback(queue_free)

func get_charge_progress() -> float:
	if state == State.CHARGING and charge_duration > 0:
		return charge_time / charge_duration
	return 0.0
