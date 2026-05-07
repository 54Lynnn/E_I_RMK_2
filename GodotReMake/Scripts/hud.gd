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
# └── BottomBar (Panel) - 底部栏背景
#     ├── LeftInfo (Control) - 左侧信息区（宽度230px）
#     │   ├── PortraitBg (Panel) - 头像背景框
#     │   ├── HeroPortrait (TextureRect) - 英雄头像（52×52）
#     │   ├── HPBar (ProgressBar) - 血条（140×20）
#     │   ├── HPLabel (Label) - 血量文字
#     │   ├── MPBar (ProgressBar) - 蓝条（140×20）
#     │   ├── MPLabel (Label) - 法力文字
#     │   ├── ExpBar (ProgressBar) - 经验条（140×16）
#     │   ├── ExpLabel (Label) - 经验文字
#     │   └── LevelLabel (Label) - 等级标签
#     ├── SkillSection (Control) - 技能区
#     │   ├── SkillBarBg (Panel) - 技能栏背景
#     │   └── SkillBarContainer (HBoxContainer) - 技能图标容器
#     └── TipsLabel (Label) - 操作提示
#
# UI尺寸修改指南：
# - 修改头像大小：调整HeroPortrait的offset_right/offset_bottom（当前52×52）
# - 修改血条大小：调整HPBar的offset_right/offset_bottom（当前140×20）
# - 修改技能图标：修改SKILL_ICON_SIZE常量（当前44）
# - 修改技能间距：修改SkillBarContainer的separation（当前6）
# - 修改底部栏高度：调整BottomBar的offset_top（当前-110）
# ============================================

# @onready 自动获取节点引用
# 左侧信息区节点
@onready var hp_bar := $BottomBar/LeftInfo/HPBar           # 血条进度条
@onready var mp_bar := $BottomBar/LeftInfo/MPBar           # 蓝条进度条
@onready var exp_bar := $BottomBar/LeftInfo/ExpBar         # 经验条进度条
@onready var level_label := $BottomBar/LeftInfo/LevelLabel # 等级标签
@onready var health_label := $BottomBar/LeftInfo/HPLabel   # 血量文字
@onready var mana_label := $BottomBar/LeftInfo/MPLabel     # 法力文字

# 技能栏节点
@onready var skill_bar_container := $BottomBar/SkillSection/SkillBarContainer

# ============================================
# 技能栏配置
# ============================================

# 技能图标尺寸（像素）
# 修改此值可改变技能图标大小
const SKILL_ICON_SIZE := 44

# 技能数据字典
# 每个技能包含：
# - name: 显示名称（用于提示）
# - texture: 图标图片路径
# - input: 快捷键（显示在提示中）
const SKILL_BAR_SKILL_DATA := {
	"magic_missile": {"name": "Magic Missile", "texture": "res://Art/Placeholder/MagicMissile.png", "input": "LMB"},
	"prayer": {"name": "Prayer", "texture": "res://Art/Placeholder/Prayer.png", "input": ""},
	"teleport": {"name": "Teleport", "texture": "res://Art/Placeholder/Teleport.png", "input": ""},
	"mistfog": {"name": "Mist Fog", "texture": "res://Art/Placeholder/MistFog.png", "input": ""},
	"stone_enchanted": {"name": "Stone Enchanted", "texture": "res://Art/Placeholder/StoneEnchanted.png", "input": ""},
	"wrath_of_god": {"name": "Wrath of God", "texture": "res://Art/Placeholder/WrathOfGod.png", "input": ""},
	"telekinesis": {"name": "Telekinesis", "texture": "res://Art/Placeholder/Telekinesis.png", "input": ""},
	"sacrifice": {"name": "Sacrifice", "texture": "res://Art/Placeholder/Sacrifice.png", "input": ""},
	"holy_light": {"name": "Holy Light", "texture": "res://Art/Placeholder/HolyLight.png", "input": ""},
	"fire_ball": {"name": "Fire Ball", "texture": "res://Art/Placeholder/FireBall.png", "input": "F"},
	"heal": {"name": "Heal", "texture": "res://Art/Placeholder/Heal.png", "input": ""},
	"fire_walk": {"name": "Fire Walk", "texture": "res://Art/Placeholder/FireWalk.png", "input": ""},
	"meteor": {"name": "Meteor", "texture": "res://Art/Placeholder/Meteor.png", "input": ""},
	"armageddon": {"name": "Armageddon", "texture": "res://Art/Placeholder/Armageddon.png", "input": ""},
	"freezing_spear": {"name": "Freezing Spear", "texture": "res://Art/Placeholder/FreezingSpear.png", "input": ""},
	"poison_cloud": {"name": "Poison Cloud", "texture": "res://Art/Placeholder/PoisonCloud.png", "input": ""},
	"fortuna": {"name": "Fortuna", "texture": "res://Art/Placeholder/Fortuna.png", "input": ""},
	"dark_ritual": {"name": "Dark Ritual", "texture": "res://Art/Placeholder/DarkRitual.png", "input": ""},
	"nova": {"name": "Nova", "texture": "res://Art/Placeholder/Nova.png", "input": ""},
}

