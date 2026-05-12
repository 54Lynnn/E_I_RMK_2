import struct

# 读取存档文件
with open('E:\\EvilInvasion\\Profiles\\123.ei', 'rb') as f:
    data = f.read()

print('存档文件详细分析')
print('=' * 50)

# 文件头
print(f'\n文件头: {data[:8]}')
print(f'版本: {data[:10]}')

# 尝试解析为各种格式
print('\n作为4字节整数:')
for i in range(0, len(data)-3, 4):
    val = struct.unpack('<I', data[i:i+4])[0]
    # 只显示有意义的值
    if val > 0 and val < 1000000:
        print(f'  偏移 {i:3d}: {val:8d}', end='')
        if val < 100:
            print(f' <- 可能是等级/技能点')
        elif val < 1000:
            print(f' <- 可能是属性值')
        elif val < 100000:
            print(f' <- 可能是经验值')
        else:
            print()

print('\n作为浮点数:')
for i in range(0, len(data)-3, 4):
    val = struct.unpack('<f', data[i:i+4])[0]
    if val > 0.1 and val < 1000:
        print(f'  偏移 {i:3d}: {val:.2f}')

# 尝试查找经验值公式
print('\n尝试推导经验值公式...')
# 如果112430是1级经验值，尝试找出规律
exp_val = 112430
print(f'当前经验值: {exp_val}')

# 尝试各种公式
import math

# 测试线性公式
for base in [50, 100, 150, 200]:
    for mult in [1, 2, 3, 4, 5]:
        calc = base * mult
        if abs(calc - exp_val) < 1000:
            print(f'  可能的公式: {base} * {mult} = {calc}')

# 测试指数公式
for base in [100, 200]:
    for power in [1.5, 2.0, 2.5, 3.0]:
        calc = int(base * math.pow(1, power))  # 1级
        if abs(calc - exp_val) < 1000:
            print(f'  可能的公式: {base} * level^{power} = {calc}')

# 测试累积公式
for base in [100, 200, 500]:
    calc = sum(base * i for i in range(1, 2))  # 1级累积
    if abs(calc - exp_val) < 1000:
        print(f'  可能的累积公式: sum({base} * i) = {calc}')

print('\n完成！')
