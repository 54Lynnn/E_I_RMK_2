# Evil Invasion Remake — 新 Agent 交接提示词

> **项目**: Evil Invasion (2006年Flash游戏) Godot 4.6 重制版
> **引擎**: Godot 4.6.2
> **GitHub**: https://github.com/54Lynnn/E_I_RMK_2
> **最新更新**: v12 Agent — hero.gd全面重构 + 统一施法调度 + 冷却缩减遗物修正 + 全项目性能优化

## 快速开始

1. `git clone` 后在 Godot 4.6.2 中导入 `GodotReMake/` 项目
2. 运行 `Scenes/Main.tscn`（Survival模式）或先运行 `GameModeSelect.tscn`
3. 按 **F2** 进入 DevMode（+100属性点+100技能点方便测试）
4. 按 **T** 打开技能树，给技能升级

## 必读文档

请依次阅读以下文档，它们包含了完整的项目信息：

1. **`HANDOVER_PROMPT_FOR_NEXT_AGENT.md`** — 项目完整状态、关键注意事项、最新变更（**最重要！**）
2. **`DEVELOPER_HANDOVER.md`** — 完整项目文档、核心系统详解
3. **`GAME_SYSTEMS_DESIGN.md`** — 游戏系统设计文档
4. **`ROADMAP.md`** — 开发路线图

---

## v10 会话完成的工作（2026-05-15）

### ✨ 新功能
- **Controls Guide 操作指南**：主菜单和暂停菜单中增加操作指南图片浏览功能，玩家可查看所有快捷键说明
- **Firewalk Toggle 重写**：将 firewalk 从普通技能重写为 toggle 类技能（按 U 开关），移动时每 30px 产生一团火焰，火焰使用 Area2D + CircleShape2D 物理碰撞检测伤害，每 0.1s 结算一次 DOT
- **爆炸伤害检测统一**：将所有范围技能的伤害判定从"怪物节点原点距离"改为"物理碰撞体重叠检测"（Area2D.get_overlapping_bodies() / PhysicsShapeQueryParameters2D.intersect_shape()），怪物碰撞体接触到范围边缘即判伤
- **游戏导出配置准备**：export_presets.cfg 配置加密参数（encrypt_pck=true, encrypt_directory=false, script_export_mode=2, embed_pck=true），创建一键导出脚本 export_game.ps1。**✅ 已成功导出加密版单 exe 文件（encrypt_pck + embed_pck 组合可用）**

### 🎯 技能与平衡调整
- **Firewalk 参数**：无 mana cost，移动 30px 产生一团火焰，伤害半径 18px，火焰持续 2 秒（含 0.3s 渐隐），每 0.1s 结算一次 DOT
- **Meteor 平衡**：陨石生成间隔 0.2s → 0.4s，单颗陨石贴图 scale 0.8 → 0.5
- **Armageddon 平衡**：每批陨石数量 15 → 12
- **Autocast 优化**：检查间隔 0.15s → 0.1s
- **Telekinesis 数据修正**：从实际代码（pickup_item.gd）提取真实 hold_time 数据，1 级 1.0s，满级 0.55s

### 🐛 Bug修复
- **Teleport 按"2"键无效**：从 `_process` 移除 teleport 的 `is_action_pressed` 检测（受 `mouse_y < hud_top` 限制），仅保留在 `_unhandled_input`（**注意：v12 已改为仅用 _process，移除了 _unhandled_input**，详见下方 v12 章节）
- **Firewalk 火焰残留**：lambda 闭包捕获 self 导致 queue_free 后回调不执行 → 所有成员值提前复制到局部变量
- **Firewalk 无伤害**：PROCESS_MODE_WHEN_PAUSED 误用 → 改为 PROCESS_MODE_ALWAYS
- **Multicast 导致 firewalk 自动关闭**：cast_fire_walk() 中移除 _try_multicast("fire_walk")
- **hide_tooltip() 与基类方法冲突**：重命名为 _hide_skill_tooltip()
- **暂停时设置 Quickslot**：skill_bar_container.process_mode = PROCESS_MODE_ALWAYS
- **Controls Guide 场景加载失败**：移除 load_steps，使用 [gd_scene format=3]，信号名 closed → guide_closed
- **PROCESS_MODE_WHEN_PAUSED 语义误解**：多次误用，实际语义是"只在暂停时运行"，非暂停时反而不运行 → 改为 PROCESS_MODE_ALWAYS

