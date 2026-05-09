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
