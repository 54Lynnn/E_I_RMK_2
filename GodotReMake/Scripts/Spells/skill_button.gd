extends Button

signal skill_upgraded(skill_id)

const MagicMissile = preload("res://Scripts/Spells/magic_missile.gd")
const Fireball = preload("res://Scripts/Spells/fireball.gd")
const FreezingSpear = preload("res://Scripts/Spells/freezing_spear.gd")
const Heal = preload("res://Scripts/Spells/heal.gd")
const Prayer = preload("res://Scripts/Spells/prayer.gd")
const Nova = preload("res://Scripts/Spells/nova.gd")
const PoisonCloud = preload("res://Scripts/Spells/poison_cloud.gd")

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var skill_description: String = ""
@export var texture_path: String = ""
@export var max_level: int = 10
@export var prereq_skill: String = ""

enum Element { BASIC, EARTH, AIR, FIRE, WATER }
@export var element: Element = Element.BASIC

var current_level: int = 0:
	set(value):
		current_level = value
		update_display()

@onready var icon_texture := $VBoxContainer/Icon
@onready var level_label := $VBoxContainer/LevelLabel
@onready var element_bar := $ElementBar
@onready var border := $Border

const ELEMENT_COLORS := {
	Element.BASIC: Color("#C084FC"),
	Element.EARTH: Color("#A08420"),
	Element.AIR: Color("#C8C8C8"),
	Element.FIRE: Color("#D94A2A"),
	Element.WATER: Color("#3B7FFF")
}

const ELEMENT_NAMES := {
	Element.BASIC: "Basic",
	Element.EARTH: "Earth",
	Element.AIR: "Air",
	Element.FIRE: "Fire",
	Element.WATER: "Water"
}

func _ready():
	pressed.connect(_on_pressed)
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		icon_texture.texture = load(texture_path)
	update_display()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if element_bar:
		element_bar.color = ELEMENT_COLORS.get(element, Color("#9370DB"))

func update_display():
	if level_label:
		level_label.text = str(current_level) + "/" + str(max_level)
	if current_level >= max_level:
		disabled = true
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_pressed():
	if Global.skill_points > 0 and current_level < max_level:
		Global.skill_points -= 1
		current_level += 1
		Global.skill_levels[skill_id] = current_level
		Global.skill_level_changed.emit(skill_id, current_level)
		skill_upgraded.emit(skill_id)
		update_display()

func _on_mouse_entered():
	if not skill_description.is_empty():
		show_tooltip()

func _on_mouse_exited():
	hide_tooltip()

func show_tooltip():
	var element_name = ELEMENT_NAMES.get(element, "Basic")
	var text = "[color=#D9A84A]" + skill_name + "[/color]  (Level " + str(current_level) + "/" + str(max_level) + ")\n"
	text += "[color=#AAAAAA]" + skill_description + "[/color]\n"
	text += "[color=#888888]" + element_name + "[/color]\n\n"

	var stats = _get_skill_stats(skill_id, current_level)
	if stats:
		text += "[color=#CCCCCC]Current:[/color]\n"
		for line in stats.current:
			text += "  " + line + "\n"
		if current_level < max_level:
			var next_stats = _get_skill_stats(skill_id, current_level + 1)
			if next_stats:
				text += "\n[color=#4CAF50]Next Level:[/color]\n"
				for line in next_stats.current:
					text += "  " + line + "\n"

	var tooltip = RichTextLabel.new()
	tooltip.name = "Tooltip"
	tooltip.bbcode_enabled = true
	tooltip.text = text
	tooltip.size = Vector2(280, 0)
	tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip.position = Vector2(-140, -120)
	tooltip.add_theme_font_size_override("normal_font_size", 14)
	add_child(tooltip)

func _get_skill_stats(skill_id: String, level: int) -> Dictionary:
	match skill_id:
		"magic_missile":
			var dmg = MagicMissile.get_damage(level) if level > 0 else 0
			var count = MagicMissile.get_missile_count(level) if level > 0 else 1
			var cost = MagicMissile.get_mana_cost(level) if level > 0 else 0
			return {"current": ["Damage: " + str(dmg), "Missiles: " + str(count), "Mana: " + str(cost)]}
		"fireball":
			var dmg = Fireball.get_damage(level) if level > 0 else 0
			var radius = Fireball.get_explosion_radius(level) if level > 0 else 0
			return {"current": ["Damage: " + str(dmg), "Explosion Radius: " + str(radius), "Mana: 7"]}
		"freezing_spear":
			var dmg = FreezingSpear.get_damage(level) if level > 0 else 0
			var count = FreezingSpear.get_spear_count(level) if level > 0 else 1
			var freeze = FreezingSpear.get_freeze_duration(level) if level > 0 else 0
			var cost = FreezingSpear.get_mana_cost(level) if level > 0 else 0
			return {"current": ["Damage: " + str(dmg), "Spears: " + str(count), "Freeze: " + str(freeze) + "s", "Mana: " + str(cost)]}
		"heal":
			var pct = Heal.get_health_restore_percent(level) if level > 0 else 0
			var cd = Heal.get_cooldown(level) if level > 0 else 0
			var cost = Heal.get_mana_cost(level) if level > 0 else 0
			return {"current": ["Restore: " + str(int(pct * 100)) + "% HP", "Cooldown: " + str(cd) + "s", "Mana: " + str(cost)]}
		"prayer":
			var hc = Prayer.get_health_cost_percent(level) if level > 0 else 0
			var mr = Prayer.get_mana_restore_percent(level) if level > 0 else 0
			var cd = Prayer.get_cooldown(level) if level > 0 else 0
			return {"current": ["HP Cost: " + str(int(hc * 100)) + "%", "Mana Restore: " + str(int(mr * 100)) + "%", "Cooldown: " + str(cd) + "s"]}
		"nova":
			var dmg = Nova.get_damage(level) if level > 0 else 0
			var radius = Nova.get_radius(level) if level > 0 else 0
			var freeze = Nova.get_freeze_duration(level) if level > 0 else 0
			var cost = Nova.get_mana_cost(level) if level > 0 else 0
			return {"current": ["Damage: " + str(dmg), "Radius: " + str(radius), "Freeze: " + str(freeze) + "s", "Mana: " + str(cost)]}
		"poison_cloud":
			var dmg = PoisonCloud.get_damage(level) if level > 0 else 0
			var dur = PoisonCloud.get_duration(level) if level > 0 else 0
			var cost = PoisonCloud.get_mana_cost(level) if level > 0 else 0
			return {"current": ["DPS: " + str(dmg), "Duration: " + str(dur) + "s", "Radius: 110", "Mana: " + str(cost)]}
	return {}

func hide_tooltip():
	var tooltip = get_node_or_null("Tooltip")
	if tooltip:
		tooltip.queue_free()
