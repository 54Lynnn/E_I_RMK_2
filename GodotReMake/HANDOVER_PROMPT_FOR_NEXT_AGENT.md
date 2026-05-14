以下的交接文档将被发送给我的合作者、一个coding assistant。请你阅读，然后根据它的要求一步一步完成任务。

---

# Evil Invasion Remake — 新 Agent 交接提示词

> **项目**: Evil Invasion (2006年Flash游戏) Godot 4.6 重制版
> **引擎**: Godot 4.6.2
> **GitHub**: https://github.com/54Lynnn/E_I_RMK_2
> **最新更新**: v9 Agent — 自动释放系统 + 技能数值校对 + 快捷槽位重做 + 移动修复

## 快速开始

1. `git clone` 后在 Godot 4.6.2 中导入 `GodotReMake/` 项目
2. 运行 `Scenes/Main.tscn`（Survival模式）或先运行 `GameModeSelect.tscn`
3. 按 **F2** 进入 DevMode（+100属性点+100技能点方便测试）
4. 按 **T** 打开技能树，给技能升级

## 必读文档

请依次阅读以下文档，它们包含了完整的项目信息：

1. **`HANDOVER_PROMPT.md`** — 项目完整状态、关键注意事项、最新变更（**最重要！**）
2. **`DEVELOPER_HANDOVER.md`** — 完整项目文档、核心系统详解
3. **`GAME_SYSTEMS_DESIGN.md`** — 游戏系统设计文档
4. **`ROADMAP.md`** — 开发路线图

---

## v9 会话完成的工作（2026-05-14）

### ✨ 新功能
- **自动释放系统（Auto-Cast）**：右键技能图标切换自动施法，金色蛇形虚线旋转光圈指示器，每0.15s检测冷却/蓝耗自动施法，朝鼠标位置施法（不自动寻找目标）
- **快捷槽位分配方案重做**：左键=LMB / Shift+左键=Shift / Shift+右键=RMB / Shift+Space+左键=Space，纯右键切换自动释放，不再冲突
- **斜向移动修复**：Input向量归一化 + 加速度700→3000，斜向移动响应更快

### 🎯 技能数值校对
- 全21个技能对照 `evil_invasion_spell.xlsx` 逐一验证
- **修复的数值错误**：Holy Light（查找表）、Magic Missile（查找表）、Nova（伤害/法力公式偏移）、Poison Cloud（法力公式偏移）、Stone Enchanted（概率公式偏移）、Fireball/FreezingSpear（常量修正）
- **Poison Cloud 伤害间隔优化**：1s→0.1s，每跳=秒伤/10
- **Chain Lightning bounce_range**：300→130
- **Armageddon 调整**：图标scale 4→2；爆炸半径 `56+(level-1)*1`；火球12→15/次；全图随机0~1536

### 🐛 Bug修复
- Prayer auto-cast 报错（无 get_mana_cost）
- 删除旧 HUD 悬停按键分配逻辑（与新的点击分配冲突）

## 开发约定

- 使用**中文**交流
- 技能数值以 `evil_invasion_spell.xlsx` 为准
- 一个技能一个场景的架构
- snake_case 命名变量/函数，PascalCase 命名场景文件
- 所有 .md 文档已更新到最新状态
- **所有怪物数值统一在 `monster_database.gd` 管理**，.tscn 中不再保留重复参数
- **刷怪参数（间隔/数量/解锁等级）来源不确定**，建议根据游戏体验调整

## 建议下一步工作（按优先级）

1. **主菜单** — 目前直接进入游戏模式选择
2. **高分榜** — 原版有在线高分榜（对话框 UI 已从 Data.pak 提取参考）
3. **选项设置** — 音量/按键自定义/画面设置（优先级低）
4. **地图纹理** — 6张 DDS 纹理已提取，替换当前绿色占位地面
5. **音效系统** — 68个OGG已提取，需对接到各技能
