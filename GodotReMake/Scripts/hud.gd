extends CanvasLayer

# ============================================
# HUD.gd - 游戏界面控制器
# ============================================
# 这个文件控制游戏主界面的底部HUD（抬头显示），包括：
# 1. 左侧玩家信息区（头像、血条、蓝条、经验条、等级）
# 2. 中间技能栏（21个技能的快捷图标）
# 3. 右下角操作提示文字
#
# 节点结构（在HUD.tscn中定义）：
# HUD (CanvasLayer)
# └── BottomBar (Panel) - 底部栏背景（高度86px）
#     ├── LeftInfo (Control) - 左侧信息区（宽度230px）
#     │   ├── PortraitBg (Panel) - 头像背景框
#     │   ├── HeroPortrait (TextureRect) - 英雄头像（52×52）
#     │   ├── HPBar (ProgressBar) - 血条（140×20）
#     │   ├── HPLabel (Label) - 血量文字
#     │   ├── MPBar (ProgressBar) - 蓝条（140×20）
#     │   ├── MPLabel (Label) - 法力文字
#     │   └── LevelLabel (Label) - 等级标签（头像下方）
#     ├── SkillSection (Control) - 技能区
#     │   ├── SkillBarBg (Panel) - 技能栏背景
#     │   └── SkillBarContainer (HBoxContainer) - 技能图标容器
#     ├── ExpBar (ProgressBar) - 通栏经验条（底部24px）
#     ├── ExpLabel (Label) - "LEVEL X" 居中显示
#     └── TipsLabel (Label) - 操作提示（右下角）
#
# UI尺寸修改指南：
# - 修改头像大小：调整HeroPortrait的offset_right/offset_bottom（当前52×52）
# - 修改血条大小：调整HPBar的offset_right/offset_bottom（当前140×20）
# - 修改技能图标：修改SKILL_ICON_SIZE常量（当前34）
# - 修改技能间距：修改SkillBarContainer的separation（当前2）
# - 修改底部栏高度：调整BottomBar的offset_top（当前-110）
# - 注意：21个技能按钮总宽 = 21×34 + 20×2 = 754px，需小于SkillBarContainer宽度772px
# ============================================

# @onready 自动获取节点引用
# 左侧信息区节点
@onready var hp_bar := $BottomBar/LeftInfo/HPBar           # 血条进度条
@onready var mp_bar := $BottomBar/LeftInfo/MPBar           # 蓝条进度条
@onready var exp_bar := $BottomBar/ExpBar              # 通栏经验条进度条（底部）
@onready var exp_label := $BottomBar/ExpLabel
@onready var level_label := $BottomBar/LeftInfo/LevelLabel # 等级标签
@onready var health_label := $BottomBar/LeftInfo/HPLabel   # 血量文字
@onready var health_percent_label := $BottomBar/LeftInfo/HPPercentLabel  # 血量百分比
@onready var mana_label := $BottomBar/LeftInfo/MPLabel     # 法力文字
@onready var mana_percent_label := $BottomBar/LeftInfo/MPPercentLabel  # 法力百分比

# 技能栏节点
@onready var skill_bar_container := $BottomBar/SkillSection/SkillBarContainer

# 快捷槽位节点
@onready var quick_slot_lmb_icon := $BottomBar/QuickSlots/SlotLMBIcon
@onready var quick_slot_rmb_icon := $BottomBar/QuickSlots/SlotRMBIcon
@onready var quick_slot_shift_icon := $BottomBar/QuickSlots/SlotShiftIcon
@onready var quick_slot_space_icon := $BottomBar/QuickSlots/SlotSpaceIcon

var hovered_skill_id := ""

# Buff/Debuff 显示区域
@onready var buff_container := $BottomBar/BuffContainer

@onready var relic_container := $RelicContainer

# Buff 图标场景
const BuffIconScene = preload("res://Scenes/BuffIcon.tscn")

# 当前显示的 buff 图标
var buff_icons := {}

# 受击红晕遮罩（来自 HUD.tscn）
@onready var damage_overlay := $DamageOverlay

# ============================================
# 技能栏配置
# ============================================

