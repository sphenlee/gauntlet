class_name GameManager
extends Node3D

enum GameState { NORMAL, COMMAND_MENU, TARGET_SELECT, PARTY_TARGET_SELECT, MAIN_MENU, TACTICS_EDITOR }

var game_state: GameState = GameState.NORMAL
var current_level: int = 1
var party_leader_index: int = 0

# Nodes
var arena: Arena
var camera_controller: CameraController
var party: Array[PlayerCharacter] = []
var enemies: Array[Enemy] = []
var command_menu: CommandMenu
var character_info: CharacterInfoPanel
var enemy_info: EnemyInfoPanel
var level_label: Label
var game_over_label: Label
var game_over_timer: float = 0.0
var game_over_delay: float = 3.0
var is_game_over: bool = false
var main_menu: MainMenu
var tactics_editor: TacticsEditor

# Target selection
var selected_enemy_index: int = 0
var selected_party_index: int = 0
var selection_cursor: MeshInstance3D

# Item inventory
var items: Dictionary = {
	"potion": {"name": "Potion", "count": 3, "max": 3, "heal_pct": 0.25},
	"hi_potion": {"name": "Hi-Potion", "count": 1, "max": 1, "heal_pct": 0.50},
	"revive": {"name": "Revive", "count": 1, "max": 1, "heal_pct": 0.25},
}
var pending_item_id: String = ""

# Party colors
var party_colors = [Color(0.2, 0.5, 1.0), Color(1.0, 0.3, 0.3), Color(0.3, 1.0, 0.3)]
var party_names = ["Hero", "Warrior", "Mage"]

# Formation offsets for followers
var formation_offsets = [
	Vector3.ZERO,
	Vector3(-1.5, 0, 1.5),
	Vector3(1.5, 0, 1.5),
]

func _ready() -> void:
	# Keep processing input while tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_arena()
	_build_party()
	_build_camera()
	_build_ui()
	_build_selection_cursor()
	_spawn_enemies()

func _build_arena() -> void:
	arena = Arena.new()
	arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	arena.portal_entered.connect(_on_portal_entered)
	add_child(arena)

func _build_party() -> void:
	for i in range(3):
		var character = _create_player_character(party_names[i], party_colors[i])
		character.process_mode = Node.PROCESS_MODE_PAUSABLE
		character.position = Vector3(i * 2.0 - 2.0, 0.5, 5.0)
		character.formation_offset = formation_offsets[i]
		character.died.connect(_on_character_died)
		character.charge_started.connect(_on_character_charge_started)
		character.damage_taken.connect(_on_character_damage_taken)
		character.healed.connect(_on_character_healed)
		character.levelled_up.connect(_on_character_levelled_up)
		# Initialize 5 empty tactic slots
		for j in range(5):
			character.tactics.append(Tactic.new())
		# Set a default tactic: attack closest enemy
		character.tactics[0].enabled = true
		character.tactics[0].condition = Tactic.Condition.ENEMY_CLOSEST
		character.tactics[0].action = Tactic.Action.ATTACK
		party.append(character)
		add_child(character)

	party[0].is_leader = true
	party_leader_index = 0

func _create_player_character(char_name: String, color: Color) -> PlayerCharacter:
	var character = PlayerCharacter.new()

	# Stats
	var stats = CharacterStats.new()
	stats.character_name = char_name
	stats.max_hp = 100
	stats.current_hp = 100
	stats.max_mp = 50
	stats.current_mp = 50
	stats.strength = 10
	stats.defense = 5
	stats.agility = 8
	stats.luck = 5
	stats.weapon_name = "Dagger"
	stats.weapon_pow = 5
	stats.weapon_range = 2.5

	# Per-character growth rates
	match char_name:
		"Hero":
			stats.growth_hp = 12
			stats.growth_mp = 4
			stats.growth_str = 3
			stats.growth_def = 2
			stats.growth_agl = 2
			stats.growth_lck = 1
		"Warrior":
			stats.growth_hp = 15
			stats.growth_mp = 2
			stats.growth_str = 4
			stats.growth_def = 3
			stats.growth_agl = 1
			stats.growth_lck = 1
		"Mage":
			stats.growth_hp = 8
			stats.growth_mp = 8
			stats.growth_str = 1
			stats.growth_def = 1
			stats.growth_agl = 3
			stats.growth_lck = 2

	character.stats = stats

	# Collision
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.6
	col.shape = shape
	col.position.y = 0.8
	character.add_child(col)

	# Mesh
	var mesh_inst = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	mesh_inst.mesh = capsule
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.set_surface_override_material(0, mat)
	mesh_inst.position.y = 0.8
	character.add_child(mesh_inst)

	# HP bar
	_add_hp_bar(character, Color(0.2, 0.5, 1.0))

	return character

