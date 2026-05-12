# Evil Invasion Remake — 交接提示词

> **发送给下一个 coding agent 的提示词**
> **日期**: 2026-05-07
> **项目位置**: `D:\project\E_I_RMK_2\GodotReMake\`（公司） / `e:\EvilInvasion\GodotReMake\`（家）
> **GitHub仓库**: https://github.com/54Lynnn/E_I_RMK_2

---

## 快速开始

1. 打开 Godot 4.6.2，导入项目 `GodotReMake/`
2. 运行主场景 `Main.tscn`
3. 按 F2 进入开发模式（获得100属性点+100技能点）
4. 按 T 打开技能树面板，给所有技能升级测试

---

## 当前项目状态（2026-05-07）

### 已完成 ✅

**核心系统**：
- [x] WASD移动 + 鼠标瞄准 + 独立冷却系统
- [x] 属性系统（5属性：力量/敏捷/耐力/智力/智慧）
- [x] 经验值简化公式（`exp_to_next = hero_level * 200`）
- [x] 开发模式（F2，+100属性点+100技能点）
- [x] 掉落系统（12种物品，5种稀有度）
- [x] **存档系统**（F5保存/F10读取，JSON格式）
- [x] **受击恢复系统**（被攻击后不能施法+减速20%）
- [x] **Buff/Debuff图标显示**
- [x] **游戏模式选择**（Survival / Quest）
- [x] **Quest模式**（10关线性推进、波次生成、等级上限、关卡选择器、存档持久化）

**技能系统（21个，全部独立场景+独立脚本）**：
- [x] **数值来源**：用户亲自在原版游戏中采集的 xlsx 数据（`evil_invasion_spell.xlsx`），所有技能 1-10 级完整数值
- [x] **英雄技能**：Magic Missile(LMB), Fireball(RMB), Freezing Spear(Z), Prayer(X), Heal(C)
- [x] **Earth系**：Teleport(2), MistFog(3), WrathOfGod(4), **StoneEnchanted(被动)**
- [x] **Air系**：Telekinesis(Q), Sacrifice(R), HolyLight(E), **Ball Lightning(I)**, **Chain Lightning(O)**
- [x] **Fire系**：FireWalk(U), Meteor(F), Armageddon(G)
- [x] **Water系**：PoisonCloud(H), Fortune(V), DarkRitual(B), Nova(N)
- [x] **Debuff系统**（monster.gd: frozen/slowed/petrified 统一管理）
- [x] **Global.hero_took_damage信号**（用于StoneEnchanted等被动反击技能）

**怪物系统（8种）**：
- [x] **数据驱动**：所有数值来自 `monster_database.gd`
- [x] **统一边缘生成**：所有模式怪物均从地图四边生成
- [x] **统一游荡**：墙壁反弹（碰到墙壁像光线反射）
- [x] **近战怪物**：Zombie, Bear, Spider, Demon, Troll, Reaper（检测400px，攻击40px）
- [x] **远程怪物**：Mummy(Archer)（检测500px，射箭保持距离）
- [x] **Boss**：Diablo（高血量，生成其他怪物）
- [x] **四种生成模式**：单个(1~3秒)/整排(18~22秒)/编组(8~12秒)/全边界(38~42秒)

### 🔧 待完成

1. **高等级技能测试**：大部分技能仅确认了LV1效果，高等级未充分测试
2. **音效系统**：用户打算最后添加
3. **地图系统**：目前只有一张测试地图，原版有8张地图
4. **Quest模式完善**：Boss战特殊设计、通关奖励结算画面
5. **UI美化**：关卡选择器UI简陋
6. **技能平衡**：参考 xlsx 文件调整

---

## ⚠️ 关键注意事项

### 1. 技能数值来源
- **❌ 不要使用 `extracted.md` 的技能数据**（该数据有等级偏移错误）
- **✅ 唯一可信来源**：`evil_invasion_spell.xlsx`（用户亲自采集）
- 所有技能脚本中的数值公式已按 xlsx 数据实现

### 2. 文件路径（重要！）
```
Scripts/
├── Spells/          ← 所有技能脚本在这里（21个）
│   ├── magic_missile.gd
│   ├── ball_lightning.gd    # I键
│   └── chain_lightning.gd   # O键
├── Monsters/        ← 所有怪物脚本在这里（8种）
│   ├── monster_base.gd
│   ├── monster_melee.gd
│   ├── monster_ranged.gd
│   └── monster_database.gd
├── Quest/           ← Quest模式相关脚本
├── hero.gd          ← 英雄控制（所有技能 import 路径为 `res://Scripts/Spells/xxx.gd`）
├── global.gd        ← 全局单例（Autoload）
└── ...
```

### 3. hero.gd 导入路径
```gdscript
# ✅ 正确：所有技能导入使用子目录路径
const BallLightning = preload("res://Scripts/Spells/ball_lightning.gd")
# ❌ 错误：不要用 Scripts/ 根目录
const BallLightning = preload("res://Scripts/ball_lightning.gd")
```

### 4. Ball Lightning 行为
- 在**鼠标光标位置**生成
- 在生成点 **130px 范围内随机游荡**
- 检测 **200px 内的敌人**，攻击最近的
- 攻击时从闪电球到目标出现**蓝白色激光束**特效
- 每次攻击间隔 **1 秒**，最多攻击 **5 次**
- 最大存活时间 **10 秒**

### 5. Chain Lightning
- 当前实现：从鼠标位置向最近敌人弹跳5次
- 注意：用户还没有确认这个实现是否符合预期，可能需要修改

### 6. Prayer 正确行为
- **一次性消耗生命值**（Lv1=65%，Lv10=20%），不是逐秒扣血
- 然后持续10秒回蓝

### 7. 元素属性分配
```
basic:  magic_missile
earth:  stone_enchanted, wrath_of_god, prayer, teleport, mistfog
air:    holy_light, sacrifice, ball_lightning, chain_lightning, telekinesis
fire:   fireball, fire_walk, meteor, armageddon, heal
water:  freezing_spear, poison_cloud, dark_ritual, nova, fortuna
```

### 8. 按钮绑定
| 按键 | 技能 | 按键 | 技能 |
|:----:|:----|:----:|:----|
| LMB | Magic Missile | RMB | Fireball |
| Z | Freezing Spear | X | Prayer |
| C | Heal | 2 | Teleport |
| 3 | Mist Fog | 4 | Wrath of God |
| Q | Telekinesis | R | Sacrifice |
| E | Holy Light | U | Fire Walk |
| F | Meteor | G | Armageddon |
| H | Poison Cloud | V | Fortuna |
| B | Dark Ritual | N | Nova |
| **I** | **Ball Lightning** | **O** | **Chain Lightning** |

---

## 必读文档

1. `DEVELOPER_HANDOVER.md` — 完整项目文档
2. `SPELL_DEVELOPMENT_GUIDE.md` — 技能开发规范（必须遵守）
3. `NAMING_CONVENTIONS.md` — 命名规范（文件、节点、代码）
4. `evil_invasion_spell.xlsx` — 技能数值参考（唯一可信来源）

---

## 用户偏好

- 使用中文交流
- 重视视觉效果还原
- "一个技能一个场景"的架构
- 数值以他采集的游戏数据为准，不要相信反编译提取的数据
- 习惯逐个技能测试、逐个修改的方式

---

**祝开发顺利！**