# 技能图标尺寸（像素）
# 修改此值可改变技能图标大小
const SKILL_ICON_SIZE := 28

# 技能数据字典
# 每个技能包含：
# - name: 显示名称（用于提示）
# - texture: 图标图片路径
# - input: 快捷键（显示在提示中）
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

# 存储技能按钮的字典，key=技能ID，value=Button节点
var skill_bar_buttons := {}

# 技能冷却多边形 overlay（key=技能ID，value=Polygon2D）
var skill_cooldown_overlays := {}

# 技能冷却峰值跟踪（key=hero cooldown key名，value=观测到的最大冷却值）
var skill_cooldown_peaks := {}

# HUD技能ID 到 hero.skill_cooldowns key 的映射
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

# Alt键状态跟踪（用于 _process 边缘检测）
var _alt_was_pressed := false

# ============================================
# 生命周期函数
# ============================================

func _ready():
	# 初始化：连接全局信号
	
	# 当生命值变化时，更新血条显示
	Global.health_changed.connect(_on_health_changed)
	
	# 当法力值变化时，更新蓝条显示
	Global.mana_changed.connect(_on_mana_changed)
	
	# 当经验值变化时，更新经验条显示
	Global.experience_changed.connect(_on_experience_changed)
	
	# 当等级变化时，更新等级标签
	Global.level_changed.connect(_on_level_changed)
	
	# 当技能等级变化时，更新技能栏显示（学习新技能后变彩色）
	Global.skill_level_changed.connect(_on_skill_level_changed)
	
	# 鼠标进入/离开 HUD 底部栏时设置标记，防止点击 HUD 触发施法
	$BottomBar.mouse_entered.connect(func(): Global.is_mouse_over_hud = true)
	$BottomBar.mouse_exited.connect(func(): Global.is_mouse_over_hud = false)
	
	# 创建技能栏按钮
	setup_skill_bar()
	
	# 给 DamageOverlay 添加径向渐变 shader
	_setup_damage_shader()
	
	# 初始化所有显示
	update_all()
	# 初始化快捷槽位显示
	_update_quick_slot_display()
	# 初始化自动释放显示
	_update_auto_cast_display()
	# 监听自动释放变化
	Global.auto_cast_changed.connect(_on_auto_cast_changed)
	# 监听遗物变化
	RelicManager.active_relics_changed.connect(_update_relic_display)
	_update_relic_display()

func _process(delta):
	# 每帧更新 buff 显示
	_update_buff_display()
	# 每帧更新技能冷却显示
	_update_skill_cooldowns(delta)
	# 每帧更新受击红晕
	_update_damage_overlay(delta)
	# _process 回退检测 Alt 键
	_check_alt_toggle()

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
	print("HUD: 怪物信息显示 %s" % ["ON" if Global.show_monster_info else "OFF"])
	_update_monster_hp_visibility()

# ============================================
# 技能栏设置
# ============================================

