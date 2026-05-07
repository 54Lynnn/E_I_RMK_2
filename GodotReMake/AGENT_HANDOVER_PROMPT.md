# Evil Invasion Remake — 新 Agent 接手提示词

> 直接复制以下内容发送给新 Agent

---

你正在接手一个 **Godot 4.6** 项目：Evil Invasion (2006) 的复刻版。

## 📁 项目位置

```
e:\EvilInvasion\GodotReMake\
```

## 📖 必读文档

项目根目录下已有两份文档，**请先阅读**：

1. **`ROADMAP.md`** — 完整开发路线图和原版游戏参数参考
2. **`DEVELOPER_HANDOVER.md`** — 详细的开发者交接文档（文件结构、核心系统、技术债务、下一步建议）
3. **`SPELL_DEVELOPMENT_GUIDE.md`** — 技能开发规范（必须遵守）

## ⚡ 快速了解当前状态

### 已完成 ✅
- 英雄 WASD 移动 + 鼠标瞄准
- **21 种法术全部实现**（在 `hero.gd` 中，共 ~990 行）
- **3 个技能已重构为独立场景**：Magic Missile、Fireball、Freezing Spear
- **伤害类型系统**：五种元素属性（basic, earth, air, fire, water）
- **技能独立冷却系统**：每个技能有自己的冷却时间，可同时施放多个技能
- **长按持续施法**：按住技能键可持续施放（受冷却限制）
- 技能树系统（4 元素学派 × 5 技能，含前置条件）
- 属性加点系统（5 种属性）
- DevMode（按 F2，给 100 技能点 + 100 属性点）
- 英雄面板 UI（按 T 打开）
- 怪物系统（目前只有蜘蛛兵）
- 物品掉落与拾取
- HUD（血/蓝/经验条）

### 当前问题 🔧
- **18 个技能仍使用旧版内联实现**，需要继续重构为独立场景
- `hero.gd` 仍然臃肿（所有法术硬编码在一起）
- 技能按键绑定不完整（目前只有 3 个技能有绑定）
- 只有 1 种怪物，需要扩展
- 无存档系统
- 无音效
- 所有纹理都是占位图

## 🎯 你的首要任务

根据用户需求，以下是最可能的工作内容：

### 1. 继续重构法术系统（高优先级）
**已有3个技能完成重构**，参考它们的代码结构继续重构剩余18个技能：

**已完成的独立场景（参考模板）**：
- `Scenes/MagicMissile.tscn` + `Scripts/magic_missile.gd` — 追踪投射物
- `Scenes/Fireball.tscn` + `Scripts/fireball.gd` — 爆炸AOE
- `Scenes/FreezingSpear.tscn` + `Scripts/freezing_spear.gd` — 直线穿透+冰冻

**重构模式**（必须遵守 `SPELL_DEVELOPMENT_GUIDE.md`）：
1. 在 `Scenes/` 创建 `{SkillName}.tscn`（Area2D 根节点 + CollisionShape2D + Sprite2D + Particles）
2. 在 `Scripts/` 创建 `{skill_name}.gd`（继承 Area2D）
3. 脚本中定义静态配置变量（`skill_name`, `base_cooldown`, `base_mana_cost`, `base_damage`）
4. 实现静态 `cast(hero, mouse_pos, skill_cooldowns)` 方法
5. 在 `hero.gd` 中导入脚本并调用 `SkillName.cast(self, mouse_pos, skill_cooldowns)`
6. 在 `global.gd` 的 `skill_levels` 中添加技能名称（必须与脚本中的 `skill_name` 一致）
7. 在 `project.godot` 中添加输入映射（如需要）

**待重构技能列表**（按系别）：
- **Earth**: Prayer, Teleport, MistFog, StoneEnchanted, WrathOfGod
- **Air**: Telekinesis, HolyLight, Sacrifice, BallLightning, ChainLightning
- **Fire**: Heal, FireWalk, Meteor, Armageddon
- **Water**: PoisonCloud, Fortuna, DarkRitual, Nova

### 2. 添加更多怪物
参考 `DEVELOPER_HANDOVER.md` 中的怪物参数表，实现：
- 熊（高血量、慢速）
- 弓手（远程攻击）
- 恶魔（快速）
- 死神（法力燃烧）
- Boss（多阶段）

### 3. 完善 UI
- 主菜单（New Game / Load Game / Options / Quit）
- 暂停菜单
- 游戏结束界面
- 快捷栏系统（底部 8 个法术槽位）

### 4. 存档系统
使用 `FileAccess` 存储 JSON 到 `user://profiles.json`

## 🔑 关键文件速查

| 文件 | 用途 |
|------|------|
| `Scripts/global.gd` | 全局状态（Autoload），管理属性、技能等级、Buff |
| `Scripts/hero.gd` | 英雄控制 + 所有法术调用（~990 行，逐步重构中） |
| `Scripts/hero_panel.gd` | 英雄面板 UI（技能树 + 属性） |
| `Scripts/monster.gd` | 怪物 AI（状态机） |
| `Scripts/loot_manager.gd` | 掉落管理（Autoload） |
| `Scripts/hud.gd` | 底部 HUD |
| `Scripts/magic_missile.gd` | ✅ Magic Missile 独立脚本（参考模板） |
| `Scripts/fireball.gd` | ✅ Fireball 独立脚本（参考模板） |
| `Scripts/freezing_spear.gd` | ✅ Freezing Spear 独立脚本（参考模板） |
| `SPELL_DEVELOPMENT_GUIDE.md` | 技能开发规范（必须遵守） |
| `project.godot` | 输入映射在这里配置 |

## ⚠️ 重要注意事项

### 技能名称一致性
**极其重要！** 技能名称必须在所有文件中保持一致：
- 脚本内 `skill_name`：`"magic_missile"`
- `global.gd` 的 `skill_levels` key：`"magic_missile"`
- `hero.gd` 的 `skill_cooldowns` key：`"magic_missile"`
- `project.godot` 的输入动作名：`spell_magic_missile`

### 当前按键绑定
- 鼠标左键：Magic Missile
- 鼠标右键：Fireball
- Z：Freezing Spear
- 其余技能未绑定按键

### 伤害系统
- 技能伤害是**固定值**，不包含英雄属性加成
- 伤害仅与技能等级相关
- 禁止在伤害计算中加入 `Global.hero_intelligence` 等属性

### Muzzle 节点路径
获取发射口时必须使用正确路径：
```gdscript
var muzzle = hero.get_node("Sprite2D/Muzzle")  # ✅ 正确
var muzzle = hero.get_node("Muzzle")             # ❌ 错误，会返回 null
```
