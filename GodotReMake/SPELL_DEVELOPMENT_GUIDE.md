# Spell 开发规范指南

## 概述

本文档定义了 EvilInvasion 项目中所有 Spell（技能）的开发规范。所有新技能必须遵循此规范，以确保代码一致性、可维护性和可扩展性。

## 核心设计原则

1. **单一职责**：每个技能脚本只负责该技能的所有逻辑
2. **数据封装**：技能的所有配置数据（冷却、伤害、法力消耗）必须在技能脚本内定义
3. **静态接口**：通过静态 `cast()` 方法提供统一的施法入口
4. **独立冷却**：每个技能有自己的冷却时间，互不干扰

---

## 文件结构规范

### 1. 文件命名

- 技能脚本：`res://Scripts/<spell_name>.gd`
- 场景文件（如需要）：`res://Scenes/<SpellName>.tscn`
- 命名规则：
  - 脚本文件名：小写 + 下划线，如 `magic_missile.gd`
  - 场景文件名：大驼峰，如 `MagicMissile.tscn`
  - 技能名称常量：小写 + 下划线，如 `"magic_missile"`

### 2. 脚本结构模板

```gdscript
extends <BaseType>

# ============================================
# <SpellName>.gd - <技能中文名>专用脚本
# ============================================
# <技能特性描述>
# ============================================

# ============================================
# 技能配置（所有数据必须在此定义）
# ============================================
static var skill_name := "<spell_name>"
static var base_cooldown := <float>
static var base_mana_cost := <float>
static var base_damage := <float>
static var damage_element := "<element>"  # basic, earth, air, fire, water

# 等级成长公式
static func get_mana_cost(level: int) -> float:
    return base_mana_cost + level * <factor>

static func get_damage(level: int) -> float:
    return base_damage + level * <factor>

# 施法入口（必须实现）
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
    var level = Global.skill_levels.get(skill_name, 0)
    if level <= 0:
        return false
    if skill_cooldowns.get(skill_name, 0.0) > 0:
        return false
    
    var mana_cost = get_mana_cost(level)
    var damage = get_damage(level)
    
    if Global.free_spells or Global.mana >= mana_cost:
        if not Global.free_spells:
            Global.mana -= mana_cost
            Global.mana_changed.emit(Global.mana, Global.max_mana)
        
        # 创建技能效果
        _create_spell_effect(hero, mouse_pos, damage)
        
        skill_cooldowns[skill_name] = base_cooldown
        return true
    return false

# ============================================
# 实例属性（投射物/效果行为）
# ============================================
@export var speed := <float>
@export var damage := <float>
# ... 其他属性
```

---

## 必须遵守的规范

### 1. 技能名称一致性

**极其重要！** 技能名称必须在所有文件中保持一致：

| 位置 | 示例 |
|------|------|
| 脚本内 `skill_name` | `"magic_missile"` |
| `global.gd` 的 `skill_levels` key | `"magic_missile"` |
| `hero.gd` 的 `skill_cooldowns` key | `"magic_missile"` |
| `project.godot` 的输入动作名 | `spell_magic_missile` |

**常见错误**：
- ❌ `fire_ball` vs `fireball`
- ❌ `freezingSpear` vs `freezing_spear`
- ❌ `MagicMissile` vs `magic_missile`

### 2. 静态配置变量

每个技能脚本必须定义以下静态变量：

```gdscript
static var skill_name := "<spell_name>"      # 技能唯一标识
static var base_cooldown := <float>           # 基础冷却时间（秒）
static var base_mana_cost := <float>          # 基础法力消耗
static var base_damage := <float>             # 基础伤害
static var damage_element := "<element>"      # 伤害属性
```

### 3. 等级成长公式

必须提供等级相关的计算方法：

```gdscript
static func get_mana_cost(level: int) -> float:
    return base_mana_cost + level * <factor>

static func get_damage(level: int) -> float:
    return base_damage + level * <factor>
```

### 4. 施法入口方法

