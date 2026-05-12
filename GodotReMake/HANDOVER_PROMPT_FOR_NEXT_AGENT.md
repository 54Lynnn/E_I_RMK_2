# Evil Invasion Remake — 新 Agent 交接提示词

> **发送给下一个 coding agent 的提示词**
> **日期**: 2026-05-12
> **项目位置**: `e:\EvilInvasion\GodotReMake\`
> **上一个Agent最后工作**: 
> - Quest模式重构：经验上限系统、关卡选择器、存档持久化
> - 更新所有文档

---

## 📋 必读文档（按顺序）

1. **`DEVELOPER_HANDOVER.md`** — 详细的开发者交接文档（文件结构、核心系统、技术债务、下一步建议）
2. **`ROADMAP.md`** — 完整开发路线图和原版游戏参数参考
3. **`GAME_SYSTEMS_DESIGN.md`** — 游戏系统设计文档（所有系统详细说明）
4. **`SPELL_DEVELOPMENT_GUIDE.md`** — 技能开发规范（必须遵守）
5. **`extracted.md`** — 原版游戏反编译数据（⚠️ 技能数值部分已删除，存在等级偏移错误。技能数值请以 `E:\EvilInvasion\evil_invasion_spell.xlsx` 为准）
6. **`NAMING_CONVENTIONS.md`** — 命名规范（文件、节点、代码）

---

## 🎯 当前项目状态（2026-05-12更新）

### ✅ 已完成

**技能系统**：
- 全部 21 个技能已实现并测试通过（一级形态）
- 技能重构为独立场景 + 独立脚本模式
- 伤害属性系统：basic, earth, air, fire, water

**怪物系统**：
- 8 种怪物已实现：Zombie, Bear, Archer(Mummy), Reaper, Demon, Boss(Diablo), Spider, Troll
- 数据驱动：所有怪物数值来自 `monster_database.gd`
- 统一生成：所有模式边缘生成 + 墙壁反弹游荡
- 四种生成模式：单个/整排/编组/全边界

**Quest模式（本次更新）**：
- ✅ **经验上限系统**：每关有固定经验上限，达到后停止经验获取和怪物生成
- ✅ **关卡选择器**：`Scenes/LevelSelect.tscn`，显示10关解锁状态
- ✅ **存档持久化**：通关时自动保存，解锁下一关
- ✅ **Resume Game**：从关卡选择器开始，保留玩家等级和属性
- ✅ **怪物种类限制**：每关使用 `allowed_monsters` 限制出现的怪物种类

**其他**：
- 存档系统（F5保存/F10读取）
- 受击恢复系统
- 属性分配系统
- 掉落系统
- 开发模式（F2）

### ⚠️ 待完成/待测试

1. **Quest模式通关奖励**：通关后显示奖励结算画面（时间、击杀数）
2. **Quest模式Boss战**：Diablo关卡特殊机制
3. **关卡选择器UI美化**：当前只是基础按钮，需要更好的视觉效果
4. **高等级技能测试**：仅 Magic Missile 和 Freezing Spear 测试了高等级
5. **音效系统**：用户打算最后做
6. **地图系统**：原版有多张地图

---

## 🔧 Quest模式关键代码规范（本次更新）

### 1. 经验上限系统
```gdscript
# quest_level_manager.gd
# 每关经验上限（Level 1: 2000, Level 2: 5200, ...）
var level_experience_caps := [2000, 5200, 8400, 11600, 14800, 18000, 21200, 24400, 27600, 30800]

# 检测是否还能获得经验
func can_gain_experience(amount: int) -> bool:
    return level_experience_gained + amount <= level_experience_caps[current_level]

# 达到上限时
# 1. 停止怪物生成（quest_monster_spawner.stop_spawning()）
# 2. 将所有存活怪物的经验设为0（防止继续获得经验）
# 3. 清除所有怪物后通关
```

### 2. 关卡选择器
```gdscript
# level_select.gd
# 显示10个关卡按钮，根据 Global.quest_max_unlocked_level 显示状态
# 0 = 只有第1关解锁，1 = 第1-2关解锁，以此类推

# 新游戏时重置
Global.quest_max_unlocked_level = 0  # 只解锁第1关

# 通关第1关后
Global.quest_max_unlocked_level = 1  # 解锁第1-2关
```

### 3. 存档系统（Quest模式）
```gdscript
# 保存时机：只在通关时保存（不再频繁存档）
# 保存内容：
# - quest_progress.current_level = next_level
# - quest_progress.monsters_killed = 0  # 从开头开始
# - quest_progress.level_start_level = Global.hero_level  # 保留等级
# - quest_max_unlocked_level = next_level  # 解锁下一关
```

### 4. 怪物种类限制
```gdscript
# quest_level_manager.gd 中的 level_configs
var level_configs := [
    { "name": "Ancient Way", "allowed_monsters": ["troll", "mummy"] },
    { "name": "Burned Land", "allowed_monsters": ["troll", "mummy", "spider"] },
    # ...
]

# quest_monster_spawner.gd 中使用
allowed_monsters = config["allowed_monsters"]
var monster_id = allowed_monsters[randi() % allowed_monsters.size()]
```

---

## 🚀 快速开始

1. 打开 Godot 4.6.2，导入项目 `e:\EvilInvasion\GodotReMake\`
2. 运行主场景 `Main.tscn`
3. 按 F2 进入开发模式（获得100属性点+100技能点）
4. 按 T 打开技能树面板
5. 按 F5 保存游戏，F10 读取存档

---

## ⚠️ 重要注意事项

### Quest模式流程
```
GameModeSelect.tscn
    ↓ 选择 Quest Mode → Start
LevelSelect.tscn（显示解锁状态）
    ↓ 选择 Level 3
QuestMain.tscn（开始第3关）
    ↓ 达到经验上限 + 清除所有怪物
LevelSelect.tscn（返回，Level 4 已解锁）
```

### 常见陷阱
- **技能图标路径**：`res://Art/Placeholder/SkillName.png`，注意大小写
- **节点引用**：修改场景后确保脚本中的 `@onready` 引用正确
- **法力/生命修改后**：必须发射信号（如 `Global.mana_changed.emit()`）
- **坐标系**：异步发射技能使用 `hero.get_global_mouse_position()` 获取世界坐标
- **怪物生成位置**：所有模式均从边缘生成，不再从玩家周围生成

---

**祝开发顺利！**
