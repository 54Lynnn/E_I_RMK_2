# ============================================
# HeroPanel.gd - 英雄面板控制器
# ============================================
# 这个文件控制角色属性面板（按C键打开），包括：
# 1. 左侧属性区：等级、经验、基础属性（力量/敏捷等）
# 2. 右侧技能树：21个技能的网格布局
# 3. 属性加点系统：消耗属性点提升基础属性
# 4. 技能升级系统：消耗技能点学习/升级技能
# 5. 开发者模式：按F12快速获得大量属性点和技能点
#
# 节点结构（在HeroPanel.tscn中定义）：
# - HeroPanel (Control)
#   - Background (Panel): 半透明黑色背景
#     - LeftPanel (VBoxContainer): 左侧信息区
#       - LevelRow: 等级和经验显示
#       - AttrPointsRow: 可用属性点
#       - StatsContainer: 属性列表（力量、敏捷等）
#     - RightPanel (VBoxContainer): 右侧技能区
#       - SkillPointsRow: 可用技能点
#       - SkillsContainer: 技能按钮网格
#         - ConnectionLines: 技能连线（Line2D节点）
#
# 打开/关闭方式：
# - 按C键：正常打开/关闭
# - 按F12：开发者模式（获得100属性点+100技能点）
#
# 重要常量：
# - SKILL_BUTTON_SIZE = 40: 技能按钮大小（像素）
# - CELL_SIZE = 56: 技能网格单元大小（包含间距）
# ============================================

extends Control

# ============================================
# @onready 变量 - 自动获取子节点引用
# ============================================

@onready var background := $Background                    # 背景面板
@onready var left_panel := $Background/LeftPanel          # 左侧属性面板
@onready var right_panel := $Background/RightPanel        # 右侧技能面板
@onready var level_label := $Background/LeftPanel/LevelRow/LevelLabel          # 等级标签
@onready var exp_label := $Background/LeftPanel/LevelRow/ExpLabel              # 经验标签
@onready var attr_points_label := $Background/LeftPanel/AttrPointsRow/AttrPointsLabel  # 属性点标签
@onready var skill_points_label := $Background/RightPanel/SkillPointsRow/SkillPointsLabel  # 技能点标签
@onready var stats_container := $Background/LeftPanel/StatsContainer  # 属性容器

# 面板是否打开的状态标记
var is_open := false

# ============================================
# 生命周期函数
# ============================================

func _ready():
	# 初始状态：隐藏面板
	visible = false
	
	# 设置属性按钮（连接+号按钮的信号）
	setup_attribute_buttons()
	
	# 设置技能树（创建21个技能按钮）
	setup_skill_tree()

func _input(event):
	# 检测按键输入
	
	# 按C键：切换面板显示/隐藏
	if event.is_action_pressed("toggle_hero_panel"):
		toggle()
	
	# 按F12：切换开发者模式
	if event.is_action_pressed("toggle_dev_mode"):
		toggle_dev_mode()

# ============================================
# 面板显示控制
# ============================================

func toggle():
	# 切换面板的打开/关闭状态
	is_open = !is_open
	visible = is_open
	
	# 打开面板时暂停游戏，关闭时恢复
	get_tree().paused = is_open
	
	# 打开时更新UI显示
	if is_open:
		update_ui()

func toggle_dev_mode():
	# 开发者模式：用于快速测试技能系统
	# 按F12切换，获得大量属性点和技能点
	Global.dev_mode = !Global.dev_mode
	
	if Global.dev_mode:
		# 开启开发者模式：增加100属性点和100技能点
		Global.attribute_points += 100
		Global.skill_points += 100
		
		# 自动打开面板
		is_open = true
		visible = true
		get_tree().paused = true
		update_ui()
	else:
		# 关闭开发者模式
		is_open = false
		visible = false
		get_tree().paused = false

func update_ui():
	# 更新所有UI显示
	
	# 更新等级和经验显示
	level_label.text = str(Global.hero_level)
	exp_label.text = str(Global.hero_experience) + " / " + str(Global.hero_level * 100)
	
	# 更新可用点数显示
	attr_points_label.text = str(Global.attribute_points)
	skill_points_label.text = str(Global.skill_points)
	
	# 更新属性按钮和技能按钮
	update_attribute_buttons()
	update_skill_buttons()

# ============================================
# 属性系统
# ============================================

