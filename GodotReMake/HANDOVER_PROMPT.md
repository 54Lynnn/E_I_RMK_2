# Evil Invasion Remake - 交接提示词

> **交接日期**: 2026-05-08
> **GitHub仓库**: https://github.com/54Lynnn/E_I_RMK_2
> **项目路径**: e:\EvilInvasion\GodotReMake

---

## 你好，新的Agent！

我是上一个与开发者合作的Agent。我们已经完成了大量工作，现在将项目交接给你。请仔细阅读以下信息，确保你能顺利接手。

---

## 1. 项目当前状态

### 已完成的核心工作
- ✅ **全部21个技能已重构为独立场景/脚本**（原版21个，包括Ball Lightning和Chain Lightning）
- ✅ **全部技能数值修正完成**（所有技能数值已对照 `E:\EvilInvasion\evil_invasion_spell.xlsx` 修正）
- ✅ **全部21个技能测试通过**（2026-05-09完成测试）
- ✅ **Dark Ritual debuff系统实现**（水属性技能统一受水抗性影响）
- ✅ **节点命名规范建立**（所有技能场景节点统一命名）
- ✅ **Fire Walk节点层级修复**（火焰正确添加到场景根节点）
- ✅ **掉落物系统完善**（图标大小1.5倍、碰撞体积增大、Telekinesis读条效果）
- ✅ **Fortuna被动技能修复**（正确实现乘法加成，监听技能等级变化）
- ✅ **Air系技能**：Ball Lightning（球状闪电，U键）和Chain Lightning（连锁闪电，R键）

### 当前技术栈
- **引擎**: Godot 4.6.2-stable
- **语言**: GDScript
- **平台**: Windows
- **Godot路径**: `e:\project\game\zhongzhuangbinqi V2\Godot_v4.6.2-stable_win64_console.exe`

---

## 2. 必读文档（按顺序）

1. **DEVELOPER_HANDOVER.md** - 项目全貌、技术债务、下一步建议
2. **ROADMAP.md** - 开发路线图、原版参数参考
3. **SPELL_DEVELOPMENT_GUIDE.md** - 技能开发规范（含节点命名规范）
4. **NAMING_CONVENTIONS.md** - 命名规范文档（新增）
5. **extracted.md** - 原版反编译数据

---

## 3. 关键设计决策（你必须知道）

### 3.1 节点命名规范（极其重要！）

所有技能生成的场景节点必须遵循统一命名：

| 节点类型 | 后缀 | 示例 |
|---------|------|------|
| 场地效果 | `_zone` | `fire_walk_zone`, `poison_cloud_zone`, `dark_ritual_zone` |
| 投射物 | `_proj` | `magic_missile_proj`, `fireball_proj` |
| 爆发效果 | `_effect` | `nova_effect` |

**规则**：
- 使用技能ID（snake_case）+ 类型后缀
- 节点名称必须在实例化后立即设置，在 `add_child()` 之前
- 场地效果技能必须使用 `hero.get_parent().add_child()` 添加到场景根节点

### 3.2 Dark Ritual debuff系统

- Dark Ritual 从直接伤害改为 debuff 系统
- 怪物进入范围获得 `dark_ritual` debuff
- debuff 结束时进行秒杀判定（30%几率）
- 判定逻辑在 `monster.gd` 的 `_on_debuff_removed` 中处理
- **水属性技能统一受水抗性影响**（Poison Cloud, Nova, Freezing Spear, Dark Ritual）

### 3.3 技能数值修正

> ⚠️ **重要**：所有技能的准确数值请以 `E:\EvilInvasion\evil_invasion_spell.xlsx` 为准。
> `extracted.md` 中的技能数值存在等级偏移错误，**请勿使用**。

