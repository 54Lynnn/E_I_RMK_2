import struct

# 读取 Logic.dll
with open('E:\\EvilInvasion\\Logic.dll', 'rb') as f:
    data = f.read()

print('深入分析 Logic.dll')
print('=' * 60)

# 1. 查找浮点数 150.0 的位置
print('\n1. 查找浮点数 150.0 的位置...')
pattern_150 = struct.pack('<f', 150.0)
pos = data.find(pattern_150)
if pos != -1:
    print(f'找到 150.0 @ 0x{pos:08X}')
    
    # 分析周围代码
    start = max(0, pos - 200)
    end = min(len(data), pos + 200)
    chunk = data[start:end]
    
    # 显示十六进制
    print(f'周围十六进制 (±200 bytes):')
    for i in range(0, len(chunk), 16):
        hex_str = ' '.join(f'{b:02X}' for b in chunk[i:i+16])
        print(f'  0x{start+i:08X}: {hex_str}')
    
    # 尝试反汇编周围的代码
    print(f'\n尝试反汇编...')
    # 查找函数开头（通常是 0x55 0x8B 0xEC - push ebp; mov ebp, esp）
    for offset in range(-200, 0):
        if pos + offset >= 0:
            if data[pos+offset:pos+offset+3] == b'\x55\x8B\xEC':
                print(f'  可能的函数开头 @ 0x{pos+offset:08X}')
                break

# 2. 查找 100.0 的位置
print('\n2. 查找浮点数 100.0 的位置...')
pattern_100 = struct.pack('<f', 100.0)
pos = 0
count = 0
while True:
    pos = data.find(pattern_100, pos)
    if pos == -1:
        break
    count += 1
    print(f'  找到 100.0 #{count} @ 0x{pos:08X}')
    
    # 显示周围文本
    start = max(0, pos - 100)
    end = min(len(data), pos + 100)
    text = ''
    for b in data[start:end]:
        if 32 <= b <= 126:
            text += chr(b)
        else:
            text += '.'
    print(f'    周围: {text[:80]}')
    
    pos += 1

# 3. 查找 200.0 的位置
print('\n3. 查找浮点数 200.0 的位置...')
pattern_200 = struct.pack('<f', 200.0)
pos = 0
count = 0
while True:
    pos = data.find(pattern_200, pos)
    if pos == -1:
        break
    count += 1
    print(f'  找到 200.0 #{count} @ 0x{pos:08X}')
    
    # 显示周围文本
    start = max(0, pos - 100)
    end = min(len(data), pos + 100)
    text = ''
    for b in data[start:end]:
        if 32 <= b <= 126:
            text += chr(b)
        else:
            text += '.'
    print(f'    周围: {text[:80]}')
    
    pos += 1

# 4. 查找经验值相关的整数常量
print('\n4. 查找经验值相关的整数常量...')
# 搜索 100, 150, 200, 300, 500, 1000 等
exp_constants = [100, 150, 200, 300, 500, 1000]
for const in exp_constants:
    pattern = struct.pack('<I', const)
    pos = 0
    count = 0
    positions = []
    while True:
        pos = data.find(pattern, pos)
        if pos == -1 or count >= 5:
            break
        positions.append(pos)
        count += 1
        pos += 1
    
    if positions:
        print(f'  整数 {const}: 找到 {count} 次')
        for p in positions[:3]:
            print(f'    @ 0x{p:08X}')

# 5. 查找 EXPERIENCE_GIVE 和 EXPERIENCE 之间的代码
print('\n5. 分析 EXPERIENCE 和 EXPERIENCE_GIVE 之间的关系...')
exp_give_pos = data.find(b'EXPERIENCE_GIVE')
exp_pos = data.find(b'EXPERIENCE')

if exp_give_pos != -1 and exp_pos != -1:
    print(f'EXPERIENCE_GIVE @ 0x{exp_give_pos:08X}')
    print(f'EXPERIENCE @ 0x{exp_pos:08X}')
    print(f'距离: {abs(exp_pos - exp_give_pos)} bytes')

print('\n完成！')
