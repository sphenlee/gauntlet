class_name CharacterInfoPanel
extends PanelContainer

var party: Array[PlayerCharacter] = []
var rows: Array[VBoxContainer] = []
var container: VBoxContainer

func setup(p_party: Array[PlayerCharacter]) -> void:
	container = VBoxContainer.new()
	add_child(container)
	party = p_party
	_build_rows()

func _build_rows() -> void:
	for child in container.get_children():
		child.queue_free()
	rows.clear()

	for character in party:
		var row = VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)

		# Charge bar
		var charge_bar = ProgressBar.new()
		charge_bar.name = "ChargeBar"
		charge_bar.max_value = 1.0
		charge_bar.value = 0.0
		charge_bar.custom_minimum_size = Vector2(180, 12)
		charge_bar.show_percentage = false
		row.add_child(charge_bar)

		# Charge label
		var charge_label = Label.new()
		charge_label.name = "ChargeLabel"
		charge_label.text = ""
		charge_label.add_theme_font_size_override("font_size", 10)
		row.add_child(charge_label)

		# Name
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = character.stats.character_name
		name_label.add_theme_font_size_override("font_size", 14)
		row.add_child(name_label)

		# HP bar
		var hp_bar = ProgressBar.new()
		hp_bar.name = "HPBar"
		hp_bar.max_value = character.stats.max_hp
		hp_bar.value = character.stats.current_hp
		hp_bar.custom_minimum_size = Vector2(180, 10)
		hp_bar.show_percentage = false
		row.add_child(hp_bar)

		# HP label
		var hp_label = Label.new()
		hp_label.name = "HPLabel"
		hp_label.text = "HP: %d/%d" % [character.stats.current_hp, character.stats.max_hp]
		hp_label.add_theme_font_size_override("font_size", 10)
		row.add_child(hp_label)

		# MP bar
		var mp_bar = ProgressBar.new()
		mp_bar.name = "MPBar"
		mp_bar.max_value = character.stats.max_mp
		mp_bar.value = character.stats.current_mp
		mp_bar.custom_minimum_size = Vector2(180, 10)
		mp_bar.show_percentage = false
		row.add_child(mp_bar)

		# MP label
		var mp_label = Label.new()
		mp_label.name = "MPLabel"
		mp_label.text = "MP: %d/%d" % [character.stats.current_mp, character.stats.max_mp]
		mp_label.add_theme_font_size_override("font_size", 10)
		row.add_child(mp_label)

		# Separator
		var sep = HSeparator.new()
		row.add_child(sep)

		container.add_child(row)
		rows.append(row)

		# Connect signals
		character.hp_changed.connect(_on_character_hp_changed)
		character.charge_changed.connect(_on_character_charge_changed)

func _process(_delta: float) -> void:
	for i in range(party.size()):
		if i >= rows.size():
			break
		var character = party[i]
		var row = rows[i]
		if not is_instance_valid(character) or not is_instance_valid(row):
			continue

		# Update charge bar
		var charge_bar = row.get_node("ChargeBar") as ProgressBar
		var charge_label = row.get_node("ChargeLabel") as Label
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
		var hp_bar = row.get_node("HPBar") as ProgressBar
		var hp_label = row.get_node("HPLabel") as Label
		if hp_bar:
			hp_bar.value = character.stats.current_hp
		if hp_label:
			hp_label.text = "HP: %d/%d" % [character.stats.current_hp, character.stats.max_hp]

		# Update MP
		var mp_bar = row.get_node("MPBar") as ProgressBar
		var mp_label = row.get_node("MPLabel") as Label
		if mp_bar:
			mp_bar.value = character.stats.current_mp
		if mp_label:
			mp_label.text = "MP: %d/%d" % [character.stats.current_mp, character.stats.max_mp]

		# Highlight leader
		var name_label = row.get_node("NameLabel") as Label
		if name_label:
			if character.is_leader:
				name_label.add_theme_color_override("font_color", Color.CYAN)
			else:
				name_label.add_theme_color_override("font_color", Color.WHITE)

func _on_character_hp_changed(_character: PlayerCharacter) -> void:
	pass  # Updated in _process

func _on_character_charge_changed(_character: PlayerCharacter) -> void:
	pass  # Updated in _process
