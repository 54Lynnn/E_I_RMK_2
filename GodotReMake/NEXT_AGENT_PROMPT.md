# Evil Invasion Remake — 新 Agent 交接提示词

> **发送给下一个 coding agent 的提示词**
> **日期**: 2026-05-07
> **项目位置**: `D:\project\E_I_RMK_2\GodotReMake\`（公司）/ `e:\EvilInvasion\GodotReMake\`（家）
> **GitHub**: https://github.com/54Lynnn/E_I_RMK_2

---

## 📋 必读文档（按顺序）

1. **`HANDOVER_PROMPT.md`** ← **从这里开始**（最精简、最准确的项目状态概览）
2. **`DEVELOPER_HANDOVER.md`** — 项目全貌、核心系统详解
3. **`SPELL_DEVELOPMENT_GUIDE.md`** — 技能开发规范（必须遵守）
4. **`NAMING_CONVENTIONS.md`** — 命名规范
5. **`evil_invasion_spell.xlsx`** — 技能数值参考（唯一可信来源）

---

## 🎯 你现在的任务

与开发者合作，继续完善 Evil Invasion 重制版。当前项目已经具备完整的可运行基础，包括：
- 21个技能全部实现并绑定按键
- 8种怪物各有独特AI
- Survival和Quest两种游戏模式
- 存档、掉落、属性等核心系统

### 建议优先处理

1. **测试并修复技能**：逐个测试21个技能的LV1效果是否符合预期
2. **听取用户反馈**：用户会逐个指出不对的技能，你逐个改
3. **完善怪物系统**：用户可能想加新怪物或调整AI
4. **地图系统**：用户准备好了8张地图的数据

---

## ⚡ 关键技术要点

### 技能脚本路径
```gdscript
# 所有技能脚本在 Scripts/Spells/ 下
const BallLightning = preload("res://Scripts/Spells/ball_lightning.gd")
```

### 技能数值来源
```python
# 唯一可信来源: evil_invasion_spell.xlsx
# ❌ 不要用 extracted.md 的数据（有等级偏移错误）
```

### Cast 方法标准模式
```gdscript
static func cast(hero: Node, mouse_pos: Vector2, skill_cooldowns: Dictionary) -> bool:
    var level = Global.skill_levels.get(skill_name, 0)
    if level <= 0: return false
    if skill_cooldowns.get(skill_name, 0.0) > 0: return false
    # ... 法力检查、扣蓝、创建效果、设置冷却 ...
```

### 怪物配置
```gdscript
# monster_database.gd 驱动所有怪物数值
# 近战: 检测400px, 攻击40px
# 远程: 检测500px, 攻击150-380px
```

### 系统文件位置
| 功能 | 文件 |
|------|------|
| 技能脚本 | `Scripts/Spells/*.gd` |
| 怪物脚本 | `Scripts/Monsters/*.gd` |
| Quest脚本 | `Scripts/Quest/*.gd` |
| 全局状态 | `Scripts/global.gd` (Autoload) |
| 英雄控制 | `Scripts/hero.gd` |
| HUD | `Scripts/hud.gd` |
| 技能面板 | `Scripts/hero_panel.gd` |
| 存档 | `Scripts/save_manager.gd` |
| 掉落 | `Scripts/loot_manager.gd` (Autoload) |

---

## ⚠️ 常见陷阱

1. **`get_tree()` 在 static 方法中不能用** → 用 `hero.get_tree()`
2. **Prayer 是一次性扣血**（Lv1=65%），不是逐秒扣
3. **Ball Lightning 在鼠标位置生成**，不是英雄位置
4. **Stone Enchanted 是被动**，敌人攻击主角时概率石化
5. **MistFog 持续20秒**，敌人进出区域时自动添加/移除减速效果
6. **Chain Lightning 用户没确认最终效果**，可能需要改

---

**祝开发顺利！有问题随时问用户，他们很友好。**