func setup_attribute_buttons():
	# 设置属性加点按钮
	# 遍历所有基础属性，连接对应的+号按钮
	
	var attrs = ["strength", "dexterity", "stamina", "intelligence", "wisdom"]
	for attr in attrs:
		# 获取属性行中的+号按钮
		# 节点命名规则：StrengthRow/AddButton, DexterityRow/AddButton等
		var btn = stats_container.get_node_or_null(attr.capitalize() + "Row/AddButton")
		if btn:
			# 连接按钮信号，使用bind传递属性名
			btn.pressed.connect(_on_attribute_added.bind(attr))

func update_attribute_buttons():
	# 更新属性按钮状态
	# 有可用属性点时启用+号按钮，否则禁用
	
	var attrs = ["strength", "dexterity", "stamina", "intelligence", "wisdom"]
	for attr in attrs:
		# 更新+号按钮状态
		var btn = stats_container.get_node_or_null(attr.capitalize() + "Row/AddButton")
		if btn:
			btn.disabled = Global.attribute_points <= 0
		
		# 更新属性值显示
		var label = stats_container.get_node_or_null(attr.capitalize() + "Row/ValueLabel")
		if label:
			label.text = str(Global.get("hero_" + attr))
	
	# 更新衍生属性（生命值、法力值等）
	update_derived_stats()

func update_derived_stats():
	# 更新衍生属性显示
	# 这些属性由基础属性计算得出
	
	# 生命值显示：当前/最大
	var health_label = stats_container.get_node_or_null("HealthRow/ValueLabel")
	if health_label:
		health_label.text = str(int(Global.health)) + "/" + str(int(Global.max_health))
	
	# 法力值显示：当前/最大
	var mana_label = stats_container.get_node_or_null("ManaRow/ValueLabel")
	if mana_label:
		mana_label.text = str(int(Global.mana)) + "/" + str(int(Global.max_mana))
	
	# 生命恢复速度：由耐力决定
	var health_regen_label = stats_container.get_node_or_null("HealthRegenRow/ValueLabel")
	if health_regen_label:
		var health_regen_rate = 1.0 + Global.hero_stamina * 0.1
		health_regen_label.text = get_regen_text(health_regen_rate)
	
	# 法力恢复速度：由智力和智慧决定
	var mana_regen_label = stats_container.get_node_or_null("ManaRegenRow/ValueLabel")
	if mana_regen_label:
		var mana_regen_rate = 1.0 + Global.hero_intelligence * 0.06 + Global.hero_wisdom * 0.18
		mana_regen_label.text = get_regen_text(mana_regen_rate)
	
	# 移动速度：由敏捷决定
	var speed_label = stats_container.get_node_or_null("SpeedRow/ValueLabel")
	if speed_label:
		var hero_speed = Global.hero_dexterity * 2.0 + 50.0
		speed_label.text = get_speed_text(hero_speed)
	
	# 受击恢复：由力量决定
	var hit_recovery_label = stats_container.get_node_or_null("HitRecoveryRow/ValueLabel")
	if hit_recovery_label:
		var hit_recovery = Global.hero_strength * 0.5 + 20.0
		hit_recovery_label.text = get_speed_text(hit_recovery)
	
	# 被击中几率：由敏捷决定（敏捷越高，被击中几率越低）
	var chance_label = stats_container.get_node_or_null("ChanceToBeHitRow/ValueLabel")
	if chance_label:
		var chance = max(0.05, min(0.96, 1.0 - Global.hero_dexterity * 0.009))
		chance_label.text = str(int(chance * 100)) + "%"

# 恢复速度文本转换
func get_regen_text(value: float) -> String:
	if value < 0.5:
		return "extra slow"
	elif value < 1.0:
		return "slow"
	elif value < 2.0:
		return "normal"
	elif value < 3.0:
		return "fast"
	else:
		return "extra fast"

# 速度文本转换
func get_speed_text(value: float) -> String:
	if value < 50:
		return "extra slow"
	elif value < 80:
		return "slow"
	elif value < 120:
		return "normal"
	elif value < 160:
		return "fast"
	else:
		return "extra fast"

func _on_attribute_added(attr: String):
	# 属性加点处理
	# 消耗1个属性点，提升对应属性1点
	
	if Global.attribute_points > 0:
		Global.attribute_points -= 1
		Global.set("hero_" + attr, Global.get("hero_" + attr) + 1)
		
		# 根据属性类型应用效果
		match attr:
			"strength":
				Global.apply_strength()      # 力量：增加生命值和伤害
			"dexterity":
				Global.apply_dexterity()     # 敏捷：增加速度和闪避
			"stamina":
				Global.apply_stamina()       # 耐力：增加生命恢复
			"intelligence":
				Global.apply_intelligence()  # 智力：增加法力值和恢复
			"wisdom":
				Global.apply_wisdom()        # 智慧：增加法力恢复
		
		# 更新UI显示
		update_ui()

