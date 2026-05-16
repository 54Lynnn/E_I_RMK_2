# Evil Invasion Remake — v12 交接提示词（发给下一个 coding agent）

> **项目**: Evil Invasion (2006年Flash游戏) Godot 4.6 重制版
> **引擎**: Godot 4.6.2
> **GitHub**: https://github.com/54Lynnn/E_I_RMK_2
> **最新更新**: v12 Agent — hero.gd全面重构 + 统一施法调度 + 冷却缩减遗物修正 + 全项目性能优化
> **语言**: 用户使用中文交流

---

## 快速开始

1. 在 Godot 4.6.2 中导入 `GodotReMake/` 项目
2. 运行 `GameModeSelect.tscn` 进入游戏
3. 按 **F2** 进入 DevMode（+100属性点+100技能点方便测试）
4. 按 **T** 打开技能树给技能升级

## 必读文档（按顺序）

1. **`HANDOVER_PROMPT_FOR_NEXT_AGENT.md`** — 最完整的交接文档（含 v10/v11/v12 所有变更）
2. **`DEVELOPER_HANDOVER.md`** — 项目结构、核心系统详解
3. **`GAME_SYSTEMS_DESIGN.md`** — 游戏系统设计文档（怪物、掉落、Buff等）
4. **`ROADMAP.md`** — 开发路线图
5. **`SPELL_DEVELOPMENT_GUIDE.md`** — 技能开发规范（**已更新 v12 统一调度模式**）

---

## v12 Agent 完成的工作（当前会话）

### 🏗️ hero.gd 架构重构（重大变更）

**变更一：移除了 `_unhandled_input()`**

旧代码中 `_process()` 和 `_unhandled_input()` 同时检测全部21个技能的按键，导致每按一次技能键被施放两次。现在完全删除了 `_unhandled_input()`（约70行），所有技能输入仅在 `_process()` 中处理。

**变更二：21个 cast_xxx() 合并为统一调度函数**

旧代码有21个独立的 cast_magic_missile()、cast_fireball() 等函数（约200行重复代码）。现在使用 SKILL_SCRIPTS 字典 + `_cast_skill(skill_id)` 统一调度：

```gdscript
const SKILL_SCRIPTS := {
    "magic_missile": MagicMissile,
    "fireball": Fireball,
    # ... 全部21个技能
}

func _cast_skill(skill_id: String) -> bool:
    var script = SKILL_SCRIPTS.get(skill_id)
    if not script: return false
    if not SKILLS_NO_ATTACK.has(skill_id): start_attack()
    if not script.cast(self, mouse_pos, skill_cooldowns): return false
    _update_shield_visual()
    if not SKILLS_NO_MULTICAST.has(skill_id): _try_multicast(skill_id)
    return true
```

添加新技能时，只需：
1. 在 SKILL_SCRIPTS 字典中添加一行映射
2. 在 _process() 中添加一行 Input 检测调用 _cast_skill("xxx")
3. **不需要写 cast_xxx() 包装函数**

### 🐛 修复的Bug

| Bug | 修复方式 |
|-----|---------|
| 冷却缩减遗物反向生效 | `get_cooldown_multiplier()` 中 `-=` 改为 `+=` |
| 冷却遗物未影响自动技能 | 自动火球/飞弹/护盾计时器乘以 `cd_mult` |
| 击退方向错误 | 从 `direction_to(monster)*-1` 改为弹道 `direction` |
| 传送键2无效 | `spell_teleport` 添加到 _process 输入检测 |
| 死亡重试快捷键残留 | `Global.reset()` 中清空 quick_slot |
| Shift/Space默认绑定错误 | 移除错误的 freezing_spear/heal 默认值 |
| 冷却扇形不居中 | `cooldown_overlay` 改用 PRESET_FULL_RECT |
| Dev按钮超出面板 | 宽度200→110px，位置上移 |

### ⚡ 性能优化

- **StyleBoxFlat 缓存**：hud.gd 不再每帧创建新对象
- **冷却UI节流**：每帧→每6帧更新一次（减少83%重绘）
- **Buff图标缓存**：进度变化<1%时跳过重建
- **全局清理**：移除60+条调试 print（12个文件）

---

## ⚠️ 关键架构提醒（v12 变更）

### 1. hero.gd 不再有 _unhandled_input

所有技能输入仅在 `_process()` 中。一次性技能（传送、toggle）用 `Input.is_action_just_pressed()`，按住连发的技能用 `Input.is_action_pressed()`。

### 2. 冷却缩减 = 技能加速

原理是 `skill_cooldowns[skill] -= delta * multiplier`，multiplier > 1.0 代表走得更快：
- cd_small: 1.05（5%加速）
- cd_medium: 1.10（10%加速）
- cd_large: 1.20（20%加速）
- 三个全拿: 1.35

需要新系统受冷却影响时，在其计时器累加时乘以 `get_cooldown_multiplier()`。

### 3. 击退系统

怪物基类 `monster_base.gd` 新增了 `knockback_velocity` 和 `knockback_timer` 变量，以及 `set_knockback(velocity, duration)` 方法。在 `_physics_process` 的 `move_and_slide()` 前应用。新技能需要击退效果时调用 `monster.set_knockback(direction * speed, duration)`。

### 4. Quickslot 默认值

| 槽位 | 空时默认 | 独立快捷键 |
|------|---------|-----------|
| LMB | Magic Missile | - |
| RMB | Fireball | - |
| Shift | 无 | Shift键本身 |
| Space | 无 | 空格键本身 |

Z=Freezing Spear, X=Prayer, C=Heal, 2=Teleport 等有独立快捷键，不受 quickslot 影响。

---

## 建议下一步工作（按优先级）

1. **高分榜** — 原版有在线高分榜功能
2. **选项设置** — 音量/按键自定义/画面设置
3. **地图纹理** — 6张 DDS 纹理已从 Data.pak 提取
4. **音效系统** — 68个OGG音频已提取，需对接各技能和事件
5. **怪物特殊能力** — Bear冲锋、Spider毒液等标注"待实现"的能力
6. **Quest模式关卡解锁持久化** — 进度数据持久化保存