func _add_hp_bar(entity: CharacterBody3D, color: Color) -> void:
	var bar = MeshInstance3D.new()
	bar.name = "HPBar"
	bar.position.y = 2.2
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var quad = QuadMesh.new()
	quad.size = Vector2(1.2, 0.12)
	bar.mesh = quad

	var shader_mat = ShaderMaterial.new()
	var shader = load("res://shaders/hp_bar.gdshader") as Shader
	shader_mat.shader = shader
	shader_mat.set_shader_parameter("fill_color", color)
	shader_mat.set_shader_parameter("bg_color", Color(0.1, 0.1, 0.1, 0.8))
	shader_mat.set_shader_parameter("fill_ratio", 1.0)
	bar.set_surface_override_material(0, shader_mat)

	entity.add_child(bar)

func _build_camera() -> void:
	camera_controller = CameraController.new()
	camera_controller.process_mode = Node.PROCESS_MODE_PAUSABLE

	var spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm3D"
	spring_arm.spring_length = 8.0
	spring_arm.collision_mask = 1
	spring_arm.margin = 0.5
	camera_controller.add_child(spring_arm)

	var camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	spring_arm.add_child(camera)

	camera_controller.follow_target = party[party_leader_index]
	add_child(camera_controller)

func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "UI"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	# Command menu (bottom left)
	command_menu = CommandMenu.new()
	command_menu.anchor_left = 0.0
	command_menu.anchor_top = 1.0
	command_menu.anchor_right = 0.0
	command_menu.anchor_bottom = 1.0
	command_menu.offset_left = 20
	command_menu.offset_top = -140
	command_menu.offset_right = 220
	command_menu.offset_bottom = -20
	command_menu.action_selected.connect(_on_action_selected)
	command_menu.item_selected.connect(_on_item_selected)
	command_menu.menu_cancelled.connect(_on_menu_cancelled)
	canvas.add_child(command_menu)
	command_menu.setup()

	# Character info (bottom right)
	character_info = CharacterInfoPanel.new()
	character_info.anchor_left = 1.0
	character_info.anchor_top = 1.0
	character_info.anchor_right = 1.0
	character_info.anchor_bottom = 1.0
	character_info.offset_left = -420
	character_info.offset_top = -100
	character_info.offset_right = -20
	character_info.offset_bottom = -20
	canvas.add_child(character_info)
	character_info.setup(party)

	# Enemy info (top left)
	enemy_info = EnemyInfoPanel.new()
	enemy_info.anchor_left = 0.0
	enemy_info.anchor_top = 0.0
	enemy_info.anchor_right = 0.0
	enemy_info.anchor_bottom = 0.0
	enemy_info.offset_left = 20
	enemy_info.offset_top = 20
	enemy_info.offset_right = 220
	enemy_info.offset_bottom = 100
	canvas.add_child(enemy_info)
	enemy_info.setup()

	# Level display (top right)
	level_label = Label.new()
	level_label.anchor_left = 1.0
	level_label.anchor_top = 0.0
	level_label.anchor_right = 1.0
	level_label.anchor_bottom = 0.0
	level_label.offset_left = -140
	level_label.offset_top = 20
	level_label.offset_right = -20
	level_label.offset_bottom = 50
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", Color.WHITE)
	level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(level_label)
	_update_level_display()

	# Game Over label (center)
	game_over_label = Label.new()
	game_over_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	game_over_label.add_theme_font_size_override("font_size", 64)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	game_over_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	game_over_label.add_theme_constant_override("shadow_offset_x", 2)
	game_over_label.add_theme_constant_override("shadow_offset_y", 2)
	game_over_label.text = "GAME OVER"
	game_over_label.visible = false
	canvas.add_child(game_over_label)

	# Main menu (nearly full screen)
	main_menu = MainMenu.new()
	main_menu.anchor_left = 0.05
	main_menu.anchor_top = 0.05
	main_menu.anchor_right = 0.95
	main_menu.anchor_bottom = 0.95
	main_menu.offset_left = 0
	main_menu.offset_top = 0
	main_menu.offset_right = 0
	main_menu.offset_bottom = 0
	main_menu.menu_closed.connect(_on_main_menu_closed)
	main_menu.tactics_opened.connect(_on_tactics_opened)
	canvas.add_child(main_menu)
	main_menu.setup()

	# Tactics editor (nearly full screen)
	tactics_editor = TacticsEditor.new()
	tactics_editor.anchor_left = 0.05
	tactics_editor.anchor_top = 0.05
	tactics_editor.anchor_right = 0.95
	tactics_editor.anchor_bottom = 0.95
	tactics_editor.offset_left = 0
	tactics_editor.offset_top = 0
	tactics_editor.offset_right = 0
	tactics_editor.offset_bottom = 0
	tactics_editor.editor_closed.connect(_on_tactics_editor_closed)
	canvas.add_child(tactics_editor)
	tactics_editor.setup(party)

