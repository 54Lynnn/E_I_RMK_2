extends Node

signal relic_selected(relic_id: String)
signal relic_ui_requested(choices: Array)
signal active_relics_changed(relic_ids: Array)

const RARITY_WEIGHTS := {
	RelicData.Rarity.COMMON: 40,
	RelicData.Rarity.UNCOMMON: 30,
	RelicData.Rarity.UNIQUE: 15,
	RelicData.Rarity.RARE: 10,
	RelicData.Rarity.EXCEPTIONAL: 5,
}

const RARITY_ORDER := [
	RelicData.Rarity.COMMON,
	RelicData.Rarity.UNCOMMON,
	RelicData.Rarity.UNIQUE,
	RelicData.Rarity.RARE,
	RelicData.Rarity.EXCEPTIONAL,
]

var all_relics: Dictionary = {}
var relics_by_rarity: Dictionary = {}
var available_pool: Dictionary = {}
var active_relic_ids: Array = []

func _ready():
	_define_all_relics()
	_build_pool()

func _define_all_relics():
	var defs = [
		# === Common（7个）===
		{ "id": "hp_small", "name": "增加血量小", "desc": "+50 最大生命值", "rarity": RelicData.Rarity.COMMON },
		{ "id": "mana_regen_small", "name": "增加回蓝小", "desc": "+1 法力恢复/秒", "rarity": RelicData.Rarity.COMMON },
		{ "id": "hp_regen_small", "name": "增加回血小", "desc": "+0.5 生命恢复/秒", "rarity": RelicData.Rarity.COMMON },
		{ "id": "auto_magic_missile", "name": "自动机枪", "desc": "每5秒自动朝光标发射 Magic Missile", "rarity": RelicData.Rarity.COMMON },
		{ "id": "aoe_small", "name": "增加范围小", "desc": "范围型技能半径 +5%", "rarity": RelicData.Rarity.COMMON },
		{ "id": "cd_small", "name": "降低冷却小", "desc": "所有冷却时间 -5%", "rarity": RelicData.Rarity.COMMON },

		# === Uncommon（3个）===
		{ "id": "tracking_fireball", "name": "追踪火球术", "desc": "Fireball 有轻微追踪效果", "rarity": RelicData.Rarity.UNCOMMON },
		{ "id": "auto_fireball", "name": "自动火球术", "desc": "每3.5秒自动朝光标发射 Fireball", "rarity": RelicData.Rarity.UNCOMMON },
		{ "id": "tracking_spear", "name": "追踪冰冻之矛", "desc": "Freezing Spear 有轻微追踪效果", "rarity": RelicData.Rarity.UNCOMMON },

		# === Unique（5个）===
		{ "id": "aoe_medium", "name": "增加范围中", "desc": "范围型技能半径 +10%", "rarity": RelicData.Rarity.UNIQUE },
		{ "id": "hp_medium", "name": "增加血量中", "desc": "+100 最大生命值", "rarity": RelicData.Rarity.UNIQUE },
		{ "id": "mana_regen_medium", "name": "增加回蓝中", "desc": "+2 法力恢复/秒", "rarity": RelicData.Rarity.UNIQUE },
		{ "id": "hp_regen_medium", "name": "增加回血中", "desc": "+1 生命恢复/秒", "rarity": RelicData.Rarity.UNIQUE },
		{ "id": "cd_medium", "name": "降低冷却中", "desc": "所有冷却时间 -10%", "rarity": RelicData.Rarity.UNIQUE },

		# === Rare（3个）===
		{ "id": "pierce_fireball", "name": "穿透火球术", "desc": "Fireball 穿透敌人后继续飞行，二段爆炸伤害减半", "rarity": RelicData.Rarity.RARE },
		{ "id": "knockback_missile", "name": "击退子弹", "desc": "Magic Missile 命中时击退敌人 50px", "rarity": RelicData.Rarity.RARE },
		{ "id": "shield", "name": "护盾", "desc": "每5秒获得一层护盾，完全格挡一次伤害", "rarity": RelicData.Rarity.RARE },

		# === Exceptional（2个）===
		{ "id": "cd_large", "name": "降低冷却大", "desc": "所有冷却时间 -20%", "rarity": RelicData.Rarity.EXCEPTIONAL },
		{ "id": "multicast", "name": "多重施法", "desc": "施法时15%概率再释放一次相同的技能", "rarity": RelicData.Rarity.EXCEPTIONAL },
	]

	for d in defs:
		var relic = RelicData.new()
		relic.id = d.id
		relic.relic_name = d.name
		relic.description = d.desc
		relic.rarity = d.rarity
		all_relics[relic.id] = relic

		if not relics_by_rarity.has(relic.rarity):
			relics_by_rarity[relic.rarity] = []
		relics_by_rarity[relic.rarity].append(relic)

func _build_pool():
	available_pool.clear()
	for rarity in RARITY_ORDER:
		if relics_by_rarity.has(rarity):
			available_pool[rarity] = relics_by_rarity[rarity].duplicate()

func _get_rarity_by_weight(exclude_rarities: Array = []) -> int:
	var total_weight = 0
	for r in RARITY_ORDER:
		if r in exclude_rarities:
			continue
		total_weight += RARITY_WEIGHTS.get(r, 0)

	var roll = randi() % max(total_weight, 1)
	var cumulative = 0
	for r in RARITY_ORDER:
		if r in exclude_rarities:
			continue
		cumulative += RARITY_WEIGHTS.get(r, 0)
		if roll < cumulative:
			return r
	return RARITY_ORDER.back()

