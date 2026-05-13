import struct

exe_path = r'e:\EvilInvasion\EvilInvasion.exe'

with open(exe_path, 'rb') as f:
    data = f.read()

print(f"File size: {len(data)} bytes")
print()

# 搜索已知的刷怪间隔数值（浮点数）
# 原版四个模式：SINGLE(1~3s), LINE(18~22s), GROUP(8~12s), ALL_SIDES(38~42s)
# 以及 monster_spawner.gd 中使用的各种数值

import struct

search_values = [
    # 可能的刷怪间隔
    (1.0, "SINGLE min"),
    (3.0, "SINGLE max"),
    (18.0, "LINE min"),
    (22.0, "LINE max"),
    (8.0, "GROUP min"),
    (12.0, "GROUP max"),
    (38.0, "ALL_SIDES min"),
    (42.0, "ALL_SIDES max"),
    # 编组大小
    (2.0, "Group 2"),
    (3.0, "Group 3"),
    (4.0, "Group 4 (2x2)"),
    (6.0, "Group 6 (3x2)"),
    (9.0, "Group 9 (3x3)"),
    # 单排数量
    (20.0, "LINE count"),
    (15.0, "ALL_SIDES per side"),
    # 生成边距
    (80.0, "spawn margin"),
    (100.0, "spawn margin alt"),
    # 最大怪物数
    (15.0, "max monsters"),
    # 怪物权重
    (25.0, "troll weight"),
    (22.0, "mummy weight"),
    (18.0, "spider weight"),
    (15.0, "demon weight"),
    (10.0, "bear weight"),
    (5.0, "reaper weight"),
    (2.0, "diablo weight"),
    # 检测范围
    (350.0, "detection range"),
    (400.0, "detection range"),
    (500.0, "detection range"),
    (600.0, "homing range"),
    # 攻击范围
    (40.0, "melee range"),
    (150.0, "too close"),
    (200.0, "attack range"),
    (300.0, "optimal range"),
    # 移动速度
    (55.0, "speed base"),
    (60.0, "speed base"),
    (65.0, "speed base"),
    # 等级相关
    (9.0, "all_sides level"),
    (17.0, "all_sides quest level"),
    # 难度系数
    (0.6, "Normal mult"),
    (0.8, "Nightmare mult"),
    (1.0, "Hardcore mult"),
]

print("=== Searching for float values ===")
for val, label in search_values:
    packed = struct.pack('<f', val)
    pos = 0
    while True:
        pos = data.find(packed, pos)
        if pos == -1:
            break
        # 显示上下文
        context_start = max(0, pos - 4)
        context_end = min(len(data), pos + 8)
        context = data[context_start:context_end]
        try:
            ctx_hex = ' '.join(f'{b:02x}' for b in context)
            ctx_ascii = ''.join(chr(b) if 32 <= b < 127 else '.' for b in context)
            print(f"  {label:25s} = {val:5.1f} at offset {pos:6d}: {ctx_hex} | {ctx_ascii}")
        except:
            pass
        pos += 1

print()

# 也搜索整数形式
print("=== Searching for integer values ===")
int_values = [
    (1, "SINGLE interval int"),
    (3, "SINGLE interval int"),
    (20, "LINE count int"),
    (15, "max/ALL_SIDES int"),
    (60, "all sides total"),
    (2, "diablo limit"),
    (3, "diablo limit"),
    (10, "percent"),
    (40, "percent"),
    (50, "percent"),
]

for val, label in int_values:
    packed = struct.pack('<I', val)
    pos = 0
    found = False
    while True:
        pos = data.find(packed, pos)
        if pos == -1:
            break
        context_start = max(0, pos - 4)
        context_end = min(len(data), pos + 8)
        context = data[context_start:context_end]
        ctx_hex = ' '.join(f'{b:02x}' for b in context)
        ctx_ascii = ''.join(chr(b) if 32 <= b < 127 else '.' for b in context)
        print(f"  {label:25s} = {val:4d} at offset {pos:6d}: {ctx_hex} | {ctx_ascii}")
        found = True
        pos += 1

print()
print("=== Looking for known strings ===")
strings_to_find = [b'SINGLE', b'LINE', b'GROUP', b'ALL_SIDES', b'SpawnPattern',
                   b'spawn', b'monster', b'Random', b'respawn', b'wander',
                   b'creep', b'wave', b'difficulty', b'budget', 
                   b'SpellBalance', b'MonsterBalance', b'HeroBalance']
for s in strings_to_find:
    pos = data.find(s)
    if pos != -1:
        context = data[max(0,pos-16):pos+len(s)+32]
        try:
            print(f"  Found '{s.decode()}' at offset {pos}")
        except:
            pass
    else:
        try:
            print(f"  NOT found '{s.decode()}'")
        except:
            pass
