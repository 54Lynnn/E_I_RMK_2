extends CanvasLayer

# ============================================
# HUD.gd - Infernal 风格游戏界面控制器
# ============================================
# 底部 HUD 约 62px 高（原 86px → 压缩）
# 左侧 HP/MP 条（6px）+ 中间 18 技能双排 + 右侧 2×2 快捷槽
# 底部全宽 EXP 条 + 居中 LEVEL X
# 无头像、无百分比标签、无 TipsLabel
# ============================================

@onready var hp_bar := $BottomBar/LeftInfo/HPBar
@onready var mp_bar := $BottomBar/LeftInfo/MPBar
@onready var exp_bar := $BottomBar/ExpBar
@onready var exp_label := $BottomBar/ExpLabel
@onready var health_label := $BottomBar/LeftInfo/HPLabel
@onready var mana_label := $BottomBar/LeftInfo/MPLabel
@onready var hp_percent_label := $BottomBar/LeftInfo/HPPercentLabel
@onready var mp_percent_label := $BottomBar/LeftInfo/MPPercentLabel

@onready var skill_row1 := $BottomBar/SkillSection/SkillRow1

@onready var quick_slot_lmb_icon := $BottomBar/QuickSlots/SlotLMB/SlotLMBIcon
@onready var quick_slot_rmb_icon := $BottomBar/QuickSlots/SlotRMB/SlotRMBIcon
@onready var quick_slot_shift_icon := $BottomBar/QuickSlots/SlotShift/SlotShiftIcon
@onready var quick_slot_space_icon := $BottomBar/QuickSlots/SlotSpace/SlotSpaceIcon

var hovered_skill_id := ""

@onready var buff_container := $BottomBar/BuffContainer
@onready var relic_container := $RelicContainer

const BuffIconScene = preload("res://Scenes/BuffIcon.tscn")
var buff_icons := {}

@onready var damage_overlay := $DamageOverlay

# ============================================
# 技能栏配置
# ============================================

const SKILL_ICON_SIZE := 34

const SKILL_BAR_SKILL_DATA := {
	"magic_missile": {"name": "Magic Missile", "texture": "res://Art/Placeholder/MagicMissile.png", "input": "LMB"},
	"prayer": {"name": "Prayer", "texture": "res://Art/Placeholder/Prayer.png", "input": "X"},
	"teleport": {"name": "Teleport", "texture": "res://Art/Placeholder/Teleport.png", "input": "2"},
	"mistfog": {"name": "Mist Fog", "texture": "res://Art/Placeholder/MistFog.png", "input": "3"},
	"stone_enchanted": {"name": "Stone Enchanted", "texture": "res://Art/Placeholder/StoneEnchanted.png", "input": ""},
	"wrath_of_god": {"name": "Wrath of God", "texture": "res://Art/Placeholder/WrathOfGod.png", "input": "4"},
	"telekinesis": {"name": "Telekinesis", "texture": "res://Art/Placeholder/Telekinesis.png", "input": "Q"},
	"sacrifice": {"name": "Sacrifice", "texture": "res://Art/Placeholder/Sacrifice.png", "input": "R"},
	"holy_light": {"name": "Holy Light", "texture": "res://Art/Placeholder/HolyLight.png", "input": "E"},
	"fireball": {"name": "Fire Ball", "texture": "res://Art/Placeholder/FireBall.png", "input": "RMB"},
	"ball_lightning": {"name": "Ball Lightning", "texture": "res://Art/Placeholder/BallLightning.png", "input": "I"},
	"chain_lightning": {"name": "Chain Lightning", "texture": "res://Art/Placeholder/ChainLightning.png", "input": "O"},
	"heal": {"name": "Heal", "texture": "res://Art/Placeholder/Heal.png", "input": "C"},
	"fire_walk": {"name": "Fire Walk", "texture": "res://Art/Placeholder/FireWalk.png", "input": "U"},
	"meteor": {"name": "Meteor", "texture": "res://Art/Placeholder/Meteor.png", "input": "F"},
	"armageddon": {"name": "Armageddon", "texture": "res://Art/Placeholder/Armageddon.png", "input": "G"},
	"freezing_spear": {"name": "Freezing Spear", "texture": "res://Art/Placeholder/FreezingSpear.png", "input": "Z"},
	"poison_cloud": {"name": "Poison Cloud", "texture": "res://Art/Placeholder/PoisonCloud.png", "input": "H"},
	"fortuna": {"name": "Fortuna", "texture": "res://Art/Placeholder/Fortuna.png", "input": "V"},
	"dark_ritual": {"name": "Dark Ritual", "texture": "res://Art/Placeholder/DarkRitual.png", "input": "B"},
	"nova": {"name": "Nova", "texture": "res://Art/Placeholder/Nova.png", "input": "N"},
}

