extends Area2D

enum ItemType {
	HEALTH_POTION,
	MANA_POTION,
	REJUVENATION,
	HASTE,
	TOME_OF_EXPERIENCE,
	MAGIC_SHIELD,
	PHYSIC_SHIELD,
	QUAD_DAMAGE,
	FREE_SPELLS,
	ATTRIBUTE_POINT,
	SKILL_POINT,
	INVULNERABILITY
}

@export var item_type: ItemType = ItemType.HEALTH_POTION
@export var lifetime := 10.0

const TEXTURE_PATH := "res://Art/Placeholder/Bonus%s.png"

@onready var sprite := $Sprite2D
@onready var progress_bar := $ProgressBar

var hover_time := 0.0
var is_hovered := false

func _ready():
	add_to_group("pickup_items")
	body_entered.connect(_on_body_entered)

	z_index = 3

	load_texture()
	_setup_progress_bar()

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0).set_delay(lifetime - 1.0)
	tween.tween_callback(queue_free)

func _setup_progress_bar():
	progress_bar.visible = false
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0

func _process(delta):
	_check_mouse_hover(delta)

func _check_mouse_hover(delta):
	var telekinesis_level = Global.skill_levels.get("telekinesis", 0)
	if telekinesis_level <= 0:
		return

	var mouse_pos = get_global_mouse_position()
	var dist = global_position.distance_to(mouse_pos)
	var pickup_radius = max(sprite.texture.get_size().x * sprite.scale.x, sprite.texture.get_size().y * sprite.scale.y) * 0.5

	if dist <= pickup_radius:
		if not is_hovered:
			is_hovered = true
			hover_time = 0.0
			progress_bar.visible = true
		else:
			var required_time = _get_cast_time(telekinesis_level)
			hover_time += delta
			var progress = (hover_time / required_time) * 100.0
			progress_bar.value = min(progress, 100.0)
			if hover_time >= required_time:
				apply_effect()
				queue_free()
	else:
		is_hovered = false
		hover_time = 0.0
		progress_bar.visible = false
		progress_bar.value = 0.0

func _get_cast_time(level: int) -> float:
	match level:
		1: return 1.0
		2: return 0.91
		3: return 0.83
		4: return 0.76
		5: return 0.70
		6: return 0.65
		7: return 0.61
		8: return 0.58
		9: return 0.56
		10: return 0.55
		_: return 1.0

func get_item_name() -> String:
	match item_type:
		ItemType.HEALTH_POTION: return "Health"
		ItemType.MANA_POTION: return "Mana"
		ItemType.REJUVENATION: return "Rejuvenation"
		ItemType.HASTE: return "Speed"
		ItemType.TOME_OF_EXPERIENCE: return "Experience"
		ItemType.MAGIC_SHIELD: return "MagicResist"
		ItemType.PHYSIC_SHIELD: return "PhysicResist"
		ItemType.QUAD_DAMAGE: return "QuadDamage"
		ItemType.FREE_SPELLS: return "FreeSpells"
		ItemType.ATTRIBUTE_POINT: return "AttributePoint"
		ItemType.SKILL_POINT: return "SkillPoint"
		ItemType.INVULNERABILITY: return "Immunity"
		_: return ""

func load_texture():
	var item_name = get_item_name()
	if item_name.is_empty():
		return
	var path = TEXTURE_PATH % item_name
	if ResourceLoader.exists(path):
		sprite.texture = load(path)

func _on_body_entered(body: Node2D):
	if body.is_in_group("hero"):
		apply_effect()
		queue_free()

func apply_effect():
	match item_type:
		ItemType.HEALTH_POTION:
			# 生命药水：每秒恢复10%生命值，持续5秒
			Global.apply_buff("health_regen", 5.0, {"percent_per_second": 0.1})
		ItemType.MANA_POTION:
			# 法力药水：每秒恢复10%法力值，持续5秒
			Global.apply_buff("mana_regen", 5.0, {"percent_per_second": 0.1})
		ItemType.REJUVENATION:
			# 恢复药水：立即恢复50%生命和法力
			Global.heal(Global.max_health * 0.5)
			Global.restore_mana(Global.max_mana * 0.5)
		ItemType.HASTE:
			# 加速药水：速度+40%，持续15秒
			Global.apply_buff("speed_boost", 15.0, {"multiplier": 1.4})
		ItemType.TOME_OF_EXPERIENCE:
			# 经验之书：获得下一级所需经验的20%
			var exp_to_next = Global.hero_level * 200
			Global.gain_experience(int(exp_to_next * 0.2))
		ItemType.MAGIC_SHIELD:
			# 魔法护盾：80%魔法减伤，持续15秒
			Global.apply_buff("magic_shield", 15.0, {"resist": 0.8})
		ItemType.PHYSIC_SHIELD:
			# 物理护盾：80%物理减伤，持续15秒
			Global.apply_buff("physic_shield", 15.0, {"resist": 0.8})
		ItemType.QUAD_DAMAGE:
			# 四倍伤害：伤害×4，持续15秒
			Global.apply_buff("damage_boost", 15.0, {"multiplier": 4.0})
		ItemType.FREE_SPELLS:
			# 免费施法：不消耗法力，持续15秒
			Global.apply_buff("free_spells", 15.0)
		ItemType.ATTRIBUTE_POINT:
			# 属性点药水：+5属性点
			Global.attribute_points += 5
		ItemType.SKILL_POINT:
			# 技能点药水：+1技能点
			Global.skill_points += 1
		ItemType.INVULNERABILITY:
			# 无敌药水：无敌15秒
			Global.apply_buff("invulnerability", 15.0)