# ============================================
# 技能树系统
# ============================================

# 技能按钮大小（像素）
# 修改此值可改变技能按钮尺寸
const SKILL_BUTTON_SIZE := 40

# 网格单元大小（包含按钮之间的间距）
# 计算公式：单元大小 = 按钮大小 + 间距
const CELL_SIZE := 56

# 存储所有技能按钮的字典
# 键：skill_id，值：SkillButton实例
var skill_buttons := {}

func setup_skill_tree():
	# 设置技能树界面
	# 创建21个技能按钮并按网格布局排列
	
	# 获取技能容器和连线层
	var skills_container = right_panel.get_node("SkillsContainer")
	var connection_lines = right_panel.get_node("SkillsContainer/ConnectionLines")
	
	# 清除旧的技能按钮（保留连线层）
	for child in skills_container.get_children():
		if child != connection_lines:
			child.queue_free()
	
	# 清空技能按钮字典
	skill_buttons.clear()
	
	# ============================================
	# 技能数据定义
	# ============================================
	# 每个技能包含：
	# - name: 显示名称
	# - desc: 详细描述（显示在提示框中）
	# - texture: 图标图片路径
	# - prereq: 前置技能ID（空字符串表示无前置）
	# - cell: 在网格中的位置（Vector2(x, y)）
	#
	# 网格坐标说明：
	# - x范围：0-7（共8列）
	# - y范围：0-3（共4行）
	# - (0,0)在左上角
	# ============================================
	
	var skills_data = {
		"magic_missile": {
			"name": "Magic Missile",
			"desc": "Launch a magic missile. Lv1: Mana 5, CD 0.5s, Dmg 20",
			"texture": "res://Art/Placeholder/MagicMissile.png",
			"prereq": "",
			"cell": Vector2(3, 3)  # 第4列，第4行（底部中间）
		},
		"prayer": {
			"name": "Prayer",
			"desc": "Sacrifice 65% health, regain 50% mana over 10s. CD: 20s",
			"texture": "res://Art/Placeholder/Prayer.png",
			"prereq": "magic_missile",
			"cell": Vector2(0, 2)
		},
		"teleport": {
			"name": "Teleport",
			"desc": "After 0.2s cast, teleport to cursor. Mana: 35, CD: 20s",
			"texture": "res://Art/Placeholder/Teleport.png",
			"prereq": "prayer",
			"cell": Vector2(0, 1)
		},
		"mistfog": {
			"name": "Mist Fog",
			"desc": "Brown fog slows enemies. Lv1: 35%, Mana: 25, CD: 5s",
			"texture": "res://Art/Placeholder/MistFog.png",
			"prereq": "prayer",
			"cell": Vector2(1, 1)
		},
		"stone_enchanted": {
			"name": "Stone Enchanted",
			"desc": "Passive: Chance to petrify attacker. Lv1: 30%, Lv10: 75%",
			"texture": "res://Art/Placeholder/StoneEnchanted.png",
			"prereq": "teleport",
			"cell": Vector2(0, 0)
		},
		"wrath_of_god": {
			"name": "Wrath of God",
			"desc": "10 hammers around hero. Lv1: Mana 55, CD 2s, Dmg 200",
			"texture": "res://Art/Placeholder/WrathOfGod.png",
			"prereq": "teleport",
			"cell": Vector2(1, 0)
		},
		"telekinesis": {
			"name": "Telekinesis",
			"desc": "Pick up items from distance. Lv1: 1.0s, Lv10: 0.1s",
			"texture": "res://Art/Placeholder/Telekinesis.png",
			"prereq": "magic_missile",
			"cell": Vector2(2, 2)
		},
		"holy_light": {
			"name": "Holy Light",
			"desc": "Light rays to cursor. Lv1: Mana 35, CD 1s, Dmg 120, 3 rays",
			"texture": "res://Art/Placeholder/HolyLight.png",
			"prereq": "telekinesis",
			"cell": Vector2(2, 1)
		},
		"sacrifice": {
			"name": "Sacrifice",
			"desc": "Kill enemy at cursor. Lv1: Health 55%, CD 3s",
			"texture": "res://Art/Placeholder/Sacrifice.png",
			"prereq": "telekinesis",
			"cell": Vector2(3, 1)
		},
		"ball_lightning": {
			"name": "Ball Lightning",
			"desc": "Orb attacks nearby enemies. Lv1: Mana 45, CD 2s, Dmg 200",
			"texture": "res://Art/Placeholder/BallLightning.png",
			"prereq": "holy_light",
			"cell": Vector2(2, 0)
		},
		"chain_lightning": {
			"name": "Chain Lightning",
			"desc": "Lightning bounces between enemies. Lv1: Mana 55, CD 1s, Dmg 1000",
			"texture": "res://Art/Placeholder/ChainLightning.png",
			"prereq": "holy_light",
			"cell": Vector2(3, 0)
		},
		"fire_ball": {
			"name": "Fire Ball",
			"desc": "Launch a fire ball that explodes on impact",
			"texture": "res://Art/Placeholder/FireBall.png",
			"prereq": "magic_missile",
			"cell": Vector2(4, 2)
		},
		"heal": {
			"name": "Heal",
			"desc": "Heal over 10s. Lv1: Mana 35, CD 15s, 5%/s",
			"texture": "res://Art/Placeholder/Heal.png",
			"prereq": "fire_ball",
			"cell": Vector2(4, 1)
		},
		"fire_walk": {
			"name": "Fire Walk",
			"desc": "Passive: Leave fire trail. Lv1: 30 dmg/s, lasts 5s",
			"texture": "res://Art/Placeholder/FireWalk.png",
			"prereq": "fire_ball",
			"cell": Vector2(5, 1)
		},
		"meteor": {
			"name": "Meteor",
			"desc": "Meteors rain at cursor. Lv1: Mana 45, CD 5s, Dmg 250, Radius 130",
			"texture": "res://Art/Placeholder/Meteor.png",
			"prereq": "heal",
			"cell": Vector2(4, 0)
		},
		"armageddon": {
			"name": "Armageddon",
			"desc": "Random fireblasts across map. Lv1: Mana 55, CD 20s, Fireblast Dmg 250, Radius 60",
			"texture": "res://Art/Placeholder/Armageddon.png",
			"prereq": "heal",
			"cell": Vector2(5, 0)
		},
		"freezing_spear": {
			"name": "Freezing Spear",
			"desc": "Launch an ice spear that freezes enemies",
			"texture": "res://Art/Placeholder/FreezingSpear.png",
			"prereq": "magic_missile",
			"cell": Vector2(6, 2)
		},
		"poison_cloud": {
			"name": "Poison Cloud",
			"desc": "Green fog damages enemies. Lv1: Mana 35, CD 5s, Dmg 60/s, Radius 110, Dur 10s",
			"texture": "res://Art/Placeholder/PoisonCloud.png",
			"prereq": "freezing_spear",
			"cell": Vector2(6, 1)
		},
		"fortuna": {
			"name": "Fortuna",
			"desc": "Passive: Increase drop chance. Lv1: +15%, +5% per level",
			"texture": "res://Art/Placeholder/Fortuna.png",
			"prereq": "freezing_spear",
			"cell": Vector2(7, 1)
		},
		"dark_ritual": {
			"name": "Dark Ritual",
			"desc": "Black fog: enemies inside 2s may be killed. Lv1: Mana 55, CD 5.5s, 30%, Radius 130",
			"texture": "res://Art/Placeholder/DarkRitual.png",
			"prereq": "poison_cloud",
			"cell": Vector2(6, 0)
		},
		"nova": {
			"name": "Nova",
			"desc": "Snowball freezes enemies. Lv1: Mana 45, CD 2s, Dmg 200, Radius 100, Freeze 1s",
			"texture": "res://Art/Placeholder/Nova.png",
			"prereq": "poison_cloud",
			"cell": Vector2(7, 0)
		}
	}
	
	# ============================================
	# 计算网格布局
	# ============================================
	
	# 获取容器尺寸
	var container_width = skills_container.size.x
	var container_height = skills_container.size.y
	
	# 计算网格总尺寸
	var total_width = 8 * CELL_SIZE   # 8列
	var total_height = 4 * CELL_SIZE  # 4行
	
	# 计算居中偏移量
	var offset_x = (container_width - total_width) / 2
	var offset_y = (container_height - total_height) / 2
	
	# ============================================
	# 创建技能按钮
	# ============================================
	
	for skill_id in skills_data:
		var data = skills_data[skill_id]
		var cell = data.cell
		
		# 计算按钮在容器中的位置
		# 位置 = 偏移量 + 网格坐标 × 单元大小
		var x = offset_x + cell.x * CELL_SIZE
		var y = offset_y + cell.y * CELL_SIZE
		
		# 创建技能按钮
		create_skill_button(skill_id, data, skills_container, Vector2(x, y))
	
	# 延迟绘制连线（确保按钮位置已更新）
	call_deferred("draw_connection_lines")