已完成修正的技能（等级1参考值）：
- Fireball: 冷却0.5s, 伤害50, 爆炸半径56
- Meteor: 冷却5s, 伤害250, 半径130
- Armageddon: 冷却20s, 伤害250
- Poison Cloud: 伤害60/秒, 持续10秒
- Nova: 伤害200, 半径100, 带冰冻效果
- Fortuna: 掉率加成15%（乘法加成：10% × 1.15 = 11.5%）
- Telekinesis: 被动技能, 悬停1.0秒拾取（带进度条显示）
- Wrath of God: 冷却2s, 伤害200
- Magic Missile: 伤害10, 1s冷却

**掉落物系统（2026-05-09更新）：**
- 基础掉落率10%，受Fortuna技能影响（乘法加成）
- 5种稀有度：Common(40%), Uncommon(30%), Unique(15%), Rare(10%), Exceptional(5%)
- 12种物品类型，包括药水、护盾、增益、属性点、技能点等
- 掉落物图标大小1.5倍，碰撞体积半径24
- Telekinesis被动：鼠标悬停自动拾取（带进度条）

---

## 4. 你的工作重点

开发者希望继续完善游戏，主要方向包括：

### 4.1 技能系统完善
- 继续按原版参数修正剩余技能数值
- 添加更多技能视觉效果
- 实现技能音效
- **新增技能**：Ball Lightning和Chain Lightning已实现，但可能需要平衡性调整

### 4.2 怪物系统扩展
- 添加更多怪物种类（Archer, Bear, Boss等）
- 让怪物行为更加多样化
- 实现不同AI（远程、快速、高血量等）

### 4.3 游戏内容丰富
- 添加地图/关卡系统
- 实现波次防御模式
- 添加Boss战

### 4.4 系统完善
- 添加存档系统
- 添加设置菜单
- 优化UI和视觉效果

---

## 5. 代码规范（必须遵守）

### 5.1 命名规范
- 变量/函数: snake_case
- 类名: PascalCase
- 常量: UPPER_SNAKE_CASE
- 信号: 过去式 snake_case

### 5.2 技能开发规范
- 每个技能独立的 `.tscn` + `.gd` 文件
- 静态 `cast()` 方法作为统一入口
- 技能数据（冷却、伤害、消耗）在脚本内定义
- Muzzle 路径必须是 `"Sprite2D/Muzzle"`

### 5.3 重要约束
- **伤害是固定值，禁止加入 hero_intelligence 等属性**
- **技能名称一致性极其重要**（magic_missile 不能写成 fire_ball）
- **代码风格**: snake_case 变量/函数，PascalCase 类名，Tab 缩进

---

## 6. 测试方法

1. 运行游戏（F5）
2. 按 F2 进入 DevMode（所有技能默认已学会）
3. 测试技能是否正常施放
4. 使用 Remote 场景树检查节点层级
5. 检查控制台输出是否有错误

---

## 7. 常见陷阱

1. **project.godot是二进制格式** - 直接文本编辑可能导致格式错误
2. **场景文件(.tscn)格式敏感** - 修改时保持缩进和格式一致
3. **自动加载脚本** - global.gd和loot_manager.gd是自动加载的
4. **节点层级** - 场地效果必须添加到场景根节点，不能添加到hero内部
5. **水抗性系统** - 所有水属性技能统一受水抗性影响

---

## 8. 开发者沟通风格

- 使用中文交流
- 会提供原版游戏截图作为参考
- 重视视觉还原度（"参考原版设计"）
- 喜欢讨论设计决策（如命名规范、机制设计）
- 希望理解"为什么"而不仅是"怎么做"

---

## 9. 快速启动

```powershell
# 检查语法
& "e:\project\game\zhongzhuangbinqi V2\Godot_v4.6.2-stable_win64_console.exe" --headless --check-only --quit "e:\EvilInvasion\GodotReMake\project.godot"

# 运行游戏
& "e:\project\game\zhongzhuangbinqi V2\Godot_v4.6.2-stable_win64_console.exe" --path "e:\EvilInvasion\GodotReMake"
```

---

**祝开发顺利！有任何问题请查阅文档或询问开发者。**
