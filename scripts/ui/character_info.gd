class_name CharacterInfoPanel
extends PanelContainer

var party: Array[PlayerCharacter] = []
var rows: Array[PanelContainer] = []
var container: VBoxContainer
var selected_index: int = -1  # -1 = no selection

func setup(p_party: Array[PlayerCharacter]) -> void:
	container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	add_child(container)
	party = p_party
	_build_rows()

func _build_rows() -> void:
	for child in container.get_children():
		child.queue_free()
	rows.clear()

	for character in party:
		# Background panel for leader highlight
		var bg = PanelContainer.new()
		bg.name = "RowBG"
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0, 0, 0, 0)  # Transparent by default
		bg_style.corner_radius_top_left = 4
		bg_style.corner_radius_top_right = 4
		bg_style.corner_radius_bottom_left = 4
		bg_style.corner_radius_bottom_right = 4
		bg.add_theme_stylebox_override("panel", bg_style)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		# Charge bar with overlaid text
		var charge_container = _make_bar_with_label(
			"ChargeBar", "ChargeLabel",
			1.0, 0.0,
			Vector2(100, 18),
			""
		)
		row.add_child(charge_container)

		# Name
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = character.stats.character_name
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.custom_minimum_size = Vector2(55, 0)
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_label)

		# HP bar with overlaid text
		var hp_container = _make_bar_with_label(
			"HPBar", "HPLabel",
			character.stats.max_hp, character.stats.current_hp,
			Vector2(120, 18),
			"%d/%d" % [character.stats.current_hp, character.stats.max_hp]
		)
		row.add_child(hp_container)

		# MP bar with overlaid text
		var mp_container = _make_bar_with_label(
			"MPBar", "MPLabel",
			character.stats.max_mp, character.stats.current_mp,
			Vector2(100, 18),
			"%d/%d" % [character.stats.current_mp, character.stats.max_mp]
		)
		row.add_child(mp_container)

		bg.add_child(row)
		container.add_child(bg)
		rows.append(bg)

		# Connect signals
		character.hp_changed.connect(_on_character_hp_changed)
		character.charge_changed.connect(_on_character_charge_changed)

func _make_bar_with_label(bar_name: String, label_name: String, max_val: float, val: float, min_size: Vector2, text: String) -> Control:
	# Wrapper Control that stacks a ProgressBar and a Label on top
	var wrapper = Control.new()
	wrapper.custom_minimum_size = min_size

	var bar = ProgressBar.new()
	bar.name = bar_name
	bar.max_value = max_val
	bar.value = val
	bar.show_percentage = false
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(bar)

	var label = Label.new()
	label.name = label_name
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Ensure text is readable over the bar
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	wrapper.add_child(label)

	return wrapper

func _process(_delta: float) -> void:
	for i in range(party.size()):
		if i >= rows.size():
			break
		var character = party[i]
		var row = rows[i]
		if not is_instance_valid(character) or not is_instance_valid(row):
			continue

		# Find bars and labels inside wrapper Controls
		var charge_bar = _find_child_recursive(row, "ChargeBar") as ProgressBar
		var charge_label = _find_child_recursive(row, "ChargeLabel") as Label
		var hp_bar = _find_child_recursive(row, "HPBar") as ProgressBar
		var hp_label = _find_child_recursive(row, "HPLabel") as Label
		var mp_bar = _find_child_recursive(row, "MPBar") as ProgressBar
		var mp_label = _find_child_recursive(row, "MPLabel") as Label
		var name_label = _find_child_recursive(row, "NameLabel") as Label

		# Update charge bar
		if charge_bar:
			charge_bar.value = character.get_charge_progress()
			if character.state == PlayerCharacter.State.ACTING:
				charge_bar.modulate = Color.GREEN
			elif character.state == PlayerCharacter.State.CHARGING:
				charge_bar.modulate = Color.YELLOW
			else:
				charge_bar.modulate = Color.WHITE
		if charge_label:
			charge_label.text = character.get_charge_text()

		# Update HP
		if hp_bar:
			hp_bar.value = character.stats.current_hp
		if hp_label:
			hp_label.text = "%d/%d" % [character.stats.current_hp, character.stats.max_hp]

		# Update MP
		if mp_bar:
			mp_bar.value = character.stats.current_mp
		if mp_label:
			mp_label.text = "%d/%d" % [character.stats.current_mp, character.stats.max_mp]

		# Highlight leader and selection
		if name_label:
			var prefix = ""
			if i == selected_index:
				prefix = "> "
				name_label.add_theme_color_override("font_color", Color.YELLOW)
			elif character.is_leader:
				name_label.add_theme_color_override("font_color", Color.CYAN)
			else:
				name_label.add_theme_color_override("font_color", Color.WHITE)
			name_label.text = prefix + character.stats.character_name

		# Leader background highlight
		var bg_style = row.get_theme_stylebox("panel") as StyleBoxFlat
		if bg_style:
			if character.is_leader:
				bg_style.bg_color = Color(0.2, 0.4, 0.6, 0.4)
			else:
				bg_style.bg_color = Color(0, 0, 0, 0)

func _find_child_recursive(node: Node, child_name: String) -> Node:
	if node.name == child_name:
		return node
	for child in node.get_children():
		var found = _find_child_recursive(child, child_name)
		if found:
			return found
	return null

func _on_character_hp_changed(_character: PlayerCharacter) -> void:
	pass  # Updated in _process

func _on_character_charge_changed(_character: PlayerCharacter) -> void:
	pass  # Updated in _process
