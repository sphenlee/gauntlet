class_name MainMenu
extends PanelContainer

signal menu_closed
signal tactics_opened

var entries: Array[String] = ["Tactics"]
var selected_index: int = 0
var is_open: bool = false
var list: VBoxContainer

func setup() -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	var title = Label.new()
	title.text = "Menu"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	vbox.add_child(list)

	visible = false
	_build_menu()

func _build_menu() -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.free()
	for i in range(entries.size()):
		var label = Label.new()
		label.text = entries[i]
		label.add_theme_font_size_override("font_size", 20)
		label.name = "Entry" + str(i)
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
	menu_closed.emit()

func _update_selection() -> void:
	for i in range(list.get_child_count()):
		var label = list.get_child(i) as Label
		if i == selected_index:
			label.add_theme_color_override("font_color", Color.YELLOW)
			label.text = "> " + entries[i]
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
			label.text = "  " + entries[i]

func handle_input(event: InputEvent) -> bool:
	if not is_open:
		return false

	if event.is_action_pressed("move_up"):
		selected_index = (selected_index - 1 + entries.size()) % entries.size()
		_update_selection()
		return true
	elif event.is_action_pressed("move_down"):
		selected_index = (selected_index + 1) % entries.size()
		_update_selection()
		return true
	elif event.is_action_pressed("action_confirm"):
		match entries[selected_index]:
			"Tactics":
				tactics_opened.emit()
		return true
	elif event.is_action_pressed("action_cancel"):
		close_menu()
		return true

	return false
