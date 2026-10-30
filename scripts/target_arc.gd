class_name TargetArc
extends MeshInstance3D

var lifetime: float = 2.0
var elapsed: float = 0.0
var arc_material: StandardMaterial3D

func setup(from: Vector3, to: Vector3, color: Color) -> void:
	_build_arc(from, to, color)

func _build_arc(from: Vector3, to: Vector3, color: Color) -> void:
	var im = ImmediateMesh.new()

	arc_material = StandardMaterial3D.new()
	arc_material.albedo_color = color
	arc_material.emission_enabled = true
	arc_material.emission = color
	arc_material.emission_energy_multiplier = 1.5
	arc_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var segments = 20
	var arc_height = 1.5

	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var pos = from.lerp(to, t)
		# Parabolic arc
		pos.y += arc_height * 4.0 * t * (1.0 - t)
		im.surface_add_vertex(pos)
	im.surface_end()

	mesh = im
	set_surface_override_material(0, arc_material)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return

	# Fade out
	var alpha = 1.0 - (elapsed / lifetime)
	if arc_material:
		arc_material.albedo_color.a = alpha
		arc_material.emission_energy_multiplier = 1.5 * alpha