func generate_choices(count: int = 3, first_pick: bool = false) -> Array:
	var choices: Array = []
	var used_ids: Array = []
	var attempts := 0

	while choices.size() < count and attempts < 50:
		attempts += 1
		var rarity: int
		if first_pick:
			rarity = RelicData.Rarity.COMMON
		else:
			var exclude: Array = []
			for r in RARITY_ORDER:
				var pool = available_pool.get(r, [])
				var remaining = _filter_available(pool, used_ids)
				if remaining.is_empty():
					exclude.append(r)
			rarity = _get_rarity_by_weight(exclude)

		var pool = available_pool.get(rarity, [])
		var remaining = _filter_available(pool, used_ids)
		if remaining.is_empty():
			continue

		var relic = remaining[randi() % remaining.size()]
		choices.append(relic)
		used_ids.append(relic.id)

	return choices

func _filter_available(pool: Array, used_ids: Array) -> Array:
	var result: Array = []
	for relic in pool:
		if not relic.id in used_ids and not relic.id in active_relic_ids:
			result.append(relic)
	return result

func select_relic(relic_id: String):
	if not all_relics.has(relic_id):
		return
	if relic_id in active_relic_ids:
		return

	active_relic_ids.append(relic_id)
	_apply_relic_effect(relic_id)
	active_relics_changed.emit(active_relic_ids)
	relic_selected.emit(relic_id)

func get_active_relic_ids() -> Array:
	return active_relic_ids.duplicate()

func has_relic(relic_id: String) -> bool:
	return relic_id in active_relic_ids

func get_cooldown_multiplier() -> float:
	var mult = 1.0
	if has_relic("cd_small"):
		mult -= 0.05
	if has_relic("cd_medium"):
		mult -= 0.10
	if has_relic("cd_large"):
		mult -= 0.20
	return max(mult, 0.1)

func get_aoe_radius_multiplier() -> float:
	var mult = 1.0
	if has_relic("aoe_small"):
		mult += 0.05
	if has_relic("aoe_medium"):
		mult += 0.10
	return mult

func get_max_hp_bonus() -> int:
	var bonus = 0
	if has_relic("hp_small"):
		bonus += 50
	if has_relic("hp_medium"):
		bonus += 100
	return bonus

func get_hp_regen_bonus() -> float:
	var bonus = 0.0
	if has_relic("hp_regen_small"):
		bonus += 0.5
	if has_relic("hp_regen_medium"):
		bonus += 1.0
	return bonus

func get_mana_regen_bonus() -> float:
	var bonus = 0.0
	if has_relic("mana_regen_small"):
		bonus += 1.0
	if has_relic("mana_regen_medium"):
		bonus += 2.0
	return bonus

func _apply_relic_effect(relic_id: String):
	match relic_id:
		"hp_small", "hp_medium":
			Global.max_health = Global.hero_strength * 10.0 + get_max_hp_bonus()
			Global.health = min(Global.health, Global.max_health)
			Global.health_changed.emit(Global.health, Global.max_health)
		"shield":
			_shield_remaining = 1
			_shield_timer = 0.0
		_:
			pass

var _shield_remaining: int = 0
var _shield_timer: float = 0.0
var _shield_cooldown: float = 5.0

func get_shield_active() -> bool:
	return _shield_remaining > 0

func try_consume_shield() -> bool:
	if _shield_remaining > 0:
		_shield_remaining -= 1
		_shield_timer = 0.0
		return true
	return false

func reset_run():
	active_relic_ids.clear()
	_shield_remaining = 0
	_shield_timer = 0.0
	_build_pool()

static func is_relic_level(level: int) -> bool:
	return level == 1 or level % 5 == 0

func _process(delta):
	if has_relic("shield"):
		_shield_timer += delta
		if _shield_remaining <= 0 and _shield_timer >= _shield_cooldown:
			_shield_remaining = 1
			_shield_timer = 0.0

	if Engine.is_editor_hint():
		return
	if not has_relic("auto_magic_missile") and not has_relic("auto_fireball"):
		return

	_auto_cast_timer += delta
	if _auto_cast_timer >= 0.15:
		_auto_cast_timer = 0.0
		_process_auto_cast()

var _auto_cast_timer: float = 0.0

func _process_auto_cast():
	var hero = get_tree().get_first_node_in_group("hero")
	if not hero or not is_instance_valid(hero):
		return
	if Global.is_in_hit_recovery:
		return

	if has_relic("auto_magic_missile"):
		_auto_mm_timer -= 0.15
		if _auto_mm_timer <= 0:
			_auto_mm_timer = 5.0
			_try_auto_cast_skill(hero, "magic_missile")

	if has_relic("auto_fireball"):
		_auto_fb_timer -= 0.15
		if _auto_fb_timer <= 0:
			_auto_fb_timer = 3.5
			_try_auto_cast_skill(hero, "fireball")

var _auto_mm_timer: float = 5.0
var _auto_fb_timer: float = 3.5

func _try_auto_cast_skill(hero: Node, skill_id: String):
	var script_map = {
		"magic_missile": "res://Scripts/Spells/magic_missile.gd",
		"fireball": "res://Scripts/Spells/fireball.gd",
	}
	var path = script_map.get(skill_id)
	if not path:
		return
	var script = load(path)
	if not script:
		return
	var mouse_pos = hero.get_global_mouse_position()
	var dummy_cd = {}
	dummy_cd[skill_id] = 0.0
	script.cast(hero, mouse_pos, dummy_cd)