# 存储技能按钮的字典，key=技能ID，value=Button节点
var skill_bar_buttons := {}

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
	
	# 创建技能栏按钮
	setup_skill_bar()
	
	# 初始化所有显示
	update_all()

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
		"holy_light", "fire_ball",
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
		btn.mouse_filter = Control.MOUSE_FILTER_PASS  # 允许鼠标事件穿透

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
		
		# 存储元数据（用于后续访问）
		btn.set_meta("skill_id", skill_id)
		btn.set_meta("icon_node", icon)
		
		# 连接点击信号
		btn.pressed.connect(_on_skill_bar_pressed.bind(skill_id))

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

func _on_skill_bar_pressed(skill_id: String):
	# 当点击技能栏按钮时调用
	
	# 检查技能是否已学习
	var level = Global.skill_levels.get(skill_id, 0)
	if level <= 0:
		return

	# 获取英雄节点
	var hero = get_tree().get_first_node_in_group("hero")
	if not hero:
		return

	# 根据技能ID调用对应的施法函数
	# 所有技能都检查 can_cast（冷却状态）
	match skill_id:
		"magic_missile":
			if hero.can_cast:
				hero.cast_magic_missile()
		"fire_ball":
			if hero.can_cast:
				hero.cast_fireball()
		"prayer":
			if hero.can_cast:
				hero.cast_prayer()
		"teleport":
			if hero.can_cast:
				hero.cast_teleport()
		"mistfog":
			if hero.can_cast:
				hero.cast_mistfog()
		"wrath_of_god":
			if hero.can_cast:
				hero.cast_wrath_of_god()
		"telekinesis":
			if hero.can_cast:
				hero.cast_telekinesis()
		"sacrifice":
			if hero.can_cast:
				hero.cast_sacrifice()
		"holy_light":
			if hero.can_cast:
				hero.cast_holy_light()
		"heal":
			if hero.can_cast:
				hero.cast_heal()
		"fire_walk":
			if hero.can_cast:
				hero.cast_fire_walk()
		"meteor":
			if hero.can_cast:
				hero.cast_meteor()
		"armageddon":
			if hero.can_cast:
				hero.cast_armageddon()
		"freezing_spear":
			if hero.can_cast:
				hero.cast_freezing_spear()
		"poison_cloud":
			if hero.can_cast:
				hero.cast_poison_cloud()
		"fortuna":
			if hero.can_cast:
				hero.cast_fortuna()
		"dark_ritual":
			if hero.can_cast:
				hero.cast_dark_ritual()
		"nova":
			if hero.can_cast:
				hero.cast_nova()

func _on_skill_level_changed(skill_id: String, _level: int):
	# 当技能等级变化时，更新技能栏显示
	update_skill_bar_display()

# ============================================
# 状态更新函数
# ============================================

func _on_health_changed(h, mh):
	# 生命值变化时更新血条
	# h: 当前生命, mh: 最大生命
	
	# 计算百分比（0-100）
	hp_bar.value = h / mh * 100.0
	
	# 更新文字显示（如 "100 / 100"）
	health_label.text = str(int(h)) + " / " + str(int(mh))

func _on_mana_changed(m, mm):
	# 法力值变化时更新蓝条
	# m: 当前法力, mm: 最大法力
	
	mp_bar.value = m / mm * 100.0
	mana_label.text = str(int(m)) + " / " + str(int(mm))

func _on_experience_changed(exp, exp_to_next):
	# 经验值变化时更新经验条
	# exp: 当前经验, exp_to_next: 升级所需经验
	
	# 计算百分比
	exp_bar.value = float(exp) / float(exp_to_next) * 100.0
	
	# 更新文字（如 "EXP: 50/100"）
	$BottomBar/LeftInfo/ExpLabel.text = "EXP: " + str(exp) + "/" + str(exp_to_next)

func _on_level_changed(lvl):
	# 等级变化时更新等级标签
	level_label.text = "Lv." + str(lvl)

func update_all():
	# 初始化时更新所有显示
	_on_health_changed(Global.health, Global.max_health)
	_on_mana_changed(Global.mana, Global.max_mana)
	_on_experience_changed(Global.hero_experience, Global.hero_level * 100)
	_on_level_changed(Global.hero_level)
	update_skill_bar_display()