func setup_skill_bar():
	# 创建技能栏的所有按钮
	
	# 如果容器不存在，直接返回（安全检查）
	if not skill_bar_container:
		return

	# 清除已有的按钮（防止重复创建）
	for child in skill_bar_container.get_children():
		child.queue_free()

	# 清空按钮字典
	skill_bar_buttons.clear()

	# 定义技能顺序（从左到右显示）
	var skill_ids := [
		"magic_missile", "prayer", "teleport", "mistfog",
		"stone_enchanted", "wrath_of_god", "telekinesis", "sacrifice",
		"holy_light", "ball_lightning", "chain_lightning", "fireball",
		"heal", "fire_walk", "meteor", "armageddon",
		"freezing_spear", "poison_cloud", "fortuna", "dark_ritual", "nova"
	]

	# 为每个技能创建按钮
	for skill_id in skill_ids:
		# 获取技能数据
		var data = SKILL_BAR_SKILL_DATA.get(skill_id, {})
		if data.is_empty():
			continue

		# 创建按钮
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(SKILL_ICON_SIZE, SKILL_ICON_SIZE)
		btn.size = Vector2(SKILL_ICON_SIZE, SKILL_ICON_SIZE)
		btn.tooltip_text = data.name  # 鼠标悬停时显示技能名
		btn.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻止点击穿透到游戏世界
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # 防止被容器纵向拉伸

		# 去掉按钮默认的灰色背景，改成透明
		var transparent_bg = StyleBoxFlat.new()
		transparent_bg.bg_color = Color(0, 0, 0, 0)
		btn.add_theme_stylebox_override("normal", transparent_bg)
		btn.add_theme_stylebox_override("hover", transparent_bg)
		btn.add_theme_stylebox_override("pressed", transparent_bg)
		btn.add_theme_stylebox_override("focus", transparent_bg)
		btn.add_theme_stylebox_override("disabled", transparent_bg)

		# 创建图标（TextureRect）
		var icon = TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(SKILL_ICON_SIZE - 4, SKILL_ICON_SIZE - 4)  # 留4像素边距
		icon.position = Vector2(2, 2)  # 居中偏移

		# 加载图标纹理（如果文件存在）
		var texture_path = data.texture
		if ResourceLoader.exists(texture_path):
			icon.texture = load(texture_path)

		# 将图标添加为按钮的子节点
		btn.add_child(icon)

		# 创建冷却扇形遮罩（Control-based）—— 在快捷键标签下层
		var overlay = preload("res://Scripts/cooldown_overlay.gd").new()
		overlay.name = "CooldownOverlay"
		overlay.mouse_filter = Control.MOUSE_FILTER_PASS
		overlay.size = Vector2(SKILL_ICON_SIZE, SKILL_ICON_SIZE)
		overlay.set_progress(0.0)
		btn.add_child(overlay)
		skill_cooldown_overlays[skill_id] = overlay

		# 添加快捷键提示标签（右下角）—— 在最上层
		var input_text = data.get("input", "")
		if not input_text.is_empty():
			var key_label = Label.new()
			key_label.text = input_text
			key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			key_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			key_label.position = Vector2(SKILL_ICON_SIZE - 28, SKILL_ICON_SIZE - 18)
			key_label.size = Vector2(26, 16)
			key_label.add_theme_font_size_override("font_size", 11)
			# 用文字描边代替背景面板，不遮挡图标
			key_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			key_label.add_theme_constant_override("outline_size", 2)
			btn.add_child(key_label)

		# 存储元数据（用于后续访问）
		btn.set_meta("skill_id", skill_id)
		btn.set_meta("icon_node", icon)

		# 创建自动释放旋转蛇形光圈（默认隐藏）
		var auto_cast_ring = TextureRect.new()
		auto_cast_ring.name = "AutoCastRing"
		auto_cast_ring.texture = _create_dashed_ring_texture(SKILL_ICON_SIZE)
		auto_cast_ring.size = Vector2(SKILL_ICON_SIZE, SKILL_ICON_SIZE)
		auto_cast_ring.pivot_offset = Vector2(SKILL_ICON_SIZE * 0.5, SKILL_ICON_SIZE * 0.5)
		auto_cast_ring.mouse_filter = Control.MOUSE_FILTER_PASS
		auto_cast_ring.visible = false
		btn.add_child(auto_cast_ring)

		# 创建持续旋转动画（初始为停止状态）
		var ring_tween = btn.create_tween()
		ring_tween.set_loops()
		ring_tween.tween_property(auto_cast_ring, "rotation", TAU, 1.5).as_relative()
		ring_tween.stop()
		btn.set_meta("ring_tween", ring_tween)

		# 连接点击信号（gui_input 可区分左键/右键）
		btn.gui_input.connect(_on_skill_button_gui_input.bind(skill_id))
		btn.mouse_entered.connect(_on_skill_button_hovered.bind(skill_id))
		btn.mouse_exited.connect(_on_skill_button_unhovered.bind(skill_id))

		# 添加到容器和字典
		skill_bar_container.add_child(btn)
		skill_bar_buttons[skill_id] = btn

	# 更新显示状态（彩色/灰色）
	update_skill_bar_display()

