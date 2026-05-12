extends SceneTree

func _init():
    print("=== Quest模式测试 ===")
    
    # 加载 Global
    var global_script = preload("res://Scripts/global.gd")
    var global = global_script.new()
    global.name = "Global"
    get_root().add_child(global)
    
    # 设置游戏状态
    global.current_game_mode = global.GameMode.QUEST
    global.hero_level = 1
    global.hero_experience = 0
    
    # 创建关卡管理器
    var level_manager = preload("res://Scripts/Quest/quest_level_manager.gd").new()
    level_manager.name = "QuestLevelManager"
    level_manager.add_to_group("quest_level_manager")
    get_root().add_child(level_manager)
    
    # 创建生成器
    var spawner = preload("res://Scripts/Quest/quest_monster_spawner.gd").new()
    spawner.name = "QuestMonsterSpawner"
    level_manager.add_child(spawner)
    level_manager.spawner = spawner
    spawner.level_manager = level_manager
    
    # 开始第1关
    print("\n--- 开始第1关 ---")
    level_manager.start_level(0)
    
    print("\n--- 模拟击杀怪物获得经验 ---")
    # 模拟击杀20只怪物，每次获得100经验
    for i in range(20):
        # 模拟击杀
        level_manager.on_monster_killed()
        
        # 获得经验
        global.gain_experience(100)
        
        print("击杀 %d, 等级 %d, 经验 %d" % [i+1, global.hero_level, global.hero_experience])
        
        # 检查生成器状态
        print("  生成器状态: is_spawning=%s, spawned_count=%d" % [str(spawner.is_spawning), spawner.spawned_count])
        
        # 如果达到等级上限，停止测试
        if level_manager.is_level_cap_reached:
            print("\n=== 达到等级上限！===")
            break
    
    print("\n--- 最终状态 ---")
    print("等级: %d" % global.hero_level)
    print("起始等级: %d" % level_manager.level_start_level)
    print("已升级: %d" % (global.hero_level - level_manager.level_start_level))
    print("等级上限: %s" % str(level_manager.is_level_cap_reached))
    print("生成器状态: is_spawning=%s" % str(spawner.is_spawning))
    
    quit()
