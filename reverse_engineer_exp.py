import struct
import re

# 读取 Logic.dll
with open('E:\\EvilInvasion\\Logic.dll', 'rb') as f:
    data = f.read()

print(f'Logic.dll 大小: {len(data)} bytes')
print('=' * 60)

# 1. 搜索所有 "EXPERIENCE" 出现位置并分析周围代码
print('\n1. 搜索 EXPERIENCE 相关代码...')
exp_positions = []
pos = 0
while True:
    pos = data.find(b'EXPERIENCE', pos)
    if pos == -1:
        break
    exp_positions.append(pos)
    pos += 1

print(f'找到 {len(exp_positions)} 个 EXPERIENCE 字符串')

# 分析每个位置周围的代码
for idx, pos in enumerate(exp_positions):
    print(f'\n位置 {idx}: 0x{pos:08X}')
    
    # 读取前后500字节
    start = max(0, pos - 500)
    end = min(len(data), pos + 500)
    chunk = data[start:end]
    
    # 尝试提取可打印字符
    text = ''
    for b in chunk:
        if 32 <= b <= 126:
            text += chr(b)
        else:
            text += '.'
    
    print(f'周围文本 (±500 bytes):')
    # 分段显示
    for i in range(0, len(text), 80):
        print(f'  {text[i:i+80]}')
    
    # 搜索附近的整数常量（可能是经验值公式的参数）
    print(f'附近整数常量:')
    for offset in range(-200, 200, 4):
        addr = pos + offset
        if addr >= 0 and addr + 4 <= len(data):
            val = struct.unpack('<I', data[addr:addr+4])[0]
            # 筛选合理的数值
            if 10 <= val <= 10000 and val % 10 == 0:
                print(f'  0x{addr:08X}: {val}')

# 2. 搜索乘法指令模式（经验值计算通常涉及乘法）
print('\n' + '=' * 60)
print('2. 搜索可能的乘法/加法指令模式...')

# x86 指令模式
# IMUL (整数乘法) 指令: 0x69 或 0x6B
imul_positions = []
pos = 0
while True:
    pos = data.find(b'\x69', pos)
    if pos == -1:
        break
    imul_positions.append(pos)
    pos += 1

print(f'找到 {len(imul_positions)} 个 IMUL 指令 (0x69)')

# 检查每个 IMUL 指令附近的常量
for idx, pos in enumerate(imul_positions[:20]):  # 只检查前20个
    # IMUL 指令格式: 69 /r id
    # 后面通常跟着一个32位常量
    if pos + 6 <= len(data):
        const = struct.unpack('<I', data[pos+2:pos+6])[0]
        if 10 <= const <= 10000:
            print(f'  IMUL @ 0x{pos:08X}: 常量 = {const}')

# 3. 搜索加法指令（ADD）
print('\n3. 搜索加法指令...')
add_positions = []
pos = 0
while True:
    pos = data.find(b'\x05', pos)  # ADD EAX, imm32
    if pos == -1:
        break
    add_positions.append(pos)
    pos += 1

print(f'找到 {len(add_positions)} 个 ADD EAX 指令 (0x05)')

for idx, pos in enumerate(add_positions[:20]):
    if pos + 5 <= len(data):
        const = struct.unpack('<I', data[pos+1:pos+5])[0]
        if 10 <= const <= 10000:
            print(f'  ADD @ 0x{pos:08X}: 常量 = {const}')

# 4. 搜索经验值相关的浮点数运算
print('\n' + '=' * 60)
print('4. 搜索浮点数常量...')

# 常见的经验值公式系数
float_constants = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 5.0, 10.0, 100.0, 150.0, 200.0]
for f_val in float_constants:
    pattern = struct.pack('<f', f_val)
    count = data.count(pattern)
    if count > 0:
        print(f'  浮点数 {f_val}: 出现 {count} 次')

print('\n完成！')
