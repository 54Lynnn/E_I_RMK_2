extends Button

signal skill_upgraded(skill_id)
signal right_clicked(skill_id)

const MagicMissile = preload("res://Scripts/Spells/magic_missile.gd")
const Fireball = preload("res://Scripts/Spells/fireball.gd")
const FreezingSpear = preload("res://Scripts/Spells/freezing_spear.gd")
const Heal = preload("res://Scripts/Spells/heal.gd")
const Prayer = preload("res://Scripts/Spells/prayer.gd")
const Nova = preload("res://Scripts/Spells/nova.gd")
const PoisonCloud = preload("res://Scripts/Spells/poison_cloud.gd")
const HolyLight = preload("res://Scripts/Spells/holy_light.gd")
const ChainLightning = preload("res://Scripts/Spells/chain_lightning.gd")
const Teleport = preload("res://Scripts/Spells/teleport.gd")
const MistFog = preload("res://Scripts/Spells/mistfog.gd")
const WrathOfGod = preload("res://Scripts/Spells/wrath_of_god.gd")
const Telekinesis = preload("res://Scripts/Spells/telekinesis.gd")
const Sacrifice = preload("res://Scripts/Spells/sacrifice.gd")
const BallLightning = preload("res://Scripts/Spells/ball_lightning.gd")
const FireWalk = preload("res://Scripts/Spells/fire_walk.gd")
const Meteor = preload("res://Scripts/Spells/meteor.gd")
const Armageddon = preload("res://Scripts/Spells/armageddon.gd")
const DarkRitual = preload("res://Scripts/Spells/dark_ritual.gd")
const StoneEnchanted = preload("res://Scripts/Spells/stone_enchanted.gd")
const Fortuna = preload("res://Scripts/Spells/fortuna.gd")

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

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		right_clicked.emit(skill_id)
		get_viewport().set_input_as_handled()

func _on_pressed():
	if Global.skill_points > 0 and current_level < max_level:
		Global.skill_points -= 1
		current_level += 1
		Global.skill_levels[skill_id] = current_level
		Global.skill_level_changed.emit(skill_id, current_level)
		skill_upgraded.emit(skill_id)
		update_display()

var _tooltip_hovering := false
var _tooltip_timer: SceneTreeTimer = null

func _on_mouse_entered():
	_tooltip_hovering = true
	if _tooltip_timer:
		_tooltip_timer.timeout.disconnect(_on_tooltip_timer_timeout)
	_tooltip_timer = get_tree().create_timer(0.2)
	_tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)

func _on_tooltip_timer_timeout():
	if is_instance_valid(self) and _tooltip_hovering:
		show_tooltip()

func _on_mouse_exited():
	_tooltip_hovering = false
	if _tooltip_timer:
		_tooltip_timer.timeout.disconnect(_on_tooltip_timer_timeout)
		_tooltip_timer = null
	_hide_skill_tooltip()

func show_tooltip():
	_hide_skill_tooltip()
	var element_name = ELEMENT_NAMES.get(element, "Basic")
	var text = "[color=#D9A84A]" + skill_name + "[/color]\n"
	text += "[color=#FFD700]LV" + str(current_level) + "/" + str(max_level) + "[/color]  [" + element_name + "]\n\n"
	text += "[color=#AAAAAA]" + skill_description + "[/color]\n\n"

	var stats = _get_skill_stats(skill_id, current_level)
	if stats:
		text += "[color=#CCCCCC]Current Level:[/color]\n"
		for line in stats.current:
			text += "  " + line + "\n"
		if current_level < max_level:
			var next_stats = _get_skill_stats(skill_id, current_level + 1)
			if next_stats:
				text += "\n[color=#4CAF50]Next Level (" + str(current_level + 1) + "):[/color]\n"
				for line in next_stats.current:
					text += "  " + line + "\n"

	var tooltip = RichTextLabel.new()
	tooltip.name = "Tooltip"
	tooltip.bbcode_enabled = true
	tooltip.fit_content = true
	tooltip.text = text
	tooltip.custom_minimum_size = Vector2(280, 0)
	tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip.add_theme_font_size_override("normal_font_size", 14)
	tooltip.add_theme_stylebox_override("normal", _create_tooltip_bg())
	tooltip.z_index = 100
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.position = get_local_mouse_position() - Vector2(145, -20)
	add_child(tooltip)

