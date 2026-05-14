# Evil Invasion Remake — 新 Agent 交接提示词

> **项目**: Evil Invasion (2006年Flash游戏) Godot 4.6 重制版
> **引擎**: Godot 4.6.2
> **GitHub**: https://github.com/54Lynnn/E_I_RMK_2
> **最新更新**: v10 Agent — Firewalk Toggle重写 + 爆炸碰撞检测统一 + Controls Guide + 导出加密

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
- **游戏导出加密配置**：export_presets.cfg 配置加密（encrypt_pck=true, encrypt_directory=true, script_export_mode=1），创建一键导出脚本 export_game.ps1

### 🎯 技能与平衡调整
- **Firewalk 参数**：无 mana cost，移动 30px 产生一团火焰，伤害半径 18px，火焰持续 2 秒（含 0.3s 渐隐），每 0.1s 结算一次 DOT
- **Meteor 平衡**：陨石生成间隔 0.2s → 0.4s，单颗陨石贴图 scale 0.8 → 0.5
- **Armageddon 平衡**：每批陨石数量 15 → 12
- **Autocast 优化**：检查间隔 0.15s → 0.1s
- **Telekinesis 数据修正**：从实际代码（pickup_item.gd）提取真实 hold_time 数据，1 级 1.0s，满级 0.55s

### 🐛 Bug修复
- **Teleport 按"2"键无效**：从 `_process` 移除 teleport 的 `is_action_pressed` 检测（受 `mouse_y < hud_top` 限制），仅保留在 `_unhandled_input`
- **Firewalk 火焰残留**：lambda 闭包捕获 self 导致 queue_free 后回调不执行 → 所有成员值提前复制到局部变量
- **Firewalk 无伤害**：PROCESS_MODE_WHEN_PAUSED 误用 → 改为 PROCESS_MODE_ALWAYS
- **Multicast 导致 firewalk 自动关闭**：cast_fire_walk() 中移除 _try_multicast("fire_walk")
- **hide_tooltip() 与基类方法冲突**：重命名为 _hide_skill_tooltip()
- **暂停时设置 Quickslot**：skill_bar_container.process_mode = PROCESS_MODE_ALWAYS
- **Controls Guide 场景加载失败**：移除 load_steps，使用 [gd_scene format=3]，信号名 closed → guide_closed
- **PROCESS_MODE_WHEN_PAUSED 语义误解**：多次误用，实际语义是"只在暂停时运行"，非暂停时反而不运行 → 改为 PROCESS_MODE_ALWAYS

### 🔍 Relic 与 Firewalk 交互审计
- 检查所有 relic 与 firewalk 的交互路径
- **范围加成**：RelicManager.get_aoe_radius_multiplier() 正确应用于 firewalk 火焰半径
- **冷却缩减**：不应用于 firewalk（toggle 类技能无冷却）
- **多重施法**：从 cast_fire_walk() 中移除 _try_multicast，toggle 类技能与多重施法不兼容
- **其他 relic**：无意外交互

### 🎨 HUD 改进
- **Firewalk toggle 图标**：hud.gd 新增 _update_firewalk_toggle_icon()，每帧检查 firewalk toggle 状态，开启时图标彩色，关闭时灰色
- **技能 tooltip 数据修正**：所有技能调用实际静态方法（get_damage/get_mana_cost 等），firewalk 显示无 mana cost + toggle 描述

---

## 开发约定

- 使用**中文**交流
- 技能数值以 `evil_invasion_spell.xlsx` 为准
- 一个技能一个场景的架构
- snake_case 命名变量/函数，PascalCase 命名场景文件
- **所有 .md 文档已更新到最新状态（2026-05-15）**
- **所有怪物数值统一在 `monster_database.gd` 管理**，.tscn 中不再保留重复参数
- **刷怪参数（间隔/数量/解锁等级）来源不确定**，建议根据游戏体验调整

## 建议下一步工作（按优先级）

1. **高分榜** — 原版有在线高分榜（对话框 UI 已从 Data.pak 提取参考）
2. **选项设置** — 音量/按键自定义/画面设置（优先级低）
3. **地图纹理** — 6张 DDS 纹理已提取，替换当前绿色占位地面
4. **音效系统** — 68个OGG已提取，需对接到各技能
5. **游戏导出** — 已配置加密导出，需下载 Godot 4.6.2 导出模板后执行 export_game.ps1