必须实现静态 `cast` 方法，签名如下：

```gdscript
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool
```

**参数说明**：
- `hero`: 玩家角色节点（用于获取位置、发射口等）
- `mouse_pos`: 鼠标在世界中的位置
- `skill_cooldowns`: 冷却时间字典（由 hero.gd 维护）

**返回值**：
- `true`: 施法成功
- `false`: 施法失败（等级不足、冷却中、法力不足等）

### 5. 施法逻辑流程

`cast` 方法必须按以下顺序执行：

1. **检查技能等级**：`level <= 0` 则返回 `false`
2. **检查冷却时间**：`skill_cooldowns[skill_name] > 0` 则返回 `false`
3. **计算数值**：根据等级计算实际法力消耗和伤害
4. **检查法力**：`Global.mana >= mana_cost` 或 `Global.free_spells`
5. **扣除法力**：如果非免费施法，扣除法力并发射信号
6. **创建效果**：实例化投射物或效果
7. **设置冷却**：`skill_cooldowns[skill_name] = base_cooldown`
8. **返回 `true`**

### 6. Muzzle 节点获取

获取发射口时必须使用正确路径：

```gdscript
var muzzle = hero.get_node("Sprite2D/Muzzle")  # ✅ 正确
var muzzle = hero.get_node("Muzzle")             # ❌ 错误，会返回 null
```

### 7. 场景实例化

```gdscript
var projectile = preload("res://Scenes/<SpellName>.tscn").instantiate()
projectile.global_position = muzzle.global_position
projectile.direction = hero.global_position.direction_to(mouse_pos)
projectile.damage = damage
hero.get_parent().add_child(projectile)
```

---

## Hero.gd 集成规范

### 1. 导入技能脚本

```gdscript
const MagicMissile = preload("res://Scripts/magic_missile.gd")
const Fireball = preload("res://Scripts/fireball.gd")
const FreezingSpear = preload("res://Scripts/freezing_spear.gd")
const Prayer = preload("res://Scripts/prayer.gd")
const Heal = preload("res://Scripts/heal.gd")
```

### 2. 添加到 skill_cooldowns

```gdscript
var skill_cooldowns := {
    "magic_missile": 0.0,
    "fireball": 0.0,
    "freezing_spear": 0.0,
    "prayer": 0.0,
    "heal": 0.0,
    # ... 其他技能
}
```

### 3. 创建施法包装方法

```gdscript
func cast_magic_missile():
    MagicMissile.cast(self, mouse_pos, skill_cooldowns)

func cast_fireball():
    Fireball.cast(self, mouse_pos, skill_cooldowns)

func cast_prayer():
    Prayer.cast(self, mouse_pos, skill_cooldowns)

func cast_heal():
    Heal.cast(self, mouse_pos, skill_cooldowns)
```

### 4. 输入处理

在 `_process` 和 `_unhandled_input` 中调用：

```gdscript
func _process(delta):
    if Input.is_action_pressed("spell_magic_missile"):
        cast_magic_missile()
    if Input.is_action_pressed("spell_fireball"):
        cast_fireball()
    if Input.is_action_pressed("spell_prayer"):
        cast_prayer()
    if Input.is_action_pressed("spell_heal"):
        cast_heal()

func _unhandled_input(event):
    if event.is_action_pressed("spell_magic_missile"):
        cast_magic_missile()
    if event.is_action_pressed("spell_fireball"):
        cast_fireball()
    if event.is_action_pressed("spell_prayer"):
        cast_prayer()
    if event.is_action_pressed("spell_heal"):
        cast_heal()
```

---

## Global.gd 集成规范

### 1. 添加到 skill_levels

```gdscript
var skill_levels := {
    "magic_missile": 1,
    "fireball": 1,
    "freezing_spear": 1,
    "prayer": 1,
    "heal": 1,
    # ... 其他技能
}
```

**注意**：技能名称必须与脚本中的 `skill_name` 完全一致！

