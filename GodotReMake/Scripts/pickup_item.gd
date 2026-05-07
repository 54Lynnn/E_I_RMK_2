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

func _ready():
	body_entered.connect(_on_body_entered)
	load_texture()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0).set_delay(lifetime - 1.0)
	tween.tween_callback(queue_free)

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
			Global.heal_over_time(Global.max_health * 0.5, 5.0)
		ItemType.MANA_POTION:
			Global.restore_mana_over_time(Global.max_mana * 0.5, 5.0)
		ItemType.REJUVENATION:
			Global.heal(Global.max_health * 0.5)
			Global.restore_mana(Global.max_mana * 0.5)
		ItemType.HASTE:
			Global.activate_speed_boost(1.4, 15.0)
		ItemType.TOME_OF_EXPERIENCE:
			Global.gain_experience(int(Global.hero_level * 100 * 0.2))
		ItemType.MAGIC_SHIELD:
			Global.activate_magic_shield(0.8, 15.0)
		ItemType.PHYSIC_SHIELD:
			Global.activate_physic_shield(0.8, 15.0)
		ItemType.QUAD_DAMAGE:
			Global.activate_damage_boost(4.0, 15.0)
		ItemType.FREE_SPELLS:
			Global.activate_free_spells(15.0)
		ItemType.ATTRIBUTE_POINT:
			Global.attribute_points += 5
		ItemType.SKILL_POINT:
			Global.skill_points += 1
		ItemType.INVULNERABILITY:
			Global.activate_invulnerability(15.0)
