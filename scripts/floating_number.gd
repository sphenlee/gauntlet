class_name FloatingNumber
extends Label3D

var lifetime: float = 1.2
var elapsed: float = 0.0
var rise_speed: float = 1.5

func setup(text: String, color: Color, world_pos: Vector3) -> void:
	self.text = text
	modulate = color
	outline_modulate = Color(0, 0, 0, 1)
	outline_size = 4
	font_size = 64
	pixel_size = 0.015
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	global_position = world_pos + Vector3(0, 1.5, 0)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return

	# Float upward
	global_position.y += rise_speed * delta

	# Fade out in the second half
	var alpha = 1.0
	if elapsed > lifetime * 0.5:
		alpha = 1.0 - ((elapsed - lifetime * 0.5) / (lifetime * 0.5))
	modulate.a = alpha
	outline_modulate.a = alpha
