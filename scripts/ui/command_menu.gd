class_name CommandMenu
extends PanelContainer

signal action_selected(action: String)
signal item_selected(item_id: String)
signal magic_selected(spell_id: String)
signal menu_cancelled

var actions: Array[String] = ["Attack", "Item"]
var selected_index: int = 0
var is_open: bool = false
var is_locked: bool = false
var list: VBoxContainer

# Submenu state
var in_submenu: bool = false
var submenu_items: Array[Dictionary] = []
var submenu_index: int = 0

func setup() -> void:
	list = VBoxContainer.new()
	add_child(list)
	visible = false
	_build_menu()

func _build_menu() -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.free()

	if in_submenu:
		_build_submenu()
	else:
		_build_main_menu()
	_update_selection()

func _build_main_menu() -> void:
	for i in range(actions.size()):
		var label = Label.new()
		label.text = actions[i]
		label.add_theme_font_size_override("font_size", 20)
		label.name = "Action" + str(i)
		list.add_child(label)

func _build_submenu() -> void:
	for i in range(submenu_items.size()):
		var item = submenu_items[i]
		var label = Label.new()
		label.text = "%s x%d" % [item["name"], item["count"]]
		label.add_theme_font_size_override("font_size", 20)
		label.name = "Item" + str(i)
		list.add_child(label)
		if item["count"] <= 0:
			label.modulate = Color(0.5, 0.5, 0.5)

func open_menu() -> void:
	is_open = true
	is_locked = false
	in_submenu = false
	selected_index = 0
	visible = true
	_build_menu()

func close_menu() -> void:
	is_open = false
	is_locked = false
	in_submenu = false
	visible = false

func lock_selection() -> void:
	is_locked = true
	_update_selection()

func open_submenu(items: Array[Dictionary]) -> void:
	in_submenu = true
	submenu_items = items
	submenu_index = 0
	selected_index = 0
	_build_menu()

func _update_selection() -> void:
	var count = list.get_child_count()
	for i in range(count):
		var label = list.get_child(i) as Label
		var text: String
		if in_submenu:
			if submenu_items[i].has("mp_cost"):
				text = submenu_items[i]["name"] + " (" + str(submenu_items[i]["mp_cost"]) + " MP)"
			else:
				text = submenu_items[i]["name"] + " x" + str(submenu_items[i]["count"])
		else:
			text = actions[i]

		if i == selected_index:
			if is_locked:
				label.add_theme_color_override("font_color", Color.GREEN)
				label.text = "> " + text + " <"
			else:
				label.add_theme_color_override("font_color", Color.YELLOW)
				label.text = "> " + text
		else:
			if in_submenu and submenu_items[i].get("count", 1) <= 0:
				label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			elif in_submenu and submenu_items[i].get("disabled", false):
				label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			else:
				label.add_theme_color_override("font_color", Color.WHITE)
			label.text = "  " + text

func handle_input(event: InputEvent) -> bool:
	if not is_open or is_locked:
		return false

	var max_index = submenu_items.size() if in_submenu else actions.size()
	if max_index == 0:
		return false

	if event.is_action_pressed("move_up"):
		selected_index = (selected_index - 1 + max_index) % max_index
		_update_selection()
		return true
	elif event.is_action_pressed("move_down"):
		selected_index = (selected_index + 1) % max_index
		_update_selection()
		return true
	elif event.is_action_pressed("action_confirm"):
		if in_submenu:
			var item = submenu_items[selected_index]
			if item.get("count", 1) > 0:
				if item.has("mp_cost"):
					magic_selected.emit(item["id"])
				else:
					item_selected.emit(item["id"])
			return true
		else:
			var action = actions[selected_index].to_lower()
			action_selected.emit(action)
			return true
	elif event.is_action_pressed("action_cancel"):
		if in_submenu:
			# Go back to main menu
			in_submenu = false
			selected_index = 0
			_build_menu()
			return true
		else:
			close_menu()
			menu_cancelled.emit()
			return true

	return false
