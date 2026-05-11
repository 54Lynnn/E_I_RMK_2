# Evil Invasion Remake — 新 Agent 交接提示词

> **发送给下一个 coding agent 的提示词**
> **日期**: 2026-05-12
> **项目位置**: `d:\project\E_I_RMK_2\GodotReMake\`
> **上一个Agent最后工作**: 
> - 实现存档系统（F5保存/F10读取，JSON格式）
> - 实现受击恢复系统（不能施法+减速20%，力量减少恢复时间）
> - 实现四种怪物生成模式（单个/整排/编组/全边界）
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
- **Ball Lightning 和 Chain Lightning 是原版Air系技能，已实现**（按键I和O）

**怪物系统**：
- 8 种怪物已实现：Zombie, Bear, Archer(Mummy), Reaper, Demon, Boss(Diablo), Spider, Troll
- **数据驱动**：所有怪物数值来自 `monster_database.gd`，随等级和难度动态缩放
- **统一生成**：所有模式（Quest/Survival）怪物均从地图边缘生成（安全边界80px）
- **统一游荡**：所有怪物生成后随机游荡，碰到墙壁像光线反射一样反弹
- **统一检测范围**：近战400px，远程500px
- **统一攻击范围**：近战40px（贴身），远程150-380px
- **四种生成模式**：
  - 单个生成（1~3秒间隔）
  - 整排生成（18~22秒间隔，20只）
  - 编组生成（8~12秒间隔，4/6/9只）
  - 全边界生成（38~42秒间隔，60只，需9级解锁）

**Quest模式**：
- 10关线性推进系统（Ancient Way → Diablo's Lair）
- 波次生成（4/6/9只一组）
- 等级上限（每关最多升4级）
- 通关检测（清除所有怪物）

**存档系统**：
- F5保存/F10读取
- JSON格式存储
- 保存英雄状态、属性、技能、位置
- 读档时清理怪物和掉落物

**受击恢复系统**：
- 被攻击后不能施法
- 移动速度降低20%
- 恢复时间：`max(0.1, 0.5 - strength * 0.004)`
- 每次受击刷新恢复时间

**经验值系统**：
- **简化公式**：`exp_to_next = hero_level * 200`
- 每级固定增加200经验值

**其他**：
- 属性分配系统
- 掉落系统
- 开发模式（F2）
- HUD 血/蓝/经验条
- Buff/Debuff 图标显示
- 相机跟随
- 伤害类型系统（5种元素）

### ⚠️ 待完成/待测试

1. **高等级技能测试**：仅 Magic Missile 和 Freezing Spear 测试了高等级，其他21个技能高等级未充分测试
2. **添加音效**：用户打算最后做
3. **地图/关卡系统**：原版有多张地图
4. **完善UI**：添加系别头像、更好的技能提示框等
5. **技能平衡**：测试并调整技能数值（参考Excel文件）
6. **Quest模式完善**：关卡解锁持久化、Boss战特殊设计、通关奖励

---

## 🔧 关键代码规范

### 1. 经验值公式（已简化）
```gdscript
# 升级所需经验 = 当前等级 × 200
var exp_to_next = hero_level * 200
```
- 修改位置：`Scripts/global.gd`（3处）、`Scripts/hud.gd`（1处）、`Scripts/pickup_item.gd`（1处）、`Scripts/hero_panel.gd`（1处）

### 2. 怪物数据（数据驱动）
```gdscript
# 所有怪物数值来自 monster_database.gd
# 近战：攻击范围=40px，检测范围=400px
# 远程：攻击范围=150-380px，检测范围=500px
```

### 3. 技能属性分配（必须遵守）
```
basic:  magic_missile
earth:  stone_enchanted, wrath_of_god, prayer, teleport, mistfog
air:    holy_light, sacrifice, ball_lightning, chain_lightning, telekinesis
fire:   fireball, fire_walk, meteor, armageddon, heal
water:  freezing_spear, poison_cloud, dark_ritual, nova, fortuna
```

### 4. 技能按键绑定
| 按键 | 技能 | 元素 |
|------|------|------|
| 鼠标左键 | Magic Missile | basic |
| 鼠标右键 | Fireball | fire |
| Z | Freezing Spear | water |
| X | Prayer | earth |
| C | Heal | fire |
| 2 | Teleport | earth |
| 3 | Mist Fog | earth |
| 4 | Wrath of God | earth |
| Q | Telekinesis | air |
| R | Sacrifice | air |
| E | Holy Light | air |
| U | Fire Walk | fire |
| F | Meteor | fire |
| G | Armageddon | fire |
| H | Poison Cloud | water |
| V | Fortuna | water |
| B | Dark Ritual | water |
| N | Nova | water |
| I | Ball Lightning | air |
| O | Chain Lightning | air |

---

## ⚠️ 重要注意事项

### 1. 怪物脚本架构
```
monster_base.gd (核心：移动、受击、死亡、游荡)
  ├── monster_melee.gd (近战：追击→攻击)
  │     ├── monster_spider.gd
  │     ├── monster_zombie.gd
  │     ├── monster_bear.gd
  │     ├── monster_demon.gd (追击加速+40%)
  │     ├── monster_reaper.gd
  │     ├── monster_troll.gd
  │     └── monster_diablo.gd (Boss)
  └── monster_ranged.gd (远程：保持距离、射箭、逃跑转身)
        └── monster_mummy.gd (Archer，使用Mummy贴图)
```

### 2. 统一怪物行为（所有模式）
- **生成**：从地图四边随机位置生成（边缘但不在墙里）
- **游荡**：生成后向随机方向游荡，碰到墙壁像光线反射一样反弹（X/Y轴分别取反）
- **发现玩家**：当玩家进入检测范围时，开始追击
- **攻击**：靠近玩家后发动攻击（近战40px，远程150-380px）
- **丢失目标**：玩家离开检测范围后，恢复游荡

### 3. 怪物生成模式
```gdscript
enum SpawnPattern { SINGLE, LINE, GROUP, ALL_SIDES }
```
- **SINGLE**: 1~3秒间隔，1只
- **LINE**: 18~22秒间隔，20只均匀铺开，排除reaper/diablo
- **GROUP**: 8~12秒间隔，4/6/9只编组，排除diablo
- **ALL_SIDES**: 38~42秒间隔，四边各15只共60只，需9级解锁，Quest模式17级前不触发

### 4. 常见陷阱
- **技能图标路径**：`res://Art/Placeholder/SkillName.png`，注意大小写
- **节点引用**：修改场景后确保脚本中的 `@onready` 引用正确
- **法力/生命修改后**：必须发射信号（如 `Global.mana_changed.emit()`）
- **坐标系**：异步发射技能使用 `hero.get_global_mouse_position()` 获取世界坐标
- **怪物生成位置**：所有模式均从边缘生成，不再从玩家周围生成

---

## 🚀 快速开始

1. 打开 Godot 4.6.2，导入项目 `d:\project\E_I_RMK_2\GodotReMake\`
2. 运行主场景 `Main.tscn`
3. 按 F2 进入开发模式（获得100属性点+100技能点）
4. 按 T 打开技能树面板
5. 按 F5 保存游戏，F10 读取存档

---

**祝开发顺利！**
