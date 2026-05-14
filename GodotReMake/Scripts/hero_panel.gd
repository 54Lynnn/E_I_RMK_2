extends Control

@onready var background := $Background
@onready var left_panel := $Background/LeftPanel
@onready var right_panel := $Background/RightPanel
@onready var level_label := $Background/LeftPanel/MarginContainer/ScrollContainer/VBoxContainer/HeaderSection/LevelRow/LevelValue
@onready var exp_label := $Background/LeftPanel/MarginContainer/ScrollContainer/VBoxContainer/HeaderSection/ExpRow/ExpValue
@onready var attr_points_label := $Background/LeftPanel/AttrPointsRow/AttrPointsValue
@onready var skill_points_label := $Background/RightPanel/SkillPointsRow/SkillPointsValue
@onready var stats_container := $Background/LeftPanel/MarginContainer/ScrollContainer/VBoxContainer

@onready var dev_relic_button := $Background/RightPanel/DevRelicButton
@onready var _dev_exp1 := $Background/RightPanel/DevExp1000
@onready var _dev_exp2 := $Background/RightPanel/DevExp5000

var is_open := false

func _ready():
	visible = false
	setup_skill_tree()
	setup_attribute_buttons()
	dev_relic_button.pressed.connect(_on_dev_relic)
	dev_relic_button.visible = false
	_dev_exp1.pressed.connect(_on_dev_exp_1000)
	_dev_exp1.visible = false
	_dev_exp2.pressed.connect(_on_dev_exp_5000)
	_dev_exp2.visible = false

func _input(event):
	if event.is_action_pressed("toggle_hero_panel"):
		if Global.is_pause_menu_open:
			return
		toggle()
	if event.is_action_pressed("toggle_dev_mode"):
		toggle_dev_mode()

func toggle():
	is_open = !is_open
	visible = is_open
	Global.hero_panel_is_open = is_open
	get_tree().paused = is_open
	if is_open:
		update_ui()
	else:
		var dev_relic = get_tree().current_scene.get_node_or_null("DevRelicSelect")
		if dev_relic:
			dev_relic.queue_free()

func toggle_dev_mode():
	Global.dev_mode = !Global.dev_mode
	if Global.dev_mode:
		is_open = true
		Global.hero_panel_is_open = true
		visible = true
		get_tree().paused = true
		update_ui()
	else:
		is_open = false
		visible = false
		get_tree().paused = false
		dev_relic_button.visible = false
		_dev_exp1.visible = false
		_dev_exp2.visible = false
		var dev_relic = get_tree().current_scene.get_node_or_null("DevRelicSelect")
		if dev_relic:
			dev_relic.queue_free()

func _on_dev_relic():
	if not Global.dev_mode:
		return
	var existing = get_tree().current_scene.get_node_or_null("DevRelicSelect")
	if existing:
		existing.queue_free()
	var relics = RelicManager.generate_choices(3, false)
	if relics.is_empty():
		return
	var ui_scene = preload("res://Scenes/RelicSelectUI.tscn")
	var ui = ui_scene.instantiate()
	ui.name = "DevRelicSelect"
	get_tree().current_scene.add_child(ui)
	ui.show_choices_dev(relics)

func _on_dev_exp_1000():
	if not Global.dev_mode:
		return
	Global.gain_experience(1000)
	update_ui()

func _on_dev_exp_5000():
	if not Global.dev_mode:
		return
	Global.gain_experience(5000)
	update_ui()

