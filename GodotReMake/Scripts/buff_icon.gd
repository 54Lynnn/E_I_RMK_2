extends Control

# ============================================
# BuffIcon.gd - Buff/Debuff 图标显示
# ============================================
# 显示一个带有扇形冷却效果的 buff/debuff 图标
#
# 设计：
# - 圆形图标显示 buff 图片
# - 灰色扇形蒙版显示剩余时间比例（使用 Polygon2D）
# - buff 持续时间越短，灰色扇形越大
# - 当 buff 消失时，图标同步消失
#
# 节点结构：
# - Border: Panel (圆形边框)
# - IconTexture: TextureRect (buff 图标)
# - CooldownPolygon: Polygon2D (扇形冷却蒙版)
# - DurationLabel: Label (剩余时间文字)
# ============================================

# Buff 数据
var buff_id: String = ""
var buff_data: Dictionary = {}

# 缓存上次进度，避免不必要的多边形重建
var _last_progress := -1.0

# 图标尺寸
const ICON_SIZE := 36

# 子节点引用
@onready var icon_texture := $IconTexture
@onready var cooldown_polygon := $CooldownPolygon
@onready var duration_label := $DurationLabel
@onready var border := $Border

# 图标纹理映射
const BUFF_TEXTURES := {
	"health_regen": "res://Art/Placeholder/BonusHealth.png",
	"mana_regen": "res://Art/Placeholder/BonusMana.png",
	"speed_boost": "res://Art/Placeholder/BonusSpeed.png",
	"damage_boost": "res://Art/Placeholder/BonusQuadDamage.png",
	"magic_shield": "res://Art/Placeholder/BonusMagicResist.png",
	"physic_shield": "res://Art/Placeholder/BonusPhysicResist.png",
	"free_spells": "res://Art/Placeholder/BonusFreeSpells.png",
	"invulnerability": "res://Art/Placeholder/BonusImmunity.png",
	"hit_slow": "res://Art/Placeholder/BonusSpeed.png",
	# 技能 buff
	"heal": "res://Art/Placeholder/Heal.png",
	"prayer": "res://Art/Placeholder/Prayer.png",
}

# Buff 类型颜色
const BUFF_BORDER_COLOR := Color(0.2, 0.8, 0.2, 1.0)      # 绿色边框（buff）
const DEBUFF_BORDER_COLOR := Color(0.9, 0.1, 0.1, 1.0)    # 红色边框（debuff）

func _ready():
	# 设置控件大小
	custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	size = Vector2(ICON_SIZE, ICON_SIZE)

func setup(buff_id_param: String, buff_data_param: Dictionary):
	buff_id = buff_id_param
	buff_data = buff_data_param

	# 加载图标
	var texture_path = BUFF_TEXTURES.get(buff_id, "")
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		icon_texture.texture = load(texture_path)

	# 设置边框颜色
	var style = border.get_theme_stylebox("panel").duplicate()
	if buff_data.get("type", "buff") == "debuff":
		style.border_color = DEBUFF_BORDER_COLOR
	else:
		style.border_color = BUFF_BORDER_COLOR
	border.add_theme_stylebox_override("panel", style)

func _process(_delta):
	# 更新显示
	if buff_data.is_empty():
		return

	var remaining = buff_data.get("remaining", 0.0)
	var duration = buff_data.get("duration", 1.0)

	# 更新扇形冷却蒙版
	_update_cooldown_polygon(remaining, duration)

	# 更新剩余时间文字
	if remaining > 0:
		duration_label.text = str(ceil(remaining))
	else:
		duration_label.text = ""

func _update_cooldown_polygon(remaining: float, duration: float):
	var progress = 1.0 - (remaining / duration)
	progress = clamp(progress, 0.0, 1.0)

	if abs(progress - _last_progress) < 0.01:
		return
	_last_progress = progress

	if progress <= 0:
		# 刚开始，不显示扇形
		cooldown_polygon.polygon = PackedVector2Array()
		return

	var radius = ICON_SIZE / 2 - 2  # 稍微缩小避免超出边框

	# 构建扇形顶点数组（相对于 Polygon2D 的 position）
	var points := PackedVector2Array()
	points.append(Vector2(0, 0))  # 中心点

	# 从顶部开始（-90度），顺时针绘制已消耗的扇形
	var start_angle = -PI / 2
	var end_angle = start_angle + progress * 2 * PI
	var segments = 32

	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = start_angle + t * (end_angle - start_angle)
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		points.append(Vector2(x, y))

	# 设置多边形顶点
	cooldown_polygon.polygon = points

	# 确保可见
	cooldown_polygon.visible = true