var skill_bar_buttons := {}
var skill_cooldown_overlays := {}
var skill_cooldown_peaks := {}

const SKILL_COOLDOWN_KEY_MAP := {
	"magic_missile": "magic_missile",
	"prayer": "prayer",
	"teleport": "teleport",
	"mistfog": "mistfog",
	"stone_enchanted": "stone_enchanted",
	"wrath_of_god": "wrath_of_god",
	"telekinesis": "telekinesis",
	"sacrifice": "sacrifice",
	"holy_light": "holy_light",
	"fireball": "fireball",
	"ball_lightning": "ball_lightning",
	"chain_lightning": "chain_lightning",
	"heal": "heal",
	"fire_walk": "fire_walk",
	"meteor": "meteor",
	"armageddon": "armageddon",
	"freezing_spear": "freezing_spear",
	"poison_cloud": "poison_cloud",
	"fortuna": "fortuna",
	"dark_ritual": "dark_ritual",
	"nova": "nova",
}

var _alt_was_pressed := false

# 缓存 StyleBox 实例（避免重复创建）
var _default_slot_style: StyleBoxFlat = null
var _active_slot_style: StyleBoxFlat = null
var _dashed_ring_texture_cache: ImageTexture = null

# 冷却UI更新节流（不需要每帧刷新，10次/秒足够）
var _cooldown_skip_counter := 0
const COOLDOWN_UPDATE_INTERVAL := 6

# ============================================
# 生命周期
# ============================================

func _ready():
	add_to_group("hud")
	skill_row1.process_mode = PROCESS_MODE_ALWAYS
	
	Global.health_changed.connect(_on_health_changed)
	Global.mana_changed.connect(_on_mana_changed)
	Global.experience_changed.connect(_on_experience_changed)
	Global.level_changed.connect(_on_level_changed)
	Global.skill_level_changed.connect(_on_skill_level_changed)
	
	$BottomBar.mouse_entered.connect(func(): Global.is_mouse_over_hud = true)
	$BottomBar.mouse_exited.connect(func(): Global.is_mouse_over_hud = false)
	
	_init_skill_buttons()
	_setup_damage_shader()
	update_all()
	_update_quick_slot_display()
	_update_auto_cast_display()
	Global.auto_cast_changed.connect(_on_auto_cast_changed)
	RelicManager.active_relics_changed.connect(_update_relic_display)
	_update_relic_display()

func _process(delta):
	_update_buff_display()
	_cooldown_skip_counter += 1
	if _cooldown_skip_counter >= COOLDOWN_UPDATE_INTERVAL:
		_cooldown_skip_counter = 0
		_update_skill_cooldowns(delta)
	_update_damage_overlay(delta)
	_check_alt_toggle()
	_update_firewalk_toggle_icon()

func _input(event):
	if event.is_action_pressed("toggle_monster_health"):
		_toggle_monster_info()
		get_viewport().set_input_as_handled()

func _check_alt_toggle():
	var alt_down = Input.is_key_pressed(KEY_ALT)
	if alt_down and not _alt_was_pressed:
		_alt_was_pressed = true
		_toggle_monster_info()
	elif not alt_down:
		_alt_was_pressed = false