func update_ui():
	if not is_inside_tree():
		return
	dev_relic_button.visible = Global.dev_mode
	_dev_exp1.visible = Global.dev_mode
	_dev_exp2.visible = Global.dev_mode
	var level_node = get_node_or_null("Background/LeftPanel/MarginContainer/ScrollContainer/VBoxContainer/HeaderSection/LevelRow/LevelValue")
	if level_node:
		level_node.text = str(Global.hero_level)
	var exp_needed = Global.hero_level * 200
	var exp_node = get_node_or_null("Background/LeftPanel/MarginContainer/ScrollContainer/VBoxContainer/HeaderSection/ExpRow/ExpValue")
	if exp_node:
		exp_node.text = str(Global.hero_experience) + " / " + str(exp_needed)
	var attr_node = get_node_or_null("Background/LeftPanel/AttrPointsRow/AttrPointsValue")
	if attr_node:
		attr_node.text = str(Global.attribute_points)
	var skill_pt_node = get_node_or_null("Background/RightPanel/SkillPointsRow/SkillPointsValue")
	if skill_pt_node:
		skill_pt_node.text = str(Global.skill_points)
	update_stats_display()
	update_skill_buttons()

func update_stats_display():
	var attrs = [
		{ "key": "hero_strength", "node": "AttrsSection/StrengthRow", "label": "Strength" },
		{ "key": "hero_dexterity", "node": "AttrsSection/DexterityRow", "label": "Dexterity" },
		{ "key": "hero_stamina", "node": "AttrsSection/StaminaRow", "label": "Stamina" },
		{ "key": "hero_intelligence", "node": "AttrsSection/IntelligenceRow", "label": "Intelligence" },
		{ "key": "hero_wisdom", "node": "AttrsSection/WisdomRow", "label": "Wisdom" }
	]
	for attr in attrs:
		var btn = stats_container.get_node_or_null(attr.node + "/AddButton")
		if btn:
			btn.disabled = Global.attribute_points <= 0
		var label = stats_container.get_node_or_null(attr.node + "/Value")
		if label:
			label.text = str(Global.get(attr.key))

	var health_label = stats_container.get_node_or_null("DerivedSection/HealthRow/Value")
	if health_label:
		health_label.text = str(int(Global.health)) + "/" + str(int(Global.max_health))

	var mana_label = stats_container.get_node_or_null("DerivedSection/ManaRow/Value")
	if mana_label:
		mana_label.text = str(int(Global.mana)) + "/" + str(int(Global.max_mana))

	var health_regen_rate = Global.hero_stamina * 0.1 + RelicManager.get_hp_regen_bonus()
	var health_regen_label = stats_container.get_node_or_null("DerivedSection/HealthRegenRow/Value")
	if health_regen_label:
		health_regen_label.text = format_regen(health_regen_rate)

	var mana_regen_rate = Global.hero_intelligence * 0.06 + Global.hero_wisdom * 0.18 + RelicManager.get_mana_regen_bonus()
	var mana_regen_label = stats_container.get_node_or_null("DerivedSection/ManaRegenRow/Value")
	if mana_regen_label:
		mana_regen_label.text = format_regen(mana_regen_rate)

	var hero_speed = 65.0 + Global.hero_dexterity * 0.5 + Global.hero_stamina * 0.35
	var speed_label = stats_container.get_node_or_null("DerivedSection/SpeedRow/Value")
	if speed_label:
		speed_label.text = format_stat(hero_speed, "speed")

	var hit_recovery = max(0.1, 0.5 - Global.hero_strength * 0.004)
	var hit_recovery_label = stats_container.get_node_or_null("DerivedSection/HitRecoveryRow/Value")
	if hit_recovery_label:
		hit_recovery_label.text = format_stat(hit_recovery, "time")

	var chance = max(0.04, 1.0 - Global.hero_dexterity * 0.004)
	var chance_label = stats_container.get_node_or_null("DerivedSection/ChanceToBeHitRow/Value")
	if chance_label:
		chance_label.text = format_stat(chance * 100, "percent")

func format_regen(value: float) -> String:
	var rating = "slow"
	if value >= 4.0:
		rating = "very fast"
	elif value >= 3.0:
		rating = "fast"
	elif value >= 2.0:
		rating = "normal"
	elif value >= 1.0:
		rating = "slow"
	return str(round(value * 10) / 10) + "/s  (" + rating + ")"

