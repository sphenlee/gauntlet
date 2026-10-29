class_name EnemyInfoPanel
extends PanelContainer

var name_label: Label
var hp_bar: ProgressBar
var hp_label: Label
var stats_label: Label

func setup() -> void:
	var vbox = VBoxContainer.new()
	add_child(vbox)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(180, 10)
	hp_bar.show_percentage = false
	vbox.add_child(hp_bar)

	hp_label = Label.new()
	hp_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hp_label)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(stats_label)

	visible = false

func show_enemy(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or not enemy.stats:
		hide_panel()
		return
	visible = true
	name_label.text = enemy.stats.character_name
	hp_bar.max_value = enemy.stats.max_hp
	hp_bar.value = enemy.stats.current_hp
	hp_label.text = "HP: %d/%d" % [enemy.stats.current_hp, enemy.stats.max_hp]
	stats_label.text = "STR:%d DEF:%d AGL:%d" % [enemy.stats.strength, enemy.stats.defense, enemy.stats.agility]

func hide_panel() -> void:
	visible = false