func _hide_skill_tooltip():
	var tooltip = get_node_or_null("Tooltip")
	if tooltip:
		tooltip.queue_free()

func _create_tooltip_bg() -> StyleBoxFlat:
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.08, 0.05, 0.95)
	bg.border_width_left = 2
	bg.border_width_right = 2
	bg.border_width_top = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(0.7, 0.55, 0.2, 1.0)
	bg.content_margin_left = 6
	bg.content_margin_right = 6
	bg.content_margin_top = 4
	bg.content_margin_bottom = 4
	return bg

func _get_skill_stats(skill_id: String, level: int) -> Dictionary:
	match skill_id:
		"magic_missile":
			var dmg = MagicMissile.get_damage(level) if level > 0 else 0
			var count = MagicMissile.get_missile_count(level) if level > 0 else 1
			var cost = MagicMissile.get_mana_cost(level) if level > 0 else 0
			return {"current": ["Damage: " + str(dmg), "Missiles: " + str(count), "Mana: " + str(cost), "Cooldown: 1.0s"]}
		"fireball":
			var dmg = Fireball.get_damage(level) if level > 0 else 0
			var radius = Fireball.get_explosion_radius(level) if level > 0 else 0
			var cost = Fireball.get_mana_cost(level) if level > 0 else 0
			return {"current": ["Damage: " + str(dmg), "Radius: " + str(radius), "Mana: " + str(cost), "Cooldown: 0.5s"]}
		"freezing_spear":
			var dmg = FreezingSpear.get_damage(level) if level > 0 else 0
			var count = FreezingSpear.get_spear_count(level) if level > 0 else 1
			var freeze = FreezingSpear.get_freeze_duration(level) if level > 0 else 0
			var cost = FreezingSpear.get_mana_cost(level) if level > 0 else 0
			return {"current": ["Damage: " + str(dmg), "Spears: " + str(count), "Freeze: " + str(freeze) + "s", "Mana: " + str(cost), "Cooldown: 1.0s"]}
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
			return {"current": ["Damage: " + str(dmg), "Radius: " + str(radius), "Freeze: " + str(freeze) + "s", "Mana: " + str(cost), "Cooldown: 2.0s"]}
		"poison_cloud":
			var dmg = PoisonCloud.get_damage(level) if level > 0 else 0
			var dur = PoisonCloud.get_duration(level) if level > 0 else 0
			var cost = PoisonCloud.get_mana_cost(level) if level > 0 else 0
			return {"current": ["DPS: " + str(dmg), "Duration: " + str(dur) + "s", "Radius: 110", "Mana: " + str(cost), "Cooldown: 5.0s"]}
		"holy_light":
			var dmg = HolyLight.get_damage(level) if level > 0 else 0
			var beams = HolyLight.get_beam_count(level) if level > 0 else 3
			var cost = HolyLight.get_mana_cost(level) if level > 0 else 0
			return {"current": ["Damage: " + str(dmg), "Beams: " + str(beams), "Mana: " + str(cost), "Cooldown: 1.0s"]}
		"chain_lightning":
			var dmg = ChainLightning.get_damage(level) if level > 0 else 0
			var cost = ChainLightning.get_mana_cost(level) if level > 0 else 0
			var cd = ChainLightning.get_cooldown(level) if level > 0 else 0
			return {"current": ["Damage: " + str(dmg), "Mana: " + str(cost), "Cooldown: " + str(cd) + "s"]}
		"teleport":
			var cost = Teleport.get_mana_cost(level) if level > 0 else 35
			var cd = Teleport.get_cooldown(level) if level > 0 else 20
			return {"current": ["Teleport to cursor location", "Mana: " + str(cost), "Cooldown: " + str(cd) + "s"]}
		"mistfog":
			var cost = MistFog.get_mana_cost(level) if level > 0 else 25
			var slow = MistFog.get_slow_factor(level) if level > 0 else 0.35
			return {"current": ["Slows enemies in area", "Slow: " + str(int(slow * 100)) + "%", "Range: 150", "Duration: 20s", "Mana: " + str(cost), "Cooldown: 5.0s"]}
		"wrath_of_god":
			var dmg = WrathOfGod.get_damage(level) if level > 0 else 0
			var cost = WrathOfGod.get_mana_cost(level) if level > 0 else 0
			var cd = WrathOfGod.get_cooldown(level) if level > 0 else 0
			return {"current": ["10 hammers strike around hero", "Damage: " + str(dmg), "Mana: " + str(cost), "Cooldown: " + str(cd) + "s"]}
		"telekinesis":
			var hold = Telekinesis.get_hold_time(level) if level > 0 else 1.0
			return {"current": ["Hold cursor over a dropped item to pick it up from afar", "Hold Time: " + str(hold) + "s (no range limit)"]}
		"sacrifice":
			var hp_cost = Sacrifice.get_health_cost_percent(level) if level > 0 else 0.55
			var dmg = Sacrifice.get_damage(level) if level > 0 else 0
			var cd = Sacrifice.get_cooldown(level) if level > 0 else 3.0
			return {"current": ["Sacrifice HP to instantly kill enemy", "HP Cost: " + str(int(hp_cost * 100)) + "%", "Range: 50", "Cooldown: " + str(cd) + "s"]}
		"ball_lightning":
			var dmg = BallLightning.get_damage(level) if level > 0 else 0
			var cost = BallLightning.get_mana_cost(level) if level > 0 else 0
			var cd = BallLightning.get_cooldown(level) if level > 0 else 0
			return {"current": ["Orb auto-attacks nearby enemies", "Damage: " + str(dmg), "Strikes: 5", "Duration: 10s", "Mana: " + str(cost), "Cooldown: " + str(cd) + "s"]}
		"fire_walk":
			var dmg = FireWalk.get_damage(level) if level > 0 else 0
			var tick_dmg = snapped(dmg * 0.1, 0.1)
			return {"current": ["Toggle skill - press U to toggle on/off", "Leave damaging fire trail while moving", "DPS: " + str(dmg) + " (" + str(tick_dmg) + "/0.1s)", "Duration: 2s per flame", "No mana cost"]}
		"meteor":
			var dmg = Meteor.get_damage(level) if level > 0 else 0
			var cost = Meteor.get_mana_cost(level) if level > 0 else 0
			var cd = Meteor.get_cooldown(level) if level > 0 else 0
			return {"current": ["Meteors rain at cursor location", "Damage: " + str(dmg), "Radius: 130", "Duration: 3s", "Mana: " + str(cost), "Cooldown: " + str(cd) + "s"]}
		"armageddon":
			var dmg = Armageddon.get_damage(level) if level > 0 else 0
			var cost = Armageddon.get_mana_cost(level) if level > 0 else 0
			var cd = Armageddon.get_cooldown(level) if level > 0 else 0
			return {"current": ["Random fireblasts across the map", "Damage: " + str(dmg), "Duration: 10s", "Mana: " + str(cost), "Cooldown: " + str(cd) + "s"]}
		"dark_ritual":
			var chance = DarkRitual.get_instant_kill_chance(level) if level > 0 else 0.30
			var cost = DarkRitual.get_mana_cost(level) if level > 0 else 0
			var cd = DarkRitual.get_cooldown(level) if level > 0 else 0
			var dur = DarkRitual.get_duration(level) if level > 0 else 0
			return {"current": ["Dark zone may instantly kill enemies", "Chance: " + str(int(chance * 100)) + "%", "Duration: " + str(dur) + "s", "Mana: " + str(cost), "Cooldown: " + str(cd) + "s"]}
		"stone_enchanted":
			var chance = StoneEnchanted.get_petrify_chance(level) if level > 0 else 0.15
			var dur = StoneEnchanted.get_petrify_duration(level) if level > 0 else 1.0
			return {"current": ["Passive: chance to petrify attacker", "Chance: " + str(int(chance * 100)) + "%", "Duration: " + str(dur) + "s"]}
		"fortuna":
			var bonus = Fortuna.get_drop_rate_bonus(level) if level > 0 else 0.0
			return {"current": ["Passive: increased item drop chance", "Drop Rate: +" + str(int(bonus * 100)) + "%"]}
	return {}

func hide_tooltip():
	var tooltip = get_node_or_null("Tooltip")
	if tooltip:
		tooltip.queue_free()
