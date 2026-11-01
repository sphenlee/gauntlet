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

		var target = _resolve_condition(character, tactic, party, enemies, leader)
		if target == null:
			continue

		# Check implicit conditions on the action
		if not _check_action_implicit(tactic.action, target, items):
			continue

		return _build_action(tactic.action, target)

	return {}

static func _resolve_condition(character: PlayerCharacter, tactic: Tactic, party: Array[PlayerCharacter], enemies: Array[Enemy], leader: PlayerCharacter) -> Node3D:
	match tactic.condition:
		Tactic.Condition.ENEMY_ANY:
			var alive = _alive_enemies(enemies)
			if alive.is_empty():
				return null
			return alive[randi() % alive.size()]

		Tactic.Condition.ENEMY_CLOSEST:
			return _nearest_enemy(character.global_position, enemies)

		Tactic.Condition.ENEMY_LEADER_TARGET:
			if leader and is_instance_valid(leader):
				var leader_target = leader.charge_target
				if leader_target and is_instance_valid(leader_target) and leader_target is Enemy:
					if leader_target.state != Enemy.State.DEAD:
						return leader_target
			return null

		Tactic.Condition.ALLY_KO:
			for member in party:
				if is_instance_valid(member) and member.state == PlayerCharacter.State.DEAD:
					return member
			return null

		Tactic.Condition.ALLY_HP_LT_75:
			return _ally_below_hp_pct(party, 0.75)

		Tactic.Condition.ALLY_HP_LT_50:
			return _ally_below_hp_pct(party, 0.50)

		Tactic.Condition.ALLY_ANY:
			# Return first alive ally (including self)
			for member in party:
				if is_instance_valid(member) and member.state != PlayerCharacter.State.DEAD:
					return member
			return null

	return null

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

	return false

static func _build_action(action: Tactic.Action, target: Node3D) -> Dictionary:
	match action:
		Tactic.Action.ATTACK:
			return {"action": "attack", "target": target, "charge_time": 2.0}
		Tactic.Action.ITEM_POTION:
			return {"action": "item:potion", "target": target, "charge_time": 1.0}
		Tactic.Action.ITEM_HI_POTION:
			return {"action": "item:hi_potion", "target": target, "charge_time": 1.0}
	return {}

static func _alive_enemies(enemies: Array[Enemy]) -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.state != Enemy.State.DEAD:
			alive.append(enemy)
	return alive

static func _nearest_enemy(pos: Vector3, enemies: Array[Enemy]) -> Enemy:
	var nearest: Enemy = null
	var nearest_dist: float = INF
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.state != Enemy.State.DEAD:
			var dist = pos.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy
	return nearest

static func _ally_below_hp_pct(party: Array[PlayerCharacter], pct: float) -> PlayerCharacter:
	for member in party:
		if is_instance_valid(member) and member.state != PlayerCharacter.State.DEAD:
			if float(member.stats.current_hp) / float(member.stats.max_hp) < pct:
				return member
	return null
