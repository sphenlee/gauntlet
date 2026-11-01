class_name TacticsEditor
extends PanelContainer

signal editor_closed

enum Column { TOGGLE, CONDITION, ACTION }
enum EditorState { GRID, CONDITION_PICKER, ACTION_PICKER, CHARACTER_PICKER }

var party: Array[PlayerCharacter] = []
var character_index: int = 0
var cursor_row: int = 0
var cursor_col: Column = Column.TOGGLE
var editor_state: EditorState = EditorState.CHARACTER_PICKER
var picker_index: int = 0

var grid_container: VBoxContainer
var header_label: Label
var picker_panel: PanelContainer
var picker_list: VBoxContainer
var picker_title: Label

const MAX_ROWS = 5

func setup(p_party: Array[PlayerCharacter]) -> void:
	party = p_party

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)

	# Header showing which character
	header_label = Label.new()
	header_label.add_theme_font_size_override("font_size", 22)
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(header_label)

	# Column headers
	var col_header = HBoxContainer.new()
	col_header.add_theme_constant_override("separation", 10)
	var toggle_hdr = Label.new()
	toggle_hdr.text = "On"
	toggle_hdr.custom_minimum_size = Vector2(40, 0)
	toggle_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_header.add_child(toggle_hdr)
	var cond_hdr = Label.new()
	cond_hdr.text = "Condition"
	cond_hdr.custom_minimum_size = Vector2(200, 0)
	col_header.add_child(cond_hdr)
	var act_hdr = Label.new()
	act_hdr.text = "Action"
	act_hdr.custom_minimum_size = Vector2(160, 0)
	col_header.add_child(act_hdr)
	main_vbox.add_child(col_header)

	# Grid
	grid_container = VBoxContainer.new()
	grid_container.add_theme_constant_override("separation", 2)
	main_vbox.add_child(grid_container)

	# Picker panel (for condition/action submenus)
	picker_panel = PanelContainer.new()
	picker_panel.visible = false
	var picker_vbox = VBoxContainer.new()
	picker_panel.add_child(picker_vbox)
	picker_title = Label.new()
	picker_title.add_theme_font_size_override("font_size", 18)
	picker_vbox.add_child(picker_title)
	picker_list = VBoxContainer.new()
	picker_vbox.add_child(picker_list)
	main_vbox.add_child(picker_panel)

	visible = false

func open_editor() -> void:
	visible = true
	editor_state = EditorState.CHARACTER_PICKER
	character_index = 0
	cursor_row = 0
	cursor_col = Column.TOGGLE
	_refresh_display()

func close_editor() -> void:
	visible = false
	editor_closed.emit()

func _refresh_display() -> void:
	if editor_state == EditorState.CHARACTER_PICKER:
		header_label.text = "Select Character: " + party[character_index].stats.character_name
	else:
		header_label.text = "Tactics: " + party[character_index].stats.character_name
	_build_grid()

func _build_grid() -> void:
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.free()

	if editor_state == EditorState.CHARACTER_PICKER:
		return

	var tactics = party[character_index].tactics
	for row_i in range(MAX_ROWS):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.name = "Row" + str(row_i)

		var tactic = tactics[row_i] if row_i < tactics.size() else null

		# Row background color
		var bg = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3

		if tactic and tactic.enabled and tactic.condition != Tactic.Condition.NONE:
			if Tactic.condition_is_enemy(tactic.condition):
				style.bg_color = Color(0.5, 0.2, 0.2, 0.4)  # Pale red
			elif Tactic.condition_is_ally(tactic.condition):
				style.bg_color = Color(0.2, 0.3, 0.5, 0.4)  # Pale blue
			else:
				style.bg_color = Color(0.3, 0.3, 0.3, 0.3)  # Gray
		else:
			style.bg_color = Color(0.3, 0.3, 0.3, 0.3)  # Gray

		bg.add_theme_stylebox_override("panel", style)

		var inner = HBoxContainer.new()
		inner.add_theme_constant_override("separation", 10)

		# Toggle
		var toggle_label = Label.new()
		toggle_label.name = "Toggle"
		toggle_label.custom_minimum_size = Vector2(40, 0)
		toggle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if tactic and tactic.enabled:
			toggle_label.text = "[X]"
		else:
			toggle_label.text = "[ ]"
		inner.add_child(toggle_label)

		# Condition
		var cond_label = Label.new()
		cond_label.name = "Condition"
		cond_label.custom_minimum_size = Vector2(200, 0)
		if tactic:
			cond_label.text = Tactic.condition_name(tactic.condition)
		else:
			cond_label.text = "-"
		inner.add_child(cond_label)

		# Action
		var act_label = Label.new()
		act_label.name = "Action"
		act_label.custom_minimum_size = Vector2(160, 0)
		if tactic:
			act_label.text = Tactic.action_name(tactic.action)
		else:
			act_label.text = "-"
		inner.add_child(act_label)

		bg.add_child(inner)
		row.add_child(bg)
		grid_container.add_child(row)

	_update_cursor()

func _update_cursor() -> void:
	for row_i in range(grid_container.get_child_count()):
		var row = grid_container.get_child(row_i)
		var bg = row.get_child(0) as PanelContainer
		var inner = bg.get_child(0) as HBoxContainer

		for col_i in range(inner.get_child_count()):
			var label = inner.get_child(col_i) as Label
			var text = label.text

			# Strip existing cursor
			text = text.trim_prefix("> ").trim_suffix(" <")

			if row_i == cursor_row and col_i == cursor_col and editor_state == EditorState.GRID:
				label.text = "> " + text + " <"
				label.add_theme_color_override("font_color", Color.YELLOW)
			else:
				label.text = text
				label.remove_theme_color_override("font_color")