func _toggle_monster_info():
	Global.show_monster_info = not Global.show_monster_info
	_update_monster_hp_visibility()

# ============================================
# 技能栏设置（单排）
# ============================================

func _init_skill_buttons():
	if not skill_row1:
		return
	
	skill_bar_buttons.clear()
	
	for btn in skill_row1.get_children():
		if not btn is Button or not btn.has_meta("skill_id"):
			continue
		
		var skill_id = btn.get_meta("skill_id")
		var data = SKILL_BAR_SKILL_DATA.get(skill_id, {})
		if data.is_empty():
			continue
		
		btn.tooltip_text = data.name
		
		var icon = btn.get_node_or_null("Icon")
		if icon and icon is TextureRect:
			var texture_path = data.get("texture", "")
			if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
				icon.texture = load(texture_path)
			btn.set_meta("icon_node", icon)
		
		var bg = ColorRect.new()
		bg.name = "SkillBg"
		bg.color = Color(0.102, 0.039, 0.02, 1.0)
		bg.size = Vector2(SKILL_ICON_SIZE, SKILL_ICON_SIZE)
		bg.position = Vector2(1, 1)
		btn.add_child(bg)
		btn.move_child(bg, 0)
		
		var border = ReferenceRect.new()
		border.name = "SkillBorder"
		border.size = Vector2(SKILL_ICON_SIZE, SKILL_ICON_SIZE)
		border.position = Vector2(1, 1)
		border.border_color = Color(0.267, 0.067, 0.0, 1.0)
		border.border_width = 1.0
		border.editor_only = false
		btn.add_child(border)
		btn.move_child(border, 1)
		
		var overlay = preload("res://Scripts/cooldown_overlay.gd").new()
		overlay.name = "CooldownOverlay"
		overlay.mouse_filter = Control.MOUSE_FILTER_PASS
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.set_progress(0.0)
		btn.add_child(overlay)
		skill_cooldown_overlays[skill_id] = overlay
		
		var auto_cast_ring = TextureRect.new()
		auto_cast_ring.name = "AutoCastRing"
		auto_cast_ring.texture = _create_dashed_ring_texture(SKILL_ICON_SIZE)
		auto_cast_ring.set_anchors_preset(Control.PRESET_FULL_RECT)
		auto_cast_ring.pivot_offset = Vector2(SKILL_ICON_SIZE * 0.5, SKILL_ICON_SIZE * 0.5)
		auto_cast_ring.mouse_filter = Control.MOUSE_FILTER_PASS
		auto_cast_ring.visible = false
		btn.add_child(auto_cast_ring)
		
		var ring_tween = btn.create_tween()
		ring_tween.set_loops()
		ring_tween.tween_property(auto_cast_ring, "rotation", TAU, 1.5).as_relative()
		ring_tween.stop()
		btn.set_meta("ring_tween", ring_tween)
		
		btn.gui_input.connect(_on_skill_button_gui_input.bind(skill_id))
		btn.mouse_entered.connect(_on_skill_button_hovered.bind(skill_id))
		btn.mouse_exited.connect(_on_skill_button_unhovered.bind(skill_id))
		
		skill_bar_buttons[skill_id] = btn
	
	update_skill_bar_display()

func update_skill_bar_display():
	for skill_id in skill_bar_buttons:
		var btn = skill_bar_buttons[skill_id]
		var icon = btn.get_meta("icon_node") as TextureRect
		var level = Global.skill_levels.get(skill_id, 0)
		
		if level >= 1:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if icon:
				icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.disabled = false
		else:
			btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
			if icon:
				icon.modulate = Color(0.5, 0.5, 0.5, 0.7)
			btn.disabled = true

func _update_firewalk_toggle_icon():
	if not skill_bar_buttons.has("fire_walk"):
		return
	var btn = skill_bar_buttons["fire_walk"]
	var icon = btn.get_meta("icon_node") as TextureRect
	if not icon:
		return
	var hero = get_tree().get_first_node_in_group("hero")
	var active = hero and hero.get_node_or_null("FireWalkEffect") != null
	if active:
		icon.modulate = Color(1.0, 0.85, 0.3, 1.0)
	else:
		icon.modulate = Color(0.5, 0.5, 0.5, 1.0)

