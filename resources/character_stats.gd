class_name CharacterStats
extends Resource

@export var character_name: String = "Character"
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var max_mp: int = 50
@export var current_mp: int = 50
@export var strength: int = 10
@export var defense: int = 5
@export var agility: int = 8
@export var luck: int = 5
@export var level: int = 1
@export var experience: int = 0

# Weapon
@export var weapon_name: String = "Dagger"
@export var weapon_pow: int = 5
@export var weapon_range: float = 2.5

# Stat growth per level (set per character)
@export var growth_hp: int = 10
@export var growth_mp: int = 3
@export var growth_str: int = 2
@export var growth_def: int = 2
@export var growth_agl: int = 1
@export var growth_lck: int = 1

func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)

func heal(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)

func is_alive() -> bool:
	return current_hp > 0

func get_attack_power() -> int:
	return strength + weapon_pow

func exp_to_next_level() -> int:
	return int(50.0 * pow(level, 1.5))

func gain_exp(amount: int) -> bool:
	# Returns true if levelled up
	experience += amount
	if experience >= exp_to_next_level():
		experience -= exp_to_next_level()
		level_up()
		return true
	return false

func level_up() -> void:
	level += 1
	max_hp += growth_hp
	max_mp += growth_mp
	strength += growth_str
	defense += growth_def
	agility += growth_agl
	luck += growth_lck
	# Full heal on level up
	current_hp = max_hp
	current_mp = max_mp
