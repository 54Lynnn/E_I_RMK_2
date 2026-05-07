# Evil Invasion 命名规范

> **创建日期**: 2026-05-08
> **适用范围**: 所有 GDScript 代码、场景节点、文件资源

---

## 1. 文件命名规范

### 1.1 脚本文件
- **规范**: snake_case
- **示例**: `magic_missile.gd`, `fire_walk.gd`, `monster_spawner.gd`

### 1.2 场景文件
- **规范**: PascalCase
- **示例**: `MagicMissile.tscn`, `FireWalk.tscn`, `Main.tscn`

### 1.3 资源文件
- **规范**: PascalCase（图片、音频等）
- **示例**: `Fireball.png`, `HolyLight.png`

---

## 2. 代码命名规范

### 2.1 变量
- **规范**: snake_case
- **示例**: `skill_name`, `base_cooldown`, `damage_multiplier`

### 2.2 函数
- **规范**: snake_case
- **示例**: `get_damage()`, `apply_debuff()`, `take_damage()`

### 2.3 类名
- **规范**: PascalCase
- **示例**: `HeroUnit`, `Monster`, `Projectile`

### 2.4 常量
- **规范**: UPPER_SNAKE_CASE
- **示例**: `MAX_LEVEL`, `BASE_DAMAGE`, `CELL_SIZE`

### 2.5 信号
- **规范**: 过去式，snake_case
- **示例**: `skill_upgraded`, `mana_changed`, `monster_died`

---

## 3. 节点命名规范（重要！）

### 3.1 技能生成的场景节点

所有技能生成的场景节点必须遵循统一命名规范：

| 节点类型 | 后缀 | 示例 |
|---------|------|------|
| 场地效果（zone） | `_zone` | `fire_walk_zone`, `poison_cloud_zone`, `dark_ritual_zone` |
| 投射物（projectile） | `_proj` | `magic_missile_proj`, `fireball_proj`, `meteor_proj`, `holy_light_proj` |
| 爆发效果（effect） | `_effect` | `nova_effect` |

### 3.2 命名规则

1. **使用技能ID（snake_case）+ 类型后缀**
2. **节点名称必须在实例化后立即设置，在 `add_child()` 之前**
3. **命名统一使用小写 + 下划线**

### 3.3 正确示例

```gdscript
# ✅ 正确：投射物
var missile = preload("res://Scenes/MagicMissile.tscn").instantiate()
missile.name = "magic_missile_proj"
hero.get_parent().add_child(missile)

# ✅ 正确：场地效果
var zone = preload("res://Scenes/PoisonCloud.tscn").instantiate()
zone.name = "poison_cloud_zone"
hero.get_parent().add_child(zone)
```

### 3.4 错误示例

```gdscript
# ❌ 错误：没有设置名称
var missile = preload("res://Scenes/MagicMissile.tscn").instantiate()
hero.get_parent().add_child(missile)

# ❌ 错误：添加到 hero 节点内部（场地效果）
var zone = preload("res://Scenes/FireWalk.tscn").instantiate()
hero.add_child(zone)  # 这会导致火焰跟着玩家移动！

# ❌ 错误：使用大驼峰
var missile = preload("res://Scenes/MagicMissile.tscn").instantiate()
missile.name = "MagicMissileProj"  # 应该使用 snake_case
```

---

## 4. 技能名称一致性

**极其重要！** 技能名称必须在所有文件中保持一致：

| 位置 | 示例 |
|------|------|
| 脚本内 `skill_name` | `"magic_missile"` |
| `global.gd` 的 `skill_levels` key | `"magic_missile"` |
| `hero.gd` 的 `skill_cooldowns` key | `"magic_missile"` |
| `project.godot` 的输入动作名 | `spell_magic_missile` |
| 节点名称 | `magic_missile_proj` |

**常见错误**：
- ❌ `fire_ball` vs `fireball`
- ❌ `freezingSpear` vs `freezing_spear`
- ❌ `MagicMissile` vs `magic_missile`

---

## 5. 场景层级规范

### 5.1 场地效果技能
- **必须**添加到场景根节点：`hero.get_parent().add_child(zone)`
- **不能**添加到 hero 节点内部

### 5.2 投射物技能
- **必须**添加到场景根节点：`hero.get_parent().add_child(proj)`
- 这样可以确保投射物有独立的世界坐标

### 5.3 绑定到玩家的效果
- 可以添加到 hero 节点内部：`hero.add_child(effect)`
- 例如：Prayer 的持续效果、Heal 的持续效果

---

## 6. 调试技巧

1. **使用 Remote 场景树**：运行游戏时切换到 Remote 查看节点层级
2. **检查节点名称**：确保所有生成的节点都有清晰的名称
3. **验证节点位置**：场地效果应该在 Main 节点下，而不是 Hero 节点下

---

**文档结束。所有新代码必须遵循此规范！**