func create_skill_button(skill_id: String, skill_data: Dictionary, parent: Node, pos: Vector2):
	# 创建单个技能按钮
	
	# 实例化技能按钮场景
	var btn = preload("res://Scenes/SkillButton.tscn").instantiate()
	
	# 设置按钮属性
	btn.skill_id = skill_id
	btn.skill_name = skill_data.name
	btn.skill_description = skill_data.desc
	btn.texture_path = skill_data.texture
	btn.current_level = Global.skill_levels.get(skill_id, 0)
	btn.set("prereq_skill", skill_data.prereq)
	
	# 连接升级信号
	btn.skill_upgraded.connect(_on_skill_upgraded)
	
	# 设置按钮尺寸和位置
	btn.custom_minimum_size = Vector2(SKILL_BUTTON_SIZE, SKILL_BUTTON_SIZE)
	btn.size = Vector2(SKILL_BUTTON_SIZE, SKILL_BUTTON_SIZE)
	btn.position = pos
	
	# 添加到容器和字典
	parent.add_child(btn)
	skill_buttons[skill_id] = btn

func draw_connection_lines():
	# 绘制技能之间的连线
	# 显示技能的前置关系（哪些技能需要先学习）
	
	# 获取连线层
	var connection_lines = right_panel.get_node("SkillsContainer/ConnectionLines")
	if not connection_lines:
		return
	
	# 清除旧连线
	for child in connection_lines.get_children():
		child.queue_free()
	
	# 遍历所有技能按钮
	for skill_id in skill_buttons:
		var btn = skill_buttons[skill_id]
		var prereq_id = btn.prereq_skill
		
		# 如果有前置技能且前置技能按钮存在
		if prereq_id != "" and skill_buttons.has(prereq_id):
			var prereq_btn = skill_buttons[prereq_id]
			
			# 计算连线起点和终点（按钮中心）
			var start_pos = prereq_btn.global_position - connection_lines.global_position + prereq_btn.size / 2
			var end_pos = btn.global_position - connection_lines.global_position + btn.size / 2
			
			# 创建连线
			var line = Line2D.new()
			line.width = 2.0
			line.default_color = Color(0.6, 0.5, 0.3, 0.8)  # 棕色半透明
			
			# 如果x坐标相同，直接连线
			if start_pos.x == end_pos.x:
				line.add_point(start_pos)
				line.add_point(end_pos)
			else:
				# 否则使用L型连线（先垂直后水平）
				var mid_y = start_pos.y + (end_pos.y - start_pos.y) * 0.5
				line.add_point(start_pos)
				line.add_point(Vector2(start_pos.x, mid_y))
				line.add_point(Vector2(end_pos.x, mid_y))
				line.add_point(end_pos)
			
			connection_lines.add_child(line)

