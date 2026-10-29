class_name Arena
extends Node3D

signal portal_entered

@export var arena_size: float = 20.0
@export var wall_height: float = 3.0

var portal: Area3D
var portal_active: bool = false

func _ready() -> void:
	_build_arena()
	_build_portal()

func _build_arena() -> void:
	# Floor
	var floor_body = StaticBody3D.new()
	floor_body.name = "Floor"
	var floor_col = CollisionShape3D.new()
	var floor_shape = BoxShape3D.new()
	floor_shape.size = Vector3(arena_size, 0.2, arena_size)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)

	var floor_mesh = MeshInstance3D.new()
	var floor_box = BoxMesh.new()
	floor_box.size = Vector3(arena_size, 0.2, arena_size)
	floor_mesh.mesh = floor_box
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.2, 0.5, 0.2)  # Grassy green
	floor_mesh.set_surface_override_material(0, floor_mat)
	floor_mesh.position.y = -0.1
	floor_body.add_child(floor_mesh)
	add_child(floor_body)

	# Walls
	var wall_positions = [
		Vector3(0, wall_height / 2, -arena_size / 2),  # North
		Vector3(0, wall_height / 2, arena_size / 2),   # South
		Vector3(-arena_size / 2, wall_height / 2, 0),   # West
		Vector3(arena_size / 2, wall_height / 2, 0),    # East
	]
	var wall_sizes = [
		Vector3(arena_size, wall_height, 0.5),
		Vector3(arena_size, wall_height, 0.5),
		Vector3(0.5, wall_height, arena_size),
		Vector3(0.5, wall_height, arena_size),
	]

	for i in range(4):
		var wall = StaticBody3D.new()
		wall.name = "Wall" + str(i)
		var wall_col = CollisionShape3D.new()
		var wall_shape = BoxShape3D.new()
		wall_shape.size = wall_sizes[i]
		wall_col.shape = wall_shape
		wall.add_child(wall_col)

		var wall_mesh = MeshInstance3D.new()
		var wall_box = BoxMesh.new()
		wall_box.size = wall_sizes[i]
		wall_mesh.mesh = wall_box
		var wall_mat = StandardMaterial3D.new()
		wall_mat.albedo_color = Color(0.5, 0.5, 0.5)
		wall_mesh.set_surface_override_material(0, wall_mat)
		wall.add_child(wall_mesh)

		wall.position = wall_positions[i]
		add_child(wall)

	# Directional light
	var light = DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.shadow_enabled = true
	add_child(light)

	# Ambient light
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.4, 0.6, 0.9)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	add_child(env)

func _build_portal() -> void:
	portal = Area3D.new()
	portal.name = "Portal"
	portal.visible = false
	portal.monitoring = false

	var portal_col = CollisionShape3D.new()
	var portal_shape = CylinderShape3D.new()
	portal_shape.radius = 1.5
	portal_shape.height = 3.0
	portal_col.shape = portal_shape
	portal.add_child(portal_col)

	var portal_mesh = MeshInstance3D.new()
	var portal_cyl = CylinderMesh.new()
	portal_cyl.top_radius = 1.5
	portal_cyl.bottom_radius = 1.5
	portal_cyl.height = 3.0
	portal_mesh.mesh = portal_cyl
	var portal_mat = StandardMaterial3D.new()
	portal_mat.albedo_color = Color(0.5, 0.0, 1.0, 0.5)
	portal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	portal_mat.emission_enabled = true
	portal_mat.emission = Color(0.5, 0.0, 1.0)
	portal_mat.emission_energy_multiplier = 2.0
	portal_mesh.set_surface_override_material(0, portal_mat)
	portal.add_child(portal_mesh)

	# Place portal at north wall
	portal.position = Vector3(0, 1.5, -arena_size / 2 + 1.0)
	portal.body_entered.connect(_on_portal_body_entered)
	add_child(portal)

func activate_portal() -> void:
	portal_active = true
	portal.visible = true
	portal.monitoring = true

func _on_portal_body_entered(body: Node3D) -> void:
	if not portal_active:
		return
	if body is PlayerCharacter and body.is_leader:
		portal_entered.emit()
