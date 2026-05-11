# Evil Invasion Remake — 工作交接提示词

> **发送给下一个 coding agent 的提示词**
> **日期**: 2026-05-11
> **项目位置**: `e:\EvilInvasion\GodotReMake\`
> **上一个Agent最后工作**: 
> - 统一怪物生成与游荡行为（边缘生成+墙壁反弹）
> - 统一英雄出生点（Survival/Quest均为1280,1280）
> - 修正近战怪物攻击范围为40px（贴身才攻击）
> - 统一检测范围（近战400px/远程500px）
> - 更新所有交接文档

---

## 🚀 快速开始

1. 打开 Godot 4.6.2，导入项目 `e:\EvilInvasion\GodotReMake\`
2. 运行主场景 `Main.tscn`
3. 按 F2 进入开发模式（获得100属性点+100技能点）
4. 按 T 打开技能树面板

---

## 📊 当前状态概览

### 已完成 ✅
- **21个技能**全部实现（独立场景+独立脚本），原版21个技能（含Ball Lightning和Chain Lightning）
- **8种怪物**：Zombie, Bear, Archer(Mummy), Reaper, Demon, Boss(Diablo), Spider, Troll
- **经验值系统**：简化公式 `exp_to_next = hero_level * 200`（每级固定增加200）
- **属性分配系统**（5属性：力量/敏捷/耐力/智力/智慧）
- **掉落系统**（12种物品，5种稀有度）
- **开发模式**（F2切换）
- **Buff/Debuff图标显示**
- **Quest模式基础系统**（10关线性推进、波次生成、等级上限、边缘生成、游荡AI）
- **统一怪物生成**（所有模式边缘生成+安全边界）
- **统一怪物游荡**（墙壁反弹+正常速度）
- **统一英雄出生点**（Survival/Quest均为1280, 1280）

### 待完成 🔧
1. **高等级技能测试**（仅Magic Missile和Freezing Spear测试了高等级，其他21个技能高等级未充分测试）
2. **音效系统**（用户打算最后做）
3. **存档系统**（FileAccess + JSON）
4. **地图/关卡系统**（原版有8张地图）
5. **UI完善**（系别头像、更好的技能提示框等）
6. **技能平衡**（参考 `E:\EvilInvasion\evil_invasion_spell.xlsx`）
7. **Quest模式完善**（关卡解锁持久化、Boss战特殊设计、通关奖励）

---

## 🎯 关键信息

### 经验值公式（重要！）
```gdscript
# 升级所需经验 = 当前等级 × 200
var exp_to_next = hero_level * 200
```
已在以下文件中修改：
- `Scripts/global.gd`（3处）
- `Scripts/hud.gd`（1处）
- `Scripts/pickup_item.gd`（1处）
- `Scripts/hero_panel.gd`（1处）

### 怪物数据（数据驱动）
```gdscript
# 所有怪物数值来自 monster_database.gd
# 近战：攻击范围=40px，检测范围=400px
# 远程：攻击范围=150-380px，检测范围=500px
```

### 技能按键绑定
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

### 技能属性分配
```
basic:  magic_missile
earth:  stone_enchanted, wrath_of_god, prayer, teleport, mistfog
air:    holy_light, sacrifice, ball_lightning, chain_lightning, telekinesis
fire:   fireball, fire_walk, meteor, armageddon, heal
water:  freezing_spear, poison_cloud, dark_ritual, nova, fortuna
```

### 项目结构
```
Scripts/
├── global.gd, hero.gd, hud.gd, etc.
├── Spells/          # 技能脚本（21个）
│   ├── magic_missile.gd, fireball.gd, etc.
│   ├── ball_lightning.gd      # I键
│   └── chain_lightning.gd     # O键
└── Monsters/        # 怪物脚本（8种）
    ├── monster_base.gd
    ├── monster_melee.gd
    ├── monster_ranged.gd
    └── monster_database.gd
```

---

## 📚 必读文档

1. `DEVELOPER_HANDOVER.md` — 详细交接文档
2. `NEXT_AGENT_PROMPT.md` — 当前任务状态
3. `SPELL_DEVELOPMENT_GUIDE.md` — 技能开发规范
4. `NAMING_CONVENTIONS.md` — 命名规范

---

**祝开发顺利！**