# ============================================
# 技能栏点击处理
# ============================================

func _on_skill_button_hovered(skill_id: String):
	hovered_skill_id = skill_id

func _on_skill_button_unhovered(_skill_id: String):
	if hovered_skill_id == _skill_id:
		hovered_skill_id = ""

func _on_skill_button_gui_input(event: InputEvent, skill_id: String):
	if not event is InputEventMouseButton or not event.pressed:
		return
	
	var level = Global.skill_levels.get(skill_id, 0)
	if level <= 0:
		return
	
	if event.button_index == MOUSE_BUTTON_LEFT:
		if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_SPACE):
			Global.quick_slot_space = skill_id
		elif Input.is_key_pressed(KEY_SHIFT):
			Global.quick_slot_shift = skill_id
		else:
			Global.quick_slot_lmb = skill_id
		_update_quick_slot_display()
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if Input.is_key_pressed(KEY_SHIFT):
			Global.quick_slot_rmb = skill_id
			_update_quick_slot_display()
		else:
			_toggle_auto_cast(skill_id)
		get_viewport().set_input_as_handled()

func _update_quick_slot_display():
	_update_single_slot(Global.quick_slot_lmb, quick_slot_lmb_icon)
	_update_single_slot(Global.quick_slot_rmb, quick_slot_rmb_icon)
	_update_single_slot(Global.quick_slot_shift, quick_slot_shift_icon)
	_update_single_slot(Global.quick_slot_space, quick_slot_space_icon)

func _update_single_slot(skill_id: String, icon_node: TextureRect):
	var slot_panel = icon_node.get_parent() as Panel
	if skill_id.is_empty():
		icon_node.texture = null
		if slot_panel:
			if not _default_slot_style:
				_default_slot_style = StyleBoxFlat.new()
				_default_slot_style.bg_color = Color(0.784, 0.196, 0, 0.15)
				_default_slot_style.border_width_left = 1
				_default_slot_style.border_width_top = 1
				_default_slot_style.border_width_right = 1
				_default_slot_style.border_width_bottom = 1
				_default_slot_style.border_color = Color(0.667, 0.267, 0.133, 1)
				_default_slot_style.corner_radius_top_left = 2
				_default_slot_style.corner_radius_top_right = 2
				_default_slot_style.corner_radius_bottom_right = 2
				_default_slot_style.corner_radius_bottom_left = 2
			slot_panel.add_theme_stylebox_override("panel", _default_slot_style)
	else:
		var data = SKILL_BAR_SKILL_DATA.get(skill_id, {})
		var texture_path = data.get("texture", "")
		if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
			icon_node.texture = load(texture_path)
		else:
			icon_node.texture = null
		if slot_panel:
			if not _active_slot_style:
				_active_slot_style = StyleBoxFlat.new()
				_active_slot_style.bg_color = Color(0.8, 0.267, 0, 0.25)
				_active_slot_style.border_width_left = 2
				_active_slot_style.border_width_top = 2
				_active_slot_style.border_width_right = 2
				_active_slot_style.border_width_bottom = 2
				_active_slot_style.border_color = Color(0.8, 0.267, 0, 1)
				_active_slot_style.corner_radius_top_left = 2
				_active_slot_style.corner_radius_top_right = 2
				_active_slot_style.corner_radius_bottom_right = 2
				_active_slot_style.corner_radius_bottom_left = 2
			slot_panel.add_theme_stylebox_override("panel", _active_slot_style)

func _on_skill_level_changed(skill_id: String, _level: int):
	update_skill_bar_display()

# ============================================
# 自动释放（Auto-Cast）系统
# ============================================