func format_stat(value: float, type: String) -> String:
	if type == "speed":
		var rating = "slow"
		if value >= 120.0:
			rating = "very fast"
		elif value >= 90.0:
			rating = "fast"
		elif value >= 74.0:
			rating = "normal"
		return str(round(value)) + "  (" + rating + ")"
	elif type == "time":
		var rating = "fast"
		if value > 0.4:
			rating = "slow"
		elif value > 0.25:
			rating = "normal"
		return str(round(value * 100) / 100) + "s  (" + rating + ")"
	elif type == "percent":
		var rating = "low"
		if value > 70.0:
			rating = "high"
		elif value > 40.0:
			rating = "moderate"
		elif value > 15.0:
			rating = "low"
		return str(round(value)) + "%  (" + rating + ")"
	return str(round(value * 100) / 100)

func setup_attribute_buttons():
	var attrs = ["strength", "dexterity", "stamina", "intelligence", "wisdom"]
	for attr in attrs:
		var btn = stats_container.get_node_or_null("AttrsSection/" + attr.capitalize() + "Row/AddButton")
		if btn:
			btn.pressed.connect(_on_attribute_added.bind(attr))

func _on_attribute_added(attr: String):
	if Global.attribute_points > 0:
		Global.attribute_points -= 1
		Global.set("hero_" + attr, Global.get("hero_" + attr) + 1)
		match attr:
			"strength":
				Global.apply_strength()
			"dexterity":
				Global.apply_dexterity()
			"stamina":
				Global.apply_stamina()
			"intelligence":
				Global.apply_intelligence()
			"wisdom":
				Global.apply_wisdom()
		update_ui()

const SKILL_BUTTON_SIZE := 46
const CELL_SIZE := 60

var skill_buttons := {}