---

## v11 会话完成的工作（2026-05-16）

### ✨ 导出与加密
- **导出配置修正**：最终工作组合为 `encrypt_pck=true` + `encrypt_directory=false` + `embed_pck=true` + `script_export_mode=2`
- **加密密钥**：在 project.godot 中添加 `[encryption] script_encryption_key`
- **一键导出**：export_game.ps1 脚本可用于 Godot 控制台导出
- **✅ 成功导出加密版单 exe**：build/EvilInvasion_Encrypted.exe，从桌面也能正常运行

### 📝 关键教训文档化
- **新增强制阅读章节**："⚠️ 关键教训：暂停状态下 UI 面板的输入处理"
  - 正确写法：`_input(event)` + `PROCESS_MODE_ALWAYS` + `event.is_action_pressed()`
  - 错误写法对比：`_process(_delta)` + `Input.is_action_just_pressed()` 在暂停时失效
  - 三种方案对比表格（`_input` ✅ vs `_process` ❌ vs `_unhandled_input` ❌）
  - **T/ESC 与技能键（ZXC）的本质区别**：元按键 vs 功能按键，事件流上游 vs 下游
  - 事件流路线图：Input → `_input()`(T/ESC) → UI → `_unhandled_input()`(技能键)
- **踩坑经过**：laptop agent 改坏 → force push 回滚 → 知识沉淀

### 🔧 GitHub 管理
- **force push 回滚**：远程 master 被改坏后，使用 `git push --force origin master` 将远程分支恢复到正常版本
- **全量文档更新**：所有 .md 文档审查、更新、废弃、删除

### 🐛 修复
- **暂停时面板输入处理**：HeroPanel 和 PauseMenu 必须使用 `_input(event)` 而非 `_process(_delta)`，且场景文件必须设置 `process_mode = 3`（PROCESS_MODE_ALWAYS）
- **HANDOVER_PROMPT.md / NEXT_AGENT_PROMPT.md**：标记为废弃，重定向到 HANDOVER_PROMPT_FOR_NEXT_AGENT.md
- **HANDOVER_MESSAGE.md**：已删除（完全过时）

---

### 🔍 Relic 与 Firewalk 交互审计
- 检查所有 relic 与 firewalk 的交互路径
- **范围加成**：RelicManager.get_aoe_radius_multiplier() 正确应用于 firewalk 火焰半径
- **冷却缩减**：不应用于 firewalk（toggle 类技能无冷却）
- **多重施法**：从 cast_fire_walk() 中移除 _try_multicast，toggle 类技能与多重施法不兼容
- **其他 relic**：无意外交互

### 🎨 HUD 改进
- **Firewalk toggle 图标**：hud.gd 新增 _update_firewalk_toggle_icon()，每帧检查 firewalk toggle 状态，开启时图标彩色，关闭时灰色
- **技能 tooltip 数据修正**：所有技能调用实际静态方法（get_damage/get_mana_cost 等），firewalk 显示无 mana cost + toggle 描述

## v12 会话完成的工作（2026-05-16）

### 🏗️ hero.gd 架构重构（重大变更）

**变更一：移除 `_unhandled_input()`，仅用 `_process()` 处理所有技能输入**

旧架构中 `_process()` 和 `_unhandled_input()` **同时**检测全部21个技能的按键状态，导致每按一次技能键被施放两次（一次来自 `_process` 的 `is_action_pressed()`，一次来自 `_unhandled_input` 的 `event.is_action_pressed()`）。

现在：
- 删除了整个 `_unhandled_input()` 函数（约70行）
- `_process` 是唯一的技能输入处理器（使用 `Input.is_action_pressed()` 支持按住连发）
- 一次性技能（传送、Fire Walk toggle）使用 `Input.is_action_just_pressed()`

**变更二：21个 cast_xxx() 函数合并为统一调度**

旧架构：
```gdscript
func cast_magic_missile():
    MagicMissile.cast(self, mouse_pos, skill_cooldowns)
func cast_fireball():
    Fireball.cast(self, mouse_pos, skill_cooldowns)
# ... 21个这样的函数
```