func _build_selection_cursor() -> void:
	selection_cursor = MeshInstance3D.new()
	selection_cursor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var torus = TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 0.8
	selection_cursor.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.0, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 0.0)
	mat.emission_energy_multiplier = 1.5
	selection_cursor.set_surface_override_material(0, mat)
	#selection_cursor.rotation_degrees.x = 90.0
	selection_cursor.visible = false
	add_child(selection_cursor)

func _spawn_enemies() -> void:
	# Clear existing enemies
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()

	var enemy_count = mini(current_level, 4)  # Cap at 4 for arena size

	for i in range(enemy_count):
		var enemy = _create_enemy(i)
		enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
		# Spread enemies around the arena
		var angle = (TAU / enemy_count) * i + PI  # Start from north
		var radius = arena.arena_size * 0.3
		enemy.position = Vector3(cos(angle) * radius, 0.5, sin(angle) * radius - 3.0)
		enemy.party_members = party
		enemy.died.connect(_on_enemy_died)
		enemy.charge_started.connect(_on_enemy_charge_started)
		enemy.damage_taken.connect(_on_enemy_damage_taken)
		enemies.append(enemy)
		add_child(enemy)

func _create_enemy(index: int) -> Enemy:
	var enemy = Enemy.new()

	var stats = CharacterStats.new()
	var enemy_names = ["Goblin", "Orc", "Skeleton", "Slime"]
	stats.character_name = enemy_names[index % enemy_names.size()] + " Lv" + str(current_level)
	stats.max_hp = 30 + current_level * 10
	stats.current_hp = stats.max_hp
	stats.max_mp = 0
	stats.current_mp = 0
	stats.strength = 5 + current_level * 2
	stats.defense = 2 + current_level
	stats.agility = 4 + current_level
	stats.luck = 3
	stats.weapon_pow = 3 + current_level
	stats.level = current_level
	enemy.stats = stats

	# Scale difficulty
	enemy.move_speed = 3.0 + current_level * 0.3
	enemy.attack_range = 2.0
	enemy.charge_duration_min = maxf(0.8, 2.0 - current_level * 0.15)
	enemy.charge_duration_max = maxf(1.5, 3.5 - current_level * 0.2)

	# Collision
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.4
	col.shape = shape
	col.position.y = 0.7
	enemy.add_child(col)

	# Mesh
	var mesh_inst = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.4
	mesh_inst.mesh = capsule
	var mat = StandardMaterial3D.new()
	var enemy_colors = [Color(0.8, 0.2, 0.2), Color(0.6, 0.3, 0.1), Color(0.5, 0.5, 0.6), Color(0.3, 0.7, 0.3)]
	mat.albedo_color = enemy_colors[index % enemy_colors.size()]
	mesh_inst.set_surface_override_material(0, mat)
	mesh_inst.position.y = 0.7
	enemy.add_child(mesh_inst)

	# HP bar
	_add_hp_bar(enemy, Color(1.0, 0.6, 0.0))

	return enemy