func setup_skill_tree():
	var skills_container = right_panel.get_node("SkillsContainer")
	var connection_lines = right_panel.get_node("SkillsContainer/ConnectionLines")
	for child in skills_container.get_children():
		if child != connection_lines:
			child.queue_free()
	skill_buttons.clear()

	var skills_data = {
		"magic_missile": {
			"name": "Magic Missile",
			"desc": "Tracking magic projectile",
			"texture": "res://Art/Placeholder/MagicMissile.png",
			"prereq": "",
			"cell": Vector2(3, 3),
			"element": 0
		},
		"prayer": {
			"name": "Prayer",
			"desc": "Sacrifice HP to regain mana over time",
			"texture": "res://Art/Placeholder/Prayer.png",
			"prereq": "magic_missile",
			"cell": Vector2(0, 2),
			"element": 1
		},
		"teleport": {
			"name": "Teleport",
			"desc": "Teleport to cursor position",
			"texture": "res://Art/Placeholder/Teleport.png",
			"prereq": "prayer",
			"cell": Vector2(0, 1),
			"element": 1
		},
		"mistfog": {
			"name": "Mist Fog",
			"desc": "Brown fog slows enemies in area",
			"texture": "res://Art/Placeholder/MistFog.png",
			"prereq": "prayer",
			"cell": Vector2(1, 1),
			"element": 1
		},
		"stone_enchanted": {
			"name": "Stone Enchanted",
			"desc": "Passive: chance to petrify attacker",
			"texture": "res://Art/Placeholder/StoneEnchanted.png",
			"prereq": "teleport",
			"cell": Vector2(0, 0),
			"element": 1
		},
		"wrath_of_god": {
			"name": "Wrath of God",
			"desc": "Hammers strike around hero",
			"texture": "res://Art/Placeholder/WrathOfGod.png",
			"prereq": "teleport",
			"cell": Vector2(1, 0),
			"element": 1
		},
		"telekinesis": {
			"name": "Telekinesis",
			"desc": "Pick up items from distance",
			"texture": "res://Art/Placeholder/Telekinesis.png",
			"prereq": "magic_missile",
			"cell": Vector2(2, 2),
			"element": 2
		},
		"holy_light": {
			"name": "Holy Light",
			"desc": "Light rays damage enemies at cursor",
			"texture": "res://Art/Placeholder/HolyLight.png",
			"prereq": "telekinesis",
			"cell": Vector2(2, 1),
			"element": 2
		},
		"sacrifice": {
			"name": "Sacrifice",
			"desc": "Sacrifice HP to instantly kill an enemy",
			"texture": "res://Art/Placeholder/Sacrifice.png",
			"prereq": "telekinesis",
			"cell": Vector2(3, 1),
			"element": 2
		},
		"ball_lightning": {
			"name": "Ball Lightning",
			"desc": "Orb auto-attacks nearby enemies",
			"texture": "res://Art/Placeholder/BallLightning.png",
			"prereq": "holy_light",
			"cell": Vector2(2, 0),
			"element": 2
		},
		"chain_lightning": {
			"name": "Chain Lightning",
			"desc": "Lightning bounces between enemies",
			"texture": "res://Art/Placeholder/ChainLightning.png",
			"prereq": "holy_light",
			"cell": Vector2(3, 0),
			"element": 2
		},
		"fireball": {
			"name": "Fire Ball",
			"desc": "Fireball explodes on impact",
			"texture": "res://Art/Placeholder/FireBall.png",
			"prereq": "magic_missile",
			"cell": Vector2(4, 2),
			"element": 3
		},
		"heal": {
			"name": "Heal",
			"desc": "Heal over time",
			"texture": "res://Art/Placeholder/Heal.png",
			"prereq": "fireball",
			"cell": Vector2(4, 1),
			"element": 3
		},
		"fire_walk": {
			"name": "Fire Walk",
			"desc": "Leave fire trail that damages enemies",
			"texture": "res://Art/Placeholder/FireWalk.png",
			"prereq": "fireball",
			"cell": Vector2(5, 1),
			"element": 3
		},
		"meteor": {
			"name": "Meteor",
			"desc": "Meteors rain at cursor location",
			"texture": "res://Art/Placeholder/Meteor.png",
			"prereq": "heal",
			"cell": Vector2(4, 0),
			"element": 3
		},
		"armageddon": {
			"name": "Armageddon",
			"desc": "Random fireblasts across the map",
			"texture": "res://Art/Placeholder/Armageddon.png",
			"prereq": "heal",
			"cell": Vector2(5, 0),
			"element": 3
		},
		"freezing_spear": {
			"name": "Freezing Spear",
			"desc": "Ice spear pierces and freezes enemies",
			"texture": "res://Art/Placeholder/FreezingSpear.png",
			"prereq": "magic_missile",
			"cell": Vector2(6, 2),
			"element": 4
		},
		"poison_cloud": {
			"name": "Poison Cloud",
			"desc": "Poison gas damages enemies in area",
			"texture": "res://Art/Placeholder/PoisonCloud.png",
			"prereq": "freezing_spear",
			"cell": Vector2(6, 1),
			"element": 4
		},
		"fortuna": {
			"name": "Fortuna",
			"desc": "Passive: increase item drop chance",
			"texture": "res://Art/Placeholder/Fortuna.png",
			"prereq": "freezing_spear",
			"cell": Vector2(7, 1),
			"element": 4
		},
		"dark_ritual": {
			"name": "Dark Ritual",
			"desc": "Dark zone may instantly kill enemies inside",
			"texture": "res://Art/Placeholder/DarkRitual.png",
			"prereq": "poison_cloud",
			"cell": Vector2(6, 0),
			"element": 4
		},
		"nova": {
			"name": "Nova",
			"desc": "Ice nova freezes nearby enemies",
			"texture": "res://Art/Placeholder/Nova.png",
			"prereq": "poison_cloud",
			"cell": Vector2(7, 0),
			"element": 4
		}
	}

	var container_width = skills_container.size.x
	var container_height = skills_container.size.y
	var total_width = 8 * CELL_SIZE
	var total_height = 4 * CELL_SIZE
	var offset_x = (container_width - total_width) / 2
	var offset_y = (container_height - total_height) / 2

	for skill_id in skills_data:
		var data = skills_data[skill_id]
		var cell = data.cell
		var x = offset_x + cell.x * CELL_SIZE
		var y = offset_y + cell.y * CELL_SIZE
		create_skill_button(skill_id, data, skills_container, Vector2(x, y))

	call_deferred("draw_connection_lines")

