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

func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)

func heal(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)

func is_alive() -> bool:
	return current_hp > 0

func get_attack_power() -> int:
	return strength + weapon_pow
