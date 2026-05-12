# Evil Invasion Remake — 新 Agent 交接提示词

> **发送给下一个 coding agent 的提示词**
> **日期**: 2026-05-13
> **项目位置**: `D:\project\E_I_RMK_2\GodotReMake\`（公司） / `e:\EvilInvasion\GodotReMake\`（家）
> **GitHub仓库**: https://github.com/54Lynnn/E_I_RMK_2
> **最新更新**: 快捷槽位系统（4槽位 2×2 网格 + 悬浮分配快捷键）

---

## 快速开始

1. 打开 Godot 4.6.2，导入项目 `GodotReMake/`
2. 运行主场景 `Main.tscn`
3. 按 F2 进入开发模式（获得100属性点+100技能点）
4. 按 T 打开技能树面板，给所有技能升级测试

---

## 当前项目状态（2026-05-13）

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

**UI/UX增强**：
- [x] **暂停菜单（PauseMenu）**：ESC打开，包含Resume/Save/Load/Return to Menu/Quit，游戏暂停
- [x] **死亡画面（GameOverScreen）**：显示关卡、击杀数、等级，提供Retry/Return to Menu；Survival模式显示累积经验值
- [x] **关卡完成画面（LevelCompleteScreen）**：本关统计，Continue进入下一关
- [x] **通关画面（VictoryScreen）**：全10关通关祝贺，清除Quest进度，Return to Menu
- [x] **技能栏冷却显示**：灰色扇形遮罩覆盖在技能图标上，显示冷却进度
- [x] **怪物信息显示（Alt键切换）**：按左Alt显示/隐藏怪物血条和伤害数字
- [x] **受击红晕（血量相关）**：血量低于50%时画面边缘出现径向红晕，血量越低越深
- [x] **快捷槽位系统（4槽位）**：LMB/RMB/Shift/Space 四个快捷槽位，2×2网格布局，悬浮技能图标+按Shift/Space分配，存档持久化

**技能系统（21个，全部独立场景+独立脚本）**：
- [x] **数值来源**：用户亲自在原版游戏中采集的 xlsx 数据（`evil_invasion_spell.xlsx`），所有技能 1-10 级完整数值
- [x] **英雄技能**：Magic Missile(LMB), Fireball(RMB), Freezing Spear(Z), Prayer(X), Heal(C)
- [x] **Earth系**：Teleport(2), MistFog(3), WrathOfGod(4), **StoneEnchanted(被动)**
- [x] **Air系**：Telekinesis(Q), Sacrifice(R), HolyLight(E), **Ball Lightning(I)**, **Chain Lightning(O)**
- [x] **Fire系**：FireWalk(U), Meteor(F), Armageddon(G)
- [x] **Water系**：PoisonCloud(H), Fortune(V), DarkRitual(B), Nova(N)
- [x] **Debuff系统**（monster.gd: frozen/slowed/petrified 统一管理）
- [x] **Global.hero_took_damage信号**（用于StoneEnchanted等被动反击技能）

**怪物系统（7种）**：
- [x] **数据驱动**：所有数值来自 `monster_database.gd`
- [x] **统一边缘生成**：所有模式怪物均从地图四边生成
- [x] **统一游荡**：墙壁反弹（碰到墙壁像光线反射）
- [x] **近战怪物**：Troll, Bear, Spider, Demon（检测400px，攻击40px）
- [x] **远程怪物**：Mummy(Archer)（检测500px，射箭保持距离）
- [x] **特殊怪物**：Reaper（远程火焰攻击），Diablo（Boss，召唤其他怪物）
- [x] **四种生成模式**：单个(1~3秒)/整排(18~22秒)/编组(8~12秒)/全边界(38~42秒)

### 🔧 待完成

1. ~~**高等级技能测试**~~ ✅ **已完成**（所有技能全等级效果已确认）
2. ~~**Quest模式完善**~~ ✅ **已完成**（通关结算/死亡/通关画面已完成）
3. **音效系统**：用户打算最后添加
4. **地图系统**：目前只有一张测试地图，原版有8张地图
5. ~~**技能平衡**~~ ✅ **已完成**（参考 xlsx 数据已全部确认）
6. **UI美化**：关卡选择器UI简陋（当前体验可接受，不优先）

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
├── Monsters/        ← 所有怪物脚本在这里（7种）
│   ├── monster_base.gd
│   ├── monster_melee.gd
│   ├── monster_ranged.gd
│   └── monster_database.gd
├── Quest/           ← Quest模式相关脚本
├── pause_menu.gd    ← 暂停菜单（ESC打开）
├── game_over_screen.gd  ← 死亡画面覆盖层
├── level_complete_screen.gd  ← 关卡完成画面
├── victory_screen.gd  ← 全通通关画面
├── cooldown_overlay.gd  ← 技能冷却扇形遮罩控件
├── hero.gd          ← 英雄控制（所有技能 import 路径为 `res://Scripts/Spells/xxx.gd`）
├── global.gd        ← 全局单例（Autoload）
└── ...
```

注意：PauseMenu 被实例化在 Main.tscn 和 QuestMain.tscn 的 CanvasLayer 下。
GameOverScreen 和 LevelCompleteScreen 是动态创建的覆盖层（death/completion 时 add_child 到当前场景）。
VictoryScreen 是独立场景，由 LevelCompleteScreen 在最后一关时跳转进入。

### 3. 技能栏冷却显示
- 每个技能按钮上覆盖一个 `CooldownOverlay`（基于 Control 的 `draw_polygon`）
- 使用 `cooldown_overlay.gd` 脚本，通过 `set_progress(0.0~1.0)` 控制扇形显示
- 峰值检测机制：首次观察到冷却值时记录为峰值，后续冷却值更高时更新峰值
- 冷却结束时重置峰值为0，扇形消失
- HUD 技能ID到 hero.skill_cooldowns key 的映射在 `SKILL_COOLDOWN_KEY_MAP` 中（注意 fire_ball → fireball）

### 4. Alt键切换怪物信息
- 绑定的操作名为 `toggle_monster_health`，物理键码为 `KEY_ALT`（131072）
- 切换 `Global.show_monster_info` 布尔值
- 开启时效果：
  - 所有存活怪物的血条一直可见
  - 怪物受到伤害时显示黄色伤害数字（向上飘动0.8秒后消失）
- 关闭时效果：
  - 血条仅在怪物受伤时短暂显示
  - 不显示伤害数字
- 新生成的怪物会根据当前 `Global.show_monster_info` 状态决定血条初始可见性

### 5. 受击红晕（Damage Vignette）
- ColorRect 直接定义在 `HUD.tscn` 中，确保 100% 被加载
- 运行时 hud.gd 的 `_setup_damage_shader()` 为其附加 ShaderMaterial
- shader 代码内联在 GDScript 字符串中，不依赖任何外部文件
- **径向渐变效果**（vignette）：
  - 画面中心半径 25% 范围内完全透明
  - 从中间到边缘红色渐深
  - `pow(distance, 2.0)` 曲线使过渡自然
- hud.gd 的 `_update_damage_overlay()` 控制 shader 的 intensity 参数：
  - 血量 > 50%：intensity = 0（完全透明）
  - 血量 ≤ 50%：intensity 从 0 → 1.0 线性增加

### 6. HUD 布局（2026-05-13 重构 + 快捷槽位）

- **瘦底栏设计**：整体底栏高度 86px（比旧版更矮）
- **左侧信息区**：等级标签 + HP条 + MP条（垂直排列，不再包含经验条）
- **右侧技能栏**：8个技能图标（34×34px，间距2px），与左侧信息区上边缘平齐
- **快捷槽位（2×2网格）**：位于技能栏右侧，4个槽位（46×30px面板）
  - 上排：LMB（左键）、RMB（右键）
  - 下排：Shift、Space
  - 每个槽位右下角有半透明快捷键小字提示
  - 图标 42×26px 居中显示，无技能名称文字
  - 底部缩进 offset_bottom=-14，与 ExpBar 保持 2px 间距
- **底部通栏经验条**：全宽 ProgressBar，居中显示 "LEVEL X" 文字
- **Buff/Debuff 图标**：位于底栏上方
- 节点结构：
  ```
  HUD (Control)
  ├── DamageOverlay (ColorRect) — 受击红晕
  ├── BuffContainer (HBoxContainer) — Buff/Debuff图标
  └── BottomBar (Panel)
      ├── LeftInfo (VBoxContainer)
      │   ├── LevelLabel
      │   ├── HPBar
      │   └── MPBar
      ├── SkillBar (HBoxContainer) — 8个技能按钮
      ├── QuickSlots (Control) — 2×2快捷槽位网格
      │   ├── SlotLMB (Panel) + SlotLMBIcon + SlotLMBLabel("LMB")
      │   ├── SlotRMB (Panel) + SlotRMBIcon + SlotRMBLabel("RMB")
      │   ├── SlotShift (Panel) + SlotShiftIcon + SlotShiftLabel("Shift")
      │   └── SlotSpace (Panel) + SlotSpaceIcon + SlotSpaceLabel("Space")
      ├── ExpBar (ProgressBar) — 通栏经验条
      └── ExpLabel (Label) — "LEVEL X" 居中文字
  ```

### 7. Survival 模式死亡统计
- `Global.survival_total_exp_gained`：Survival 模式本轮累积获得的经验值
- 每次获得经验时累加（在 hero.gd 中）
- 死亡时 GameOverScreen 显示 "EXPERIENCE GAINED: X" 而非击杀数
- Quest 模式死亡仍显示击杀数

### 8. 暂停菜单（PauseMenu）注意事项
- 使用已存在的 `pause_game` 输入动作（ESC键）
- HeroPanel 和 PauseMenu 互斥：通过 `Global.is_pause_menu_open` 和 `Global.hero_panel_is_open` 控制
- 当 PauseMenu 打开时，HeroPanel 的 C 键不响应
- PauseMenu 使用 `process_mode = 3`（WHEN_PAUSED）以在暂停时仍能处理输入
- layer = 100，确保显示在最上层

### 9. hero.gd 导入路径
```gdscript
# ✅ 正确：所有技能导入使用子目录路径
const BallLightning = preload("res://Scripts/Spells/ball_lightning.gd")
# ❌ 错误：不要用 Scripts/ 根目录
const BallLightning = preload("res://Scripts/ball_lightning.gd")
```

### 10. Ball Lightning 行为
- 在**鼠标光标位置**生成
- 在生成点 **130px 范围内随机游荡**
- 检测 **200px 内的敌人**，攻击最近的
- 攻击时从闪电球到目标出现**蓝白色激光束**特效
- 每次攻击间隔 **1 秒**，最多攻击 **5 次**
- 最大存活时间 **10 秒**

### 11. Chain Lightning
- 当前实现：从鼠标位置向最近敌人弹跳5次
- 注意：用户还没有确认这个实现是否符合预期，可能需要修改

### 12. Prayer 正确行为
- **一次性消耗生命值**（Lv1=65%，Lv10=20%），不是逐秒扣血
- 然后持续10秒回蓝

### 13. 元素属性分配
```
basic:  magic_missile
earth:  stone_enchanted, wrath_of_god, prayer, teleport, mistfog
air:    holy_light, sacrifice, ball_lightning, chain_lightning, telekinesis
fire:   fireball, fire_walk, meteor, armageddon, heal
water:  freezing_spear, poison_cloud, dark_ritual, nova, fortuna
```

### 14. 按钮绑定

| 按键 | 技能 | 按键 | 技能 |
|:----:|:----|:----:|:----|
| LMB | 快捷槽位LMB（默认Magic Missile） | RMB | 快捷槽位RMB（默认Fireball） |
| Shift | 快捷槽位Shift | Space | 快捷槽位Space |
| Z | Freezing Spear | X | Prayer |
| C | Heal | 2 | Teleport |
| 3 | Mist Fog | 4 | Wrath of God |
| Q | Telekinesis | R | Sacrifice |
| E | Holy Light | U | Fire Walk |
| F | Meteor | G | Armageddon |
| H | Poison Cloud | V | Fortuna |
| B | Dark Ritual | N | Nova |
| **I** | **Ball Lightning** | **O** | **Chain Lightning** |

**快捷槽位说明**：
- LMB/RMB/Shift/Space 不再是固定技能，而是可自定义的快捷槽位
- **分配方式**：
  - LMB/RMB：在技能栏图标上**点击鼠标左键/右键**即可分配
  - Shift/Space：**鼠标悬浮**在技能图标上，按 Shift 或 Space 键分配
- 分配后图标显示在对应槽位中，右下角有快捷键小字提示
- 快捷槽位配置会随存档保存/读取

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