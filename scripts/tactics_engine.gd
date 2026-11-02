class_name TacticsEngine

# Evaluates a character's tactic list and returns an action to perform.
# Returns a Dictionary: { "action": String, "target": Node3D, "charge_time": float }
# Returns empty Dictionary if no tactic matched.

static func evaluate(character: PlayerCharacter, tactics: Array[Tactic], party: Array[PlayerCharacter], enemies: Array[Enemy], leader: PlayerCharacter, items: Dictionary) -> Dictionary:
	for tactic in tactics:
		if not tactic.enabled:
			continue
		if tactic.condition == Tactic.Condition.NONE or tactic.action == Tactic.Action.NONE:
			continue

		var candidates = _resolve_condition(character, tactic, party, enemies, leader)

		# Check implicit conditions on each candidate, pick first valid
		for target in candidates:
			if _check_action_implicit(tactic.action, target, items):
				return _build_action(tactic.action, target)

	return {}

static func _resolve_condition(character: PlayerCharacter, tactic: Tactic, party: Array[PlayerCharacter], enemies: Array[Enemy], leader: PlayerCharacter) -> Array[Node3D]:
	var candidates: Array[Node3D] = []

	match tactic.condition:
		Tactic.Condition.ENEMY_ANY:
			# All alive enemies, shuffled
			candidates = _alive_enemies(enemies).duplicate()
			candidates.shuffle()

		Tactic.Condition.ENEMY_CLOSEST:
			# All alive enemies, sorted by distance
			candidates = _alive_enemies(enemies).duplicate()
			candidates.sort_custom(func(a, b): return character.global_position.distance_to(a.global_position) < character.global_position.distance_to(b.global_position))

		Tactic.Condition.ENEMY_LEADER_TARGET:
			if leader and is_instance_valid(leader):
				var leader_target = leader.charge_target
				if leader_target and is_instance_valid(leader_target) and leader_target is Enemy:
					if leader_target.state != Enemy.State.DEAD:
						candidates.append(leader_target)

		Tactic.Condition.ALLY_KO:
			for member in party:
				if is_instance_valid(member) and member.state == PlayerCharacter.State.DEAD:
					candidates.append(member)

		Tactic.Condition.ALLY_HP_LT_75:
			candidates = _allies_below_hp_pct(party, 0.75)

		Tactic.Condition.ALLY_HP_LT_50:
			candidates = _allies_below_hp_pct(party, 0.50)

		Tactic.Condition.ALLY_ANY:
			for member in party:
				if is_instance_valid(member) and member.state != PlayerCharacter.State.DEAD:
					candidates.append(member)

	return candidates

static func _check_action_implicit(action: Tactic.Action, target: Node3D, items: Dictionary) -> bool:
	match action:
		Tactic.Action.ATTACK:
			# Can only attack enemies
			return target is Enemy and target.state != Enemy.State.DEAD

		Tactic.Action.ITEM_POTION, Tactic.Action.ITEM_HI_POTION:
			# Must have items left
			var item_id = Tactic.action_to_item_id(action)
			if items.has(item_id) and items[item_id]["count"] <= 0:
				return false
			# Can only use on alive party members
			if not target is PlayerCharacter:
				return false
			if target.state == PlayerCharacter.State.DEAD:
				return false
			# Don't heal if already at full HP
			if target.stats.current_hp >= target.stats.max_hp:
				return false
			return true

		Tactic.Action.ITEM_REVIVE:
			# Must have items left
			if items.has("revive") and items["revive"]["count"] <= 0:
				return false
			# Can only use on KOed party members
			if not target is PlayerCharacter:
				return false
			if target.state != PlayerCharacter.State.DEAD:
				return false
			return true

	return false

static func _build_action(action: Tactic.Action, target: Node3D) -> Dictionary:
	match action:
		Tactic.Action.ATTACK:
			return {"action": "attack", "target": target, "charge_time": 2.0}
		Tactic.Action.ITEM_POTION:
			return {"action": "item:potion", "target": target, "charge_time": 1.0}
		Tactic.Action.ITEM_HI_POTION:
			return {"action": "item:hi_potion", "target": target, "charge_time": 1.0}
		Tactic.Action.ITEM_REVIVE:
			return {"action": "item:revive", "target": target, "charge_time": 1.0}
	return {}

static func _alive_enemies(enemies: Array[Enemy]) -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.state != Enemy.State.DEAD:
			alive.append(enemy)
	return alive


static func _allies_below_hp_pct(party: Array[PlayerCharacter], pct: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for member in party:
		if is_instance_valid(member) and member.state != PlayerCharacter.State.DEAD:
			if float(member.stats.current_hp) / float(member.stats.max_hp) < pct:
				result.append(member)
	return result