func _process(delta: float) -> void:
	_update_selection_cursor()

	# Game over countdown
	if is_game_over:
		game_over_timer -= delta
		if game_over_timer <= 0:
			_finish_game_over()
		return

	if get_tree().paused:
		return
	_handle_leader_movement()
	_handle_follower_formation(delta)
	_handle_auto_attacks(delta)
	_update_camera_state()

func _input(event: InputEvent) -> void:
	if is_game_over:
		return

	# Escape quits the game (not a controller button, keyboard only)
	if event.is_action_pressed("quit_game"):
		get_tree().quit()
		return

	match game_state:
		GameState.NORMAL:
			_handle_normal_input(event)
		GameState.COMMAND_MENU:
			if command_menu.handle_input(event):
				get_viewport().set_input_as_handled()
		GameState.TARGET_SELECT:
			_handle_target_select_input(event)
		GameState.PARTY_TARGET_SELECT:
			_handle_party_target_select_input(event)
		GameState.MAIN_MENU:
			if main_menu.handle_input(event):
				get_viewport().set_input_as_handled()
		GameState.TACTICS_EDITOR:
			if tactics_editor.handle_input(event):
				get_viewport().set_input_as_handled()

func _set_game_state(new_state: GameState) -> void:
	game_state = new_state
	# Pause while any menu is open
	get_tree().paused = command_menu.is_open or main_menu.is_open or tactics_editor.visible

func _handle_normal_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_confirm"):
		var leader = party[party_leader_index]
		if is_instance_valid(leader) and leader.state != PlayerCharacter.State.DEAD:
			# Cancel any in-progress charge and prevent auto-repeat
			leader.cancel_charge()
			leader.last_attack_target = null
			command_menu.open_menu()
			_set_game_state(GameState.COMMAND_MENU)
	elif event.is_action_pressed("enemy_select_next") or event.is_action_pressed("enemy_select_prev"):
		# Enter enemy selection mode
		var alive_enemies = _get_alive_enemies()
		if not alive_enemies.is_empty():
			_set_game_state(GameState.TARGET_SELECT)
			selected_enemy_index = 0
			_show_enemy_info(alive_enemies[0])
	elif event.is_action_pressed("leader_switch_next"):
		_cycle_leader(1)
	elif event.is_action_pressed("leader_switch_prev"):
		_cycle_leader(-1)
	elif event.is_action_pressed("open_main_menu"):
		main_menu.open_menu()
		_set_game_state(GameState.MAIN_MENU)

func _handle_target_select_input(event: InputEvent) -> void:
	var alive_enemies = _get_alive_enemies()
	if alive_enemies.is_empty():
		command_menu.close_menu()
		_set_game_state(GameState.NORMAL)
		enemy_info.hide_panel()
		return

	if event.is_action_pressed("enemy_select_next"):
		selected_enemy_index = (selected_enemy_index + 1) % alive_enemies.size()
		_show_enemy_info(alive_enemies[selected_enemy_index])
	elif event.is_action_pressed("enemy_select_prev"):
		selected_enemy_index = (selected_enemy_index - 1 + alive_enemies.size()) % alive_enemies.size()
		_show_enemy_info(alive_enemies[selected_enemy_index])
	elif event.is_action_pressed("action_confirm"):
		# Confirm target for attack
		var leader = party[party_leader_index]
		var target = alive_enemies[selected_enemy_index]
		leader.start_charge("attack", target, 1.5)
		command_menu.close_menu()
		_set_game_state(GameState.NORMAL)
		enemy_info.hide_panel()
		selection_cursor.visible = false
	elif event.is_action_pressed("action_cancel"):
		command_menu.close_menu()
		_set_game_state(GameState.NORMAL)
		enemy_info.hide_panel()
		selection_cursor.visible = false