func _toggle_auto_cast(skill_id: String):
	var enabled = not Global.auto_cast_skills.get(skill_id, false)
	if enabled:
		Global.auto_cast_skills[skill_id] = true
	else:
		Global.auto_cast_skills.erase(skill_id)
	Global.auto_cast_changed.emit(skill_id, enabled)

func _on_auto_cast_changed(skill_id: String, enabled: bool):
	_update_single_auto_cast_ring(skill_id, enabled)

func _update_auto_cast_display():
	for skill_id in skill_bar_buttons:
		var enabled = Global.auto_cast_skills.get(skill_id, false)
		_update_single_auto_cast_ring(skill_id, enabled)

func _update_single_auto_cast_ring(skill_id: String, enabled: bool):
	var btn = skill_bar_buttons.get(skill_id)
	if not btn:
		return
	var ring = btn.get_node_or_null("AutoCastRing")
	if ring:
		ring.visible = enabled
		var tween = btn.get_meta("ring_tween")
		if enabled:
			ring.rotation = 0.0
			tween.play()
		else:
			tween.stop()
			ring.rotation = 0.0

func _create_dashed_ring_texture(size: int) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center = Vector2(size * 0.5 - 0.5, size * 0.5 - 0.5)
	var radius = size * 0.5 - 1.5
	var num_dashes := 12
	
	for i in range(num_dashes):
		var angle = (float(i) / float(num_dashes)) * TAU - PI / 2
		var progress = float(i) / float(num_dashes)
		var dot_radius = lerp(2.0, 0.3, progress)
		
		if dot_radius < 0.3:
			continue
		
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		var cx = int(pos.x)
		var cy = int(pos.y)
		var r = int(ceil(dot_radius))
		
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var dist = sqrt(dx * dx + dy * dy)
				if dist <= dot_radius:
					var alpha = 1.0 - (dist / max(dot_radius, 0.1)) * 0.3
					var px = cx + dx
					var py = cy + dy
					if px >= 0 and px < size and py >= 0 and py < size:
						image.set_pixel(px, py, Color(1.0, 0.84, 0.0, alpha))
	
	return ImageTexture.create_from_image(image)

# ============================================
# 状态更新
# ============================================

func _on_health_changed(h, mh):
	hp_bar.value = h / mh * 100.0
	health_label.text = str(int(h))
	var pct = int(h / mh * 100)
	hp_percent_label.text = "(%d%%)" % pct

func _on_mana_changed(m, mm):
	mp_bar.value = m / mm * 100.0
	mana_label.text = str(int(m))
	var pct = int(m / mm * 100)
	mp_percent_label.text = "(%d%%)" % pct

func _on_experience_changed(exp, exp_to_next):
	exp_bar.value = float(exp) / float(exp_to_next) * 100.0
	exp_label.text = "LEVEL %d" % Global.hero_level

func _on_level_changed(lvl):
	exp_label.text = "LEVEL %d" % lvl

func update_all():
	_on_health_changed(Global.health, Global.max_health)
	_on_mana_changed(Global.mana, Global.max_mana)
	_on_experience_changed(Global.hero_experience, Global.hero_level * 200)
	_on_level_changed(Global.hero_level)
	update_skill_bar_display()

# ============================================
# Buff/Debuff 显示
# ============================================

func _update_buff_display():
	var to_remove := []
	for buff_id in buff_icons.keys():
		if not Global.hero_buffs.has(buff_id):
			to_remove.append(buff_id)
	
	for buff_id in to_remove:
		var icon = buff_icons[buff_id]
		icon.queue_free()
		buff_icons.erase(buff_id)
	
	for buff_id in Global.hero_buffs.keys():
		if not buff_icons.has(buff_id):
			var icon = BuffIconScene.instantiate()
			buff_container.add_child(icon)
			icon.setup(buff_id, Global.hero_buffs[buff_id])
			buff_icons[buff_id] = icon
	
	for buff_id in buff_icons.keys():
		if Global.hero_buffs.has(buff_id):
			buff_icons[buff_id].buff_data = Global.hero_buffs[buff_id]