func create_skill_button(skill_id: String, skill_data: Dictionary, parent: Node, pos: Vector2):
	var btn = preload("res://Scenes/SkillButton.tscn").instantiate()
	btn.skill_id = skill_id
	btn.skill_name = skill_data.name
	btn.skill_description = skill_data.desc
	btn.texture_path = skill_data.texture
	btn.current_level = Global.skill_levels.get(skill_id, 0)
	btn.prereq_skill = skill_data.prereq
	btn.element = skill_data.get("element", 0)
	btn.skill_upgraded.connect(_on_skill_upgraded)
	btn.custom_minimum_size = Vector2(SKILL_BUTTON_SIZE, SKILL_BUTTON_SIZE)
	btn.size = Vector2(SKILL_BUTTON_SIZE, SKILL_BUTTON_SIZE)
	btn.position = pos
	parent.add_child(btn)
	skill_buttons[skill_id] = btn

func draw_connection_lines():
	var connection_lines = right_panel.get_node("SkillsContainer/ConnectionLines")
	if not connection_lines:
		return
	for child in connection_lines.get_children():
		child.queue_free()

	for skill_id in skill_buttons:
		var btn = skill_buttons[skill_id]
		var prereq_id = btn.prereq_skill
		if prereq_id != "" and skill_buttons.has(prereq_id):
			var prereq_btn = skill_buttons[prereq_id]
			var start_pos = prereq_btn.global_position - connection_lines.global_position + prereq_btn.size / 2
			var end_pos = btn.global_position - connection_lines.global_position + btn.size / 2
			var line = Line2D.new()
			line.width = 2.0

			var has_prereq = Global.skill_levels.get(prereq_id, 0) > 0
			line.default_color = Color(0.85, 0.65, 0.2, 0.9) if has_prereq else Color(0.4, 0.35, 0.25, 0.5)

			if start_pos.x == end_pos.x:
				line.add_point(start_pos)
				line.add_point(end_pos)
			else:
				var mid_y = start_pos.y + (end_pos.y - start_pos.y) * 0.5
				line.add_point(start_pos)
				line.add_point(Vector2(start_pos.x, mid_y))
				line.add_point(Vector2(end_pos.x, mid_y))
				line.add_point(end_pos)
			connection_lines.add_child(line)

func update_skill_buttons():
	var skills_container = right_panel.get_node("SkillsContainer")
	var connection_lines = right_panel.get_node("SkillsContainer/ConnectionLines")
	for child in skills_container.get_children():
		if child == connection_lines:
			continue
		if child.has_method("update_display"):
			child.current_level = Global.skill_levels.get(child.skill_id, 0)
			var prereq = child.prereq_skill
			if prereq != "":
				var prereq_level = Global.skill_levels.get(prereq, 0)
				child.disabled = prereq_level <= 0
				if prereq_level <= 0:
					child.modulate = Color(0.3, 0.3, 0.3, 1.0)
				else:
					child.modulate = Color(1.0, 1.0, 1.0, 1.0)
			else:
				child.disabled = false
				child.modulate = Color(1.0, 1.0, 1.0, 1.0)
	call_deferred("draw_connection_lines")

func _on_skill_upgraded(skill_id: String):
	update_ui()