---

## Project.godot 集成规范

### 1. 添加输入映射

```
spell_<skill_name>={
"deadzone": 0.5,
"events": [<InputEvent>]
}
```

**命名规则**：`spell_` + 技能名称（小写 + 下划线）

### 2. 输入事件类型

- **鼠标按键**：`InputEventMouseButton`，`button_index: 1`（左键）/ `2`（右键）
- **键盘按键**：`InputEventKey`，`physical_keycode: <KeyCode>`

---

## 伤害系统规范

### 1. 伤害值设置

- 技能脚本中的 `base_damage` 是**固定值**，不包含英雄属性加成
- 伤害成长仅与技能等级相关
- **禁止**在伤害计算中加入 `Global.hero_intelligence` 等属性

### 2. 伤害元素类型

```gdscript
static var damage_element := "basic"   # 基础伤害
static var damage_element := "fire"    # 火焰伤害
static var damage_element := "water"   # 冰霜/水流伤害
static var damage_element := "air"     # 雷电/风伤害
static var damage_element := "earth"   # 土/毒伤害
```

---

## 调试规范

### 1. 添加调试输出

在 `cast` 方法中添加 `print` 以便调试：

```gdscript
print("Cast <SpellName> at ", muzzle.global_position, " towards ", mouse_pos)
```

### 2. 常见错误检查清单

- [ ] `skill_name` 与 `global.gd` 中的 key 一致
- [ ] `skill_name` 与 `hero.gd` 的 `skill_cooldowns` key 一致
- [ ] `muzzle` 路径是 `"Sprite2D/Muzzle"`
- [ ] 场景文件路径正确
- [ ] `cast` 方法返回 `bool`
- [ ] 冷却时间在施法成功后设置

---

## 示例：完整的 Magic Missile 技能

```gdscript
extends Area2D

# ============================================
# MagicMissile.gd - 魔法飞弹专用脚本
# ============================================

# 技能配置
static var skill_name := "magic_missile"
static var base_cooldown := 1.0
static var base_mana_cost := 5.0
static var base_damage := 5.0
static var damage_element := "basic"

# 等级成长
static func get_mana_cost(level: int) -> float:
    return base_mana_cost + level

static func get_damage(level: int) -> float:
    return base_damage + level * 5.0

static func get_missile_count(level: int) -> int:
    return 1 + int((level - 1) / 3)

# 施法入口
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
    var level = Global.skill_levels.get(skill_name, 0)
    if level <= 0:
        return false
    if skill_cooldowns.get(skill_name, 0.0) > 0:
        return false
    
    var mana_cost = get_mana_cost(level)
    var damage = get_damage(level)
    var missile_count = get_missile_count(level)
    
    if Global.free_spells or Global.mana >= mana_cost:
        if not Global.free_spells:
            Global.mana -= mana_cost
            Global.mana_changed.emit(Global.mana, Global.max_mana)
        
        var muzzle = hero.get_node("Sprite2D/Muzzle")
        for i in range(missile_count):
            var missile = preload("res://Scenes/MagicMissile.tscn").instantiate()
            missile.global_position = muzzle.global_position
            var spread = deg_to_rad(10.0)
            var angle = hero.global_position.angle_to_point(mouse_pos) + randf_range(-spread, spread)
            missile.direction = Vector2(cos(angle), sin(angle))
            missile.damage = damage
            hero.get_parent().add_child(missile)
        
        skill_cooldowns[skill_name] = base_cooldown
        return true
    return false

# 实例属性
@export var speed := 500
@export var damage := 10.0
@export var max_distance := 4000
```

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2026-05-07 | 初始版本，基于 Magic Missile / Fireball / Freezing Spear 重构经验 |
| 1.1 | 2026-05-08 | 更新：确认技能数据封装规范，hero.gd 不再管理技能数据 |
| 1.2 | 2026-05-08 | 更新：新增 Prayer / Heal 技能规范，hero.gd 占位符模式说明 |
