import struct
import os

print('对比存档文件')
print('=' * 60)

# 读取存档
save_file = 'E:\\EvilInvasion\\Profiles\\123.ei'
with open(save_file, 'rb') as f:
    data = f.read()

# 读取 profiles.dat
profiles_file = 'E:\\EvilInvasion\\Profiles\\profiles.dat'
if os.path.exists(profiles_file):
    with open(profiles_file, 'rb') as f:
        profiles_data = f.read()
    print(f'profiles.dat 大小: {len(profiles_data)} bytes')
    
    # 解析 profiles.dat
    print('\nprofiles.dat 内容:')
    for i in range(0, len(profiles_data)-3, 4):
        val = struct.unpack('<I', profiles_data[i:i+4])[0]
        print(f'  偏移 {i:3d}: {val:10d}')

print('\n' + '=' * 60)
print('深入分析存档中的经验值...')

# 检查偏移20-23的值
exp_val = struct.unpack('<I', data[20:24])[0]
print(f'偏移20-23的值: {exp_val}')

# 尝试不同的解释
print('\n尝试不同的解释:')
print(f'1. 作为经验值: {exp_val}')
print(f'2. 作为某种编码: 可能是 {exp_val // 100} 或 {exp_val // 1000}')

# 检查是否与等级相关
level = struct.unpack('<I', data[16:20])[0]
print(f'\n当前等级: {level}')
print(f'如果经验值 = 等级 * 150:')
print(f'  等级1需要: 150')
print(f'  等级2需要: 300')
print(f'  等级3需要: 450')

# 检查112430是否可能是某种累积值
print(f'\n112430 可能是累积经验值:')
print(f'  如果每级需要 level * 150:')
print(f'  升到等级N需要的总经验 = 150 * (1 + 2 + ... + N-1) = 150 * N*(N-1)/2')

# 反推等级
import math
# 150 * N * (N-1) / 2 = 112430
# N * (N-1) = 112430 * 2 / 150 = 1499.06
# N^2 - N - 1499 = 0
# N = (1 + sqrt(1 + 4*1499)) / 2 = (1 + sqrt(5997)) / 2 = (1 + 77.44) / 2 = 39.22

n = (1 + math.sqrt(1 + 4 * 1499.06)) / 2
print(f'\n如果112430是累积经验值，对应的等级约为: {n:.1f}')

# 检查存档中的其他可能经验值位置
print('\n检查其他可能的经验值位置:')
for i in range(0, len(data)-3, 4):
    val = struct.unpack('<I', data[i:i+4])[0]
    if val > 0 and val < 10000:
        print(f'  偏移 {i:3d}: {val:6d} <- 可能是经验值？')

print('\n' + '=' * 60)
print('结论:')
print('存档文件结构已初步解析，但经验值的具体含义需要进一步验证')
print('建议:')
print('1. 在游戏中创建新存档')
print('2. 获得一些经验后保存')
print('3. 对比两个存档的差异')
print('4. 这样可以精确定位经验值字段')