新架构（[hero.gd](file:///e:/EvilInvasion/GodotReMake/Scripts/hero.gd)）：
```gdscript
const SKILL_SCRIPTS := {
    "magic_missile": MagicMissile,
    "fireball": Fireball,
    # ... 全部21个技能
}

func _cast_skill(skill_id: String) -> bool:
    var script = SKILL_SCRIPTS.get(skill_id)
    if not script:
        return false
    if not SKILLS_NO_ATTACK.has(skill_id):
        start_attack()
    if not script.cast(self, mouse_pos, skill_cooldowns):
        return false
    _update_shield_visual()
    if not SKILLS_NO_MULTICAST.has(skill_id):
        _try_multicast(skill_id)
    return true
```

效果：**净减少约200行重复代码**，所有技能通过 `_cast_skill("skill_id")` 统一调用。

### 🐛 Bug修复
- **冷却缩减遗物反向生效**：`relic_manager.gd` 中 `get_cooldown_multiplier()` 原用 `-=` 导致冷却倒计时变慢，改为 `+=` 后实现真正的"技能加速"效果
- **遗物影响范围扩大**：冷却遗物现在正确影响自动火球间隔、自动飞弹间隔和护盾充能速度
- **击退方向修复**：从 `global_position.direction_to(monster) * -1`（随机方向）改为 `direction`（弹道飞行方向）
- **击退距离修正**：速度从 50→100（50px/s × 0.1s = 5px → 100px/s × 0.1s = 10px）
- **传送键修复**：`spell_teleport`（键2）重新添加到 `_process()` 的输入检测中
- **死亡重试清空快捷键**：`Global.reset()` 中清空 quick_slot_lmb/rmb/shift/space，新局恢复默认
- **Shift/Space默认技能修正**：从错误默认值（freezing_spear/heal）改为空，无快捷键绑定

### ⚡ 性能优化
- **StyleBoxFlat 缓存**：`hud.gd` 中 `_update_single_slot()` 不再每次创建 StyleBoxFlat 实例
- **冷却更新节流**：冷却UI从每帧更新改为每6帧更新一次（~10次/秒），减少83% UI重绘
- **Buff图标缓存**：`buff_icon.gd` 添加进度值缓存，变化<1%时跳过多边形重建
- **全局清理**：移除60+条调试 print 语句（12个文件）

### 🎨 UI 修复
- **冷却扇形居中**：`cooldown_overlay` 改用 `PRESET_FULL_RECT` 填满按钮，中心自动对齐图标
- **Dev按钮位置**：HeroPanel.tscn 中按钮宽度从200缩至110px，位置上移避免与SkillPointsRow重叠

### 📝 文档更新
- **`SPELL_DEVELOPMENT_GUIDE.md`**：全面更新 Hero.gd 集成规范章节，移除旧的 cast_xxx() 模式，替换为 SKILL_SCRIPTS 字典 + 统一 `_cast_skill()` 模式，移除 `_unhandled_input` 输入处理示例
- **`ROADMAP.md`**：新增 v12 优化/修复清单，更新最后更新日期
- **`HANDOVER_PROMPT_FOR_NEXT_AGENT.md`**：新增本会话工作记录

---

## 开发约定

- 使用**中文**交流
- 技能数值以 `evil_invasion_spell.xlsx` 为准
- 一个技能一个场景的架构
- snake_case 命名变量/函数，PascalCase 命名场景文件
- **所有 .md 文档已更新到最新状态（2026-05-16）**
- **所有怪物数值统一在 `monster_database.gd` 管理**，.tscn 中不再保留重复参数
- **刷怪参数（间隔/数量/解锁等级）来源不确定**，建议根据游戏体验调整

## ⚠️ 关键教训：暂停状态下 UI 面板的输入处理

**HeroPanel（T键）和PauseMenu（ESC键）必须使用 `_input(event)` + `PROCESS_MODE_ALWAYS` 来实现。**

### 正确写法（不可改动）
```gdscript
extends Control
# 场景文件中必须设置 process_mode = 3（PROCESS_MODE_ALWAYS）

func _input(event):                          # ← 必须用 _input，不能用 _process
    if event.is_action_pressed("toggle_hero_panel"):  # ← 必须用 event 参数，不能用 Input 单例
        toggle()
```

### ❌ 曾经踩过的坑

有个 agent 把 `_input(event)` 改成了 `_process(_delta)` + `Input.is_action_just_pressed()`，结果：
- 按 T 打不开 HeroPanel（按键被暂停状态吞掉）
- 按 ESC 打不开 PauseMenu（连带影响）
- 整个游戏无法正常交互
- 最终需要通过 `git push --force origin master` 回滚修复

### 为什么 `_input(event)` 不可替代？

| 方案 | 暂停时能否工作 | 原理 |
|------|:---:|------|
| `_input(event)` + `PROCESS_MODE_ALWAYS` | ✅ | 每个输入事件独立传递到节点，不受暂停影响 |
| `_process(_delta)` + `Input.is_action_just_pressed()` | ❌ | 依赖全局输入缓存，暂停时缓存刷新时机错乱 |
| `_unhandled_input(event)` | ❌ | 暂停时停止分发 |

### 适用范围
- **HeroPanel**：`toggle_hero_panel`（T键）
- **PauseMenu**：`pause_game`（ESC键）
- **VictoryScreen / GameOverScreen / LevelCompleteScreen**：`pause_game`（阻止事件传播）
- 所有需要在游戏暂停时接收输入的 UI 面板都必须用此模式

### 为什么 T/ESC 和技能键（ZXC 等）不同？

这是**两类本质不同的按键**，必须用不同的输入处理模式：

| 维度 | 菜单键 T / ESC | 技能键 Z X C V 等 |
|------|:---:|:---:|
| **作用对象** | 引擎本身（场景树暂停/恢复） | 游戏世界（英雄放技能） |
| **暂停时** | **必须工作**（否则关不掉面板） | **必须不工作**（暂停了还放技能不合理） |
| **处理函数** | `_input(event)` | `_unhandled_input(event)` 或 `_process(delta)` |
| **process_mode** | `ALWAYS`（3） | `INHERIT`（默认） |
| **事件流位置** | 上游（先拿到事件） | 下游（等 UI 处理完） |

**事件流路线：**
```
Input 事件进入 Godot
      │
      ▼
  _input()         ← T / ESC 在这里处理（上游）
      │
      ▼
  _input()         ← 其他 UI 处理
      │
      ▼
  _unhandled_input()  ← 技能键 ZXC 在这里处理（下游）
```

**技能键为什么用下游？**
- 技能键需要"无冲"（同时按 Z 放火球 + X 放冰霜，互不干扰）
- `_unhandled_input` 在事件流末尾，前面的 UI 节点都处理完了再轮到英雄
- 如果游戏暂停，事件根本流不到 `_unhandled_input` → 技能自然不会在暂停时触发 ✅

**菜单键为什么用上游？**
- T / ESC 是"控制游戏状态"的元按键，而不是"在游戏内部操作"的功能按键
- 必须在 `_input` 中立即截获，调用 `set_input_as_handled()` 防止事件继续传播到技能系统
- 必须配合 `PROCESS_MODE_ALWAYS`，确保暂停时仍能接收按键来关闭面板

**一句话总结：T 和 ESC 是控制游戏状态的「元按键」，ZXC 是在游戏内部操作的「功能按键」。前者必须跳出暂停之外工作，后者必须在暂停时自然停止。**

## 建议下一步工作（按优先级）

1. **高分榜** — 原版有在线高分榜（对话框 UI 已从 Data.pak 提取参考）
2. **选项设置** — 音量/按键自定义/画面设置（优先级低）
3. **地图纹理** — 6张 DDS 纹理已提取，替换当前绿色占位地面
4. **音效系统** — 68个OGG已提取，需对接到各技能
5. **游戏导出** — export_presets.cfg 已配置加密参数，已成功导出加密版单 exe（build/EvilInvasion_Encrypted.exe），后续导出可直接运行 export_game.ps1 或使用 Godot → Export 菜单

---

## ⚠️ v12 关键架构变更提醒

### 1. hero.gd 不再有 `_unhandled_input()`
所有技能输入仅在 `_process()` 中使用 `Input.is_action_pressed()` / `Input.is_action_just_pressed()` 检测。
如果需要添加新的技能快捷键，只需在 `_process()` 中添加一行调用 `_cast_skill("skill_id")` 即可，**不需要重复添加 cast_xxx() 包装函数**。

### 2. 冷却缩减 == 技能加速
`get_cooldown_multiplier()` 返回 >1.0 的值。原理：`skill_cooldowns[skill] -= delta * multiplier`。
- `multiplier = 1.0`：正常速度
- `multiplier = 1.05`：快5%（cd_small）
- 需要某系统受冷却影响时，在计时器累加时乘以 `cd_mult` 即可

### 3. Quickslot 默认值
- LMB 空时默认 Magic Missile
- RMB 空时默认 Fireball
- Shift/Space 空时无默认技能（Z=Freezing Spear, C=Heal 有独立快捷键）