func _handle_party_target_select_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.is_action_pressed("leader_switch_next"):
		selected_party_index = (selected_party_index - 1 + party.size()) % party.size()
		character_info.selected_index = selected_party_index
	elif event.is_action_pressed("move_down") or event.is_action_pressed("leader_switch_prev"):
		selected_party_index = (selected_party_index + 1) % party.size()
		character_info.selected_index = selected_party_index
	elif event.is_action_pressed("action_confirm"):
		_use_item_on_party_member(selected_party_index)
	elif event.is_action_pressed("action_cancel"):
		command_menu.close_menu()
		_set_game_state(GameState.NORMAL)
		selection_cursor.visible = false
		character_info.selected_index = -1
		pending_item_id = ""

func _use_item_on_party_member(index: int) -> void:
	if index < 0 or index >= party.size():
		return
	var target = party[index]
	if not is_instance_valid(target):
		return
	# Revive targets dead characters, other items target alive ones
	if pending_item_id == "revive":
		if target.state != PlayerCharacter.State.DEAD:
			return
	else:
		if target.state == PlayerCharacter.State.DEAD:
			return
	if pending_item_id.is_empty():
		return

	var item = items[pending_item_id]
	if item["count"] <= 0:
		return

	# Deduct item
	item["count"] -= 1

	# Start charge on the leader with the item action
	var leader = party[party_leader_index]
	leader.start_charge("item:" + pending_item_id, target, 0.75)

	command_menu.close_menu()
	_set_game_state(GameState.NORMAL)
	selection_cursor.visible = false
	character_info.selected_index = -1
	pending_item_id = ""