# ============================================
# 技能冷却
# ============================================

func _update_skill_cooldowns(_delta: float):
	var hero = get_tree().get_first_node_in_group("hero")
	if not hero or not is_instance_valid(hero):
		return
	
	var hero_cooldowns = hero.skill_cooldowns
	if hero_cooldowns == null:
		return
	
	for skill_id in skill_cooldown_overlays:
		var overlay = skill_cooldown_overlays[skill_id]
		if not is_instance_valid(overlay):
			continue
		
		var cooldown_key = SKILL_COOLDOWN_KEY_MAP.get(skill_id, "")
		if cooldown_key.is_empty():
			continue
		
		var remaining = hero_cooldowns.get(cooldown_key, 0.0)
		var peak = skill_cooldown_peaks.get(cooldown_key, 0.0)
		
		if remaining > peak:
			skill_cooldown_peaks[cooldown_key] = remaining
			peak = remaining
		
		if remaining <= 0.0:
			if overlay.progress > 0.0:
				_trigger_cooldown_ready_flash(skill_id)
			overlay.set_progress(0.0)
			skill_cooldown_peaks[cooldown_key] = 0.0
		else:
			var progress = 1.0 - (remaining / peak) if peak > 0 else 0.0
			overlay.set_progress(progress)

func _trigger_cooldown_ready_flash(skill_id: String):
	var btn = skill_bar_buttons.get(skill_id)
	if not btn:
		return
	var icon = btn.get_meta("icon_node") as TextureRect
	if not icon:
		return
	
	var tween = create_tween()
	tween.tween_property(icon, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.1)
	tween.tween_property(icon, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)

func _update_monster_hp_visibility():
	var monsters = get_tree().get_nodes_in_group("monsters")
	for monster in monsters:
		if is_instance_valid(monster) and monster.has_node("HealthBar"):
			var hp_bar_node = monster.get_node("HealthBar")
			if Global.show_monster_info:
				hp_bar_node.visible = monster.health > 0
			else:
				hp_bar_node.visible = false

# ============================================
# 受击红晕
# ============================================

func _setup_damage_shader():
	var shader = Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float intensity : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n\tfloat d = distance(UV, vec2(0.5));\n\tfloat a = pow(max(d - 0.25, 0.0) / 0.75, 2.0) * intensity * 0.7;\n\tCOLOR = vec4(1.0, 0.0, 0.0, a);\n}"
	var mat = ShaderMaterial.new()
	mat.shader = shader
	damage_overlay.material = mat

func _update_damage_overlay(_delta: float):
	if not is_instance_valid(damage_overlay):
		return
	var ratio = Global.health / Global.max_health
	var intensity = 0.0 if ratio > 0.5 else (1.0 - ratio / 0.5) * 1.0
	var mat = damage_overlay.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("intensity", intensity)

# ============================================
# 遗物显示
# ============================================

func _update_relic_display():
	for child in relic_container.get_children():
		child.queue_free()
	var relic_ids = RelicManager.get_active_relic_ids()
	for rid in relic_ids:
		var relic = RelicManager.all_relics.get(rid)
		if not relic:
			continue
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var color = _get_relic_rarity_color(relic.rarity)
		icon.modulate = color
		if ResourceLoader.exists(relic.icon_path):
			icon.texture = load(relic.icon_path)
		icon.tooltip_text = relic.relic_name + "\n" + relic.description
		relic_container.add_child(icon)

func _get_relic_rarity_color(rarity: int) -> Color:
	match rarity:
		RelicData.Rarity.COMMON: return Color(0.7, 0.7, 0.7)
		RelicData.Rarity.UNCOMMON: return Color(0.2, 0.8, 0.2)
		RelicData.Rarity.UNIQUE: return Color(0.2, 0.5, 1.0)
		RelicData.Rarity.RARE: return Color(0.7, 0.2, 0.9)
		RelicData.Rarity.EXCEPTIONAL: return Color(1.0, 0.7, 0.1)
		_: return Color.WHITE
