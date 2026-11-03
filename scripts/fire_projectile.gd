class_name FireProjectile
extends MeshInstance3D

var speed: float = 12.0
var target_pos: Vector3
var lifetime: float = 3.0
var elapsed: float = 0.0

func setup(from: Vector3, to: Vector3) -> void:
	global_position = from + Vector3(0, 1.0, 0)
	target_pos = to + Vector3(0, 0.5, 0)

	# Fire ball mesh
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.0)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	set_surface_override_material(0, mat)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return

	# Move toward target
	var dir = (target_pos - global_position).normalized()
	global_position += dir * speed * delta

	# Check if reached target
	if global_position.distance_to(target_pos) < 0.5:
		_explode()

func _explode() -> void:
	# Spawn a quick flash
	var flash = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.8
	sphere.height = 1.6
	flash.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.0, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.set_surface_override_material(0, mat)
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.global_position = target_pos

	get_parent().add_child(flash)

	# Fade and remove the flash
	var tween = flash.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tween.tween_property(mat, "emission_energy_multiplier", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

	queue_free()