func update_skill_bar_display():
	# 更新所有技能按钮的显示状态
	# 已学习（等级>=1）：彩色，可点击
	# 未学习（等级=0）：灰色半透明，禁用
	
	for skill_id in skill_bar_buttons:
		var btn = skill_bar_buttons[skill_id]
		var icon = btn.get_meta("icon_node") as TextureRect
		var level = Global.skill_levels.get(skill_id, 0)

		if level >= 1:
			# 已学习：正常颜色
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if icon:
				icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.disabled = false
		else:
			# 未学习：灰色+70%透明度
			btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
			if icon:
				icon.modulate = Color(0.5, 0.5, 0.5, 0.7)
			btn.disabled = true

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
	if skill_id.is_empty():
		icon_node.texture = null
	else:
		var data = SKILL_BAR_SKILL_DATA.get(skill_id, {})
		var texture_path = data.get("texture", "")
		if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
			icon_node.texture = load(texture_path)
		else:
			icon_node.texture = null

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
# 状态更新函数
# ============================================

func _on_health_changed(h, mh):
	# 生命值变化时更新血条
	# h: 当前生命, mh: 最大生命
	
	# 计算百分比（0-100）
	hp_bar.value = h / mh * 100.0
	
	# 更新文字显示（如 "100 / 100"）
	health_label.text = str(int(h)) + "/" + str(int(mh))
	health_percent_label.text = "(" + str(int(h / mh * 100)) + "%)"

func _on_mana_changed(m, mm):
	# 法力值变化时更新蓝条
	# m: 当前法力, mm: 最大法力
	
	mp_bar.value = m / mm * 100.0
	mana_label.text = str(int(m)) + "/" + str(int(mm))
	mana_percent_label.text = "(" + str(int(m / mm * 100)) + "%)"

func _on_experience_changed(exp, exp_to_next):
	# 经验值变化时更新经验条
	# exp: 当前经验, exp_to_next: 升级所需经验
	
	# 计算百分比
	exp_bar.value = float(exp) / float(exp_to_next) * 100.0
	
	exp_label.text = "LEVEL %d" % Global.hero_level

func _on_level_changed(lvl):
	level_label.text = "Lv." + str(lvl)
	exp_label.text = "LEVEL %d" % lvl

func update_all():
	# 初始化时更新所有显示
	_on_health_changed(Global.health, Global.max_health)
	_on_mana_changed(Global.mana, Global.max_mana)
	_on_experience_changed(Global.hero_experience, Global.hero_level * 200)
	_on_level_changed(Global.hero_level)
	update_skill_bar_display()

# ============================================
# Buff/Debuff 显示更新
# ============================================

func _update_buff_display():
	# 同步 Global.hero_buffs 和 UI 显示
	
	# 1. 移除已经不存在的 buff 图标
	var to_remove := []
	for buff_id in buff_icons.keys():
		if not Global.hero_buffs.has(buff_id):
			to_remove.append(buff_id)
	
	for buff_id in to_remove:
		var icon = buff_icons[buff_id]
		icon.queue_free()
		buff_icons.erase(buff_id)
	
	# 2. 添加新出现的 buff 图标
	for buff_id in Global.hero_buffs.keys():
		if not buff_icons.has(buff_id):
			var icon = BuffIconScene.instantiate()
			buff_container.add_child(icon)
			icon.setup(buff_id, Global.hero_buffs[buff_id])
			buff_icons[buff_id] = icon
	
	# 3. 更新现有 buff 数据
	for buff_id in buff_icons.keys():
		if Global.hero_buffs.has(buff_id):
			buff_icons[buff_id].buff_data = Global.hero_buffs[buff_id]

# ============================================
# 技能冷却显示
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
			overlay.set_progress(0.0)
			skill_cooldown_peaks[cooldown_key] = 0.0
		else:
			var progress = 1.0 - (remaining / peak) if peak > 0 else 0.0
			overlay.set_progress(progress)

func _update_monster_hp_visibility():
	var monsters = get_tree().get_nodes_in_group("monsters")
	for monster in monsters:
		if is_instance_valid(monster) and monster.has_node("HealthBar"):
			var hp_bar = monster.get_node("HealthBar")
			if Global.show_monster_info:
				hp_bar.visible = monster.health > 0
			else:
				hp_bar.visible = false

# ============================================
# 受击红晕更新
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