func _handle_leader_movement() -> void:
	if game_state != GameState.NORMAL:
		return
	var leader = party[party_leader_index]
	if not is_instance_valid(leader) or leader.state == PlayerCharacter.State.DEAD:
		return

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var cam_basis = camera_controller.get_camera_basis()
	leader.apply_leader_input(input_dir, cam_basis)
	camera_controller.is_player_moving = input_dir.length() > 0.1
	if input_dir.length() > 0.1:
		var move_dir = (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		move_dir.y = 0
		camera_controller.player_move_direction = move_dir

func _handle_follower_formation(delta: float) -> void:
	var leader = party[party_leader_index]
	if not is_instance_valid(leader):
		return
	for i in range(party.size()):
		if i == party_leader_index:
			continue
		var follower = party[i]
		if is_instance_valid(follower):
			follower.follow_target(leader.global_position, delta)

func _handle_auto_attacks(delta: float) -> void:
	# Evaluate tactics for non-leader party members
	for i in range(party.size()):
		if i == party_leader_index:
			continue
		var member = party[i]
		if not is_instance_valid(member) or member.state != PlayerCharacter.State.IDLE:
			continue
		member.tactic_cooldown -= delta
		if member.tactic_cooldown <= 0:
			var result = TacticsEngine.evaluate(member, member.tactics, party, enemies, party[party_leader_index], items)
			if not result.is_empty():
				member.start_charge(result["action"], result["target"], result["charge_time"])
				# Deduct item from inventory if it's an item action
				if result["action"].begins_with("item:"):
					var item_id = result["action"].trim_prefix("item:")
					if items.has(item_id):
						items[item_id]["count"] -= 1
			member.tactic_cooldown = member.tactic_delay + randf_range(0.3, 1.0)

func _find_nearest_enemy(pos: Vector3) -> Enemy:
	var nearest: Enemy = null
	var nearest_dist: float = INF
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.state != Enemy.State.DEAD:
			var dist = pos.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy
	return nearest

func _get_alive_enemies() -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.state != Enemy.State.DEAD:
			alive.append(enemy)
	return alive

func _update_camera_state() -> void:
	pass

func _update_selection_cursor() -> void:
	match game_state:
		GameState.TARGET_SELECT:
			var alive_enemies = _get_alive_enemies()
			if not alive_enemies.is_empty() and selected_enemy_index < alive_enemies.size():
				var target = alive_enemies[selected_enemy_index]
				if is_instance_valid(target):
					selection_cursor.visible = true
					selection_cursor.global_position = target.global_position + Vector3(0, 0.1, 0)
		GameState.PARTY_TARGET_SELECT:
			if selected_party_index < party.size():
				var target = party[selected_party_index]
				if is_instance_valid(target):
					selection_cursor.visible = true
					selection_cursor.global_position = target.global_position + Vector3(0, 0.1, 0)
		_:
			selection_cursor.visible = false

func _show_enemy_info(enemy: Enemy) -> void:
	enemy_info.show_enemy(enemy)

func _cycle_leader(direction: int) -> void:
	# Find next alive party member
	var index = party_leader_index
	for i in range(party.size()):
		index = (index + direction + party.size()) % party.size()
		if is_instance_valid(party[index]) and party[index].state != PlayerCharacter.State.DEAD:
			_switch_leader(index)
			return

func _switch_leader(new_index: int) -> void:
	if new_index == party_leader_index:
		return
	if new_index < 0 or new_index >= party.size():
		return
	var new_leader = party[new_index]
	if not is_instance_valid(new_leader) or new_leader.state == PlayerCharacter.State.DEAD:
		return

	party[party_leader_index].is_leader = false
	party_leader_index = new_index
	party[party_leader_index].is_leader = true
	# Glide camera to new leader (don't snap)
	camera_controller.follow_target = party[party_leader_index]

func _on_action_selected(action: String) -> void:
	if action == "attack":
		var alive_enemies = _get_alive_enemies()
		if not alive_enemies.is_empty():
			command_menu.lock_selection()
			_set_game_state(GameState.TARGET_SELECT)
			selected_enemy_index = 0
			_show_enemy_info(alive_enemies[0])
		else:
			command_menu.close_menu()
			_set_game_state(GameState.NORMAL)
	elif action == "item":
		var item_list: Array[Dictionary] = []
		for key in items:
			item_list.append({"id": key, "name": items[key]["name"], "count": items[key]["count"]})
		command_menu.open_submenu(item_list)

func _on_item_selected(item_id: String) -> void:
	pending_item_id = item_id
	command_menu.lock_selection()
	_set_game_state(GameState.PARTY_TARGET_SELECT)
	selected_party_index = 0
	character_info.selected_index = selected_party_index

func _on_menu_cancelled() -> void:
	_set_game_state(GameState.NORMAL)

func _on_main_menu_closed() -> void:
	_set_game_state(GameState.NORMAL)

func _on_tactics_opened() -> void:
	main_menu.is_open = false
	main_menu.visible = false
	tactics_editor.open_editor()
	_set_game_state(GameState.TACTICS_EDITOR)

func _on_tactics_editor_closed() -> void:
	_set_game_state(GameState.NORMAL)

func _on_character_damage_taken(character: PlayerCharacter, amount: int) -> void:
	_spawn_floating_number(str(amount), Color(1.0, 0.6, 0.0), character.global_position)

func _on_character_healed(character: PlayerCharacter, amount: int) -> void:
	_spawn_floating_number("+" + str(amount), Color(0.2, 1.0, 0.3), character.global_position)

func _on_character_levelled_up(character: PlayerCharacter) -> void:
	_spawn_floating_number("LEVEL UP! Lv" + str(character.stats.level), Color(1.0, 1.0, 0.3), character.global_position)

func _on_enemy_damage_taken(enemy: Enemy, amount: int) -> void:
	_spawn_floating_number(str(amount), Color(0.3, 0.6, 1.0), enemy.global_position)

func _spawn_floating_number(text: String, color: Color, pos: Vector3) -> void:
	var num = FloatingNumber.new()
	num.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(num)
	num.setup(text, color, pos)

func _on_character_charge_started(character: PlayerCharacter, target: Node3D) -> void:
	if character.charge_action.begins_with("item:"):
		_spawn_arc(character, target, Color(0.2, 1.0, 0.3))
	else:
		_spawn_arc(character, target, Color(0.3, 0.6, 1.0))

func _on_enemy_charge_started(enemy: Enemy, target: Node3D) -> void:
	_spawn_arc(enemy, target, Color(1.0, 0.6, 0.0))

func _spawn_arc(from_node: Node3D, to_node: Node3D, color: Color) -> void:
	if not is_instance_valid(from_node) or not is_instance_valid(to_node):
		return
	var arc = TargetArc.new()
	arc.process_mode = Node.PROCESS_MODE_PAUSABLE
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Use world-space positions, arc is added to the scene root
	var from_pos = from_node.global_position + Vector3(0, 1.0, 0)
	var to_pos = to_node.global_position + Vector3(0, 1.0, 0)
	add_child(arc)
	arc.setup(from_pos, to_pos, color)

func _on_enemy_died(enemy: Enemy) -> void:
	# Check if all enemies are dead
	var alive = _get_alive_enemies()
	if alive.is_empty():
		# Victory! Activate portal
		arena.activate_portal()

func _on_character_died(character: PlayerCharacter) -> void:
	# Check if all party members are dead
	var any_alive = false
	for member in party:
		if is_instance_valid(member) and member.state != PlayerCharacter.State.DEAD:
			any_alive = true
			break

	if not any_alive:
		_game_over()
	elif character.is_leader:
		# Auto-switch to next alive member
		for i in range(party.size()):
			if is_instance_valid(party[i]) and party[i].state != PlayerCharacter.State.DEAD:
				_switch_leader(i)
				break

func _on_portal_entered() -> void:
	current_level += 1
	_update_level_display()
	_advance_level()

func _advance_level() -> void:
	# Reset party positions
	for i in range(party.size()):
		if is_instance_valid(party[i]):
			party[i].position = Vector3(i * 2.0 - 2.0, 0.5, 5.0)
			party[i].state = PlayerCharacter.State.IDLE

	# Heal party slightly between levels and award arena clear EXP
	var clear_exp = 15 * current_level
	for member in party:
		if is_instance_valid(member) and member.state != PlayerCharacter.State.DEAD:
			member.stats.heal(member.stats.max_hp / 4)
			member.gain_exp(clear_exp)

	# Replenish items
	for key in items:
		items[key]["count"] = items[key]["max"]

	# Spawn new enemies
	_spawn_enemies()

	# Reset camera
	camera_controller.snap_to_target()

func _update_level_display() -> void:
	if level_label:
		level_label.text = "Level %d" % current_level

func _game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over_label.visible = true
	game_over_timer = game_over_delay

func _finish_game_over() -> void:
	is_game_over = false
	game_over_label.visible = false
	current_level = 1
	_update_level_display()
	for i in range(party.size()):
		if is_instance_valid(party[i]):
			party[i].stats.current_hp = party[i].stats.max_hp
			party[i].stats.current_mp = party[i].stats.max_mp
			party[i].state = PlayerCharacter.State.IDLE
			party[i].rotation_degrees.z = 0
			party[i].position = Vector3(i * 2.0 - 2.0, 0.5, 5.0)
			party[i].last_attack_target = null
	# Replenish items
	for key in items:
		items[key]["count"] = items[key]["max"]
	_spawn_enemies()
	camera_controller.snap_to_target()
