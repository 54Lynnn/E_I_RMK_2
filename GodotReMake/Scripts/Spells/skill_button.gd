# ============================================
# SkillButton.gd - 技能按钮组件
# ============================================
# 这个文件是技能树界面中每个技能按钮的控制脚本。
# 它继承自Button类，用于显示单个技能的信息并处理升级操作。
#
# 使用场景：
# 1. 技能树界面（HeroPanel）中的21个技能按钮
# 2. 每个按钮显示技能图标、当前等级/最大等级
# 3. 点击按钮消耗技能点进行升级
# 4. 鼠标悬停显示技能提示信息
#
# 节点结构（在SkillButton.tscn中定义）：
# - SkillButton (Button)
#   - VBoxContainer: 垂直布局容器
#     - Icon (TextureRect): 技能图标图片
#     - LevelLabel (Label): 等级显示文本（如"3/10"）
#
# 信号说明：
# - skill_upgraded(skill_id): 技能升级时发出，通知父面板更新
#
# 属性说明（@export变量）：
# - skill_id: 技能唯一标识符（如"magic_missile"）
# - skill_name: 技能显示名称
# - skill_description: 技能详细描述
# - texture_path: 图标图片资源路径
# - max_level: 技能最高等级（默认10）
# - prereq_skill: 前置技能ID（空字符串表示无前置）
# ============================================

extends Button

# 自定义信号：技能升级时发出
# 参数 skill_id: 升级的技能标识符
signal skill_upgraded(skill_id)

# ============================================
# 导出变量 - 可在Godot编辑器中设置
# ============================================

# 技能唯一标识符，用于在Global.skill_levels中查找
@export var skill_id: String = ""

# 技能显示名称，用于提示框
@export var skill_name: String = ""

# 技能详细描述，显示在提示框中
@export var skill_description: String = ""

# 图标图片的资源路径，如"res://Art/Placeholder/MagicMissile.png"
@export var texture_path: String = ""

# 技能最高等级，默认10级
@export var max_level: int = 10

# 前置技能ID，学习此技能需要先学习前置技能
# 空字符串表示没有前置技能
@export var prereq_skill: String = ""

# ============================================
# 核心变量
# ============================================

# 当前技能等级，使用setter自动更新显示
# 当设置新值时，会自动调用update_display()
var current_level: int = 0:
	set(value):
		current_level = value
		update_display()

# @onready 变量：在_ready()时自动获取子节点引用
@onready var icon_texture := $VBoxContainer/Icon      # 技能图标
@onready var level_label := $VBoxContainer/LevelLabel # 等级标签

# ============================================
# 生命周期函数
# ============================================

func _ready():
	# 连接按钮按下信号
	pressed.connect(_on_pressed)
	
	# 加载并设置技能图标
	# 检查texture_path是否有效且资源存在
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		icon_texture.texture = load(texture_path)
	
	# 初始化显示
	update_display()
	
	# 连接鼠标悬停信号（用于显示提示框）
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# ============================================
# 显示更新函数
# ============================================

func update_display():
	# 更新等级标签文本，格式为"当前等级/最大等级"
	# 例如："3/10"表示当前3级，最高10级
	if level_label:
		level_label.text = str(current_level) + "/" + str(max_level)
	
	# 根据等级状态设置按钮外观
	if current_level >= max_level:
		# 已满级：禁用按钮，显示灰色
		disabled = true
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		# 未满级：启用按钮，显示正常颜色
		modulate = Color(1.0, 1.0, 1.0, 1.0)

# ============================================
# 交互处理函数
# ============================================

func _on_pressed():
	# 按钮被点击时的处理
	# 检查条件：有足够的技能点且未满级
	if Global.skill_points > 0 and current_level < max_level:
		# 消耗1个技能点
		Global.skill_points -= 1
		
		# 提升技能等级
		current_level += 1
		
		# 更新全局技能等级数据
		Global.skill_levels[skill_id] = current_level
		
		# 发出信号通知全局技能等级变化
		# 这会触发HUD中的技能栏更新
		Global.skill_level_changed.emit(skill_id, current_level)
		
		# 发出信号通知父面板（HeroPanel）
		skill_upgraded.emit(skill_id)
		
		# 更新按钮显示
		update_display()

# ============================================
# 提示框功能
# ============================================

func _on_mouse_entered():
	# 鼠标进入按钮区域时显示提示框
	if not skill_description.is_empty():
		show_tooltip()

func _on_mouse_exited():
	# 鼠标离开按钮区域时隐藏提示框
	hide_tooltip()

func show_tooltip():
	# 创建并显示提示框
	# 提示框包含：技能名称、描述、当前等级/最大等级
	var tooltip = Label.new()
	tooltip.name = "Tooltip"
	tooltip.text = skill_name + "\n" + skill_description + "\nLevel: " + str(current_level) + "/" + str(max_level)
	
	# 设置提示框位置（按钮上方60像素）
	tooltip.position = Vector2(0, -60)
	
	# 将提示框添加为按钮的子节点
	add_child(tooltip)

func hide_tooltip():
	# 隐藏并删除提示框
	var tooltip = get_node_or_null("Tooltip")
	if tooltip:
		tooltip.queue_free()