func _open_picker(title: String, options: Array) -> void:
	picker_panel.visible = true
	picker_title.text = title
	picker_index = 0

	for child in picker_list.get_children():
		picker_list.remove_child(child)
		child.free()

	for i in range(options.size()):
		var label = Label.new()
		label.text = options[i]
		label.add_theme_font_size_override("font_size", 16)
		label.name = "Option" + str(i)
		picker_list.add_child(label)

	_update_picker_cursor()

func _update_picker_cursor() -> void:
	for i in range(picker_list.get_child_count()):
		var label = picker_list.get_child(i) as Label
		var text = label.text.trim_prefix("> ")
		if i == picker_index:
			label.text = "> " + text
			label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			label.text = text
			label.remove_theme_color_override("font_color")

func _close_picker() -> void:
	picker_panel.visible = false
	editor_state = EditorState.GRID
	_refresh_display()

func handle_input(event: InputEvent) -> bool:
	match editor_state:
		EditorState.CHARACTER_PICKER:
			return _handle_character_picker_input(event)
		EditorState.GRID:
			return _handle_grid_input(event)
		EditorState.CONDITION_PICKER:
			return _handle_condition_picker_input(event)
		EditorState.ACTION_PICKER:
			return _handle_action_picker_input(event)
	return false

func _handle_character_picker_input(event: InputEvent) -> bool:
	if event.is_action_pressed("move_up"):
		character_index = (character_index - 1 + party.size()) % party.size()
		_refresh_display()
		return true
	elif event.is_action_pressed("move_down"):
		character_index = (character_index + 1) % party.size()
		_refresh_display()
		return true
	elif event.is_action_pressed("action_confirm"):
		editor_state = EditorState.GRID
		cursor_row = 0
		cursor_col = Column.TOGGLE
		_refresh_display()
		return true
	elif event.is_action_pressed("action_cancel"):
		close_editor()
		return true
	return false

func _handle_grid_input(event: InputEvent) -> bool:
	if event.is_action_pressed("move_up"):
		cursor_row = (cursor_row - 1 + MAX_ROWS) % MAX_ROWS
		_update_cursor()
		return true
	elif event.is_action_pressed("move_down"):
		cursor_row = (cursor_row + 1) % MAX_ROWS
		_update_cursor()
		return true
	elif event.is_action_pressed("enemy_select_prev"):
		cursor_col = (cursor_col - 1 + 3) % 3 as Column
		_update_cursor()
		return true
	elif event.is_action_pressed("enemy_select_next"):
		cursor_col = (cursor_col + 1) % 3 as Column
		_update_cursor()
		return true
	elif event.is_action_pressed("action_confirm"):
		var tactics = party[character_index].tactics
		if cursor_row < tactics.size():
			match cursor_col:
				Column.TOGGLE:
					tactics[cursor_row].enabled = not tactics[cursor_row].enabled
					_refresh_display()
				Column.CONDITION:
					editor_state = EditorState.CONDITION_PICKER
					var options: Array = []
					for cond in Tactic.all_conditions():
						options.append(Tactic.condition_name(cond))
					_open_picker("Select Condition", options)
				Column.ACTION:
					editor_state = EditorState.ACTION_PICKER
					var options: Array = []
					for act in Tactic.all_actions():
						options.append(Tactic.action_name(act))
					_open_picker("Select Action", options)
		return true
	elif event.is_action_pressed("action_cancel"):
		editor_state = EditorState.CHARACTER_PICKER
		_refresh_display()
		return true
	return false

func _handle_condition_picker_input(event: InputEvent) -> bool:
	var conditions = Tactic.all_conditions()
	if event.is_action_pressed("move_up"):
		picker_index = (picker_index - 1 + conditions.size()) % conditions.size()
		_update_picker_cursor()
		return true
	elif event.is_action_pressed("move_down"):
		picker_index = (picker_index + 1) % conditions.size()
		_update_picker_cursor()
		return true
	elif event.is_action_pressed("action_confirm"):
		var tactics = party[character_index].tactics
		if cursor_row < tactics.size():
			tactics[cursor_row].condition = conditions[picker_index]
			# Auto-enable when setting a condition
			if conditions[picker_index] != Tactic.Condition.NONE:
				tactics[cursor_row].enabled = true
		_close_picker()
		return true
	elif event.is_action_pressed("action_cancel"):
		_close_picker()
		return true
	return false

func _handle_action_picker_input(event: InputEvent) -> bool:
	var actions = Tactic.all_actions()
	if event.is_action_pressed("move_up"):
		picker_index = (picker_index - 1 + actions.size()) % actions.size()
		_update_picker_cursor()
		return true
	elif event.is_action_pressed("move_down"):
		picker_index = (picker_index + 1) % actions.size()
		_update_picker_cursor()
		return true
	elif event.is_action_pressed("action_confirm"):
		var tactics = party[character_index].tactics
		if cursor_row < tactics.size():
			tactics[cursor_row].action = actions[picker_index]
		_close_picker()
		return true
	elif event.is_action_pressed("action_cancel"):
		_close_picker()
		return true
	return false
