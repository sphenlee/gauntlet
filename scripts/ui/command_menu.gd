class_name CommandMenu
extends PanelContainer

signal action_selected(action: String)
signal menu_cancelled

var actions: Array[String] = ["Attack"]
var selected_index: int = 0
var is_open: bool = false
var list: VBoxContainer

func setup() -> void:
	list = VBoxContainer.new()
	add_child(list)
	visible = false
	_build_menu()

func _build_menu() -> void:
	for child in list.get_children():
		child.queue_free()
	for i in range(actions.size()):
		var label = Label.new()
		label.text = actions[i]
		label.add_theme_font_size_override("font_size", 20)
		label.name = "Action" + str(i)
		list.add_child(label)
	_update_selection()

func open_menu() -> void:
	is_open = true
	selected_index = 0
	visible = true
	_update_selection()

func close_menu() -> void:
	is_open = false
	visible = false

func _update_selection() -> void:
	for i in range(list.get_child_count()):
		var label = list.get_child(i) as Label
		if i == selected_index:
			label.add_theme_color_override("font_color", Color.YELLOW)
			label.text = "> " + actions[i]
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
			label.text = "  " + actions[i]

func handle_input(event: InputEvent) -> bool:
	if not is_open:
		return false

	if event.is_action_pressed("move_up"):
		selected_index = (selected_index - 1 + actions.size()) % actions.size()
		_update_selection()
		return true
	elif event.is_action_pressed("move_down"):
		selected_index = (selected_index + 1) % actions.size()
		_update_selection()
		return true
	elif event.is_action_pressed("action_confirm"):
		action_selected.emit(actions[selected_index].to_lower())
		close_menu()
		return true
	elif event.is_action_pressed("action_cancel"):
		menu_cancelled.emit()
		close_menu()
		return true

	return false
