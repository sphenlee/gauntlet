class_name Tactic
extends Resource

enum Condition {
	NONE,
	ENEMY_ANY,
	ENEMY_CLOSEST,
	ENEMY_LEADER_TARGET,
	ALLY_KO,
	ALLY_HP_LT_75,
	ALLY_HP_LT_50,
	ALLY_ANY,
}

enum Action {
	NONE,
	ATTACK,
	ITEM_POTION,
	ITEM_HI_POTION,
}

@export var enabled: bool = false
@export var condition: Condition = Condition.NONE
@export var action: Action = Action.NONE

static func condition_name(cond: Condition) -> String:
	match cond:
		Condition.NONE: return "-"
		Condition.ENEMY_ANY: return "Enemy - Any"
		Condition.ENEMY_CLOSEST: return "Enemy - Closest"
		Condition.ENEMY_LEADER_TARGET: return "Enemy - Leader Target"
		Condition.ALLY_KO: return "Ally - KO"
		Condition.ALLY_HP_LT_75: return "Ally - HP < 75%"
		Condition.ALLY_HP_LT_50: return "Ally - HP < 50%"
		Condition.ALLY_ANY: return "Ally - Any"
	return "?"

static func action_name(act: Action) -> String:
	match act:
		Action.NONE: return "-"
		Action.ATTACK: return "Attack"
		Action.ITEM_POTION: return "Item: Potion"
		Action.ITEM_HI_POTION: return "Item: Hi-Potion"
	return "?"

static func condition_is_enemy(cond: Condition) -> bool:
	return cond in [Condition.ENEMY_ANY, Condition.ENEMY_CLOSEST, Condition.ENEMY_LEADER_TARGET]

static func condition_is_ally(cond: Condition) -> bool:
	return cond in [Condition.ALLY_KO, Condition.ALLY_HP_LT_75, Condition.ALLY_HP_LT_50, Condition.ALLY_ANY]

static func action_is_item(act: Action) -> bool:
	return act in [Action.ITEM_POTION, Action.ITEM_HI_POTION]

static func action_to_item_id(act: Action) -> String:
	match act:
		Action.ITEM_POTION: return "potion"
		Action.ITEM_HI_POTION: return "hi_potion"
	return ""

static func all_conditions() -> Array[Condition]:
	return [
		Condition.NONE,
		Condition.ENEMY_ANY,
		Condition.ENEMY_CLOSEST,
		Condition.ENEMY_LEADER_TARGET,
		Condition.ALLY_KO,
		Condition.ALLY_HP_LT_75,
		Condition.ALLY_HP_LT_50,
		Condition.ALLY_ANY,
	]

static func all_actions() -> Array[Action]:
	return [
		Action.NONE,
		Action.ATTACK,
		Action.ITEM_POTION,
		Action.ITEM_HI_POTION,
	]