func update_skill_buttons():
	# 更新所有技能按钮的状态
	# 根据前置技能是否学习来决定按钮是否可用
	
	var skills_container = right_panel.get_node("SkillsContainer")
	var connection_lines = right_panel.get_node("SkillsContainer/ConnectionLines")
	
	for child in skills_container.get_children():
		# 跳过连线层
		if child == connection_lines:
			continue
		
		# 检查是否是技能按钮
		if child.has_method("update_display"):
			# 更新当前等级
			child.current_level = Global.skill_levels.get(child.skill_id, 0)
			
			# 检查前置技能
			var prereq = child.prereq_skill
			if prereq != "":
				var prereq_level = Global.skill_levels.get(prereq, 0)
				
				# 前置技能未学习：禁用并变暗
				child.disabled = prereq_level <= 0
				if prereq_level <= 0:
					child.modulate = Color(0.3, 0.3, 0.3, 1.0)
				else:
					child.modulate = Color(1.0, 1.0, 1.0, 1.0)
			else:
				# 无前置技能：正常显示
				child.disabled = false
				child.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# 重新绘制连线
	call_deferred("draw_connection_lines")

func _on_skill_upgraded(skill_id: String):
	# 技能升级后的回调
	# 更新整个UI以反映变化
	update_ui()
